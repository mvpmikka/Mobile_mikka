import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/api_exception.dart';
import '../models/ai_chat.dart';
import '../providers/ai_chat_provider.dart';
import '../theme/app_colors.dart';
import 'directions_screen.dart';

class _ChatMessage {
  const _ChatMessage({required this.text, required this.fromUser, this.sets = const []});

  final String text;
  final bool fromUser;
  final List<AiRestaurantSet> sets;
}

/// Chat-style restaurant search backed by the AI_Id service: the user
/// describes a budget (and optionally a people count), and the assistant
/// replies with matching restaurant + dish combos.
class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: "Salom! Byudjetingiz va necha kishi ekanligingizni yozing, "
          "men mos restoran va taomlarni tavsiya qilaman.\n\n"
          "Masalan: \"2 kishiga 150000 so'm\"",
      fromUser: false,
    ),
  ];
  bool _isSending = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && mounted) {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        setState(() {
          _messages.add(
            const _ChatMessage(
              text: "Mikrofonga ruxsat berilmagan. Telefon sozlamalaridan "
                  "ruxsat berib qayta urining.",
              fromUser: false,
            ),
          );
        });
        return;
      }
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _controller.text = result.recognizedWords);
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, fromUser: true));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await ref.read(aiChatServiceProvider).sendMessage(text);
      setState(() {
        _messages.add(_ChatMessage(text: result.reply, fromUser: false, sets: result.sets));
      });
    } on ApiException catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: e.message, fromUser: false));
      });
    } catch (_) {
      setState(() {
        _messages.add(
          const _ChatMessage(
            text: "Nimadir xato ketdi. Qayta urinib ko'ring.",
            fromUser: false,
          ),
        );
      });
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.darkText(context)),
        ),
        title: Text(
          'AI orqali qidirish',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    );
                  }
                  return _MessageBubble(message: _messages[index]);
                },
              ),
            ),
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: TextStyle(color: AppColors.darkText(context), fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: "Masalan: 3 kishiga 200000 so'm",
                  hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _toggleListening,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.red.withValues(alpha: 0.12)
                    : AppColors.surface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : AppColors.mutedText(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final align = message.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.fromUser ? AppColors.orange : AppColors.surface(context);
    final textColor = message.fromUser ? Colors.white : AppColors.darkText(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
              border: message.fromUser
                  ? null
                  : Border.all(color: AppColors.fieldBorder(context)),
            ),
            child: Text(message.text, style: TextStyle(color: textColor, fontSize: 14)),
          ),
          if (message.sets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final set in message.sets) _RestaurantSetCard(set: set),
          ],
        ],
      ),
    );
  }
}

class _RestaurantSetCard extends StatelessWidget {
  const _RestaurantSetCard({required this.set});

  final AiRestaurantSet set;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_outlined, color: AppColors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  set.restaurant,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.darkText(context),
                  ),
                ),
              ),
              Icon(Icons.star_rounded, color: AppColors.orange, size: 16),
              const SizedBox(width: 2),
              Text(
                set.rating.toStringAsFixed(1),
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DirectionsScreen(
                  destinationName: set.restaurant,
                  destinationAddress: set.location,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.orange, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    set.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.orange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.mutedText(context), size: 16),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final dish in set.dishes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dish.name} (${dish.quantity})',
                      style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
                    ),
                  ),
                  Text(
                    '${dish.price.toStringAsFixed(0)} so\'m',
                    style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                  ),
                ],
              ),
            ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${set.peopleCount} kishiga',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              Text(
                'Jami: ${set.total.toStringAsFixed(0)} so\'m',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
