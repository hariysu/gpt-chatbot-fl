import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gpt_chatbot/models/chat_model.dart';
import 'package:gpt_chatbot/constants/claude_api_const.dart';

import '../utils/message_utils.dart';

class ClaudeApiService {
  static Future<List<Map<String, dynamic>>> sendMessageClaude({
    required List<Map<String, dynamic>> messages,
    required String modelId,
  }) async {
    var messagesWithoutName =
        MessageUtils.sanitizeMessages(messages, isGemini: false);

    try {
      var response = await http.post(
        Uri.parse("$baseUrl/messages"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          "model": modelId,
          "system":
              "You are a helpful AI assistant. Today is Mon Dec 02 2024, local time is 14 PM.",
          "messages": messagesWithoutName,
          "max_tokens": 1024,
        }),
      );
      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      List<Map<String, dynamic>> messagesList = [];
      if (jsonResponse["content"] != null) {
        messagesList = [
          ChatModel(
            content: jsonResponse["content"][0]["text"],
            role: "assistant",
          ).toJson(modelID: modelId),
        ];
      }
      return messagesList;
    } catch (error) {
      log("errorSendMessageClaude $error");
      rethrow;
    }
  }

  static Stream<Map<String, dynamic>> sendMessageClaudeStream({
    required List<Map<String, dynamic>> messages,
    required String modelId,
  }) async* {
    var messagesWithoutName =
        MessageUtils.sanitizeMessages(messages, isGemini: false);
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/messages"),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          "model": modelId,
          "messages": messagesWithoutName,
          "max_tokens": 1024,
          "stream": true,
        }),
      );

      final stream = utf8.decode(response.bodyBytes).split('\n');

      for (var line in stream) {
        if (line.startsWith('data: ') && line.length > 6) {
          final data = line.substring(6);
          if (data == "[DONE]") continue;

          Map<String, dynamic> jsonResponse = json.decode(data);
          if (jsonResponse['content'] != null) {
            final content = jsonResponse['content'][0]['text'];
            if (content != null) {
              yield ChatModel(
                content: content,
                role: "assistant",
              ).toJson(modelID: modelId);
            }
          }
        }
      }
    } catch (error) {
      log("errorSendMessageClaudeStream $error");
      rethrow;
    }
  }
}
