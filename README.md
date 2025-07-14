# Notesheet Tracker

A Flutter application for tracking and managing notesheets with review workflows.

## Setup

1. Clone the repository
```bash
git clone https://github.com/yourusername/notesheet_tracker.git
cd notesheet_tracker
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Supabase
- Copy `lib/config/supabase_config.template.dart` to `lib/config/supabase_config.dart`
- Replace the placeholder values with your actual Supabase project URL and anon key:
  ```dart
  static const String url = 'YOUR_SUPABASE_PROJECT_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  ```

4. Run the app
```bash
flutter run
```

## Features

- User authentication with email/password
- Create and manage notesheets
- PDF file attachments
- Review workflow with multiple reviewers
- Admin dashboard for user management
- Dark mode support

## Architecture

- Uses Supabase for backend (auth, database, storage)
- Provider pattern for state management
- Clean architecture with services and models
- Error handling with user-friendly messages

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
