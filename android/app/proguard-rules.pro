# TensorFlow Lite GPU
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**
-keep class com.google.ar.sceneform.** { *; }
-keep class com.google.ar.core.** { *; }
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }
-keep class com.google.ar.sceneform.assets.** { *; }
-keep class com.google.ar.sceneform.animation.** { *; }
-keep class com.google.ar.sceneform.rendering.** { *; }
-keep class com.google.ar.sceneform.utilities.** { *; }

# R8가 내부적으로 제거하지 못하게
-dontwarn com.google.ar.sceneform.**
-dontwarn com.google.devtools.build.android.desugar.runtime.ThrowableExtension