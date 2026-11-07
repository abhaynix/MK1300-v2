import 'dart:async';
import 'dart:typed_data';
import '../hid/hid_device.dart';

/// Task entry inside the serial USB command queue.
class _CommandTask {
  final Uint8List payload;
  final bool expectsResponse;
  final Completer<Uint8List?> completer;
  final int timeoutMs;

  _CommandTask({
    required this.payload,
    required this.expectsResponse,
    required this.completer,
    this.timeoutMs = 1000,
  });
}

/// Sequential asynchronous command queue for USB HID communication.
class CommandQueue {
  final HidDevice _device;
  final List<_CommandTask> _queue = [];
  bool _isProcessing = false;

  CommandQueue(this._device);

  /// Sends a command to the device without awaiting a response packet.
  Future<bool> sendCommand(Uint8List payload) async {
    final completer = Completer<Uint8List?>();
    _queue.add(_CommandTask(
      payload: payload,
      expectsResponse: false,
      completer: completer,
    ));
    _processQueue();
    final res = await completer.future;
    return res != null;
  }

  /// Sends a command to the device and awaits the 64-byte response packet.
  Future<Uint8List?> writeAndReadCommand(Uint8List payload, {int timeoutMs = 1000}) async {
    final completer = Completer<Uint8List?>();
    _queue.add(_CommandTask(
      payload: payload,
      expectsResponse: true,
      completer: completer,
      timeoutMs: timeoutMs,
    ));
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);
      try {
        if (!_device.isOpen) {
          final opened = await _device.open();
          if (!opened) {
            task.completer.complete(null);
            continue;
          }
        }

        final writeSuccess = await _device.writeReport(task.payload);
        if (!writeSuccess) {
          task.completer.complete(null);
          continue;
        }

        if (task.expectsResponse) {
          final response = await _device.readReport(timeoutMs: task.timeoutMs);
          task.completer.complete(response);
        } else {
          task.completer.complete(Uint8List(0));
        }
      } catch (e) {
        task.completer.completeError(e);
      }
    }

    _isProcessing = false;
  }

  /// Clears pending tasks from the queue.
  void clear() {
    for (final task in _queue) {
      if (!task.completer.isCompleted) {
        task.completer.complete(null);
      }
    }
    _queue.clear();
    _isProcessing = false;
  }
}
