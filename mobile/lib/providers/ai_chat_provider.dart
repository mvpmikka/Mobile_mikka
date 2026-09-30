import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ai_chat_service.dart';

final aiChatServiceProvider = Provider<AiChatService>((ref) => AiChatService());
