import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NotesScreen extends StatelessWidget {
  final String notes;

  const NotesScreen({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lecture Notes")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Markdown(
          data: notes,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            h2: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            p: const TextStyle(fontSize: 16, height: 1.5),
            code: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Color(0xfff4f4f4),
            ),
          ),
        ),
      ),
    );
  }
}
