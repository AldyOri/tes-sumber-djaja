# Sumber Djaja — Flutter frontend

**English** | [Bahasa Indonesia](README.id.md)

Warehouse stock transfers for Case 2. Android is the primary target; web supports the same workflows. Operator-facing labels and validation messages use Bahasa Indonesia.

## Prerequisites

- Flutter with Dart 3.11+. Developed with Flutter 3.47.8 / Dart 3.13.7.
- Android Studio, Android SDK, accepted SDK licenses, and an emulator or USB-debuggable device.
- Android SDK Platform 36, Build-Tools 36, and NDK `27.1.12297006`. Gradle pins the NDK for reproducible builds. Install missing components through Android Studio's SDK Manager.
- Chrome for web.
- The running backend with a migrated, seeded database: [backend setup](../backend/README.md).

From this directory:

```sh
flutter doctor
flutter pub get
```

## Android

Start an emulator in Android Studio's Device Manager, or use:

```sh
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter run -d <android-device-id>
```

Android defaults to `http://10.0.2.2:3000/api`, reaching the host backend from the standard emulator. The backend must listen on `0.0.0.0:3000`, as configured in its example.

For a physical device, use the computer's LAN address. Keep both devices on the same network and allow the backend port through the firewall:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

Alternatively, forward the port over USB:

```sh
adb reverse tcp:3000 tcp:3000
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
```

The Android manifest allows internet access and HTTP for the local demo. Forms scroll and resize when the keyboard opens.

```sh
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Release signing/deployment are outside scope.

## Web

```sh
flutter run -d chrome --web-port=5173
```

Web defaults to `http://localhost:3000/api`. The backend example allows `http://localhost:5173` and `http://127.0.0.1:5173` through `CORS_ORIGINS`. Restart the backend after changing CORS.

```sh
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=5173 --dart-define=API_BASE_URL=http://127.0.0.1:3000/api
flutter build web --dart-define=API_BASE_URL=http://localhost:3000/api
```

`API_BASE_URL` includes `/api` and is configured at compile time. Restart/rebuild when changing it. HTTP is for local development; an HTTPS web origin needs an HTTPS API.

## Structure and reading the code

```text
lib/
  main.dart
  app/                         Setup, dependencies, theme, navigation
  core/
    config/                    Target-specific API configuration
    network/                   HTTP client, API errors, pagination
    utils/                     Validation and WIB formatting
  shared/
    controllers/               Repeated pagination and master-save behavior
    widgets/                   Search, pickers, forms, feedback, layout
  features/
    items/                     Item master and forms
    warehouses/                Warehouse master and forms
    stocks/                    Warehouse selection and balances
    transfers/                 Form, history, immutable details
```

Follow a workflow from screen to controller, repository, and data model. Repositories own endpoints/JSON conversion; controllers own state and validation; presentation files own widgets and navigation. Shared controllers cover repeated behavior. Dependencies are created once in `app/app_dependencies.dart` and passed explicitly.

Code uses descriptive English identifiers, named parameters, Dart formatting, and blank lines between logical steps. Comments explain business constraints and asynchronous behavior. Feature-specific widgets stay with their feature.

## Behavior

- Four destinations: Barang, Gudang, Stok Gudang, and Mutasi. Phones use bottom navigation; wide windows use a side rail.
- Search and pagination are server-backed. Warehouse pickers support subsequent pages. Transfer availability follows all stock pages so items beyond the first page remain selectable.
- Master values are trimmed; SKU/code are uppercased. Backend duplicate/unit-lock errors appear inline. Master creation/editing never adds stock.
- Transfers contain 1–50 distinct items with positive integer quantities up to 2,147,483,647. Warehouses must differ. Changing the source clears lines and loads the new source's stock.
- Availability is advisory; the backend checks balances in its transaction. Stock-conflict responses preserve the form and refresh availability.
- Pending submission disables editing, back navigation, and repeat submission. Transfer POST requests never retry automatically.
- An uncertain submission locks another attempt. The draft stays open while the operator checks history; returning also reloads source stock. Only after both requests succeed can an acknowledgment that no matching transfer exists permit another submission. This does not provide server-side idempotency.
- Success opens the transfer reference/details and refreshes history. Returning to stock fetches fresh balances. Completed transfers cannot be changed or deleted.
- Times use Asia/Jakarta (UTC+7), labeled WIB, regardless of device timezone.

## Verification and demo

```sh
dart format --output=none --set-exit-if-changed lib
flutter analyze
flutter build apk --debug
flutter build web
```

No test framework is added. Manually check Android, then repeat the core workflow on web:

1. With a clean fixture, Gudang A shows BRG-001 = 100, BRG-002 = 50, BRG-003 = 0. Gudang B shows 20, 0, 30.
2. Create/edit a barang and gudang. Try missing fields and duplicate codes. New master records have zero stock; edits preserve balances.
3. Transfer 10 BRG-001 from A to B, optionally adding 5 BRG-002. Verify the success reference, both detail lines, history filters, and detail reopening.
4. Confirm BRG-001 is 90 in A and 30 in B. If included, BRG-002 is 45 in A and 5 in B.
5. Try a decimal, zero, or excessive quantity. Add/remove lines and change the source to check clearing. Search empty results and browse subsequent pages in lists/pickers.
6. Simulate connection failure. Lists offer retry; failed submissions preserve inputs and require outcome review. Restore connectivity and use the explicit review/retry controls.
7. Check phone widths and forms with the keyboard open.

Use the backend's explicit seed/reset instructions for a fresh fixture. Starting the app never resets or reseeds inventory.

### Verified locally

On 25 October 2026, Flutter analysis and Android debug APK/web release builds passed. Chrome checks covered master creation/editing, required/duplicate validation, zero stock, multi-item submission, history filters, empty searches, list connection errors/retry, and uncertain-submission review with retained input. A simulated stale stock response also verified a real backend stock-conflict rejection: the form retained quantity 29, refreshed actual availability to 28, and created no transfer. The production web build loaded without console errors.

On an Android API 34 Pixel 3a emulator, the app loaded live stock/history, accepted quantity entry with the keyboard open, and completed a transfer of 2 BRG-003 from Gudang B to a newly created Gudang C. The returned reference/detail appeared and the API reported quantity 2 in C. Editing an existing item's unit also displayed the backend's unit-lock error inline. Local verification intentionally created demo master records and transfers; use the documented reset workflow when you need the original fixture.
