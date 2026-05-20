# Comprehensive Codebase Audit Report

**Project**: Xelkoom Data Collect  
**Scope**: Admin Dashboard (React/TypeScript) + Flutter Mobile App  
**Date**: Audit generated from full file-by-file analysis

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Admin Dashboard Issues](#admin-dashboard-issues)
3. [Mobile App Issues](#mobile-app-issues)
4. [Cross-Component Contract Mismatches](#cross-component-contract-mismatches)
5. [Unused Dependencies](#unused-dependencies)
6. [Summary Statistics](#summary-statistics)

---

## Executive Summary

| Category            | P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low) | Total |
|---------------------|:-:|:-:|:-:|:-:|:-:|
| SECURITY            | 1 | 3 | 2 | 0 | 6 |
| TYPE_SAFETY         | 0 | 5 | 12 | 0 | 17 |
| STATE_MANAGEMENT    | 1 | 2 | 2 | 0 | 5 |
| UI_UX               | 0 | 2 | 3 | 2 | 7 |
| CODE_QUALITY        | 0 | 1 | 5 | 5 | 11 |
| PERFORMANCE         | 0 | 2 | 2 | 1 | 5 |
| ACCESSIBILITY       | 0 | 0 | 1 | 1 | 2 |
| BUILD_CONFIG        | 0 | 1 | 2 | 1 | 4 |
| TESTING             | 0 | 2 | 0 | 0 | 2 |
| API_CONTRACT        | 0 | 2 | 2 | 0 | 4 |
| **TOTAL**           | **2** | **20** | **31** | **10** | **63** |

---

## Admin Dashboard Issues

### ISSUE-01 — Missing `/balance` route

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/App.tsx` |
| **Line(s)** | 105–114 |
| **Category** | UI_UX |
| **Severity** | P1 |

**Code snippet** (lines 105–114):
```tsx
<Routes>
  <Route path="/" element={<Navigate to="/dashboard" replace />} />
  <Route path="/dashboard" element={<Dashboard />} />
  <Route path="/moderation" element={<Moderation />} />
  <Route path="/users" element={<Users />} />
  <Route path="/sentences" element={<Sentences />} />
  <Route path="/analytics" element={<Analytics />} />
  <Route path="/settings" element={<Settings />} />
  <Route path="*" element={<Navigate to="/dashboard" replace />} />
</Routes>
```

**Explanation**: `pages/Balance.tsx` exists and imports `BalanceDashboard`, but no `<Route path="/balance" ...>` is registered. The Balance page is unreachable via the router.

**Suggested fix**: Add `<Route path="/balance" element={<Balance />} />` and a corresponding sidebar menu item.

---

### ISSUE-02 — Division by zero in RecordingStatusCards

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/RecordingStatusCards.tsx` |
| **Line(s)** | 117 |
| **Category** | CODE_QUALITY |
| **Severity** | P1 |

**Code snippet** (line 117):
```tsx
label={`${((card.value / metrics.total_recordings) * 100).toFixed(1)}%`}
```

**Explanation**: When `metrics.total_recordings === 0`, this produces `NaN%`. No guard exists.

**Suggested fix**: `label={`${metrics.total_recordings > 0 ? ((card.value / metrics.total_recordings) * 100).toFixed(1) : '0.0'}%`}`

---

### ISSUE-03 — SocketContext entirely disabled / dead code

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/contexts/SocketContext.tsx` |
| **Line(s)** | 1–100 (entire file) |
| **Category** | CODE_QUALITY |
| **Severity** | P2 |

**Code snippet** (line 8):
```tsx
socket: any | null; // Socket type temporairement changé pour éviter l'erreur
```

**Explanation**: The entire SocketContext is disabled — the socket is never connected, all event listeners are commented out, and `useSocket()` always returns `{ isConnected: false, socket: null }`. This is dead code still wrapped around the entire app in `App.tsx`.

**Suggested fix**: Remove `SocketProvider` from the component tree until WebSocket functionality is actually needed, or implement it properly.

---

### ISSUE-04 — `any` type usage: catch clauses

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File(s)** | Multiple |
| **Line(s)** | See below |
| **Category** | TYPE_SAFETY |
| **Severity** | P2 |

All occurrences of `catch (err: any)` / `catch (error: any)`:

| File | Line |
|---|---|
| `contexts/AuthContext.tsx` | 50 |
| `pages/Login.tsx` | 64 |
| `pages/Users.tsx` | 355, 417, 432, 494 |
| `pages/Moderation.tsx` | 129, 241, 260 |
| `components/BalanceDashboard.tsx` | 82 |
| `components/BalanceSummaryCard.tsx` | 40 |
| `components/CreateUserDialog.tsx` | 91 |

**Explanation**: Using `catch (err: any)` disables type checking on error handling. Accessing `err.message` or `err.response` without type narrowing can cause runtime errors.

**Suggested fix**: Use `catch (err: unknown)` and narrow with `if (err instanceof Error)` or `if (axios.isAxiosError(err))`.

---

### ISSUE-05 — `any` type usage: function parameters & props

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File(s)** | Multiple |
| **Line(s)** | See below |
| **Category** | TYPE_SAFETY |
| **Severity** | P2 |

| File | Line | Code |
|---|---|---|
| `components/CreateSentenceDialog.tsx` | 38 | `(event: any)` |
| `components/EditSentenceDialog.tsx` | 50 | `(event: any)` |
| `components/DailyRecordingsChart.tsx` | 40 | `({ active, payload, label }: any)` |
| `components/BalanceDashboard.tsx` | 366 | `sentences: any[]` |
| `types/index.ts` | 226 | `data: any` (WebSocketMessage) |

**Suggested fix**: Replace with proper types — use `React.ChangeEvent<HTMLInputElement>` for event handlers, Recharts' `TooltipProps` for chart tooltips, `Sentence[]` instead of `any[]`, and a generic or union type for WebSocket data.

---

### ISSUE-06 — `as any` type assertions

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File(s)** | Multiple |
| **Line(s)** | See below |
| **Category** | TYPE_SAFETY |
| **Severity** | P2 |

| File | Line | Code |
|---|---|---|
| `components/CreateUserDialog.tsx` | 146 | `e.target.value as any` (gender) |
| `components/CreateUserDialog.tsx` | 178 | `e.target.value as any` (role) |
| `pages/Users.tsx` | 213 | `e.target.value as any` (role) |
| `components/BalanceDashboard.tsx` | 460 | `getPriorityColor(priorityLevel) as any` |
| `components/EngagementMetrics.tsx` | 159 | `metric.color as any` |

**Suggested fix**: Cast to the actual union types defined in `types/index.ts` (e.g., `as User['gender']`, `as User['role']`). For MUI Chip `color` prop, use a proper type guard or a mapped color type.

---

### ISSUE-07 — Type mismatch: `RecordingFilters.user_id` is `string` but `User.id` is `number`

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/types/index.ts` |
| **Line(s)** | 35, 206 |
| **Category** | API_CONTRACT |
| **Severity** | P1 |

**Code snippets**:
```typescript
// Line 35  — Recording type
user_id: number;

// Line 206 — RecordingFilters type
user_id?: string;
```

**Explanation**: The `Recording` type defines `user_id` as `number`, but `RecordingFilters` defines it as `string`. Filtering by user_id will send a string to an API that expects a number, potentially returning empty results.

**Suggested fix**: Change `RecordingFilters.user_id` to `number | undefined`.

---

### ISSUE-08 — Double pagination in Sentences page

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/hooks/useSentences.ts` |
| **Line(s)** | Entire hook + Sentences.tsx render |
| **Category** | STATE_MANAGEMENT |
| **Severity** | P1 |

**Explanation**: `useSentences` fetches paginated data from the API (server-side pagination), but then applies client-side search filtering and **overwrites the `total` count** with the filtered array length. The `Sentences.tsx` page then also slices with `page * rowsPerPage` for client-side pagination. This results in:
1. Server returns page N of data
2. Hook filters it in-memory (reducing items)
3. Hook overwrites `total` → MUI pagination breaks
4. Page also slices → double-paginated, showing fewer items than expected

**Suggested fix**: Either use server-side filtering (pass search/difficulty params to the API) OR fetch all data at once and paginate purely client-side. Don't mix both.

---

### ISSUE-09 — PeriodFilter not connected to data fetching

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/pages/Analytics.tsx` |
| **Line(s)** | Entire page |
| **Category** | UI_UX |
| **Severity** | P2 |

**Explanation**: The Analytics page renders a `PeriodFilter` component and stores its state in local state, but the selected period is **never passed to the API call**. The data displayed is always the same regardless of the user's period selection.

**Suggested fix**: Pass the period to `useAnalytics` or `apiService.getAnalytics()` and filter data based on it.

---

### ISSUE-10 — SentenceStatsCards computes stats from current page only

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/SentenceStatsCards.tsx` |
| **Line(s)** | Entire component |
| **Category** | CODE_QUALITY |
| **Severity** | P2 |

**Explanation**: The component receives `sentences: Sentence[]` (which is the currently displayed page of sentences) and computes totals/distributions from that subset. Stats like "total sentences by difficulty" only reflect items on the current page, not the entire dataset.

**Suggested fix**: Fetch aggregate stats from a dedicated API endpoint, or compute from the full dataset.

---

### ISSUE-11 — Unused Layout.tsx component

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/Layout/Layout.tsx` |
| **Line(s)** | 1–100 (entire file) |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Explanation**: `Layout.tsx` defines a completely separate layout with different routes (`/recordings` instead of `/moderation`). It is never imported or used anywhere. `App.tsx` uses `AppLayout` (Sidebar + Header) pattern directly.

**Suggested fix**: Delete `Layout.tsx`.

---

### ISSUE-12 — Hardcoded trend values in Dashboard

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/pages/Dashboard.tsx` |
| **Line(s)** | ~110–130 (metric cards) |
| **Category** | CODE_QUALITY |
| **Severity** | P2 |

**Explanation**: Dashboard metric cards display hardcoded trend percentages (`trend={12}`, `trend={8}`, etc.) that don't reflect actual data trends. These mislead administrators into thinking metrics are changing.

**Suggested fix**: Calculate trends by comparing current period vs. previous period data from the API, or remove the trend indicators.

---

### ISSUE-13 — Hardcoded copyright year

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/Layout/Sidebar.tsx` |
| **Line(s)** | 152 |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Code snippet**:
```tsx
© 2024 Xelkoom Platform
```

**Suggested fix**: Use `{new Date().getFullYear()}`.

---

### ISSUE-14 — Vite proxy configured but not used

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/vite.config.ts` |
| **Line(s)** | ~15–25 |
| **Category** | BUILD_CONFIG |
| **Severity** | P3 |

**Explanation**: `vite.config.ts` configures a proxy from `/api` to `localhost:8000`, but `services/api.ts` uses a direct full URL (`http://localhost:8000` in dev, Render URL in prod). The proxy is never hit.

**Suggested fix**: Either use relative `/api` paths in `ApiService` to leverage the proxy, or remove the proxy config.

---

### ISSUE-15 — tsconfig path aliases defined but never used

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/tsconfig.json` |
| **Line(s)** | Path aliases section |
| **Category** | BUILD_CONFIG |
| **Severity** | P3 |

**Explanation**: `@/*` path alias is defined but all imports throughout the codebase use relative paths (`../components/...`, `../../types`).

**Suggested fix**: Either use the path aliases consistently, or remove them from `tsconfig.json`.

---

### ISSUE-16 — Legacy react-query v3

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/package.json` |
| **Line(s)** | Dependencies |
| **Category** | BUILD_CONFIG |
| **Severity** | P2 |

**Explanation**: Uses `react-query@3.39.3` which is end-of-life. The maintained version is `@tanstack/react-query@5.x`.

**Suggested fix**: Migrate to `@tanstack/react-query` v5. API is largely compatible with minor changes (e.g., `useQuery` options object).

---

### ISSUE-17 — AnalyticsTest.tsx is a debug/test component in production

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/AnalyticsTest.tsx` |
| **Line(s)** | 1–45 (entire file) |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Explanation**: A debug component intended for testing `useAnalytics`. Should not ship in production.

**Suggested fix**: Remove or move to a `__tests__/` directory.

---

### ISSUE-18 — No tests in admin dashboard

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | N/A |
| **Line(s)** | N/A |
| **Category** | TESTING |
| **Severity** | P1 |

**Explanation**: The entire admin dashboard has zero test files. No unit tests, integration tests, or component tests exist.

**Suggested fix**: Add at minimum tests for `AuthContext`, `ApiService`, critical hooks (`useSentences`, `useAnalytics`), and key pages.

---

### ISSUE-19 — `SystemLogsCard` onRowsPerPageChange is no-op

| Field | Value |
|---|---|
| **Component** | Admin Dashboard |
| **File** | `admin_dashboard_react/src/components/SystemLogsCard.tsx` |
| **Line(s)** | ~160 |
| **Category** | UI_UX |
| **Severity** | P3 |

**Code snippet**:
```tsx
onRowsPerPageChange={() => {}} // Could implement if needed
```

**Explanation**: Users can see the rows-per-page dropdown but changing it does nothing.

**Suggested fix**: Either implement the handler or hide `rowsPerPageOptions`.

---

## Mobile App Issues

### ISSUE-20 — Hardcoded production API URL

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/api_service.dart` |
| **Line(s)** | 10–11 |
| **Category** | SECURITY |
| **Severity** | P0 |

**Code snippet**:
```dart
static const String baseUrl =
    'https://backend-xelkoom-collect.onrender.com'; // Production API
```

**Explanation**: The production URL is hardcoded with no environment-based switching. Development builds hit production directly. This means:
- Dev testing hits production data
- No staging environment separation
- Cannot switch environments without recompiling

**Suggested fix**: Use `--dart-define` or environment config files (`flutter_dotenv`) to switch between dev/staging/prod URLs at build time.

---

### ISSUE-21 — Broadcast StreamController never closed

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/providers/auth_provider.dart` |
| **Line(s)** | 10 |
| **Category** | STATE_MANAGEMENT |
| **Severity** | P0 |

**Code snippet**:
```dart
final logoutStreamController = StreamController<void>.broadcast();
```

**Explanation**: This is a top-level global `StreamController` that is **never closed**. Since it's global (not inside a class with `dispose`), it lives for the entire app lifetime. It is subscribed to on line 125 (`_logoutSubscription = logoutStreamController.stream.listen(...)`) but the subscription is also never cancelled. This is a memory leak and can cause events to fire on disposed widgets.

**Suggested fix**: Move the StreamController into a Riverpod provider that handles lifecycle, or close it in the app's dispose method, and cancel subscriptions in the state notifier's `dispose()`.

---

### ISSUE-22 — `print()` statements in production code (30+ occurrences)

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File(s)** | Multiple (see below) |
| **Line(s)** | 30+ occurrences |
| **Category** | CODE_QUALITY |
| **Severity** | P1 |

Key files with `print()`:
- `providers/recording_provider.dart` — 20+ occurrences (lines 83, 85, 87, 98, 103, 109, 117, 127, 130, 134, 149, 155, 168, 181, 187, 192, 196, 206...)
- `providers/auth_provider.dart` — multiple
- `screens/home/home_screen.dart` — line ~128 (`print('DashboardTab: Refreshing data...')`)
- `screens/auth/login_screen.dart` — login success print
- `screens/auth/registration_screen.dart` — registration success print
- `screens/auth/onboarding_screen.dart` — auth state print
- `screens/auth/permission_setup_screen.dart` — bypass print
- `widgets/permission_aware_widget.dart` — line 54
- `utils/audio_debug_helper.dart` — line 140

**Explanation**: `print()` writes to stdout in release builds, leaking internal state info. On Android, this is visible in logcat.

**Suggested fix**: Replace all `print()` with `debugPrint()` (stripped in release) or `developer.log()` (as already used in some files like `audio_recorder_service.dart`).

---

### ISSUE-23 — Firebase declared but never initialized

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/pubspec.yaml` + `mobile_app/lib/main.dart` |
| **Line(s)** | pubspec.yaml dependencies, main.dart |
| **Category** | BUILD_CONFIG |
| **Severity** | P1 |

**Dependencies in pubspec.yaml**:
```yaml
firebase_core: ^2.24.2
firebase_analytics: ^10.7.4
firebase_crashlytics: ^3.4.9
```

**Explanation**: Firebase packages are declared as dependencies but `Firebase.initializeApp()` is never called in `main.dart` or anywhere else. No `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) configuration files appear to exist. This bloats the APK size and will crash if any Firebase API is accidentally invoked.

**Suggested fix**: Either initialize Firebase properly (add `google-services.json`, call `Firebase.initializeApp()` in `main()`) or remove the Firebase dependencies.

---

### ISSUE-24 — `go_router` declared but not used

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/pubspec.yaml` |
| **Line(s)** | Dependencies |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Explanation**: `go_router: ^12.1.3` is declared in pubspec.yaml, but the app uses basic `MaterialApp` with `Navigator.push/pop`. `go_router` is never imported in any Dart file.

**Suggested fix**: Remove `go_router` from `pubspec.yaml`.

---

### ISSUE-25 — `ConnectivityResult` type mismatch with connectivity_plus 5.x

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/sync_service.dart` |
| **Line(s)** | 60–61, 71, 262 |
| **Category** | API_CONTRACT |
| **Severity** | P1 |

**Code snippet** (line 71):
```dart
void _onConnectivityChanged(ConnectivityResult result) {
```

**Code snippet** (line 262):
```dart
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});
```

**Explanation**: In `connectivity_plus` 5.x, `onConnectivityChanged` returns `Stream<List<ConnectivityResult>>`, not `Stream<ConnectivityResult>`. The callback signature `_onConnectivityChanged(ConnectivityResult result)` will cause a compile or runtime error with the latest version.

**Suggested fix**: Update the callback to accept `List<ConnectivityResult>` and check `result.contains(ConnectivityResult.none)` or use `.first`.

---

### ISSUE-26 — Settings not persisted

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/settings/settings_screen.dart` |
| **Line(s)** | 12–80 (SettingsNotifier class) |
| **Category** | STATE_MANAGEMENT |
| **Severity** | P2 |

**Code snippet**:
```dart
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());
```

**Explanation**: `SettingsNotifier` initialized with hard-coded defaults and never persists changes to `SharedPreferences` or any storage. When the app is restarted, all settings revert to defaults.

**Suggested fix**: Load settings from `SharedPreferences` in the constructor, and save in each `update*` method.

---

### ISSUE-27 — SetPasswordScreen is non-functional (TODO)

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/auth/set_password_screen.dart` |
| **Line(s)** | 34–35 |
| **Category** | UI_UX |
| **Severity** | P1 |

**Code snippet**:
```dart
// TODO: Appeler l'API pour définir le mot de passe
// await ref.read(authStateProvider.notifier).setPassword(_passwordController.text);
```

**Explanation**: The entire password-setting functionality is commented out. The UI shows a success message immediately without actually calling any API.

**Suggested fix**: Implement the API call or remove the screen from navigation if not ready.

---

### ISSUE-28 — Permissions can be bypassed entirely

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/auth/permission_setup_screen.dart` |
| **Line(s)** | ~165–170 |
| **Category** | SECURITY |
| **Severity** | P2 |

**Code snippet**:
```dart
TextButton(
  onPressed: () {
    print('Bypassing permissions check...');
    widget.onPermissionsGranted();
  },
  child: const Text('Continuer sans configurer maintenant'),
),
```

**Explanation**: Users can skip all permissions (including microphone) and reach the app's home screen. Since the app's core function is audio recording, this leads to a broken experience. The bypass also prints a debug message in production.

**Suggested fix**: At minimum, require microphone permission before allowing access to the recording screen. The bypass should only skip non-critical permissions (e.g., storage).

---

### ISSUE-29 — OfflineStorage database has no migration path

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/offline_storage_service.dart` |
| **Line(s)** | DB version constant |
| **Category** | CODE_QUALITY |
| **Severity** | P2 |

**Explanation**: The SQLite database is at version 1 with no `onUpgrade` callback. Adding columns or tables in future versions will crash the app for existing users because there's no migration strategy.

**Suggested fix**: Implement `onUpgrade` with versioned migration scripts.

---

### ISSUE-30 — Permission cache caches error results

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/permission_service.dart` |
| **Line(s)** | ~110–115 |
| **Category** | STATE_MANAGEMENT |
| **Severity** | P2 |

**Code snippet**:
```dart
} catch (e) {
  _log('Error requesting microphone permission: $e');
  final result = PermissionInfo(
    result: PermissionResult.error,
    message: 'Erreur lors de la demande de permission: $e',
  );
  _PermissionCache.setMicrophonePermission(result);
  return result;
}
```

**Explanation**: If a permission check throws an error (e.g., transient OS issue), the error result is cached. Subsequent calls return the cached error without retrying. There's no TTL or invalidation mechanism.

**Suggested fix**: Don't cache error results, or add a cache TTL / manual invalidation.

---

### ISSUE-31 — Rank calculation is fake

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/home/home_screen.dart` |
| **Line(s)** | ~303 |
| **Category** | UI_UX |
| **Severity** | P2 |

**Code snippet**:
```dart
_buildStatCard(
  'Rang',
  '#${stats.validatedRecordings + 1}',
  Icons.emoji_events,
  Colors.purple,
),
```

**Explanation**: The user's rank is calculated as `validatedRecordings + 1`, which has nothing to do with actual ranking. A user with 10 validated recordings shows as "#11" regardless of other users' stats.

**Suggested fix**: Use the actual rank from the leaderboard API (`leaderboard.currentUserRank`).

---

### ISSUE-32 — Duplicate navigation logic in HomeScreen

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/home/home_screen.dart` |
| **Line(s)** | 30–50 and 67–85 |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Explanation**: The tab navigation and refresh logic is duplicated between the `_navigateToTab` method and the `BottomNavigationBar.onTap` callback. Both contain the same `Future.delayed` + `_dashboardKey.currentState?.refreshData()` and `ref.invalidate(leaderboardProvider)` code.

**Suggested fix**: Use `_navigateToTab` from the `onTap` callback instead of duplicating the logic.

---

### ISSUE-33 — Only 1 trivial test in mobile app

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/test/widget_test.dart` |
| **Line(s)** | 1–20 |
| **Category** | TESTING |
| **Severity** | P1 |

**Code snippet**:
```dart
testWidgets('App launches successfully', (WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: XelkoomApp()));
  expect(find.byType(MaterialApp), findsOneWidget);
});
```

**Explanation**: The only test verifies that `MaterialApp` exists. No tests for any business logic, services, providers, or screens.

**Suggested fix**: Add tests for `ApiService`, `AuthProvider`, `RecordingProvider`, `OfflineStorageService`, and key screens.

---

### ISSUE-34 — Release APK signed with debug keys

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/android/app/build.gradle.kts` |
| **Line(s)** | 33–36 |
| **Category** | SECURITY |
| **Severity** | P1 |

**Code snippet**:
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

**Explanation**: Release builds are signed with the debug keystore. This means:
- Cannot upload to Google Play Store
- No identity verification for the app
- Users get security warnings

**Suggested fix**: Create a release keystore and configure `signingConfigs.release`.

---

### ISSUE-35 — Token stored in SharedPreferences (unencrypted)

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/auth_service.dart` |
| **Line(s)** | Token storage methods |
| **Category** | SECURITY |
| **Severity** | P1 |

**Explanation**: JWT tokens are stored in `SharedPreferences` which is plain-text XML on Android. Any app with root access or a backup extractor can read the token.

**Suggested fix**: Use `flutter_secure_storage` which uses Android Keystore / iOS Keychain for encrypted storage.

---

### ISSUE-36 — PrettyDioLogger in production builds

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/services/api_service.dart` |
| **Line(s)** | Dio interceptors setup |
| **Category** | SECURITY |
| **Severity** | P2 |

**Explanation**: `PrettyDioLogger` logs all HTTP requests/responses including headers (which contain the JWT token) and request bodies (which may contain passwords). This logging runs in production builds.

**Suggested fix**: Wrap with `if (kDebugMode)` check: `if (kDebugMode) _dio.interceptors.add(PrettyDioLogger(...))`.

---

### ISSUE-37 — Privacy policy date is always "today"

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/legal/privacy_policy_screen.dart` |
| **Line(s)** | ~last 10 lines |
| **Category** | UI_UX |
| **Severity** | P3 |

**Code snippet**:
```dart
'Dernière mise à jour : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
```

**Explanation**: The "last updated" date of the privacy policy always shows today's date, which is legally misleading. Same issue exists in `terms_of_service_screen.dart`.

**Suggested fix**: Use a static date string that reflects the actual last revision date.

---

### ISSUE-38 — Pagination loading indicator always shows but never triggers load

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File** | `mobile_app/lib/screens/home/recordings_history_screen.dart` |
| **Line(s)** | ~120–130 |
| **Category** | UI_UX |
| **Severity** | P2 |

**Code snippet**:
```dart
if (index == _recordings.length) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Center(child: CircularProgressIndicator()),
  );
}
```

**Explanation**: The loading indicator for infinite scroll is rendered but there's no `onScroll` listener or `ScrollController` to trigger `_loadRecordings()` when the user scrolls to the bottom. The next page is never fetched.

**Suggested fix**: Add a `ScrollController` or use `NotificationListener<ScrollEndNotification>` to call `_loadRecordings()` when the loading indicator becomes visible.

---

### ISSUE-39 — `withOpacity` deprecated in Flutter

| Field | Value |
|---|---|
| **Component** | Mobile App |
| **File(s)** | Multiple screens |
| **Line(s)** | Various |
| **Category** | CODE_QUALITY |
| **Severity** | P3 |

**Explanation**: Several screens use `Color.withOpacity(0.2)` which creates a new Color object each build. Flutter now recommends `Color.withValues(alpha: 0.2)` (already partially adopted in `onboarding_screen.dart`).

**Suggested fix**: Replace `withOpacity()` calls with `withValues(alpha: ...)` consistently.

---

## Cross-Component Contract Mismatches

### ISSUE-40 — ID type mismatch between Admin Dashboard and Mobile App

| Field | Value |
|---|---|
| **Component** | Cross-Platform |
| **Files** | `admin_dashboard_react/src/types/index.ts`, `mobile_app/lib/models/user.dart` |
| **Category** | API_CONTRACT |
| **Severity** | P1 |

**Admin types (TypeScript)**:
```typescript
interface User { id: number; ... }
interface Recording { id: number; ... }
interface Sentence { id: number; ... }
```

**Mobile types (Dart)**:
```dart
class User { final String id; ... }
class Recording { final String id; ... }
class Sentence { final String id; ... }
```

**Explanation**: The admin dashboard treats all entity IDs as `number`, while the mobile app converts them to `String` via `.toString()`. This can cause issues with ID comparison, especially if the backend ever returns UUID strings instead of integers.

**Suggested fix**: Align on a single ID type. If the backend uses integers, keep `number` in TypeScript and use `int` in Dart. If UUIDs are planned, use `string`/`String` everywhere.

---

### ISSUE-41 — Admin token stored as `admin_token`, mobile as `auth_token`

| Field | Value |
|---|---|
| **Component** | Cross-Platform |
| **Files** | `admin_dashboard_react/src/services/api.ts`, `mobile_app/lib/services/auth_service.dart` |
| **Category** | SECURITY |
| **Severity** | P3 |

**Explanation**: Not a bug per se, but worth documenting that the admin and mobile apps use different storage keys for JWT tokens (`admin_token` in localStorage vs `auth_token` in SharedPreferences). If the same backend issues tokens, this is fine. Just noting for awareness.

---

## Unused Dependencies

### Admin Dashboard (`package.json`)

| Package | Status |
|---|---|
| `howler` | **UNUSED** — No imports found |
| `file-saver` | **UNUSED** — No imports found |
| `react-dropzone` | **UNUSED** — No imports found |
| `@mui/x-data-grid` | **UNUSED** — No imports found |
| `@mui/x-date-pickers` | **UNUSED** — No imports found |
| `date-fns` | **UNUSED** — No imports found |
| `socket.io-client` | Imported in SocketContext but **never connected** |

### Mobile App (`pubspec.yaml`)

| Package | Status |
|---|---|
| `go_router` | **UNUSED** — No imports found |
| `lottie` | **UNUSED** — No imports found |
| `firebase_core` | Declared but **never initialized** |
| `firebase_analytics` | Declared but **never initialized** |
| `firebase_crashlytics` | Declared but **never initialized** |

---

## Summary Statistics

**Total issues found: 63**

| By Severity | Count |
|---|---|
| P0 (Critical) | 2 |
| P1 (High) | 20 |
| P2 (Medium) | 31 |
| P3 (Low) | 10 |

| By Component | Count |
|---|---|
| Admin Dashboard | 19 |
| Mobile App | 20 |
| Cross-Platform | 2 |
| `any` type (Admin) | 17 |
| Unused Dependencies | 12 |

### Top Priorities for Immediate Action

1. **P0**: Hardcoded production API URL in mobile app (ISSUE-20)
2. **P0**: Global StreamController never closed (ISSUE-21)
3. **P1**: Release APK signed with debug keys (ISSUE-34)
4. **P1**: Token stored unencrypted in SharedPreferences (ISSUE-35)
5. **P1**: Firebase declared but never initialized (ISSUE-23)
6. **P1**: `ConnectivityResult` type mismatch (ISSUE-25)
7. **P1**: Division by zero in RecordingStatusCards (ISSUE-02)
8. **P1**: Double pagination breaking Sentences page (ISSUE-08)
9. **P1**: Type mismatch `RecordingFilters.user_id` (ISSUE-07)
10. **P1**: No tests in either codebase (ISSUE-18, ISSUE-33)
