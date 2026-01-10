# 🌌 MindFree

MindFree is a premium, AI-powered productivity and mindfulness application built with Flutter. It combines task management, note-taking, and intelligent assistance within an immersive 3D-inspired user interface.

## ✨ Features

- **🧠 AI Assistant**: Integrated with Google Gemini for intelligent insights and conversational assistance.
- **📅 Smart Task Management**: Organize your life with a flexible task system, including calendar integration and reorderable grid views.
- **📝 Fluid Note-Taking**: Capture thoughts instantly in a clean, distraction-free environment.
- **🚀 Immersive UI**: Experience a "journey scroll" effect with a global 3D space background and high-performance micro-animations.
- **🎙️ Voice Integration**: Speech-to-text capabilities for hands-free productivity.
- **📂 Project Organization**: Group your tasks and notes into dedicated projects.
- **🔔 Live Activities**: Stay updated with real-time task progress directly on your Lock Screen (iOS).
- **💾 Offline First**: Robust local data persistence using Isar database for a seamless offline experience.

## 🛠️ Technical Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev) (Generator-based)
- **Database**: [Isar](https://isar.dev) (High-performance NoSQL)
- **AI**: [Google Generative AI (Gemini)](https://pub.dev/packages/google_generative_ai)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Styling**: Google Fonts, Flutter Animate, and Custom Canvas-based animations.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.4)
- Dart SDK
- An API Key for Google Gemini

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/mindfree.git
   cd mindfree
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate local code**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## 🏗️ Project Structure

```text
lib/
├── core/          # Styles, constants, and global utilities
├── data/          # Models, Repositories, and Service layers (Isar, Gemini)
├── features/      # Feature-based architecture (Home, Tasks, Notes, AI, etc.)
└── main.dart      # Application entry point
```

## 🎨 Design Philosophy

MindFree is designed to be more than just a tool; it's an experience. The UI leverages:
- **Glassmorphism**: Subtle translucent layers for a modern aesthetic.
- **Dynamic Space Field**: A unique 3D background that responds to user interaction and scroll depth.
- **Premium Typography**: Using `Outfit` and `Inter` for maximum readability and class.

---

Built with ❤️ for a clearer mind.
