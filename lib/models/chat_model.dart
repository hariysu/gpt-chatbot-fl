class ChatModel {
  final String content;
  final String role; /* chatIndex 0 = user  1 = api/assistant */
  final String? base64Image;
  final String? documentText;

  ChatModel({
    required this.content,
    required this.role,
    this.base64Image = "",
    this.documentText = "",
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
      content: json["content"],
      role: json["role"],
      base64Image: json["base64Image"] ?? "",
      documentText: json["documentText"] ?? "");
}
