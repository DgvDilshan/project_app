import 'dart:typed_data';

class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.sourceLabel,
    this.fileName,
  });

  final Uint8List bytes;
  final String sourceLabel; // e.g. "Camera" or "Gallery"
  final String? fileName;
}
