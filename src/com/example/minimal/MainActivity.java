package com.example.minimal;

import android.util.Log;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;


public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d("MainActivity", "App started");
        Log.i("MainActivity", "Info message");
        Log.e("MainActivity", "Error message");

        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        try {
            Process process = Runtime.getRuntime().exec("logcat -d");
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream())
            );

            String line;
            while ((line = reader.readLine()) != null) {
                Log.d("SHELL", line);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }


}
