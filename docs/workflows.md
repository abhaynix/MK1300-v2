# Application Workflows: Ant Esports MK1300 V2

## 1. Workflow 1: Application Startup & Device Handshake

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant App as Flutter App
    participant USB as USB HID Service (hidapi)
    participant KB as MK1300 V2 Hardware

    User->>App: Launch Application
    App->>USB: Initialize HID Context & Enumerate Devices
    USB->>USB: Filter VID == 0x36AE && PID == 0xFE12 && UsagePage == 0xFF00
    alt Keyboard Connected
        USB->>App: Device Found & Handle Opened
        App->>KB: CMD 0x06, Sub 0x05 (Get Device Hardware Config)
        KB-->>App: 64-byte Response (Firmware, Battery, Active Profile, Layer)
        App->>KB: CMD 0x06, Sub 0x0A (Get Active Lighting Config)
        KB-->>App: 64-byte Response (Mode, Brightness, Speed, Direction, HSV)
        App->>KB: CMD 0x06, Sub 0x08 (Read Key Mapping Chunks - Layer 0)
        KB-->>App: 4 Chunks x 56 bytes (61 Key Descriptors)
        App->>KB: CMD 0x06, Sub 0x13 (Read Custom Per-Key RGB Chunks)
        KB-->>App: 4 Chunks x 56 bytes (61 RGB Triples)
        App->>KB: CMD 0x06, Sub 0x0C (Read Macro Table - 4096 bytes)
        KB-->>App: 74 Chunks x 56 bytes
        App->>App: Populate Reactive UI State Machine
        App-->>User: Render Interactive Keyboard Visualizer & Active Settings
    else No Keyboard Connected
        App-->>User: Display "Device Disconnected" Warning & Offline Preview
        App->>USB: Start Background Hot-Plug Polling Listener
    end
```

---

## 2. Workflow 2: RGB Lighting Configuration

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as Lighting Page
    participant Service as LightingService
    participant Queue as Command Queue
    participant KB as MK1300 V2 Hardware

    User->>UI: Selects Lighting Mode (e.g. Mode 5 "Horizontal Streamer")
    UI->>Service: setLightEffect(mode: 5)
    Service->>Queue: Enqueue Query Preset: CMD 0x06, Sub 0x16 [22, 0, 0, 0, 1, 0, 5]
    Queue->>KB: Send 64-byte Report
    KB-->>Queue: Return Default Parameters for Mode 5
    Service->>Queue: Enqueue Write Config: CMD 0x06, Sub 0x0B [11, 11, 0, 0, ...]
    Queue->>KB: Send 64-byte Report
    KB-->>Queue: Acknowledge Packet
    User->>UI: Adjusts Speed Slider to 4
    UI->>Service: updateSpeed(4)
    Service->>Queue: Enqueue Write Config: CMD 0x06, Sub 0x0B
    Queue->>KB: Send 64-byte Report
    KB-->>Queue: Acknowledge Packet
    Note over KB: Keyboard immediately changes lighting pattern
```

---

## 3. Workflow 3: Single Key Remap & Multi-Layer Assignment

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as Key Remap Page
    participant Service as KeyService
    participant KB as MK1300 V2 Hardware

    User->>UI: Selects Layer: "Fn Layer" (Layer 1)
    UI->>UI: Update Visualizer Overlay with Fn Layer Keycodes
    User->>UI: Clicks Key "W" (Index 17)
    UI->>UI: Opens Key Remapping Drawer
    User->>UI: Clicks "Arrow Up" in Basic Keys
    UI->>Service: setSingleKey(keyIndex: 17, layer: 1, type: 32, code: 82)
    Service->>Service: Construct 64-byte Single Key Packet: CMD 0x06, Sub 0x10
    Service->>KB: Send Report: [0x06, 0x10, 0x07, 68, 0, 0, 1, 0, 32, 0, 82, 0, ...]
    KB-->>Service: Hardware Acknowledge
    UI->>UI: Update "W" Visualizer Legend to "↑"
    Note over KB: Pressing Fn + W now emits USB HID Arrow Up (Code 82)
```

---

## 4. Workflow 4: Macro Recording, Editing & Flashing

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant UI as Macro Page
    participant Rec as Macro Recorder Service
    participant Comp as Macro Compiler
    participant KB as MK1300 V2 Hardware

    User->>UI: Clicks "Start Recording" on Macro "M0"
    UI->>Rec: Start Global Hook
    User->>User: Presses 'Ctrl', then 'C', then releases 'C', then 'Ctrl'
    Rec->>UI: Stream Actions: Down(Ctrl), Down(C), Up(C), Up(Ctrl) with Δt delays
    User->>UI: Clicks "End Recording"
    UI->>Rec: Stop Global Hook
    User->>UI: Edits Delay of Step 2 from 23ms to 50ms
    UI->>UI: Update Action Table in-memory
    User->>UI: Clicks "Save to Keyboard"
    UI->>Comp: compileMacroTable(allMacros)
    Comp->>Comp: Generate 4096-byte Buffer with Offset Table & 4-byte Actions
    loop For each 59-byte chunk (70 iterations)
        Comp->>KB: CMD 0x06, Sub 0x0D [13, chunkLen, offsetLow, offsetHigh, ...bytes]
        KB-->>Comp: Acknowledge chunk
    end
    UI-->>User: Display "Macros Successfully Saved to Keyboard!"
```

---

## 5. Workflow 5: Profile Switching

1. User clicks the Profile dropdown in the top bar (Profile 1, 2, or 3).
2. App dispatches `CMD 0x06, Sub 0xFB, [profileIndex]`.
3. Keyboard switches its internal active memory bank.
4. App automatically re-queries Key Infos (`Sub 0x08`), Lighting Config (`Sub 0x0A`), and Custom Colors (`Sub 0x13`) to refresh the visualizer with the new profile's settings.
