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
