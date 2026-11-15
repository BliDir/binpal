# ML Kit comes from Google Play Services, which downloads the models, so the
# app ships none (see build.gradle.kts). The Flutter plugins also refer to
# options photo check never uses: the Chinese, Devanagari and Korean text
# recognizers, and custom or Firebase labeling models. Those classes are left
# out on purpose.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.label.custom.**
-dontwarn com.google.mlkit.linkfirebase.**
