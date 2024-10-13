class ChatModel {
  final String msg;
  final int chatIndex; /* 0 = user  1 = api */
  final String? base64Image;
  final String? documentText;

  ChatModel({
    required this.msg,
    required this.chatIndex,
    this.base64Image = "",
    this.documentText = "",
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
      msg: json["msg"],
      chatIndex: json["chatIndex"],
      base64Image: json["base64Image"] ?? "",
      documentText: json["documentText"] ?? "");
}
