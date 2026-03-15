import 'package:flutter/material.dart';
import 'package:smart_lecture/screens/lecture_detail_screen.dart';
import 'package:smart_lecture/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/audio_service.dart';
import '../../../models/lecture.dart';
import '../../../services/storage_service.dart';
import 'dart:async';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() =>
      _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();

  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  List<Lecture> _lectures = [];

  void _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioService.stopRecording();
      _timer?.cancel();

      if (path != null) {
        setState(() {
          _isRecording = false;
        });

        final url = await _storageService.uploadLecture(
          path,
        );

        final transcript = await AiService()
            .transcribeAudio(path);

        final response = await Supabase.instance.client
            .from('lectures')
            .insert({
              'title': "Lecture ${_lectures.length + 1}",
              'audio_url': url,
              'transcript': transcript,
              'duration_seconds': _recordDuration,
            })
            .select()
            .single();

        final lecture = Lecture(
          id: response['id'],
          title: response['title'],
          filePath: response['audio_url'],
          createdAt: DateTime.parse(response['created_at']),
          durationSeconds: response['duration_seconds'],
          transcript: response['transcript'],
        );

        setState(() {
          _lectures.insert(0, lecture);
        });
      }
    } else {
      final path = await _audioService.startRecording();

      if (path != null) {
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _timer = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            setState(() {
              _recordDuration++;
            });
          },
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadLectures() async {
    final data = await Supabase.instance.client
        .from('lectures')
        .select()
        .order('created_at', ascending: false);

    setState(() {
      _lectures = data.map<Lecture>((item) {
        return Lecture(
          id: item['id'],
          title: item['title'],
          filePath: item['audio_url'], // using storage URL
          createdAt: DateTime.parse(item['created_at']),
          durationSeconds: item['duration_seconds'],
          transcript: item['transcript'],
          notes: item['notes'],
        );
      }).toList();
    });
  }

  Widget buildLectureCard(Lecture lecture) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: const Icon(Icons.play_circle_outline),
        title: Text(lecture.title),
        subtitle: Text(
          "${lecture.createdAt.toString().substring(0, 16)} • ${_formatDuration(lecture.durationSeconds)}",
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  LectureDetailScreen(lecture: lecture),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadLectures();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SmartLecture"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          Center(
            child: GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? Colors.red
                      : Colors.blue,
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (_isRecording)
            Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Your Lectures",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              itemCount: _lectures.length,
              itemBuilder: (_, index) =>
                  buildLectureCard(_lectures[index]),
            ),
          ),
        ],
      ),
    );
  }
}
