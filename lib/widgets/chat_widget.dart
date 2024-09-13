import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:gpt_chatbot/constants/const.dart';

class ChatWidget extends StatelessWidget {
  const ChatWidget(
      {super.key,
      required this.msg,
      required this.chatIndex,
      this.shouldAnimate = false});

  final String msg;
  final int chatIndex;
  final bool shouldAnimate;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: scaffoldBackgroundColor /*cardColor*/,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: chatIndex == 0 // index 0 = user, 1 = gpt
                  ? Bubble(
                      alignment: Alignment.topRight,
                      color: Colors.greenAccent.shade100,
                      showNip: true,
                      nip: BubbleNip.rightBottom,
                      radius: const Radius.circular(10.0),
                      child: Text(
                        msg,
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : shouldAnimate // animated last message
                      ? Bubble(
                          alignment: Alignment.topLeft,
                          color: Colors.grey.shade100,
                          showNip: true,
                          nip: BubbleNip.leftBottom,
                          radius: const Radius.circular(10.0),
                          child: AnimatedTextKit(
                              pause: const Duration(milliseconds: 0),
                              isRepeatingAnimation: false,
                              repeatForever: false,
                              displayFullTextOnTap: true,
                              totalRepeatCount: 0,
                              animatedTexts: [
                                TyperAnimatedText(msg,
                                    speed: const Duration(milliseconds: 8),
                                    textStyle: const TextStyle(fontSize: 16)),
                              ]),
                        )
                      : Bubble(
                          alignment: Alignment.topLeft,
                          color: Colors.grey.shade100,
                          showNip: true,
                          nip: BubbleNip.leftBottom,
                          radius: const Radius.circular(10.0),
                          child: Text(
                            msg,
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
