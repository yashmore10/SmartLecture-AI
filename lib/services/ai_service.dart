import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey = dotenv.env['GROQ_API_KEY']!;

  Future<String?> generateNotes(String transcript) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://api.groq.com/openai/v1/chat/completions",
        ),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are an expert academic note taker.",
            },
            {
              "role": "user",
              "content":
                  """
You are an expert professor.

Turn the lecture transcript into EXTREMELY detailed study notes.

Include:

# Topic Overview

# Key Concepts
Explain each concept in simple language.

# Detailed Explanation
Explain the lecture step by step.

# Real World Examples

# Code Examples (if technical topic)

# Common Interview Questions

# Key Takeaways

# Quick Revision Points

Make it structured markdown for students.

Answer the question using clear Markdown formatting.

Use:

# Headings
## Subheadings
- Bullet points
**Bold important terms**
```code blocks```

Transcript:
$transcript
""",
            },
          ],
          "temperature": 0.7,
          "max_tokens": 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } else {
        print("Notes error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Notes exception: $e");
      return null;
    }
  }

  Future<String?> transcribeAudio(String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          "https://api.groq.com/openai/v1/audio/transcriptions",
        ),
      );

      request.headers['Authorization'] = "Bearer $apiKey";

      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );

      request.fields['model'] = 'whisper-large-v3';

      var response = await request.send();

      var responseBody = await response.stream
          .bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data["text"];
      } else {
        print("Transcription error: $responseBody");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<String?> askQuestion({
    required String transcript,
    required String question,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          "https://api.groq.com/openai/v1/chat/completions",
        ),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are an intelligent tutor. Answer questions based ONLY on the lecture transcript.",
            },
            {
              "role": "user",
              "content":
                  """
Lecture Transcript:
$transcript

Student Question:
$question

Answer clearly with examples.
""",
            },
          ],
          "temperature": 0.4,
          "max_tokens": 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
