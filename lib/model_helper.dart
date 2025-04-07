import 'package:flutter/services.dart';

class ModelHelper {
  static const platform = MethodChannel('com.example.walletway/channel');

  Future<List<double>> predict(List<double> inputData) async {
    try {
      final result = await platform.invokeMethod<List<dynamic>>(
        'processData',
        inputData,
      );
      return result?.cast<double>() ?? [];
    } catch (e) {
      print('Error invoking model: $e');
      return [];
    }
  }
}
