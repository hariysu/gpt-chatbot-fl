import 'package:flutter/cupertino.dart';
import 'package:gpt_chatbot/services/claude_api_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_model.dart';
import '../services/gemini_api_service.dart';
import '../services/openai_api_service.dart';

class ChatProvider with ChangeNotifier {
  //
  Map<String, List<Map<String, dynamic>>> allChats = {};
  String? currentChatId;
  String? sentChatId;
  Box? chatBox;

  ChatProvider() {
    _initHive();
  }

  Future<void> _initHive() async {
    chatBox = await Hive.openBox('chatBox');

    /* To transform/read the data in the Hive data box called chatBox and assign it to a variable called allChats to use it Chat Screen*/
    allChats = _convertHiveDataToMap(chatBox!.toMap());
    // Sort chats by DateTime (keys) so the newest chat appears first
    _sortChatsByDate();

    // Set currentChatId to the most recent chat if exists
    currentChatId = allChats.isNotEmpty ? allChats.keys.first : null;
    notifyListeners();
  }

  Map<String, List<Map<String, dynamic>>> _convertHiveDataToMap(
      Map<dynamic, dynamic> data) {
    return data.map((key, value) {
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
    });
  }

  // To start a new chat
  void startNewChat({String? modelId}) {
    final newChatId = DateTime.now().toIso8601String();
    if (modelId?.startsWith('gpt') == true) {
      allChats[newChatId] = [
        {
          "role": "system",
          'content': [
            {
              'type': 'text',
              'text': 'You are a helpful assistant.',
            }
          ],
        }
      ];
    } else if (modelId?.startsWith('gemini') == true) {
      /* parameters(system_instruction) are added to the function in GeminiApiService.sendMessageGemini() */
      allChats[newChatId] = [];
    } else if (modelId?.startsWith('claude') == true) {
      /* parameters(system) are added to the function in GeminiApiService.sendMessageClaude() */
      allChats[newChatId] = [];
    }

    currentChatId = newChatId;

    // Save the new chat
    chatBox!.put(newChatId, allChats[newChatId]);
    _sortChatsByDate();
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
      String? imageType,
      String? documentText,
      String? documentName,
      String? modelId}) {
    final message = ChatModel(
            content: content,
            role: "user",
            base64Image: base64Image ?? "",
            imageType: imageType ?? "",
            documentText: documentText ?? "",
            documentName: documentName ?? "")
        .toJson(modelID: modelId);
    if (currentChatId == null) {
      startNewChat(modelId: modelId); // for the first message
    }

    allChats[currentChatId]?.add(message);
    //print(allChats[currentChatId]);

    // Update current chat's DateTime and re-save
    final updatedChatId = DateTime.now().toIso8601String();
    allChats[updatedChatId] = allChats.remove(
        currentChatId)!; // Stores the same data as updatedChatId instead of currentChatId
    chatBox!.delete(currentChatId); // Deletes old chat Id from chatBox

    // We use sentChatId because user can choose another tab when API's response is coming
    sentChatId = currentChatId = updatedChatId;

    // Save updated chat to Hive
    chatBox!.put(updatedChatId, allChats[updatedChatId]);
    //print("addUserMessage: $allChats[updatedChatId]");
    _sortChatsByDate();
    notifyListeners();
  }

  // Sends request using messages, then adds GPT responses to the messages
  Future<void> sendMessageAndGetAnswers({
    required String chosenModelId,
    VoidCallback? onFirstChunk,
    VoidCallback? onChunkReceived,
  }) async {
    /* Commented out because I'm using stream now. But I'll keep it for future use.
    if (chosenModelId.toLowerCase().startsWith("gpt")) {
      List<Map<String, dynamic>> chatListLive =
          await OpenAiApiService.sendMessageGPT(
              messages: allChats[sentChatId] ?? [], modelId: chosenModelId);
      allChats[sentChatId]!.addAll(chatListLive);
    }*/
    /* Commented out because I'm using stream now. But I'll keep it for future use.
    if (chosenModelId.toLowerCase().startsWith("gemini")) {
      List<Map<String, dynamic>> chatListLive =
          await GeminiApiService.sendMessageGemini(
        messages: allChats[sentChatId] ?? [],
        modelId: chosenModelId,
      );
      allChats[sentChatId]!.addAll(chatListLive);
    }*/
    if (chosenModelId.toLowerCase().startsWith("claude")) {
      List<Map<String, dynamic>> chatListLive =
          await ClaudeApiService.sendMessageClaude(
        messages: allChats[sentChatId] ?? [],
        modelId: chosenModelId,
      );
      allChats[sentChatId]!.addAll(chatListLive);
    }
    if (chosenModelId.toLowerCase().startsWith("gemini")) {
      // Create initial assistant message
      Map<String, dynamic> assistantMessage = {
        'role': 'model',
        'parts': [
          {'text': ' '}
        ],
      };
      allChats[sentChatId]!.add(assistantMessage);

      String accumulatedContent = '';
      bool isFirstChunk = true;
      await for (final chunk in GeminiApiService.sendMessageGeminiStream(
          messages: allChats[sentChatId] ?? [], modelId: chosenModelId)) {
        // Call onFirstChunk callback on first chunk
        if (isFirstChunk) {
          onFirstChunk?.call(); // similar to onFirstChunk()
          isFirstChunk = false;
        }

        // Get the new content from the chunk
        String newContent = chunk['parts'].first['text'] ?? '';
        accumulatedContent += newContent;
        // Update the message content
        assistantMessage['parts'].first['text'] = accumulatedContent;

        // Add a small delay to make the streaming visible
        await Future.delayed(const Duration(milliseconds: 50));

        // Call the scroll callback for each chunk(to scroll to bottom)
        onChunkReceived?.call(); // similar to onChunkReceived()

        // Force UI refresh
        notifyListeners();
      }
    } else if (chosenModelId.toLowerCase().startsWith("gpt")) {
      // Create initial assistant message
      Map<String, dynamic> assistantMessage = {
        'role': 'assistant',
        'content': [
          {
            "type": "text",
            'text': ' ',
          }
        ],
      };
      allChats[sentChatId]!.add(assistantMessage);

      String accumulatedContent = '';
      bool isFirstChunk = true;

      await for (final chunk in OpenAiApiService.sendMessageGPTStream(
          messages: allChats[sentChatId] ?? [], modelId: chosenModelId)) {
        // Call onFirstChunk callback on first chunk
        if (isFirstChunk) {
          onFirstChunk?.call(); // similar to onFirstChunk()
          isFirstChunk = false;
        }

        // Get the new content from the chunk
        String newContent = chunk['content'].first['text'] ?? '';
        accumulatedContent += newContent;
        // Update the message content
        assistantMessage['content'].first['text'] = accumulatedContent;

        // Add a small delay to make the streaming visible
        await Future.delayed(const Duration(milliseconds: 50));

        // Call the scroll callback for each chunk(to scroll to bottom)
        onChunkReceived?.call(); // similar to onChunkReceived()

        // Force UI refresh
        notifyListeners();
      }
    } else if (chosenModelId.toLowerCase().startsWith("davinci") ||
        chosenModelId.toLowerCase().startsWith("curie") ||
        chosenModelId.toLowerCase().startsWith("babbage") ||
        chosenModelId.toLowerCase().startsWith("ada")) {
      List<Map<String, dynamic>> chatListLegacy =
          await OpenAiApiService.sendMessage(
              messages: allChats[sentChatId] ?? [], modelId: chosenModelId);
      allChats[sentChatId]!.addAll(chatListLegacy);
    }

    // Update chat's DateTime and re-save
    final updatedChatId = DateTime.now().toIso8601String();
    allChats[updatedChatId] = allChats.remove(
        sentChatId)!; // Stores the same data as updatedChatId instead of sentChatId
    chatBox!.delete(sentChatId); // Deletes old chat Id from chatBox
    currentChatId = updatedChatId;

    // Save updated chat to Hive
    chatBox!.put(updatedChatId, allChats[updatedChatId]);
    //print("sendMessageAndGetAnswers: $allChats[updatedChatId]");
    _sortChatsByDate();

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
        currentChatId = allChats.isNotEmpty ? allChats.keys.first : null;
      }

      notifyListeners();
    }
  }

  // Helper function to sort chats by DateTime (keys)
  void _sortChatsByDate() {
    allChats = Map.fromEntries(
      allChats.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }
}
