# =======================
# Google Play Core
# =======================
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# =======================
# ML Kit
# =======================
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.** { *; }

# Ignore warnings for unused multilingual text recognizers
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.devanagari.**

# =======================
# TensorFlow Lite (with GPU)
# =======================
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# =======================
# Flutter & Plugins
# =======================
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# =======================
# Firebase (if used)
# =======================
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# =======================
# Icon Fonts (FontAwesome, MaterialIcons)
# =======================
-keep class **.FontAwesome { *; }
-keep class **.MaterialIcons { *; }

# =======================
# Annotations (for reflection)
# =======================
-keepattributes *Annotation*
