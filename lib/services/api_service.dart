import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:gpt_chatbot/constants/api_consts.dart';
import 'package:gpt_chatbot/models/chat_model.dart';
import 'package:gpt_chatbot/models/models_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // List available models
  static Future<List<Datum>> getModels() async {
    try {
      var response = await http.get(
        Uri.parse("$baseUrl/models"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          "Content-Type": "application/json"
        },
      );
      Map jsonResponse = jsonDecode(response.body);

      if (jsonResponse['error'] != null) {
        // print("jsonResponse['error'] ${jsonResponse['error']["message"]}");
        throw HttpException(jsonResponse['error']["message"]);
      }
      List temp = [];
      for (var value in jsonResponse["data"]) {
        temp.add(value);
        // log("temp ${value["id"]}");
      }
      return ModelsModel.fromJson(jsonDecode(response.body)).data;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }

  // Send Message using ChatGPT API live models (Provide String, document, text)
  static Future<List<Map<String, dynamic>>> sendMessageGPT(
      {required List<Map<String, dynamic>> messages,
      required String modelId}) async {
    /* Eğer Provider'ın dinlememesi için messages'ta yaptığınız değişikliklerin tamamen izole edilmesini istiyorsanız, bu durumda List.from() kopyalama yöntemi yerine derin kopyalama yapmanız gerekebilir. Çünkü List.from() sadece üst düzeyde bir kopyalama yapar, iç içe listeler veya map yapıları varsa bunlar kopyalanmaz. Derin kopyalama yapılmazsa, Provider hâlâ orijinal veriyi izleyebilir. */
    /* List<Map<String, dynamic>> sanitizedMessages =
        List<Map<String, dynamic>>.from(messages); */

    /* We used jsonEncode() and then jsonDecode() to create a deep copy of messages. In this way, all nested structures were also copied. */
    // Deep copy of the original messages list to avoid modifying the provider.
    List<Map<String, dynamic>> sanitizedMessages =
        List<Map<String, dynamic>>.from(jsonDecode(jsonEncode(messages)));

    /* The removeNamesFromList function traverses the list, checks the name key and removes it. If there are nested lists, it checks them with the same function.*/
    void removeNamesFromList(List<dynamic> list) {
      for (var item in list) {
        // Check each item
        if (item is Map<String, dynamic> && item.containsKey('name')) {
          // If 'name' exists, remove it
          item.remove('name');
        }

        // If there are nested lists, check them too
        if (item.containsKey('content') && item['content'] is List) {
          removeNamesFromList(item['content']);
        }
      }
    }

    // Remove 'name' fields from the deep copy
    removeNamesFromList(sanitizedMessages);

    try {
      log("modelId $modelId");
      var response = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          "Content-Type": "application/json"
        },
        body: jsonEncode(
          {
            "model": modelId,
            "messages": sanitizedMessages, // We send sanitizedMessages to API
          },
        ),
      );

      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      List<Map<String, dynamic>> messagesList = [];
      if (jsonResponse["choices"].length > 0) {
        messagesList = List.generate(
          jsonResponse["choices"].length,
          (index) => ChatModel(
            content: jsonResponse["choices"][index]["message"]["content"],
            role: "assistant",
          ).toJson(),
        );
      }
      return messagesList;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }

  // Stream version of sendMessageGPT
  static Stream<Map<String, dynamic>> sendMessageGPTStream({
    required List<Map<String, dynamic>> messages,
    required String modelId,
  }) async* {
    // Deep copy of messages (same as in sendMessageGPT)
    List<Map<String, dynamic>> sanitizedMessages =
        List<Map<String, dynamic>>.from(jsonDecode(jsonEncode(messages)));

    // Remove names function (same as in sendMessageGPT)
    void removeNamesFromList(List<dynamic> list) {
      for (var item in list) {
        if (item is Map<String, dynamic> && item.containsKey('name')) {
          item.remove('name');
        }
        if (item.containsKey('content') && item['content'] is List) {
          removeNamesFromList(item['content']);
        }
      }
    }

    removeNamesFromList(sanitizedMessages);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": modelId,
          "messages": sanitizedMessages,
          "stream": true, // Enable streaming
        }),
      );

      // Process the stream of SSE events
      final stream = response.body.split('\n');
      for (var line in stream) {
        if (line.startsWith('data: ') && line != 'data: [DONE]') {
          final data = line.substring(6);
          Map<String, dynamic> jsonResponse = json.decode(data);

          if (jsonResponse['choices']?.isNotEmpty ?? false) {
            final content = jsonResponse['choices'][0]['delta']['content'];
            if (content != null) {
              yield ChatModel(
                content: content,
                role: "assistant",
              ).toJson();
            }
          }
        }
      }
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }

  // I kept this for future use. I might need non-streaming version.
  // Send Message using ChatGPT API legacy models (/v1/completions (Legacy))
  // gpt-3.5-turbo-instruct,  babbage-002,  davinci-002
  static Future<List<Map<String, dynamic>>> sendMessage(
      {required List<Map<String, dynamic>> messages,
      required String modelId}) async {
    try {
      log("modelId $modelId");
      var response = await http.post(
        Uri.parse("$baseUrl/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          "Content-Type": "application/json"
        },
        body: jsonEncode(
          {
            "model": modelId,
            "prompt": messages.last['content'],
            "max_tokens": 100,
          },
        ),
      );

      // Map jsonResponse = jsonDecode(response.body);

      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        // print("jsonResponse['error'] ${jsonResponse['error']["message"]}");
        throw HttpException(jsonResponse['error']["message"]);
      }

      List<Map<String, dynamic>> messagesList = [];
      if (jsonResponse["choices"].length > 0) {
        // log("jsonResponse[choices]text ${jsonResponse["choices"][0]["text"]}");
        messagesList = List.generate(
          jsonResponse["choices"].length,
          (index) => ChatModel(
            content: jsonResponse["choices"][index]["text"],
            role: "assistant",
          ).toJson(),
        );
      }
      return messagesList;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }
}
