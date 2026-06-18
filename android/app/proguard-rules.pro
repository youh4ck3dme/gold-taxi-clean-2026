# Flutter ProGuard Rules

# Keep annotations to prevent serializable model fields from being stripped
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Flutter engine rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class class_path.to.your.models.** { *; }

# Hive rules (if needed to prevent key class name changes)
-keep class hive.** { *; }
-keep class com.google.gson.** { *; }

# Keep system service references
-dontwarn android.runtime.**
-dontwarn ch.qos.logback.core.status.StatusBase

# Google Play Core classes referenced by Flutter deferred components
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
