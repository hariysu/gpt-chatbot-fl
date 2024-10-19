import 'dart:convert';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:gpt_chatbot/constants/const.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget(
      {super.key,
      required this.content,
      required this.role,
      this.shouldAnimate = false,
      this.image = "",
      this.documentName});

  final String content;
  final String role;
  final bool shouldAnimate;
  final String? image;
  final String? documentName;

  @override
  Widget build(BuildContext context) {
    // Convert Base64 data into Uint8List
    final bytes = base64Decode(image ?? "");
    return Column(
      children: [
        Material(
          color: scaffoldBackgroundColor /*cardColor*/,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: role == "user"
                  ? Bubble(
                      alignment: Alignment.topRight,
                      color: Colors.greenAccent.shade100,
                      showNip: true,
                      nip: BubbleNip.rightBottom,
                      radius: const Radius.circular(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (image != "")
                            Image.memory(
                              bytes,
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                            ),
                          if (documentName != "")
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    if (documentName!.split('.').last == "pdf")
                                      const Icon(Icons.picture_as_pdf_outlined,
                                          size: 40),
                                    if (documentName!.split('.').last == "txt")
                                      const Icon(Icons.text_fields, size: 40),
                                    if (documentName!.split('.').last ==
                                            "doc" ||
                                        documentName!.split('.').last == "docx")
                                      const Icon(Icons.table_restaurant,
                                          size: 40),
                                    Text(documentName!),
                                  ],
                                ),
                              ),
                            ),
                          Text(
                            content,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : shouldAnimate // animated last message
                      ? Bubble(
                          alignment: Alignment.topLeft,
                          color: Colors.grey.shade100,
                          showNip: true,
                          nip: BubbleNip.leftBottom,
                          radius: const Radius.circular(10.0),
                          child: Text(
                            content,
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : Bubble(
                          alignment: Alignment.topLeft,
                          color: Colors.grey.shade100,
                          showNip: true,
                          nip: BubbleNip.leftBottom,
                          radius: const Radius.circular(10.0),
                          child: Text(
                            content,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
            ),
          ),
        ),
      ],
    );
  }
}
