class ChatModel {
  final String content;
  final String role;
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

  // Function to convert Json format
  Map<String, dynamic> toJson() {
    return {
      "role": role,
      "content": content,
    };
  }
}
