import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  //
  List<Map<String, dynamic>> messages = [
    {"role": "system", "content": "You are a helpful assistant."}
  ];

  Box? chatBox;

  ChatProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    chatBox = await Hive.openBox('chatBox'); // Open Hive box

    // Load if there is data in the box
    if (chatBox!.isNotEmpty) {
      // print(messages.runtimeType);  List<Map<String, dynamic>>
      // print(chatBox!.get('messages', defaultValue: messages).runtimeType);  List<dynamic>

      // Properly cast the returned data
      final List<dynamic> savedMessages =
          chatBox!.get('messages', defaultValue: messages);

      // This conversion transforms 'List<dynamic>' to 'List<Map<String, dynamic>>'
      messages = savedMessages
          .map((message) => Map<String, dynamic>.from(message))
          .toList();
    }

    notifyListeners();
  }

  List<Map<String, dynamic>> get getMessages {
    return messages;
  }

  // Adds user messages to the messages
  void addUserMessage(
      {required String content,
      String? base64Image,
      String? documentText,
      String? documentName}) {
    final message = ChatModel(
            content: content,
            role: "user",
            base64Image: base64Image ?? "",
            documentText: documentText ?? "",
            documentName: documentName ?? "")
        .toJson();
    messages.add(message);
    chatBox!.put('messages', messages); // Save messages to Hive
    notifyListeners();
  }

  // Sends request using messages, then adds GPT responses to the messages
  Future<void> sendMessageAndGetAnswers({required String chosenModelId}) async {
    if (chosenModelId.toLowerCase().startsWith("gpt")) {
      List<Map<String, dynamic>> chatListLive = await ApiService.sendMessageGPT(
          messages: messages, modelId: chosenModelId);
      messages.addAll(chatListLive);
    } else {
      List<Map<String, dynamic>> chatListLegacy = await ApiService.sendMessage(
          messages: messages, modelId: chosenModelId);
      messages.addAll(chatListLegacy);
    }
    chatBox!.put('messages', messages); // Save updated messages to Hive
    notifyListeners();
  }
}
