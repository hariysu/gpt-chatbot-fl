class MessageContentParser {
  final List<dynamic>? messageContent;
  final List<dynamic>? messageParts;
  final int index;

  MessageContentParser({
    this.messageContent,
    this.messageParts,
    required this.index,
  });

  Map<String, String?> parseContent() {
    String relatedContent = "";
    String? relatedImage = "";
    String? documentNameAndExtension = "";

    // Handle GPT format
    if (messageContent != null) {
      if (messageContent?.first['text'] != null &&
          !messageContent?.first['text']?.contains('   ') &&
          messageContent?.length == 1) {
        relatedContent = messageContent?.first['text'];
      } else if (messageContent?.first['text']?.contains('   ') ?? false) {
        relatedContent = messageContent?.first['text'].split('   ').first;
        documentNameAndExtension = messageContent?.first['name'];
      } else if (messageContent!.length > 1 &&
          messageContent?.last?['image_url']?['url'] != null) {
        relatedContent = messageContent?.first['text'];
        relatedImage = messageContent?.last['image_url']['url'].split(',').last;
      }

      if (index == 0) {
        return {'skip': 'true'};
      }
    }
    // Handle Gemini format
    else if (messageParts != null) {
      if (messageParts?.first['text'] != null &&
          !messageParts?.first['text']?.contains('   ') &&
          messageParts?.length == 1) {
        relatedContent = messageParts?.first['text'];
      } else if (messageParts?.first['text']?.contains('   ') ?? false) {
        relatedContent = messageParts?.first['text'].split('   ').first;
        documentNameAndExtension = messageParts?.first['name'];
      } else if (messageParts!.length > 1 &&
          messageParts?.last['inline_data'] != null) {
        relatedContent = messageParts?.first['text'];
        relatedImage = messageParts?.last['inline_data']['data'];
      }
    }

    return {
      'content': relatedContent,
      'image': relatedImage,
      'documentName': documentNameAndExtension,
    };
  }
}
