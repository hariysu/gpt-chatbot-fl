import 'dart:convert';

import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:gpt_chatbot/constants/const.dart';

String? _globalContent;
BuildContext? _globalContext;

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
    _globalContent = content;
    _globalContext = context;
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
                  : // (shouldAnimate) animated last message
                  Bubble(
                      alignment: Alignment.topLeft,
                      color: Colors.grey.shade100,
                      showNip: true,
                      nip: BubbleNip.leftBottom,
                      radius: const Radius.circular(10.0),
                      child: MarkdownBody(
                        data: content,
                        selectable: true,
                        builders: {
                          'pre': CodeBlockBuilder(), // Theme Functionality
                        },
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          p: const TextStyle(fontSize: 16),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          horizontalRuleDecoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                width: 1,
                                color: Colors.grey.shade300,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// Theme Functionality
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget visitText(text, TextStyle? preferredStyle) {
    final language = _detectSoftwareLanguage(_globalContent ?? '');
    // In order to select code snippet
    return SizedBox(
      width: double.maxFinite,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(
            children: [
              HighlightView(
                text.textContent,
                language: language,
                theme: atomOneDarkTheme,
                padding: const EdgeInsets.all(8),
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
              // Kopyalama ikonu
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    // Kodun kopyalanması için işlemler
                    Clipboard.setData(ClipboardData(text: text.textContent));
                    ScaffoldMessenger.of(_globalContext!).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Detect language definition with regex
  String _detectSoftwareLanguage(String content) {
    // The language definition at the beginning of the code block: ```dart, ``cpp, etc.
    final regex = RegExp(r'```(\w+)');
    final match = regex.firstMatch(content);

    if (match != null) {
      final language = match.group(1)?.toLowerCase() ?? 'plaintext';
      // If available in the list of supported languages, use
      if (supportedLanguages.contains(language)) {
        return language;
      }
    }
    // Default value for unrecognized language
    return 'plaintext';
  }
}
