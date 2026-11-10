import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/theme.dart';
import '../../../hardware/services/keyboard_service.dart';
import '../models/macro_action.dart';
import '../models/macro_model.dart';

class MacroPage extends StatefulWidget {
  final KeyboardService keyboardService;

  const MacroPage({super.key, required this.keyboardService});

  @override
  State<MacroPage> createState() => _MacroPageState();
}

class _MacroPageState extends State<MacroPage> {
  int _selectedMacroIndex = 0;
  int _selectedActionIndex = -1;
  bool _isRecording = false;
  bool _useFixedDelay = false;
  int _fixedDelayMs = 50;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.keyboardService;
    final macros = service.macros;
    final currentMacro = (macros.isNotEmpty && _selectedMacroIndex < macros.length)
        ? macros[_selectedMacroIndex]
        : null;

    return Focus(
      autofocus: true,
      onKeyEvent: _isRecording ? _handleLiveRecordingKeystroke : null,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Left Column: Macro List
            Container(
              width: 320,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.panelBorder),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Macro List',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: AppTheme.accentCyan),
                        tooltip: 'Add New Action',
                        onPressed: () {
                          if (currentMacro != null) {
                            setState(() {
                              currentMacro.actions.add(MacroAction(
                                name: 'A',
                                code: 4,
                                type: MacroActionType.keyboardKey,
                                isPress: true,
                                delay: 50,
                              ));
                              currentMacro.actions.add(MacroAction(
                                name: 'A',
                                code: 4,
                                type: MacroActionType.keyboardKey,
                                isPress: false,
                                delay: 50,
                              ));
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: macros.length,
                      separatorBuilder: (context, i) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final m = macros[index];
                        final isSelected = (index == _selectedMacroIndex);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMacroIndex = index;
                              _selectedActionIndex = -1;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.surfaceLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? AppTheme.accentCyan : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  m.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.accentCyan : Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${m.actions.length} steps',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Actions: Import, Export, Save to Keyboard
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_upload, size: 14),
                          label: const Text('Export', style: TextStyle(fontSize: 12)),
                          onPressed: _exportMacros,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_download, size: 14),
                          label: const Text('Import', style: TextStyle(fontSize: 12)),
                          onPressed: _importMacros,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.save, size: 16),
                      label: Text(_isSaving ? 'Writing EEPROM...' : 'Save to Keyboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isSaving ? null : () => _saveToHardware(service),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // Right Column: Action Sequence Table & Controls
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.panelBorder),
                ),
                padding: const EdgeInsets.all(20),
                child: currentMacro == null
                    ? const Center(child: Text('Select or create a macro'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Name, Playback Mode & Recording status
                          Row(
                            children: [
                              Text(
                                'Macro: ${currentMacro.name}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.panelBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: currentMacro.loopMode,
                                    dropdownColor: AppTheme.surfaceLight,
                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                    items: const [
                                      DropdownMenuItem(value: 0, child: Text('Play Once')),
                                      DropdownMenuItem(value: 1, child: Text('Loop until Release')),
                                      DropdownMenuItem(value: 2, child: Text('Loop until Any Key')),
                                      DropdownMenuItem(value: 3, child: Text('Toggle Loop')),
                                    ],
                                    onChanged: (mode) {
                                      if (mode != null) {
                                        setState(() => currentMacro.loopMode = mode);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record, size: 16),
                                label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording ? AppTheme.accentRed : AppTheme.accentCyan,
                                  foregroundColor: Colors.black,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isRecording = !_isRecording;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Table of recorded actions
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF161822),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.panelBorder),
                              ),
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E2230),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(flex: 3, child: Text('Key / Event', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 3, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                                        Expanded(flex: 3, child: Text('Delay (ms)', style: TextStyle(fontWeight: FontWeight.bold))),
                                      ],
                                    ),
                                  ),
                                  // Table Body
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: currentMacro.actions.length,
                                      separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFF222634)),
                                      itemBuilder: (context, index) {
                                        final action = currentMacro.actions[index];
                                        final isSelected = (index == _selectedActionIndex);

                                        return InkWell(
                                          onTap: () {
                                            setState(() => _selectedActionIndex = index);
                                          },
                                          child: Container(
                                            color: isSelected ? AppTheme.accentCyan.withValues(alpha: 0.15) : Colors.transparent,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(action.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    action.isPress ? 'Press (Down)' : 'Release (Up)',
                                                    style: TextStyle(
                                                      color: action.isPress ? AppTheme.accentGreen : Colors.orangeAccent,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 70,
                                                        height: 30,
                                                        child: TextField(
                                                          controller: TextEditingController(text: '${action.delay}'),
                                                          keyboardType: TextInputType.number,
                                                          decoration: InputDecoration(
                                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                            filled: true,
                                                            fillColor: AppTheme.surfaceLight,
                                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                                          ),
                                                          onSubmitted: (val) {
                                                            final parsed = int.tryParse(val);
                                                            if (parsed != null) {
                                                              setState(() => action.delay = parsed.clamp(0, 10000));
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      const Text('ms', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Bottom Toolbar: Sequence reorder & delete buttons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward),
                                tooltip: 'Move Up',
                                onPressed: (_selectedActionIndex > 0)
                                    ? () {
                                        setState(() {
                                          final item = currentMacro.actions.removeAt(_selectedActionIndex);
                                          currentMacro.actions.insert(_selectedActionIndex - 1, item);
                                          _selectedActionIndex--;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_downward),
                                tooltip: 'Move Down',
                                onPressed: (_selectedActionIndex >= 0 && _selectedActionIndex < currentMacro.actions.length - 1)
                                    ? () {
                                        setState(() {
                                          final item = currentMacro.actions.removeAt(_selectedActionIndex);
                                          currentMacro.actions.insert(_selectedActionIndex + 1, item);
                                          _selectedActionIndex++;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.accentRed),
                                tooltip: 'Delete Selected Action',
                                onPressed: (_selectedActionIndex >= 0 && _selectedActionIndex < currentMacro.actions.length)
                                    ? () {
                                        setState(() {
                                          currentMacro.actions.removeAt(_selectedActionIndex);
                                          _selectedActionIndex = -1;
                                        });
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.clear_all),
                                tooltip: 'Clear All Actions',
                                onPressed: () {
                                  setState(() {
                                    currentMacro.actions.clear();
                                    _selectedActionIndex = -1;
                                  });
                                },
                              ),
                              const Spacer(),
                              // Fixed Delay checkbox
                              Checkbox(
                                value: _useFixedDelay,
                                activeColor: AppTheme.accentCyan,
                                onChanged: (val) {
                                  setState(() => _useFixedDelay = val ?? false);
                                },
                              ),
                              const Text('Fixed Delay: ', style: TextStyle(fontSize: 13)),
                              SizedBox(
                                width: 55,
                                height: 30,
                                child: TextField(
                                  controller: TextEditingController(text: '$_fixedDelayMs'),
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                                    filled: true,
                                    fillColor: AppTheme.surfaceLight,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
                                  ),
                                  onSubmitted: (val) {
                                    final parsed = int.tryParse(val);
                                    if (parsed != null) setState(() => _fixedDelayMs = parsed.clamp(0, 10000));
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('ms', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleLiveRecordingKeystroke(FocusNode node, KeyEvent event) {
    final service = widget.keyboardService;
    final macros = service.macros;
    if (_selectedMacroIndex >= macros.length) return KeyEventResult.ignored;

    final currentMacro = macros[_selectedMacroIndex];
    final keyLabel = event.logicalKey.keyLabel;
    final isDown = event is KeyDownEvent;
    final delay = _useFixedDelay ? _fixedDelayMs : 50;

    setState(() {
      currentMacro.actions.add(MacroAction(
        name: keyLabel.isNotEmpty ? keyLabel : 'Key',
        code: event.logicalKey.keyId & 0xFF,
        type: MacroActionType.keyboardKey,
        isPress: isDown,
        delay: delay,
      ));
    });

    return KeyEventResult.handled;
  }

  Future<void> _saveToHardware(KeyboardService service) async {
    setState(() => _isSaving = true);
    try {
      final success = await service.saveMacrosToKeyboard(service.macros);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? (service.isUsingMock
                    ? 'Macros saved to simulated EEPROM (Verified)'
                    : 'Macros successfully programmed to keyboard EEPROM!')
                : (service.lastSyncError ?? 'Failed to save macros')),
            backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _exportMacros() async {
    final service = widget.keyboardService;
    final jsonStr = jsonEncode(service.macros.map((m) => m.toJson()).toList());
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Export Macros',
      fileName: 'mk1300_macros.json',
      bytes: bytes,
    );
    if (uri != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Macros exported successfully!')),
        );
      }
    }
  }

  Future<void> _importMacros() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isNotEmpty && files.first.path != null) {
      final file = File(files.first.path!);
      final content = await file.readAsString();
      final List<dynamic> list = jsonDecode(content);
      final imported = list.map((item) => MacroModel.fromJson(item as Map<String, dynamic>)).toList();
      widget.keyboardService.saveMacrosToKeyboard(imported);
      setState(() {});
    }
  }
}
