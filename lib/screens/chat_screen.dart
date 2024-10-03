import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gpt_chatbot/constants/const.dart';
import 'package:gpt_chatbot/providers/chat_provider.dart';
import 'package:gpt_chatbot/services/services.dart';
import 'package:gpt_chatbot/widgets/chat_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../providers/models_provider.dart';
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
  File? _imageFile;

  String? base64Image;

  SpeechToText speech = SpeechToText();
  bool _isListening = false;
  late String textOfSpeech = "";

  late ModelsProvider modelsProvider;
  late ChatProvider chatProvider;

  @override
  void initState() {
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
        leading: const Icon(Icons.menu_rounded, color: Colors.white),
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
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 10),
                  controller: _listScrollController,
                  itemCount: chatProvider.getChatList.length, //chatList.length,
                  itemBuilder: (context, index) {
                    return ChatWidget(
                      msg: chatProvider
                          .getChatList[index].msg, // chatList[index].msg,
                      chatIndex: chatProvider.getChatList[index]
                          .chatIndex, //chatList[index].chatIndex,
                      shouldAnimate:
                          chatProvider.getChatList.length - 1 == index,
                      image: chatProvider.getChatList[index].base64Image,
                    );
                  }),
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

  Widget _buildImagePreview() {
    return _imageFile != null
        ? Expanded(
            flex: 1,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 100,
                ),
                Positioned(
                  top: -20,
                  right: -25,
                  child: ElevatedButton(
                    onPressed: _clearImage,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: const CircleBorder(),
                        minimumSize: const Size(30, 30)),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      base64Image = null;
    });
  }

  Widget _buildMicButton() {
    return IconButton(
      onPressed: _isListening ? _stopListening : _startListening,
      icon:
          Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
    );
  }

  Widget _buildImagePickerButton() {
    return IconButton(
      onPressed: _pickImageFromGallery,
      icon: const Icon(
        Icons.image,
        color: Colors.white,
      ),
    );
  }

  void _pickImageFromGallery() async {
    final XFile? pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        /*if (_imageFile == null) return;*/
        // Convert image to base64
        base64Image = base64Encode(_imageFile!.readAsBytesSync());
      });
    } else {
      print('No image selected.');
    }
  }

  Widget _buildSendButton() {
    return IconButton(
      onPressed: () async {
        await _sendMessageFCT(
            modelsProvider: modelsProvider, chatProvider: chatProvider);
        setState(() {
          base64Image = null;
          //_imageFile = null;
        });
      },
      icon: const Icon(
        Icons.send,
        color: Colors.white,
      ),
    );
  }

  void _scrollToBottom() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1),
        curve: Curves.easeOut);
  }

  Future<void> _handleMessageSubmission() async {
    await _sendMessageFCT(
        modelsProvider: modelsProvider, chatProvider: chatProvider);
    setState(() {
      base64Image = null;
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
      String msg = textEditingController.text.isEmpty
          ? textOfSpeech
          : textEditingController.text;
      _prepareForNewMessage(msg);
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg,
          chosenModelId: modelsProvider.getCurrentModel,
          base64Image: base64Image ?? "");
    } catch (error) {
      log("error $error");
      _showErrorSnackBar(error.toString());
    } finally {
      setState(() {
        _isTyping = false;
        // Scrolls after the page is loaded
        _scrollToBottom();
      });
    }
  }

  void _prepareForNewMessage(String msg) {
    return setState(() {
      _isTyping = true;
      // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
      chatProvider.addUserMessage(msg: msg, base64Image: base64Image);
      textEditingController.clear();
      focusNode.unfocus();
      _imageFile = null;
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
    _handleMessageSubmission();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      textOfSpeech = result.recognizedWords;
      // Stop listening when the conversation ends
      if (result.finalResult) {
        _stopListening();
      }
      print(textOfSpeech);
    });
  }
}
