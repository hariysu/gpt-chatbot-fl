class ChatModel {
  final String content;
  final int chatIndex; /* 0 = user  1 = api */
  final String? base64Image;
  final String? documentText;

  ChatModel({
    required this.content,
    required this.chatIndex,
    this.base64Image = "",
    this.documentText = "",
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
      content: json["content"],
      chatIndex: json["chatIndex"],
      base64Image: json["base64Image"] ?? "",
      documentText: json["documentText"] ?? "");
}
