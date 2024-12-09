class MessageContentParser {
  final List<dynamic>? messageOpenAi;
  final List<dynamic>? messageGemini;
  final List<dynamic>? messageClaude;
  final int index;
  final String modelId;

  MessageContentParser({
    this.messageOpenAi,
    this.messageGemini,
    this.messageClaude,
    required this.index,
    required this.modelId,
  });

  Map<String, String?> parseContent() {
    String relatedContent = "";
    String? relatedImage = "";
    String? documentNameAndExtension = "";

    /* print("modelId: $modelId");
    print("messageGemini: $messageGemini");
    print("messageClaude: $messageClaude");
    print("messageOpenAi: $messageOpenAi"); */

    // Handle GPT format
    if (messageOpenAi != null) {
      if (messageOpenAi?.first['text'] != null &&
          !messageOpenAi?.first['text']?.contains('   ') &&
          messageOpenAi?.length == 1) {
        relatedContent = messageOpenAi?.first['text'];
      } else if (messageOpenAi?.first['text']?.contains('   ') ?? false) {
        relatedContent = messageOpenAi?.first['text'].split('   ').first;
        documentNameAndExtension = messageOpenAi?.first['name'];
      } else if (messageOpenAi!.length > 1 &&
          messageOpenAi?.last?['image_url']?['url'] != null) {
        relatedContent = messageOpenAi?.first['text'];
        relatedImage = messageOpenAi?.last['image_url']['url'].split(',').last;
      }

      if (index == 0) {
        return {'skip': 'true'};
      }
    }

    // Handle Claude format
    else if (messageClaude != null) {
      if (messageClaude?.first['text'] != null &&
          !messageClaude?.first['text']?.contains('   ') &&
          messageClaude?.length == 1) {
        relatedContent = messageClaude?.first['text'];
      } else if (messageClaude?.first['text']?.contains('   ') ?? false) {
        relatedContent = messageClaude?.first['text'].split('   ').first;
        documentNameAndExtension = messageClaude?.first['name'];
      } else if (messageClaude!.length > 1 &&
          messageClaude?.last['source'] != null) {
        relatedContent = messageClaude?.first['text'];
        relatedImage = messageClaude?.last['source']['data'];
      }
    }

    // Handle Gemini format
    else if (messageGemini != null) {
      if (messageGemini?.first['text'] != null &&
          !messageGemini?.first['text']?.contains('   ') &&
          messageGemini?.length == 1) {
        relatedContent = messageGemini?.first['text'];
      } else if (messageGemini?.first['text']?.contains('   ') ?? false) {
        relatedContent = messageGemini?.first['text'].split('   ').first;
        documentNameAndExtension = messageGemini?.first['name'];
      } else if (messageGemini!.length > 1 &&
          messageGemini?.last['inline_data'] != null) {
        relatedContent = messageGemini?.first['text'];
        relatedImage = messageGemini?.last['inline_data']['data'];
      }
    }

    return {
      'content': relatedContent,
      'image': relatedImage,
      'documentName': documentNameAndExtension,
    };
  }
}
