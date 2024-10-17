import 'dart:developer';

import 'package:flutter/cupertino.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  /* List<ChatModel> chatList = [];
  List<ChatModel> get getChatList {
    return chatList;
  } */

  List<Map<String, dynamic>> messages = [
    {"role": "system", "content": "You are a helpful assistant."}
  ];
  List<Map<String, dynamic>> get getMessages {
    return messages;
  }

  // Adds user messages to the messages
  void addUserMessage(
      {required String content, String? base64Image, String? documentText}) {
    messages.add(ChatModel(
            content: content,
            role: "user",
            base64Image: base64Image ?? "",
            documentText: documentText ?? "")
        .toJson());
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
    notifyListeners();
  }
}
