# Authentication Setup

This Flutter app now has a complete authentication system integrated with your backend API.

## Features

- **Sign In**: Users can sign in with email and password
- **Sign Up**: New users can create an account
- **Persistent Sessions**: Authentication tokens are saved locally
- **Auto Login**: App automatically logs in users if they have a valid session
- **Sign Out**: Users can sign out from the profile page
- **Protected Routes**: App shows sign-in screen for unauthenticated users

## Backend Configuration

The backend URL is configured in `/lib/config/app_config.dart`:

```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:3000';
  
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

**To change the backend URL**: Simply update the `baseUrl` value in this file.

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # Backend URL and app configuration
├── models/
│   ├── user.dart                # User model
│   └── auth_response.dart       # Authentication response model
├── services/
│   ├── api_service.dart         # API calls (signin, signup, profile)
│   └── storage_service.dart     # Local storage for tokens and user data
├── providers/
│   └── auth_provider.dart       # Authentication state management
├── screens/
│   ├── signin_screen.dart       # Sign in UI
│   ├── signup_screen.dart       # Sign up UI
│   └── home_screen.dart         # Main app with bottom navigation
└── main.dart                    # App entry point with AuthWrapper
```

## How It Works

1. **App Launch**: `AuthWrapper` checks if user has a saved token
2. **Authenticated**: Shows `HomeScreen` with bottom navigation (Home, Search, Profile)
3. **Not Authenticated**: Shows `SignInScreen`
4. **Sign In**: Calls `/signin` API, saves token and user data
5. **Sign Up**: Calls `/signup` API, then redirects to sign in
6. **Profile Page**: Displays user info with sign out button
7. **Sign Out**: Clears stored data and returns to sign in screen

## API Endpoints Used

- `POST /signin` - Authenticate user
- `POST /signup` - Create new account
- `GET /profile` - Get authenticated user profile

## Dependencies

- `http: ^1.2.0` - HTTP requests
- `shared_preferences: ^2.2.2` - Local storage
- `provider: ^6.1.1` - State management

## Usage

1. Make sure your backend is running on `http://localhost:3000`
2. Run the app: `flutter run`
3. Create an account or sign in with existing credentials

## Customization

### Change Backend URL

Edit `/lib/config/app_config.dart` and update the `baseUrl`:

```dart
static const String baseUrl = 'https://your-api.com';
```

### Add More API Calls

Add methods to `/lib/services/api_service.dart`:

```dart
Future<YourModel> yourApiCall() async {
  final url = Uri.parse('${AppConfig.baseUrl}/your-endpoint');
  final response = await http.get(
    url,
    headers: await _getHeaders(includeAuth: true),
  );
  // Handle response...
}
```

### Extend User Model

Edit `/lib/models/user.dart` to add more fields as needed.

