import 'dart:typed_data';
import '../../../core/constants/key_codes.dart';
import '../../../core/utils/byte_buffer.dart';
import '../models/macro_action.dart';
import '../models/macro_model.dart';

/// Compiler and decompiler for the keyboard's 4096-byte non-volatile macro arena.
class MacroCompiler {
  MacroCompiler._();

  /// Compiles up to 16 [MacroModel] objects into the exact 4096-byte binary format.
  /// (Verified from original JavaScript compiler function D)
  static Uint8List compileToEeprom(List<MacroModel> macros) {
    final buffer = Uint8List(4096);
    // Initialize offset table (first 64 bytes) with 0xFF
    for (int i = 0; i < 64; i++) {
      buffer[i] = 0xFF;
    }

    int arenaOffset = 64; // Action arena starts at byte 64

    for (int m = 0; m < macros.length && m < 16; m++) {
      final macro = macros[m];
      if (macro.actions.isEmpty) continue;

      // Write 16-bit little-endian pointer into offset table
      buffer[2 * m] = arenaOffset & 0xFF;
      buffer[2 * m + 1] = (arenaOffset >> 8) & 0xFF;

      for (int a = 0; a < macro.actions.length; a++) {
        final action = macro.actions[a];
        final isLast = (a == macro.actions.length - 1);

        int flags = 0;
        if (action.isPress) {
          flags |= 0x40; // Bit 6 = Key Down / Press
        }
        if (isLast) {
          flags |= 0x80; // Bit 7 = Last action terminator
        }

        switch (action.type) {
          case MacroActionType.mouseButton:
            flags |= 0x03;
            break;
          case MacroActionType.keyboardKey:
            flags |= 0x02;
            break;
          case MacroActionType.scrollVertical:
            flags |= 0x04;
            break;
          case MacroActionType.scrollHorizontal:
            flags |= 0x05;
            break;
        }

        final delay = action.delay.clamp(0, 10000);
        if (arenaOffset + 3 < 4096) {
          buffer[arenaOffset + 0] = delay & 0xFF;
          buffer[arenaOffset + 1] = (delay >> 8) & 0xFF;
          buffer[arenaOffset + 2] = flags;
          buffer[arenaOffset + 3] = action.code & 0xFF;
          arenaOffset += 4;
        } else {
          break; // Capacity limit reached
        }
      }
    }

    return buffer;
  }

  /// Decompiles a 4096-byte EEPROM memory snapshot into 16 [MacroModel] objects.
  /// (Verified from original JavaScript decoder function A)
  static List<MacroModel> decompileFromEeprom(Uint8List buffer) {
    final List<MacroModel> result = [];

    for (int m = 0; m < 16; m++) {
      final macroName = 'M$m';
      if (2 * m + 1 >= buffer.length) {
        result.add(MacroModel(name: macroName, actions: []));
        continue;
      }

      final low = buffer[2 * m];
      final high = buffer[2 * m + 1];

      // Unassigned macro slot check
      if ((low == 0xFF && high == 0xFF) || (low == 0x00 && high == 0x00)) {
        result.add(MacroModel(name: macroName, actions: []));
        continue;
      }

      int arenaOffset = ByteBufferUtils.fromUint16BytesLE(low, high);
      if (arenaOffset >= 4096 || arenaOffset < 64) {
        result.add(MacroModel(name: macroName, actions: []));
        continue;
      }

      final List<MacroAction> actions = [];
      bool isFinished = false;

      while (!isFinished && arenaOffset + 3 < buffer.length) {
        final delay = ByteBufferUtils.fromUint16BytesLE(buffer[arenaOffset], buffer[arenaOffset + 1]);
        final flags = buffer[arenaOffset + 2];
        final code = buffer[arenaOffset + 3];

        final typeCode = flags & 0x3F;
        MacroActionType type = MacroActionType.keyboardKey;
        if (typeCode == 3) {
          type = MacroActionType.mouseButton;
        } else if (typeCode == 2) {
          type = MacroActionType.keyboardKey;
        } else if (typeCode == 4) {
          type = MacroActionType.scrollVertical;
        } else if (typeCode == 5) {
          type = MacroActionType.scrollHorizontal;
        }

        final isPress = (flags & 0x40) != 0;
        isFinished = ((flags & 0x80) != 0) || flags == 0;

        String name = 'Key';
        if (type == MacroActionType.keyboardKey) {
          name = KeyCodes.resolveKeyName(32, 0, code, 0);
        } else if (type == MacroActionType.mouseButton) {
          if (code == 1) {
            name = 'Mouse Left';
          } else if (code == 2) {
            name = 'Mouse Right';
          } else if (code == 4) {
            name = 'Mouse Middle';
          } else if (code == 16) {
            name = 'Mouse Forward';
          } else if (code == 8) {
            name = 'Mouse Backward';
          }
        } else if (type == MacroActionType.scrollVertical) {
          name = (code == 255) ? 'Scroll Down' : 'Scroll Up';
        } else if (type == MacroActionType.scrollHorizontal) {
          name = (code == 255) ? 'Scroll Left' : 'Scroll Right';
        }

        actions.add(MacroAction(
          name: name,
          code: code,
          type: type,
          isPress: isPress,
          delay: delay,
        ));

        arenaOffset += 4;
      }

      result.add(MacroModel(name: macroName, actions: actions));
    }

    return result;
  }
}
