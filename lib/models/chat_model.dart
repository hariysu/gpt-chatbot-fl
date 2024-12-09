import 'package:hive_flutter/hive_flutter.dart';

part 'chat_model.g.dart';

@HiveType(typeId: 0)
class ChatModel extends HiveObject {
  @HiveField(0)
  String content;

  @HiveField(1)
  String role;

  @HiveField(2)
  String? base64Image;

  @HiveField(3)
  String? imageType;

  @HiveField(4)
  String? documentText;

  @HiveField(5)
  String? documentName;

  ChatModel({
    required this.content,
    required this.role,
    this.base64Image = "",
    this.imageType = "",
    this.documentText = "",
    this.documentName = "",
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        content: json["content"] is List
            ? (json["content"][0]["text"] ?? "")
            : json["content"],
        role: json["role"],
        base64Image: json["base64Image"] ?? "",
        imageType: json["imageType"] ?? "",
        documentText: json["documentText"] ?? "",
        documentName: json["documentName"] ?? "",
      );

  // Function to convert Json format
  Map<String, dynamic> toJson({required modelID}) {
    if (modelID.toLowerCase().startsWith("gpt")) {
      return {
        "role": role,
        if (base64Image == "" && documentText == "")
          "content": [
            {
              "type": "text",
              "text": content,
            }
          ]
        else if (documentText != "")
          "content": [
            {
              "type": "text",
              // Use three space to be able split the content from documentText
              "text": "$content   ${documentText!}",
              "name": documentName,
            }
          ]
        else if (base64Image != "")
          "content": [
            {
              "type": "text",
              "text": content,
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:$imageType;base64,$base64Image"}
            }
          ]
      };
    } else if (modelID.toLowerCase().startsWith("claude")) {
      return {
        "role": role,
        if (base64Image == "" && documentText == "")
          "content": [
            {
              "type": "text",
              "text": content,
            }
          ]
        else if (documentText != "")
          "content": [
            {
              "type": "text",
              // Use three space to be able split the content from documentText
              "text": "$content   ${documentText!}",
              "name": documentName,
            }
          ]
        else if (base64Image != "")
          "content": [
            {
              "type": "text",
              "text": content,
            },
            {
              "type": "image",
              "source": {
                "type": "base64",
                "media_type": imageType,
                "data": base64Image
              }
            }
          ]
      };
    } else if (modelID.toLowerCase().startsWith("gemini")) {
      return {
        "role": role,
        if (base64Image == "" && documentText == "")
          "parts": [
            {"text": content}
          ]
        else if (documentText != "")
          "parts": [
            {
              "text": "$content   ${documentText!}",
              "name": documentName,
            }
          ]
        else if (base64Image != "")
          "parts": [
            {
              "text": content,
            },
            {
              "inline_data": {
                "mime_type": imageType,
                "data": base64Image,
              }
            }
          ]
      };
    }
    return {};
  }
}
