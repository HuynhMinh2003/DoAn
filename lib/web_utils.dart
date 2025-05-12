@JS()
library array_buffer_converter;

import 'dart:typed_data';
import 'package:js/js.dart';

@JS('Uint8Array')
class JSUint8Array {
  external factory JSUint8Array(Object buffer);
  external int get length;
  external int operator [](int index);
}

Uint8List arrayBufferToUint8List(Object buffer) {
  final jsArray = JSUint8Array(buffer);
  final list = List<int>.generate(jsArray.length, (i) => jsArray[i]);
  return Uint8List.fromList(list);
}
