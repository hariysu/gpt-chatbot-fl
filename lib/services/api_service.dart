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

  // Send Message using ChatGPT API live models
  static Future<List<ChatModel>> sendMessageGPT(
      {required String content, required String modelId}) async {
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
            "messages": [
              {
                "role": "user",
                "content": content,
              }
            ]
          },
        ),
      );
      /*print(jsonDecode(response.body));*/
      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        // print("jsonResponse['error'] ${jsonResponse['error']["message"]}");
        throw HttpException(jsonResponse['error']["message"]);
      }
      List<ChatModel> chatList = [];
      if (jsonResponse["choices"].length > 0) {
        // log("jsonResponse[choices]text ${jsonResponse["choices"][0]["text"]}");
        chatList = List.generate(
          jsonResponse["choices"].length,
          (index) => ChatModel(
            content: jsonResponse["choices"][index]["message"]["content"],
            role: "assistant",
          ),
        );
      }
      return chatList;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }

  // Send Message with images
  static Future<List<ChatModel>> sendMessageWithImagesOrDocuments(
      {required String content,
      required String modelId,
      required String base64Image,
      required String documentContent}) async {
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
            "messages": [
              {
                "role": "user",
                "content": [
                  {
                    "type": "text",
                    "text": documentContent.isEmpty
                        ? content
                        : content + '\n' + documentContent,
                  },
                  // Use base64Image if it is not empty
                  if (base64Image.isNotEmpty)
                    {
                      "type": "image_url",
                      "image_url": {
                        "url": "data:image/jpeg;base64,$base64Image"
                      }
                    }
                ],
              }
            ]
          },
        ),
      );
      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        // print("jsonResponse['error'] ${jsonResponse['error']["message"]}");
        throw HttpException(jsonResponse['error']["message"]);
      }
      List<ChatModel> chatList = [];
      if (jsonResponse["choices"].length > 0) {
        //log("jsonResponse[choices]text ${jsonResponse["choices"][0]["text"]}");
        chatList = List.generate(
          jsonResponse["choices"].length,
          (index) => ChatModel(
            content: jsonResponse["choices"][index]["message"]["content"],
            role: "assistant",
          ),
        );
      }
      return chatList;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }

  // Send Message using ChatGPT API legacy models (/v1/completions (Legacy))
  // gpt-3.5-turbo-instruct,  babbage-002,  davinci-002
  static Future<List<ChatModel>> sendMessage(
      {required String content, required String modelId}) async {
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
            "prompt": content,
            "max_tokens": 300,
          },
        ),
      );

      // Map jsonResponse = jsonDecode(response.body);

      Map jsonResponse = json.decode(utf8.decode(response.bodyBytes));
      if (jsonResponse['error'] != null) {
        // print("jsonResponse['error'] ${jsonResponse['error']["message"]}");
        throw HttpException(jsonResponse['error']["message"]);
      }
      List<ChatModel> chatList = [];
      if (jsonResponse["choices"].length > 0) {
        // log("jsonResponse[choices]text ${jsonResponse["choices"][0]["text"]}");
        chatList = List.generate(
          jsonResponse["choices"].length,
          (index) => ChatModel(
            content: jsonResponse["choices"][index]["text"],
            role: "assistant",
          ),
        );
      }
      return chatList;
    } catch (error) {
      log("error $error");
      rethrow;
    }
  }
}
