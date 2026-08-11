# VibeCircle Mobile UI

Lightweight Expo SDK 54 prototype based on the VibeCircle app blueprint.

## Included

- Login, registration, verification, reset, and optional profile setup
- Home, purpose selection, global discovery, profiles, filters, and communities
- Interactive instant matching, inbox, realtime chat, Agora audio/video calls, and feedback
- Community feed, posts, notifications, profile, privacy, block/report, and settings
- Persistent local state using Zustand and AsyncStorage
- Email, password, 18+, username, profile, and content validation

The app connects to the VibeCircle FastAPI backend through `EXPO_PUBLIC_API_URL`.

## Native development build

Push notifications and Agora calls use native modules and do not run in Expo Go. Build the
development client after native dependency or app-config changes:

```powershell
npx eas build --profile development --platform android
npx expo start --dev-client
```

## Architecture

The mobile app uses feature-first MVVM boundaries:

```text
src/
  data/
    repositories/       Repository contracts and local implementations
  features/
    auth/
      models/
      screens/          One route per file
      viewmodels/
      views/
    chat/
    community/
    discovery/
    home/
    matching/
    notifications/
    profile/
    rooms/
  navigation/           Typed root and tab navigation
  store/                Persisted local application state
  components/           Reusable presentation components
  theme/                Design tokens
  types/                Shared domain and route models
  utils/                Pure validation helpers
```

There are 48 separate `screens/*Screen.tsx` files. The root stack exposes 44 routes, while five primary pages are mounted through bottom tabs. Pages appear according to the user flow; for example, verification follows registration, calls start from chat, and room pages open from discovery.

## Run

```powershell
cd "D:\React App\VibeCam-App\VibeCam"
npx expo start --clear
```

Open it with the Expo Go app that supports SDK 54.

# VibeCircle Mobile

Expo SDK 54 mobile client using feature-first MVVM structure, React Navigation, Zustand, Axios, and encrypted SecureStore sessions.

## Connect the API

Copy `.env.example` to `.env` and replace `YOUR_COMPUTER_LAN_IP` with the computer's IPv4 address when using Expo Go on a physical phone:

```env
EXPO_PUBLIC_API_URL=http://192.168.1.10:8000/api/v1
```

Android Emulator can use `http://10.0.2.2:8000/api/v1`. Restart Expo after changing environment values:

```powershell
npx expo start --clear
```

The mobile client keeps optimistic/offline-friendly Zustand state while API responses provide canonical server state. Access and refresh tokens are stored in Expo SecureStore, not AsyncStorage.
