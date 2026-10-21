# 🌿 GreenSpace v2

GreenSpace is a Flutter app for discovering environmental news, connecting with a
community, joining events, and reporting local environmental concerns.

## ✨ Features

- 🔐 **Authentication** — Sign up and sign in with Supabase Auth.
- 📰 **Environmental news** — Browse environment, climate, and sustainability
  articles from NewsAPI.
- 💬 **Community forum** — Share and engage with environmental posts.
- 📅 **Events** — Browse and participate in community events.
- 📍 **Green Guardian** — Submit and manage reports about local environmental
  issues, with optional media.
- 🌱 **Soil scan** — Capture or select an image and send it to the configured
  analysis backend.
- 🎨 **Theme preferences** — Switch the app's appearance.

## 🧰 Built With

- Flutter and Dart
- Supabase for authentication, database, and storage
- NewsAPI for environmental articles
- A separately hosted image-analysis backend

## 🚀 Getting Started

### Prerequisites

- Flutter SDK with Dart **3.9.2 or later**
- A configured Supabase project
- A NewsAPI key (for environmental news)
- The image-analysis backend (for soil scanning)

### Install and run

1. Clone this repository and open its root directory.
2. Install the Flutter dependencies:

   ```bash
   flutter pub get
   ```

3. Create a local `.env` file in the project root. This file is ignored by Git.
   Add the configuration values described below.
4. Start the app:

   ```bash
   flutter run
   ```

## ⚙️ Configuration

For mobile and desktop builds, add the following values to `.env`:

```dotenv
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
NEWS_API_KEY=your-newsapi-key
BACKEND_URL=http://localhost:8080
```

| Variable | Used for |
| --- | --- |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase client authentication |
| `NEWS_API_KEY` | Fetching environmental news |
| `BACKEND_URL` | Image-analysis API; defaults to `http://localhost:8080` |

The image-analysis service expects the backend to provide `GET /api/ping` and
`POST /analyze-frame`. Change `BACKEND_URL` to the address reachable from the
device or emulator.

For web builds, provide the Supabase values as compile-time defines:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key
```

Configure the Supabase database tables and storage buckets used by the app
before using connected features. Use a Supabase **anon** key with appropriate
Row Level Security policies; never put a service-role key or other private
credential in a client app or commit real credentials.



## 🧪 Tests

Run the Flutter tests with:

```bash
flutter test
```

## 📄 License

No license is currently specified in this repository.
