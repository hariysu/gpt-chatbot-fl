import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gpt_chatbot/models/chat_model.dart';
import 'package:gpt_chatbot/constants/gemini_api_consts.dart';

import '../utils/message_utils.dart'; // You'll need to create this

class GeminiApiService {
  // I kept this for future use. I might need non-streaming version.
  static Future<List<Map<String, dynamic>>> sendMessageGemini({
    required List<Map<String, dynamic>> messages,
    required String modelId,
  }) async {
    var messagesWithoutName =
        MessageUtils.sanitizeMessages(messages, isGemini: true);

    try {
      var response = await http.post(
        Uri.parse("$baseUrl/models/$modelId:generateContent"),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text":
                    "You are a helpful AI assistant. Today is Mon Dec 02 2024, local time is 14 PM."
              }
            ]
          },
          "contents": messagesWithoutName,
          "generationConfig": {},
        }),
      );
      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      List<Map<String, dynamic>> messagesList = [];
      if (jsonResponse["candidates"]?.isNotEmpty ?? false) {
        messagesList = [
          ChatModel(
            content: jsonResponse["candidates"][0]["content"]["parts"][0]
                ["text"],
            role: "model",
          ).toJson(modelID: modelId),
        ];
      }
      return messagesList;
    } catch (error) {
      log("errorSendMessageGemini $error");
      rethrow;
    }
  }

  static Stream<Map<String, dynamic>> sendMessageGeminiStream({
    required List<Map<String, dynamic>> messages,
    required String modelId,
  }) async* {
    var messagesWithoutName =
        MessageUtils.sanitizeMessages(messages, isGemini: true);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/models/$modelId:streamGenerateContent?alt=sse"),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text":
                    "You are a helpful AI assistant. Today is Mon Dec 02 2024, local time is 14 PM."
              }
            ]
          },
          "contents": messagesWithoutName,
          "generationConfig": {},
        }),
      );
      //Process the stream of SSE events
      final stream = utf8.decode(response.bodyBytes).split('\n');

      for (var line in stream) {
        if (line.startsWith('data: ') && line.length > 6) {
          final data = line.substring(6);

          Map<String, dynamic> jsonResponse = json.decode(data);
          if (jsonResponse['candidates']?.isNotEmpty ?? false) {
            final content =
                jsonResponse['candidates'][0]['content']['parts'][0]['text'];
            if (content != null) {
              yield ChatModel(
                content: content,
                role: "model",
              ).toJson(modelID: modelId);
            }
          }
        }
      }
    } catch (error) {
      log("errorSendMessageGeminiStream $error");
      rethrow;
    }
  }
}
