package com.example.flutter_custom_push;

import com.clevertap.android.sdk.ActivityLifecycleCallback;
import com.clevertap.android.sdk.CleverTapAPI;
import com.clevertap.android.sdk.pushnotification.CTPushNotificationListener;

import java.util.HashMap;

import io.flutter.app.FlutterApplication;

public class MyApplication extends FlutterApplication {
//    MethodChannel channel;
//    String CHANNEL = "myChannel";

    @Override
    public void onCreate() {
        ActivityLifecycleCallback.register(this);
        CleverTapAPI.setDebugLevel(CleverTapAPI.LogLevel.DEBUG);
        super.onCreate();
    }


}
