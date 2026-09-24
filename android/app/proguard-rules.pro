# google_mlkit_text_recognition references optional script packs
# (Chinese / Devanagari / Japanese / Korean) that we do not ship.
# App only uses TextRecognitionScript.latin — tell R8 these are OK to miss.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
