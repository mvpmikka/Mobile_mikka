# WebRTC's native (JNI) layer calls into these Java classes by name/signature,
# so R8 can't see that usage statically — without these keeps, calls/media
# break at runtime in release builds even though the app still builds fine.
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Play Services Auth (google_sign_in) and Google Maps use reflection-based
# deserialization for their API models.
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# socket_io_client pulls in okhttp + org.json; okhttp's internal platform
# detection reflects on classes that don't exist on Android, and org.json
# fields are read by name during (de)serialization.
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**
-keep class org.json.** { *; }

-dontwarn javax.annotation.**
