# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Play Core (deferred components split install) — referenced by Flutter tooling
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Kotlin metadata / coroutines (kept conservative)
-keep class kotlin.Metadata { *; }
-dontwarn kotlinx.**

# Keep annotations used for JSON / reflection-style plugins
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
