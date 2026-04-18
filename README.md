# Picture That
Picture that is a Flutter application that uses Google’s Gemini 2.5 Flash AI to identify plant species from a single photo. By using the device's native camera, it allows the user to take a picture of the plant and the app will provide professional-grade botanical insights including common names, scientific classifications, toxicity reports, and specific care instructions. We are using the Free plan, which means we are limited to 5 Requests per minute, 250K tokens per minute, and 20 requests per day, please keep this in mind while testing.

# Neural Network and Software Design
Picture that us a flutter mobile application that uses a device's built in camera to take a picture of a plant. The image is then sent to Gemini Flash 2.5 using the google_generative_ai flutter package api, along with a prompt for context. Gemini Flash 2.5 then returns the plant's common name, scientific name, toxicology information and care instructions in markdown form. This information is then displayed to the user using the flutter_markdown package for a clean and readable output.

# How to run
Run the exported picturethat.apk file that we provide in the GitHub repo.

# How to use
1. Launch the app.

2. Tap Open Native Camera.

3. Take a clear, well-lit photo of a plant.

4. Confirm the photo.

5. Wait a moment for Picture That to analyze and display the care guide.
