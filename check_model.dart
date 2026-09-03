import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() async {
  try {
    final interpreter = await Interpreter.fromFile(File('assets/models/agrovision_quantized.tflite'));
    
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
    
    interpreter.close();
  } catch (e) {
    print('Error: $e');
  }
}
