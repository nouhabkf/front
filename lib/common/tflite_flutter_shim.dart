// TFLite Flutter shim.
//
// On web, `dart:ffi` is not available, so `tflite_flutter` cannot compile.
// We provide a minimal stub API to keep the app buildable on web targets.
export 'tflite_flutter_shim_stub.dart'
    if (dart.library.ffi) 'tflite_flutter_shim_io.dart';

