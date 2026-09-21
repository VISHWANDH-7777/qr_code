# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads
# (Usually included via consumer rules, but added as precaution for R8)
-keep class com.google.android.gms.ads.** { *; }

# Hive
# Hive uses generated Dart adapters and no native Java reflection, so it doesn't need native keep rules.

# Ignore warnings for Play Core classes referenced by Flutter Engine but not provided
-dontwarn com.google.android.play.core.**
