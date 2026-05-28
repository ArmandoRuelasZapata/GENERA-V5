## Flutter / Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

## Kotlin metadata
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

## Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

## Google Maps
-keep class com.google.android.gms.maps.** { *; }
-dontwarn com.google.android.gms.**

## Prevenir strip de modelos de respuesta JSON
-keepclassmembers class * {
    public <fields>;
}

## Evitar crash en release con Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

## OWASP M7 / MobSF: Strip Android Log calls in release builds.
## Removes Log.v, Log.d, Log.i, Log.w, Log.e, Log.wtf so no sensitive
## data leaks through logcat on production devices.
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
}

## Strip System.out.println (used by some plugins)
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}
