import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smart_lecture/screens/chat_screen.dart';
import 'package:smart_lecture/screens/notes_screen.dart';
import 'package:smart_lecture/services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lecture.dart';

class LectureDetailScreen extends StatefulWidget {
  final Lecture lecture;

  const LectureDetailScreen({
    super.key,
    required this.lecture,
  });

  @override
  State<LectureDetailScreen> createState() =>
      _LectureDetailScreenState();
}

class _LectureDetailScreenState
    extends State<LectureDetailScreen> {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _player.setUrl(widget.lecture.filePath);

    _player.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState ==
          ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  void _togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _generateNotes() async {
    // If notes already exist → just open them
    if (widget.lecture.notes != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              NotesScreen(notes: widget.lecture.notes!),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    final notes = await AiService().generateNotes(
      widget.lecture.transcript!,
    );

    setState(() {
      _isGenerating = false;
    });

    if (notes != null) {
      widget.lecture.notes = notes; // save locally

      await Supabase.instance.client
          .from('lectures')
          .update({'notes': notes})
          .eq('id', widget.lecture.id);
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotesScreen(
          notes: notes ?? "No notes generated.",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.play_circle,
                          size: 80,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Duration: ${lecture.durationSeconds} seconds",
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                          label: Text(
                            _isPlaying ? "Pause" : "Play",
                          ),
                          onPressed: _togglePlayback,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (lecture.transcript != null) ...[
              _sectionTitle("Transcript"),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  lecture.transcript!,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text("Ask AI"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            transcript: lecture.transcript!,
                            lectureId: lecture.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.notes),
                    label: _isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                          )
                        : const Text("Generate Notes"),
                    onPressed: _isGenerating
                        ? null
                        : _generateNotes,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
