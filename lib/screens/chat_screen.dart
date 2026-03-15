import 'package:flutter/material.dart';
import 'package:smart_lecture/models/chat_messages.dart';
import 'package:smart_lecture/services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String transcript;
  final String lectureId;

  const ChatScreen({
    super.key,
    required this.transcript,
    required this.lectureId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller =
      TextEditingController();
  final ScrollController scrollController =
      ScrollController();

  final List<ChatMessage> messages = [];
  final AiService aiService = AiService();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    try {
      final data = await Supabase.instance.client
          .from('chat_messages')
          .select()
          .eq('lecture_id', widget.lectureId)
          .order('created_at');

      setState(() {
        messages.clear();

        for (var item in data) {
          messages.add(
            ChatMessage(
              text: item['message'],
              isUser: item['role'] == 'user',
            ),
          );
        }
      });

      scrollToBottom();
    } catch (e) {
      print("Error loading messages: $e");
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (scrollController.hasClients) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final question = controller.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add(
        ChatMessage(text: question, isUser: true),
      );
      isLoading = true;
    });

    controller.clear();
    scrollToBottom();

    try {
      /// Save user message
      await Supabase.instance.client
          .from('chat_messages')
          .insert({
            'lecture_id': widget.lectureId,
            'role': 'user',
            'message': question,
          });

      final response = await aiService.askQuestion(
        transcript: widget.transcript,
        question: question,
      );

      final aiMessage =
          response ?? "Sorry, I couldn't answer that.";

      /// Save AI message
      await Supabase.instance.client
          .from('chat_messages')
          .insert({
            'lecture_id': widget.lectureId,
            'role': 'assistant',
            'message': aiMessage,
          });

      setState(() {
        messages.add(
          ChatMessage(text: aiMessage, isUser: false),
        );
        isLoading = false;
      });

      scrollToBottom();
    } catch (e) {
      print("Error sending message: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors.blue
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: msg.isUser
            ? Text(
                msg.text,
                style: const TextStyle(color: Colors.white),
              )
            : MarkdownBody(data: msg.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lecture Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, index) =>
                  buildMessage(messages[index]),
            ),
          ),

          if (isLoading) const LinearProgressIndicator(),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Ask about the lecture...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
