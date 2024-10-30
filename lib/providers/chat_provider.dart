import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  //
  Map<String, List<Map<String, dynamic>>> allChats = {};
  String? currentChatId;
  String? sentChatId;
  Box? chatBox;
  Box? lastChatIdBox;

  ChatProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    chatBox = await Hive.openBox('chatBox');
    lastChatIdBox = await Hive.openBox('lastChatIdBox');

    /* To transform/read the data in the Hive data box called chatBox and assign it to a variable called allChats to use it Chat Screen*/
    allChats = chatBox!.toMap().map(
      (key, value) {
        // Check the type and content of value
        if (value is List) {
          try {
            // Convert all items if they are of type Map<String, dynamic>
            return MapEntry(key,
                value.map((item) => Map<String, dynamic>.from(item)).toList());
          } catch (e) {
            throw ('Error converting item to Map<String, dynamic>: $e');
          }
        }
        // Return an empty list if conversion fails
        return MapEntry(key, <Map<String, dynamic>>[]);
      },
    );
    // Restore currentChatId from lastChatId(To open user's last chat screen)
    currentChatId = lastChatIdBox!.get('lastChatId');
    print(currentChatId);
    notifyListeners();
  }

  // To start a new chat
  void startNewChat() {
    final newChatId = DateTime.now().toIso8601String();
    allChats[newChatId] = [
      {"role": "system", "content": "You are a helpful assistant."}
    ];
    currentChatId = newChatId;

    // Save the new chat
    chatBox!.put(newChatId, allChats[newChatId]);
    notifyListeners();
  }

  // Get the current chat
  List<Map<String, dynamic>> get currentMessages {
    return allChats[currentChatId] ?? [];
  }

  // Adds user message to the Hive chatBox
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
    if (currentChatId == null) startNewChat(); // for the first message
    allChats[currentChatId]?.add(message);
    chatBox!.put(
        currentChatId, allChats[currentChatId]); // Save user's message to Hive
    sentChatId = currentChatId;
    notifyListeners();
  }

  // Sends request using messages, then adds GPT responses to the messages
  Future<void> sendMessageAndGetAnswers({required String chosenModelId}) async {
    if (chosenModelId.toLowerCase().startsWith("gpt")) {
      List<Map<String, dynamic>> chatListLive = await ApiService.sendMessageGPT(
          messages: allChats[sentChatId] ?? [], modelId: chosenModelId);
      allChats[sentChatId]!.addAll(chatListLive);
    } else {
      List<Map<String, dynamic>> chatListLegacy = await ApiService.sendMessage(
          messages: allChats[sentChatId] ?? [], modelId: chosenModelId);
      allChats[sentChatId]!.addAll(chatListLegacy);
    }
    // We use sentChatId because user can choose another tab when API's response is coming
    chatBox!
        .put(sentChatId, allChats[sentChatId]); // Save updated messages to Hive
    lastChatIdBox!.put('lastChatId',
        sentChatId); // Update the last chat ID to remember last conversation

    notifyListeners();
  }

  // Deletes a chat by its ID
  void deleteChat(String chatId) {
    // Check if the chat exists
    if (allChats.containsKey(chatId)) {
      allChats.remove(chatId); // Remove chat from the map
      chatBox!.delete(chatId); // Delete chat from Hive box

      // Update currentChatId if the deleted chat is currentChatId
      if (currentChatId == chatId) {
        currentChatId = allChats.isNotEmpty ? allChats.keys.last : null;
        print(allChats.keys);
        print(currentChatId);
        lastChatIdBox!.put('lastChatId', currentChatId);
      }

      notifyListeners();
    }
  }
}

/* 
allChats'i ChatGPT ile Json'a dönüştürdüğümde:
{ 
  "2024-10-30T12:50:16.324320": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "merhaba" },
    { "role": "assistant", "content": "Merhaba! Size nasıl yardımcı olabilirim?" },
    { "role": "user", "content": "nasilsin" },
    { "role": "assistant", "content": "Ben bir yapay zeka olduğum için hislerim yok, ama sizinle konuşmak için buradayım! Siz nasılsınız?" }
  ],
  "2024-10-30T12:50:37.054498": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "naber" },
    { "role": "assistant", "content": "Merhaba! Nasılsın? Size nasıl yardımcı olabilirim?" }
  ],
  "2024-10-30T12:52:00.866643": [
    { "role": "system", "content": "You are a helpful assistant." },
    { "role": "user", "content": "iyilik saglik be dostlar" },
    { "role": "assistant", "content": "Merhaba! İyi olun, sağlıklı olun. Size nasıl yardımcı olabilirim?" }
  ]
} */
