import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  try {
    print('Loading model...');
    final interpreter = Interpreter.fromFile(File('assets/models/hybrid_agrovision_model.tflite'));
    
    final inputTensor = interpreter.getInputTensor(0);
    print('Input Tensor:');
    print('  Name: ${inputTensor.name}');
    print('  Type: ${inputTensor.type}');
    print('  Shape: ${inputTensor.shape}');
    
    final outputTensor = interpreter.getOutputTensor(0);
    print('\nOutput Tensor:');
    print('  Name: ${outputTensor.name}');
    print('  Type: ${outputTensor.type}');
    print('  Shape: ${outputTensor.shape}');

    print('\nTesting inference with dummy data...');
    var input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) => [0.0, 0.0, 0.0]
        ),
      ),
    );
    
    var output = List.generate(1, (_) => List.filled(3, 0.0));
    
    interpreter.run(input, output);
    print('Inference successful!');
    print('Output: ${output[0]}');
    
    interpreter.close();
  } catch (e) {
    print('Error: $e');
  }
}
