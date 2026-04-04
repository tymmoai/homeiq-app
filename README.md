# HomeIQ App

A modern Flutter application for smart home management, inspired by homeiq.tymmo.ai.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── routes/                   # Navigation and routing
│   └── app_router.dart
├── screens/                  # App screens
│   ├── splash_screen.dart
│   └── home_screen.dart
├── widgets/                  # Reusable widgets
├── services/                 # Business logic and API services
├── models/                   # Data models
├── utils/                    # Utility functions
└── theme/                    # App theming
    └── app_theme.dart
```

## Features

- **Modern UI**: Clean and intuitive Material Design 3 interface
- **Navigation**: Smooth navigation using GoRouter
- **State Management**: Provider for state management
- **Multi-platform**: Supports Android, iOS, Web, Windows, macOS, and Linux

## Getting Started

### Prerequisites

- Flutter SDK (3.10.0 or higher)
- Dart SDK (3.10.0 or higher)

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## Current Screens

- **Splash Screen**: App loading screen with branding
- **Home Screen**: Main dashboard with bottom navigation
  - Dashboard Tab: Overview and quick stats
  - Devices Tab: Manage smart devices
  - Rooms Tab: Organize devices by rooms
  - Settings Tab: App settings and preferences

## Dependencies

- `provider`: State management
- `go_router`: Navigation
- `http`: HTTP client for API calls
- `shared_preferences`: Local storage
- `json_annotation`: JSON serialization
- `flutter_svg`: SVG support
- `cached_network_image`: Image caching

## Development

This is a frontend-only application. Backend integration can be added later when needed.

## License

Private project - not for public distribution.

# homeiq-frontend
Frontend application for HomeIQ – a smart home diagnostics and issue-detection platform. This repository contains UI, user flows, and frontend logic.
