/// Web stub for TensorFlow Lite (tflite_flutter).
///
/// The real `tflite_flutter` package requires `dart:ffi`, which is not available
/// on web. This stub only exists to let the project compile on web builds.
///
/// Any attempt to actually run inference on web will throw an [UnsupportedError].

class InterpreterOptions {
  int threads = 1;
  void delete() {}
}

enum TensorType { float32, int8, uint8 }

class Tensor {
  Tensor({
    this.shape = const <int>[],
    this.type = TensorType.float32,
    this.numElementsValue = 0,
  });

  final List<int> shape;
  final TensorType type;
  final int numElementsValue;

  int numElements() => numElementsValue;
}

class Interpreter {
  Interpreter._();

  static Never _unsupported() => throw UnsupportedError(
        'TensorFlow Lite is not supported on web builds (dart:ffi unavailable).',
      );

  static Future<Interpreter> fromAsset(
    String assetPath, {
    InterpreterOptions? options,
  }) async =>
      _unsupported();

  static Interpreter fromBuffer(Object data) => _unsupported();

  Tensor getInputTensor(int index) => _unsupported();
  Tensor getOutputTensor(int index) => _unsupported();

  void run(Object input, Object output) => _unsupported();
  void close() {}
}

