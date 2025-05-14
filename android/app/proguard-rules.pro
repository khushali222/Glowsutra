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

# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
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
