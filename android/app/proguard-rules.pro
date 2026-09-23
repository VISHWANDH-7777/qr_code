# R8/ProGuard rules for release builds (isMinifyEnabled = true).
#
# android/app/build.gradle.kts references this file, so it must exist and it must
# keep the Google Mobile Ads SDK + UMP consent classes. Without these rules the
# release build fails / strips the reflection based AdMob code and ads never load.

# Google Mobile Ads SDK
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# User Messaging Platform (UMP consent)
-keep class com.google.android.ump.** { *; }
-dontwarn com.google.android.ump.**

# Mediation adapters (harmless when unused, required when mediation is added)
-keep class com.google.ads.mediation.** { *; }
-keep class com.google.android.gms.ads.mediation.** { *; }
-dontwarn com.google.ads.mediation.**

# Play Core (referenced by Flutter tooling / deferred components)
-dontwarn com.google.android.play.core.**
