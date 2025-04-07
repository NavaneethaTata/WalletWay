package com.example.walletway;

import android.content.Context;
import org.tensorflow.lite.Interpreter;

import java.io.FileInputStream;
import java.io.IOException;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

public class ModelHelper {
    private Interpreter interpreter;

    public ModelHelper(Context context, String modelPath) throws IOException {
        interpreter = new Interpreter(loadModelFile(context, modelPath));
    }

    private MappedByteBuffer loadModelFile(Context context, String modelPath) throws IOException {
        try (FileInputStream fileInputStream = new FileInputStream(context.getAssets().openFd(modelPath).getFileDescriptor())) {
            FileChannel fileChannel = fileInputStream.getChannel();
            long startOffset = context.getAssets().openFd(modelPath).getStartOffset();
            long declaredLength = context.getAssets().openFd(modelPath).getDeclaredLength();
            return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);
        }
    }

    public float[] predict(float[] input) {
        float[][] output = new float[1][3]; // Adjust the second dimension to match your model's output size
        interpreter.run(input, output);
        return output[0];
    }

    public void close() {
        if (interpreter != null) {
            interpreter.close();
        }
    }
}
