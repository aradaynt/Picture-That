# Picture That
Picture that is a Flutter application that uses Google’s Gemini 2.5 Flash AI to identify plant species from a single photo. By using the device's native camera, it allows the user to take a picture of the plant and the app will provide professional-grade botanical insights including common names, scientific classifications, toxicity reports, and specific care instructions. We are using the Free plan, which means we are limited to 5 Requests per minute, 250K tokens per minute, and 20 requests per day, please keep this in mind while testing.

# Neural Network and Software Design
Picture that us a flutter mobile application that uses a device's built in camera to take a picture of a plant. The image is then sent to Gemini Flash 2.5 using the google_generative_ai flutter package api, along with a prompt for context. Gemini Flash 2.5 then returns the plant's common name, scientific name, toxicology information and care instructions in markdown form. This information is then displayed to the user using the flutter_markdown package for a clean and readable output.

# Video Link

[YouTube](https://www.youtube.com/watch?v=0UcR3u29hPA)

# How to run

Run the exported picturethat.apk file that we provide in the GitHub repo. [This is not the case anymore, we realized the api keys are exposed even in the apk file, so we changed the key and you will have to build the apk yourself once we give you the .env file]

# Build Instructions

### Prerequisites

Flutter SDK: Version 3.x (latest stable recommended).

Dart SDK: Automatically included with Flutter.

Android Studio / SDK: Required for the Android toolchain and adb drivers.

Physical Android Device: Must have "USB Debugging" enabled in Developer Options.

Internet Connection: Required for the initial flutter pub get to download dependencies.

The Environment Variables: Please request the .env file from someone in our group (email us), and place it in the root folder of the project (same folder as pubspec.yaml).

### Build & Run Instructions

Step 1: Install Dependencies <br>
This fetches all the packages listed in your configuration. Make sure you are in the project directory.
```Bash
flutter pub get
```

Step 2: Clean and Rebuild (Optional but Recommended)<br>
This prevents any "zombie" configurations from previous builds from interfering.
```Bash
flutter clean
flutter pub get
```
Step 3: Run on Device<br>
If you have a phone connected, you can run it directly:

```Bash
flutter run --release
```

OR Step 4: Build the APK<br>
If you just want the file to install manually later:

```Bash
flutter build apk --release
```
The resulting file will be at: `build/app/outputs/flutter-apk/app-release.apk`


# How to use
1. Launch the app.

2. Tap Open Native Camera.

3. Take a clear, well-lit photo of a plant.

4. Confirm the photo.

5. Wait a moment for Picture That to analyze and display the care guide.
