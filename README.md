Smart Lecture

Smart Lecture is a mobile app built with Flutter that helps students interact with their lectures more effectively. Instead of scrolling through long recordings or notes, the app lets users record lectures, generate transcripts, and ask questions about the lecture using AI.

The idea is simple: once a lecture is recorded and processed, you can chat with the lecture to clarify concepts or quickly find information.

Features

Lecture Recording
Record lectures directly inside the app.

Transcript-based Q&A
Ask questions about a lecture and get contextual answers from the transcript.

Lecture Notes
View and review generated notes for each lecture.

AI Chat Interface
A chat-style interface to interact with the lecture content.

Lecture Management
Each lecture is stored separately, making it easy to navigate between recordings.

Tech Stack

Frontend

Flutter

Dart

Material UI

Backend / Services

AI API integration

Local storage handling

Audio recording service

Project Structure
lib/
│
├── models/
│   ├── chat_messages.dart
│   └── lecture.dart
│
├── screens/
│   ├── chat_screen.dart
│   ├── lecture_detail_screen.dart
│   ├── notes_screen.dart
│   └── recording_screen.dart
│
├── services/
│   ├── ai_service.dart
│   ├── audio_service.dart
│   └── storage_service.dart
│
└── main.dart
How it Works

A lecture is recorded through the app.

The audio is processed and linked with a transcript.

The transcript is used as context for the AI service.

Users can ask questions in the chat screen and get answers based on the lecture content.

Running the Project

Clone the repository:

git clone https://github.com/yourusername/smart-lecture.git
cd smart-lecture

Install dependencies:

flutter pub get

Run the app:

flutter run
Future Improvements

Some ideas for future iterations:

Lecture summarization

Search within transcripts

Highlight key concepts automatically

Export notes as PDF

Cloud sync for lectures
