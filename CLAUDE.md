# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Environment Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your Gemini API keys to `.env`:
   ```
   GEMINI_API_KEY_1=your_api_key_here
   GEMINI_API_KEY_2=optional_backup_key
   GEMINI_API_KEY_3=optional_backup_key
   ```

   Get API keys at: https://aistudio.google.com/apikey

**Note:** The `.env` file is gitignored to keep API keys secure. Multiple keys support automatic rotation when quota is exceeded.

## Build & Development Commands

```bash
# Get dependencies
flutter pub get

# Run code generation (required after modifying models, controllers, or routes)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Generate app icons
dart run flutter_launcher_icons
```

## Architecture Overview

Mindfree is a Flutter task/project management app with AI voice-to-task capabilities, using a feature-first architecture.

### Directory Structure

- **lib/core/** - Shared utilities, theme, and reusable widgets
- **lib/data/** - Data layer (models, repositories, services)
- **lib/features/** - Feature modules (dashboard, tasks, projects, notes, calendar, settings, etc.)

### Key Technologies

- **State Management**: Riverpod with code generation (`riverpod_annotation`)
- **Database**: Isar (local NoSQL database)
- **Routing**: GoRouter with code generation
- **AI Integration**: Google Gemini 2.5 Flash API via `google_generative_ai` + `flutter_dotenv`
- **Speech**: `speech_to_text` for voice input

### Data Flow Pattern

1. **Models** (`lib/data/models/`): Isar collections with `.g.dart` generated files
2. **Repositories** (`lib/data/repositories/`): CRUD operations using Isar
3. **Controllers** (`lib/features/*/presentation/*_controller.dart`): Riverpod providers managing business logic
4. **Views** (`lib/features/*/presentation/*_view.dart`): UI consuming controllers via `ref.watch()`

### Code Generation

This project uses `build_runner` for:
- Isar schema generation (`*.g.dart` for models)
- Riverpod provider generation (`*.g.dart` for controllers/repositories)
- GoRouter route generation (`router.g.dart`)

Always run `dart run build_runner build --delete-conflicting-outputs` after modifying annotated classes.

### Main Data Models

- **Project**: Has name, description, color, emoji
- **Task**: Belongs to optional project, has title, description, due/end dates, priority (0-2), reminders, subtasks
- **Note**: Markdown-based notes with project association
