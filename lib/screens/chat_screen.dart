import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:gpt_chatbot/constants/const.dart';
import 'package:gpt_chatbot/providers/chat_provider.dart';
import 'package:gpt_chatbot/services/services.dart';
import 'package:gpt_chatbot/widgets/chat_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../providers/models_provider.dart';
import '../utils/message_content_parser.dart';
import '../widgets/text_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTyping = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  String? base64Image;

  SpeechToText speech = SpeechToText();

  bool _isListening = false;
  late String textOfSpeech = "";

  late ModelsProvider modelsProvider;
  late ChatProvider chatProvider;

  final FlutterTts flutterTts = FlutterTts();

  String? _documentText;
  String? _documentName;

  @override
  void initState() {
    _initializeControllers();
    /*WidgetsBinding.instance.addPostFrameCallback((_) => */ _scrollToBottom() /*)*/;
    _initSpeech();
    super.initState();
  }

  void _initializeControllers() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    modelsProvider = Provider.of<ModelsProvider>(context);
    chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 20,
        title: const Text("GPT Chatbot",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 25)),
        toolbarHeight: 60,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async =>
                await Services.showModalSheet(context: context),
            icon: const Icon(
              Icons.more_vert_rounded,
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 10),
                controller: _listScrollController,
                itemCount:
                    chatProvider.currentMessages.length, //chatList.length,
                itemBuilder: (context, index) {
                  var parsedContent = MessageContentParser(
                    messageContent: chatProvider.currentMessages[index]
                        ['content'],
                    messageParts: chatProvider.currentMessages[index]['parts'],
                    index: index,
                  ).parseContent();

                  // Check to skip the first assistant message(For OpenAI)
                  if (parsedContent['skip'] == 'true') {
                    return const SizedBox.shrink();
                  }
                  return ChatWidget(
                    content: parsedContent['content'] ?? '',
                    role: chatProvider.currentMessages[index]['role'],
                    shouldAnimate:
                        chatProvider.currentMessages.length - 1 == index,
                    image: parsedContent['image'],
                    documentName: parsedContent['documentName'],
                  );
                },
              ),
            ),
            if (_isTyping) ...[
              LoadingAnimationWidget.waveDots(color: Colors.white, size: 30)
            ],
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Material(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      _buildImagePreview(),
                      _buildDocumentPreview(),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: TextField(
                            focusNode: focusNode,
                            style: const TextStyle(color: Colors.white),
                            controller: textEditingController,
                            onSubmitted: (_) => _handleMessageSubmission(),
                            decoration: const InputDecoration.collapsed(
                                hintText: "How can I help you?",
                                hintStyle: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      ),
                      _buildDocumentUploadButton(),
                      _buildMicButton(),
                      _buildImagePickerButton(),
                      _buildSendButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            IconButton(
                onPressed: () {
                  chatProvider.startNewChat(
                      modelId: modelsProvider.getCurrentModel);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
                icon: const Icon(Icons.add)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: Provider.of<ChatProvider>(context, listen: true)
                    .allChats
                    .length, // we have to use listen true otherwise it doesn't update
                itemBuilder: (BuildContext context, int index) {
                  String chatId = chatProvider.allChats.keys.elementAt(index);
                  String? listTileContent = _getTabName(index);
                  //String tabName = chatProvider.allChats.values.elementAt(index)
                  return listTileContent != null
                      ? Dismissible(
                          key: Key(chatId),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            // Remove item
                            chatProvider.deleteChat(chatId);
                            _showErrorSnackBar("Chat deleted");
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16.0),
                            child: const Icon(Icons.delete),
                          ),
                          child: ListTile(
                            title: Text(listTileContent, maxLines: 2),
                            onTap: () {
                              chatProvider.currentChatId = chatId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const ChatScreen()),
                              );
                            },
                            selected: chatProvider.currentChatId == chatId,
                            selectedTileColor: Colors.blueGrey.shade500,
                          ),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getTabName(int index) {
    List<Map<String, dynamic>> answersOfGPT =
        Provider.of<ChatProvider>(context, listen: true)
            .allChats
            .values
            .elementAt(index);
    if (modelsProvider.getCurrentModel.startsWith("gpt")) {
      return answersOfGPT.firstWhere(
        (element) => element["role"] == "assistant",
        orElse: () => {"content": null},
      )["content"];
    } else if (modelsProvider.getCurrentModel.startsWith("gemini")) {
      return answersOfGPT.firstWhere(
        (element) => element["role"] == "model",
        orElse: () => {"content": null},
      )["parts"]?[0]?["text"];
    }
    return null;
  }

  Widget _buildImagePreview() {
    final imageBytes =
        base64Decode(base64Image ?? ''); // Convert Base64 data into Uint8List
    return base64Image != null
        ? Expanded(
            flex: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.memory(
                  imageBytes,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 100,
                ),
                Positioned(
                  top: -20,
                  right: -25,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        clearDocumentAndImage();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        minimumSize: const Size(30, 30)),
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  Widget _buildDocumentPreview() {
    return _documentText != null
        ? Expanded(
            flex: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.file_present,
                  size: 40,
                ),
                Positioned(
                  top: -20,
                  right: -25,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        clearDocumentAndImage();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        minimumSize: const Size(20, 20)),
                    child: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  Widget _buildImagePickerButton() {
    return IconButton(
      onPressed: _pickImageFromGallery,
      icon: const Icon(
        Icons.image,
      ),
    );
  }

  Widget _buildMicButton() {
    return IconButton(
      onPressed: _isListening ? _stopListening : _startListening,
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
      ),
    );
  }

  Widget _buildDocumentUploadButton() {
    return IconButton(
      onPressed: _pickFileFromDevice,
      icon: const Icon(
        Icons.folder,
      ),
    );
  }

  void _pickFileFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String? fileExtension = result.files.single.extension;
      _documentName = result.files.single.name;
      //print(_documentName);

      // Text extraction operations
      _documentText = await _extractTextFromFile(file, fileExtension);

      setState(() {});
    } else {
      log('No file selected.');
    }
  }

// Text extraction function regarding file type
  Future<String?> _extractTextFromFile(File file, String? fileExtension) async {
    if (fileExtension == "txt") {
      return await file.readAsString();
    } else if (fileExtension == "pdf") {
      return await _extractTextFromPdf(file);
    } else if (fileExtension == "doc" || fileExtension == "docx") {
      return await _extractTextFromDocx(file);
    }
    return null;
  }

// Text extraction function for PDF
  Future<String?> _extractTextFromPdf(File file) async {
    final bytes = await file.readAsBytes();
    PdfDocument document = PdfDocument(inputBytes: bytes);
    String text = PdfTextExtractor(document).extractText(startPageIndex: 0);
    document.dispose();
    return text;
  }

// Text extraction function for DOC and DOCX
  Future<String?> _extractTextFromDocx(File file) async {
    final bytes = await file.readAsBytes();
    return docxToText(bytes);
  }

  void _pickImageFromGallery() async {
    final XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        File? imageFile = File(pickedImage.path);
        /*if (_imageFile == null) return;*/
        // Convert image to base64
        base64Image = base64Encode(imageFile.readAsBytesSync());
      });
    } else {
      log('No image selected.');
    }
  }

  void clearDocumentAndImage() {
    base64Image = _documentText = null;
  }

  Widget _buildSendButton() {
    return IconButton(
      onPressed: () async {
        _handleMessageSubmission();
      },
      icon: const Icon(
        Icons.send,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 1),
          curve: Curves.easeOut);
    });
  }

  Future<void> _handleMessageSubmission() async {
    await _sendMessageFCT(
        modelsProvider: modelsProvider, chatProvider: chatProvider);
    setState(() {
      clearDocumentAndImage();
    });
  }

  Future<void> _sendMessageFCT(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTyping) {
      _showErrorSnackBar("You can't send multiple messages at a time");
      return;
    }
    if (textEditingController.text.isEmpty && textOfSpeech.isEmpty) {
      _showErrorSnackBar("Please type a message");
      return;
    }
    try {
      // Use text of speech as a message when text input is empty
      String content = textEditingController.text.isEmpty
          ? textOfSpeech
          : textEditingController.text;
      _prepareForNewMessage(content);

      await chatProvider.sendMessageAndGetAnswers(
        chosenModelId: modelsProvider.getCurrentModel,
        onFirstChunk: () {
          setState(() {
            _isTyping = false;
          });
        },
        onChunkReceived: () {
          _scrollToBottom();
        },
      );
    } catch (error) {
      // for API Errors
      log("errorA $error");
      _showErrorSnackBar(error.toString());
      setState(() {
        _isTyping = false; // Only set false here in case of error
      });
    }
  }

  void _prepareForNewMessage(String content) {
    return setState(() {
      _isTyping = true;
      // chatList.add(ChatModel(content: textEditingController.text, role: "user"));
      chatProvider.addUserMessage(
        content: content,
        base64Image: base64Image,
        documentText: _documentText,
        documentName: _documentName,
        modelId: modelsProvider.getCurrentModel,
      );
      textEditingController.clear();
      focusNode.unfocus();
      clearDocumentAndImage();
      // Scrolls after user message printed to screen
      _scrollToBottom();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: TextWidget(label: message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _initSpeech() async {
    speech = SpeechToText();
    await speech.initialize();
    setState(() {});
  }

  Future _startListening() async {
    await speech.listen(
      onResult: _onSpeechResult,
      //listenFor: Duration(seconds: 10),
      localeId: 'tr_TR',
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await speech.stop();
    setState(() => _isListening = false);
    await _handleMessageSubmission();
    _beginSpeaking(chatProvider.currentMessages.last['content']);
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      textOfSpeech = result.recognizedWords;
      // Stop listening when the conversation ends
      if (result.finalResult) {
        _stopListening();
      }
      log(textOfSpeech);
    });
  }

  Future _beginSpeaking(String text) async {
    await flutterTts.setLanguage("tr-TR");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(1.0);
    await flutterTts.speak(text);
  }
}
