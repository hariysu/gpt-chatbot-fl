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
  String? documentText;

  @HiveField(4)
  String? documentName;

  ChatModel({
    required this.content,
    required this.role,
    this.base64Image = "",
    this.documentText = "",
    this.documentName = "",
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
        content: json["content"] is List
            ? (json["content"][0]["text"] ?? "")
            : json["content"],
        role: json["role"],
        base64Image: json["base64Image"] ?? "",
        documentText: json["documentText"] ?? "",
        documentName: json["documentName"] ?? "",
      );

  // Function to convert Json format
  Map<String, dynamic> toJson() {
    return {
      "role": role,
      if (base64Image == "" && documentText == "")
        "content": content
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
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          }
        ]
    };
  }
}
