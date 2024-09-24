import 'package:flutter/cupertino.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  List<ChatModel> chatList = [];
  List<ChatModel> get getChatList {
    return chatList;
  }

  // Adds user messages to the chatList
  void addUserMessage({required String msg, String? base64Image}) {
    chatList
        .add(ChatModel(msg: msg, chatIndex: 0, base64Image: base64Image ?? ""));
    notifyListeners();
  }

  // Adds GPT responses to the chatList
  Future<void> sendMessageAndGetAnswers(
      {required String msg,
      required String chosenModelId,
      required String base64Image}) async {
    // Only for messages with images except dall-e
    if (chosenModelId.toLowerCase().startsWith("gpt-4") && base64Image != "") {
      List<ChatModel> chatListWithImages =
          await ApiService.sendMessageWithImages(
              message: msg, modelId: chosenModelId, base64Image: base64Image);
      chatList.addAll(chatListWithImages);
    } else if (chosenModelId.toLowerCase().startsWith("gpt")) {
      List<ChatModel> chatListLive =
          await ApiService.sendMessageGPT(message: msg, modelId: chosenModelId);
      chatList.addAll(chatListLive);
    } else {
      List<ChatModel> chatListLegacy =
          await ApiService.sendMessage(message: msg, modelId: chosenModelId);
      chatList.addAll(chatListLegacy);
    }
    notifyListeners();
  }
}
