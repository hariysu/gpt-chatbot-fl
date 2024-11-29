import 'package:flutter/material.dart';
import 'package:gpt_chatbot/providers/models_provider.dart';
import 'package:gpt_chatbot/screens/chat_screen.dart';
import 'package:gpt_chatbot/screens/home_page.dart';
import 'package:gpt_chatbot/screens/login_screen.dart';
import 'package:gpt_chatbot/screens/signup_screen.dart';
import 'package:gpt_chatbot/utils/routes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'constants/const.dart';
import 'providers/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ModelsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'GPT Chatbot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
          appBarTheme: AppBarTheme(
            color: cardColor,
            iconTheme: const IconThemeData(
              color: Colors.red, // AppBar ve Drawer icon rengi
            ),
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: iconAndTextColor), //textColors
          ),
          iconTheme: const IconThemeData(
            color: Colors.green, // Uygulamadaki tüm ikonların rengi
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          // Drawer rengi ayarı
          drawerTheme: DrawerThemeData(
            backgroundColor:
                scaffoldBackgroundColor, // Drawer için istediğin rengi burada ayarlayabilirsin
          ),
          listTileTheme: const ListTileThemeData(
            textColor: Colors.yellow, // Drawer'daki ListTile text rengi
          ),
        ),
        initialRoute: Routes.chat,
        routes: {
          Routes.home: (context) => const HomePage(),
          Routes.login: (context) => const LoginScreen(),
          Routes.signup: (context) => const SignupScreen(),
          Routes.chat: (context) => const ChatScreen(),
        },
      ),
    );
  }
}
