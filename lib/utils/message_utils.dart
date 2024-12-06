import 'dart:convert';

class MessageUtils {
  static List<Map<String, dynamic>> createDeepCopy(
      List<Map<String, dynamic>> messages) {
    return List<Map<String, dynamic>>.from(jsonDecode(jsonEncode(messages)));
  }

  // Remove names function
  static void removeNamesFromList(List<dynamic> list, {bool isGemini = false}) {
    for (var item in list) {
      if (item is Map<String, dynamic> && item.containsKey('name')) {
        item.remove('name');
      }
      // Check nested lists based on API type
      if (isGemini && item.containsKey('parts') && item['parts'] is List) {
        removeNamesFromList(item['parts'], isGemini: true);
      } else if (!isGemini &&
          item.containsKey('content') &&
          item['content'] is List) {
        removeNamesFromList(item['content'], isGemini: false);
      }
    }
  }

  static List<Map<String, dynamic>> sanitizeMessages(
    List<Map<String, dynamic>> messages, {
    bool isGemini = false,
  }) {
    var messagesCopy = createDeepCopy(messages);
    removeNamesFromList(messagesCopy, isGemini: isGemini);
    return messagesCopy;
  }
}
