# ProGuard/R8 keep rules for release builds.
#
# NOTE: Retrofit, Dio and json_serializable in this app are DART packages,
# compiled to native (AOT) code — R8 never sees them, so they need no keep
# rules. Flutter ships its own rules for io.flutter.**. Only the Android/Java
# libraries below need help.

# Play Core: Flutter references the split-install / deferred-components API,
# which R8 otherwise reports as missing and fails the build.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase Cloud Messaging (push notifications).
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Razorpay checkout uses reflection + a JS bridge; these keeps are from the
# Razorpay integration guide and prevent a crash on the payment screen.
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
