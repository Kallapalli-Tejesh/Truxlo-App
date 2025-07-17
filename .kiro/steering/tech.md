# Technology Stack & Development Guidelines

## Framework & Language
- **Flutter** - Cross-platform mobile app framework
- **Dart** - Programming language (SDK >=3.2.3 <4.0.0)

## Backend & Database
- **Supabase** - Backend-as-a-Service with PostgreSQL database
- **Row Level Security (RLS)** - Database-level security policies
- **Real-time subscriptions** - Live data updates via Supabase channels

## State Management & Architecture
- **Riverpod** - State management solution with code generation
- **Feature-based architecture** - Organized by business domains (auth, driver, warehouse, broker, jobs)
- **Provider pattern** - Dependency injection and state sharing
- **Clean Architecture** - Separation of concerns with domain, data, and presentation layers

## Key Dependencies
- `supabase_flutter` - Supabase client integration
- `flutter_riverpod` - State management with providers
- `riverpod_annotation` & `riverpod_generator` - Code generation for providers
- `google_maps_flutter` - Maps integration for tracking
- `location` & `geolocator` - Location services
- `geocoding` - Address to coordinates conversion
- `google_polyline_algorithm` - Route visualization
- `flutter_secure_storage` - Secure local storage
- `flutter_dotenv` - Environment variable management
- `cached_network_image` - Image caching and optimization
- `http` - HTTP client for API calls
- `encrypt` & `crypto` - Data encryption utilities
- `timeago` - Human-readable time formatting

## Development Tools
- `build_runner` - Code generation runner
- `riverpod_generator` - Provider code generation
- `flutter_lints` - Dart/Flutter linting rules
- `flutter_launcher_icons` - App icon generation

## Architecture Patterns

### File Structure
```
lib/
├── core/
│   ├── theme/
│   └── services/
├── features/
│   ├── auth/
│   ├── driver/
│   ├── warehouse/
│   ├── broker/
│   └── jobs/
├── providers/
├── widgets/
└── main.dart
```

### Feature Structure
```
feature/
├── data/
├── domain/
│   └── models/
└── presentation/
    ├── pages/
    └── widgets/
```

## Database Schema Guidelines
- Use UUID primary keys with `uuid_generate_v4()`
- Include `created_at` and `updated_at` timestamps
- Implement proper foreign key relationships
- Use enums for status fields
- Enable RLS on all tables

## Common Commands

### Setup
```bash
flutter pub get
flutter pub run build_runner build
```

### Development
```bash
flutter run
flutter run --debug
flutter run --release
```

### Code Generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch
```

### Testing
```bash
flutter test
flutter test --coverage
```

### Build
```bash
flutter build apk
flutter build ios
flutter build web
```

## Environment Configuration
- Uses `.env` file for sensitive configuration
- Required variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Environment loading handled in `main.dart` with error handling

## Coding Standards

### Error Handling
- Always use try-catch blocks for async operations
- Provide meaningful error messages
- Use `debugPrint` for development logging
- Handle network connectivity issues gracefully

### State Management
- Use Riverpod providers for shared state
- Implement proper loading and error states
- Use `ConsumerWidget` for widgets that need providers
- Keep providers focused and single-purpose

### Security
- Never store sensitive data in plain text
- Use secure storage for tokens and credentials
- Implement proper input validation
- Follow RLS policies in database design

### Performance
- Use `cached_network_image` for remote images
- Implement proper list virtualization for large datasets
- Use `const` constructors where possible
- Optimize database queries with proper indexing

### UI/UX Guidelines
- Follow Material Design 3 principles
- Use consistent theming from `AppTheme`
- Implement proper loading states and error handling
- Ensure accessibility compliance
- Test on multiple screen sizes