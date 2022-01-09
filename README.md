# ExamPlanner

Flutter application for planning midterms and final exams.

- In order for the application to work, you need to create a Google API key that will be associated with a project in your Google Cloud account. For that, visit https://developers.google.com/maps/documentation/javascript/get-api-key.
- After you create your API key, make sure the Places, Maps Static, SDK for IOS & Android and Distances APIs are enabled in your Google Cloud project.
- After you ensure that the APIs are enabled, edit the Android manifest .xml file and replace "YOUR_API_KEY" with your Google API key.
- Also, in the lib folder, create a file called "secrets.dart" and add your Google API key in a static const String variable.
- For the purpose of the local notifications functionalities, add static const String variables in the secrets file for the group channel id, name, description and key variables. Input any String value you want into those variables. If any errors are received, just input "testchannel" and then the property of the channel (eg. for channel name input "testchannelname"). 

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
