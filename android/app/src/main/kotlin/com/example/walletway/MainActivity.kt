package com.example.walletway

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.walletway/channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Set up MethodChannel for communication with Flutter
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "processData") {
                val inputData = call.arguments as? List<Number> // Accepts any numeric type
                if (inputData.isNullOrEmpty()) {
                    result.error("INVALID_INPUT", "Input data is empty or invalid", null)
                } else {
                    val output = processData(inputData)
                    result.success(output)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // Placeholder for any native logic
    private fun processData(inputData: List<Number>): List<Double> {
        // Example logic: Multiply each input by 2
        return inputData.map { it.toDouble() * 2 }
    }
}
