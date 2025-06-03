# GPT Chatbot Flutter App

A powerful cross-platform mobile application built with Flutter that provides an intuitive interface to interact with multiple AI chatbots including OpenAI's GPT models, Google's Gemini, and Anthropic's Claude.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI-412991?style=for-the-badge&logo=openai&logoColor=white)

## 🎥 Demo Video

Check out our app in action! The following demo shows the key features running on a simulator:

### 📱 Simulator Demo
![Demo Video](assets/demo/demo-video.gif)

## ✨ Features

### 🤖 Multi-AI Model Support
- **OpenAI GPT Models**: Integration with various GPT models including GPT-4, GPT-3.5-turbo, and legacy models
- **Google Gemini**: Support for Google's Gemini AI models
- **Anthropic Claude**: Integration with Claude AI models
- Dynamic model switching within the app

### 💬 Chat Capabilities
- **Real-time Streaming**: Live streaming responses from AI models
- **Message History**: Persistent chat history using Hive local database
- **Multiple Chat Sessions**: Start new conversations while preserving history
- **Rich Text Display**: Markdown and syntax highlighting support for code blocks

### 📱 Multimedia Support
- **Image Processing**: Upload and analyze images with vision-capable models
- **Document Reading**: Support for PDF and DOCX file processing
- **Speech-to-Text**: Voice input functionality for hands-free interaction
- **Text-to-Speech**: Audio playback of AI responses

### 🎨 User Interface
- **Material Design 3**: Modern, responsive UI following Material Design principles
- **Dark Theme**: Optimized for comfortable usage in various lighting conditions
- **Custom Animations**: Smooth transitions and loading animations
- **Responsive Layout**: Adapts to different screen sizes and orientations

### 🔐 User Management
- **Authentication System**: Login and signup functionality
- **User Profiles**: Personalized user experience
- **Session Management**: Secure user session handling

## 🛠️ Technology Stack

- **Framework**: Flutter 3.7.6
- **Language**: Dart (SDK >=2.19.3 <3.0.0)
- **State Management**: Provider pattern
- **Local Database**: Hive (NoSQL database)
- **HTTP Client**: http package for API communications
- **UI Components**: Material Design 3

### Key Dependencies

```yaml
dependencies:
  flutter_sdk: flutter
  provider: ^6.0.5              # State management
  http: ^0.13.6                 # HTTP requests
  hive_flutter: ^1.1.0          # Local database
  image_picker: ^1.0.4          # Image selection
  speech_to_text: ^6.1.1        # Voice input
  flutter_tts: ^3.6.0           # Text-to-speech
  file_picker: ^5.0.0           # File selection
  syncfusion_flutter_pdf: ^24.2.8  # PDF processing
  docx_to_text: ^1.0.1          # DOCX processing
  flutter_markdown: ^0.6.15     # Markdown rendering
  flutter_highlight: ^0.7.0     # Code syntax highlighting
  loading_animation_widget: ^1.2.1  # Loading animations
```

## 📁 Project Structure

```
lib/
├── constants/           # App constants and configuration
│   ├── const.dart      # UI constants (colors, themes)
│   └── openai_api_consts.dart  # API configuration
├── models/             # Data models
│   ├── chat_model.dart # Chat message data model
│   ├── models_model.dart # AI models data structure
│   └── chat_model.g.dart # Generated Hive adapter
├── providers/          # State management
│   ├── chat_provider.dart    # Chat state management
│   └── models_provider.dart  # AI models management
├── screens/            # UI screens
│   ├── chat_screen.dart     # Main chat interface
│   ├── home_page.dart       # Home/landing page
│   ├── login_screen.dart    # User authentication
│   └── signup_screen.dart   # User registration
├── services/           # External service integrations
│   ├── openai_api_service.dart  # OpenAI API integration
│   ├── gemini_api_service.dart  # Google Gemini API
│   ├── claude_api_service.dart  # Anthropic Claude API
│   ├── services.dart           # Utility services
│   └── assets_manager.dart     # Asset management
├── utils/              # Utility functions
│   ├── routes.dart            # App navigation routes
│   ├── message_utils.dart     # Message processing utilities
│   └── message_content_parser.dart # Content parsing logic
├── widgets/            # Reusable UI components
│   ├── chat_widget.dart       # Chat message widget
│   └── text_widget.dart       # Custom text widget
└── main.dart          # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.7.6 or later
- Dart SDK 2.19.3 or later
- Android Studio / VS Code with Flutter extensions
- API keys for desired AI services (OpenAI, Google Gemini, Anthropic Claude)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/gpt-chatbot-fl.git
   cd gpt-chatbot-fl
   ```

2. **Install Flutter Version Manager (FVM)** (Optional but recommended)
   ```bash
   dart pub global activate fvm
   fvm install 3.7.6
   fvm use 3.7.6
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Configure API Keys**
   
   Edit `lib/constants/openai_api_consts.dart` and add your API keys:
   ```dart
   String baseUrl = "https://api.openai.com/v1";
   String apiKey = "your-openai-api-key-here";
   ```
   
   Similarly, configure other API services in their respective files:
   - `lib/services/gemini_api_service.dart`
   - `lib/services/claude_api_service.dart`

6. **Run the application**
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
- Minimum SDK version: Check `android/app/build.gradle`
- Permissions are automatically handled through dependencies

#### iOS
- iOS deployment target: Check `ios/Runner.xcodeproj`
- Permissions for camera, microphone, and file access are configured in `Info.plist`


## 📱 Usage

### Basic Chat
1. Open the app and navigate to the chat screen
2. Type your message in the text input field
3. Tap send or press Enter to send the message
4. View the AI response in real-time streaming

### Advanced Features

#### Image Analysis
1. Tap the image picker button (📷)
2. Select an image from gallery or take a photo
3. Add your question about the image
4. Send to get AI analysis

#### Document Processing
1. Tap the document upload button (📎)
2. Select a PDF or DOCX file
3. The document content will be processed and included in your chat context

#### Voice Input
1. Tap and hold the microphone button (🎤)
2. Speak your message
3. Release to convert speech to text
4. Edit if needed and send

#### Model Switching
1. Open the app drawer
2. Select "Models" or use the more options menu
3. Choose your preferred AI model
4. Continue chatting with the new model

## 🏗️ Architecture

### State Management
The app uses the Provider pattern for state management:

- **ChatProvider**: Manages chat messages, current conversation, and chat history
- **ModelsProvider**: Handles AI model selection and availability

### Data Persistence
- **Hive Database**: Stores chat history locally for offline access
- **Shared Preferences**: Stores user preferences and settings

### API Integration
Each AI service has its own dedicated service class:
- Handles authentication
- Manages API requests and responses
- Implements streaming for real-time responses
- Processes different content types (text, images, documents)

## 🔒 Security Considerations

- API keys should be stored securely (consider using environment variables for production)
- User data is stored locally using Hive encryption
- Network requests use HTTPS only
- Input validation and sanitization for all user inputs

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🙏 Acknowledgments

- OpenAI for GPT models
- Google for Gemini AI
- Anthropic for Claude AI
- Flutter team for the amazing framework
- All open-source contributors

## 📞 Support

For support, questions, or feature requests:
- Create an issue on GitHub
- Contact the development team
- Check the documentation

---

**Note**: This project includes invalidated API keys. Remember to replace placeholder API keys with your actual keys and never commit real API keys to version control. Consider using environment variables or secure key management solutions for production deployments.
