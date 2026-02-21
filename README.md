# Waiter View (Flutter)

Public mobile client for restaurant waiter operations.

Owner: **Prodromos Sarakinou**

## Overview
This app provides:
- `Νέα Παραγγελία` (create new order)
- `Προσθήκη Έξτρα` (append to existing table order)
- `Δείτε Παραγγελία` (view/search current orders)

It uses a feature-first modular structure with clear separation between:
- presentation (UI/state)
- domain models
- data/networking
- app/core configuration

## Architecture

### Style
- Feature-first foldering
- Lightweight layered architecture
- Stateful UI with explicit dependency wiring (no DI container yet)

### Folder Structure
```text
lib/
  app/
    waiter_app.dart
  core/
    config/
      api_config.dart
    network/
      waiter_api_client.dart
    theme/
      app_theme.dart
  features/
    home/
      presentation/
        waiter_home_screen.dart
    orders/
      domain/
        models.dart
      presentation/
        waiter_orders_screen.dart
    waiter_view/
      presentation/
        waiter_view_screen.dart
  main.dart
```

### Responsibilities
- `app/waiter_app.dart`
  - App bootstrap, theme mode state, route entry.
- `core/config/api_config.dart`
  - Runtime config (`API_BASE_URL`).
- `core/network/waiter_api_client.dart`
  - HTTP calls and API error handling.
- `core/theme/app_theme.dart`
  - Color tokens, adaptive palette, light/dark themes.
- `features/orders/domain/models.dart`
  - Shared domain models and enums.
- `features/*/presentation/*`
  - Feature UIs and local interaction logic.

## Data Flow
1. UI triggers action (`tap`, `submit`, `refresh`).
2. Presentation calls `WaiterApiClient`.
3. API response maps to domain models.
4. UI updates local state and re-renders.

## API Integration
Default base URL:
- `http://localhost:3000`

Override at runtime:
```bash
flutter run --dart-define=API_BASE_URL=https://your-host
```

Used endpoints:
- `GET /api/menu`
- `GET /api/orders`
- `POST /api/orders`

## Development Notes
- Current network layer uses `dart:io HttpClient` (no external HTTP package).
- Theme is runtime-switchable (light/dark) from header toggle actions.
- UI copy is Greek-first for restaurant floor usage.

## Testing
```bash
flutter test
```

## References
- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture)
- [Material Design 3](https://m3.material.io/)
- [Flutter Theming](https://docs.flutter.dev/cookbook/design/themes)
- [Dart HttpClient](https://api.dart.dev/stable/dart-io/HttpClient-class.html)
