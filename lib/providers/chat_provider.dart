import 'dart:developer';

import 'package:flutter/cupertino.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatModel> chatList = [];
  List<ChatModel> get getChatList {
    return chatList;
  }

  // Adds user messages to the chatList
  void addUserMessage(
      {required String content, String? base64Image, String? documentText}) {
    chatList.add(ChatModel(
        content: content,
        role: "user",
        base64Image: base64Image ?? "",
        documentText: documentText ?? ""));
    notifyListeners();
  }

  // Adds GPT responses to the chatList
  Future<void> sendMessageAndGetAnswers(
      {required String content,
      required String chosenModelId,
      required String base64Image,
      required String documentText}) async {
    // Only for messages with images or documents except dall-e
    if ((chosenModelId.toLowerCase().startsWith("gpt-4") &&
            base64Image != "") ||
        (chosenModelId.toLowerCase().startsWith("gpt-4") &&
            documentText != "")) {
      List<ChatModel> chatListWithImages =
          await ApiService.sendMessageWithImagesOrDocuments(
        content: content,
        modelId: chosenModelId,
        base64Image: base64Image,
        documentContent: documentText,
      );
      chatList.addAll(chatListWithImages);
    } else if (chosenModelId.toLowerCase().startsWith("gpt")) {
      List<ChatModel> chatListLive = await ApiService.sendMessageGPT(
          content: content, modelId: chosenModelId);
      chatList.addAll(chatListLive);
    } else {
      List<ChatModel> chatListLegacy = await ApiService.sendMessage(
          content: content, modelId: chosenModelId);
      chatList.addAll(chatListLegacy);
    }
    notifyListeners();
  }
}
