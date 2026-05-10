# Flutter engine và plugin registrant
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**    { *; }
-keep class io.flutter.view.**    { *; }
-keep class io.flutter.**         { *; }
-keep class io.flutter.plugins.** { *; }

# Pigeon-generated channels (shared_preferences mới dùng pigeon, R8 hay strip
# các class này khiến channel "dev.flutter.pigeon.*" không kết nối được).
-keep class dev.flutter.pigeon.** { *; }
-keep class * extends io.flutter.plugin.common.MessageCodec { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# file_picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# ffmpeg_kit_flutter_new
-keep class com.arthenica.**       { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.arthenica.**

# gal (lưu ảnh thư viện)
-keep class dev.steenbakker.gal.** { *; }

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# video_player
-keep class io.flutter.plugins.videoplayer.** { *; }

# Giữ Parcelable / Serializable mặc định (cần cho IPC)
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Kotlin metadata (nhiều plugin Kotlin cần)
-keep class kotlin.Metadata { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
