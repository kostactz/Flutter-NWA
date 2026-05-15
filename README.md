# AWA Shell 

A hardened Flutter shell for Native-Enabled Progressive Web Apps (PWA). This shell provides a secure bridge for PWAs to access native device APIs like Camera, GPS, and SMS.

## Getting Started

### Prerequisites
- Flutter SDK (3.x recommended)
- Android Studio / Xcode (for native builds)

### Running the App
Use the provided `run.sh` script to run the application. You can specify the mode and the target PWA URL.

```bash
# Usage: ./run.sh run [debug|release] [PWA_URL]
./run.sh run debug https://your-pwa-domain.com
```

### Building the Shell
To build a production-ready APK or IPA:

```bash
# Usage: ./run.sh build [debug|release] [PWA_URL]
./run.sh build release https://your-pwa-domain.com
```

## Debugging

### Bridge Logs
The shell includes a **Debug Overlay** to monitor JSON-RPC traffic between the PWA and Flutter.
- **Activation:** Rapidly tap the **top 50 pixels** of the screen **5 times**.
- **Usage:** This overlay displays all requests sent from the PWA and responses returned by Flutter, including error details.

### PWA Console Logs
When running in `debug` mode, console messages from the PWA are mirrored to the Flutter terminal with the prefix `PWA Console:`.

### WebView Inspection
- **Android:** Open `chrome://inspect/#devices` in Chrome while the app is running in debug mode.
- **iOS:** Open Safari -> Develop -> [Your Device] -> [PWA URL].

## Testing
Run unit tests for the bridge and services using the `test.sh` script:

```bash
./test.sh
```

## Bridge API Reference
The PWA communicates with the shell via `window.flutter_inappwebview.callHandler('AWABridge', payload)`.

**Request Schema:**
```json
{
  "id": "unique-uuid",
  "method": "service.action",
  "params": { ... }
}
```

**Supported Methods:**
- `location.current`: Returns `{ latitude, longitude, accuracy }`
- `media.camera`: Opens camera, returns file URI or Base64.
- `media.filePicker`: Opens file selector.
- `sms.send`: Opens native SMS composer.
- `sms.receive`: (Android Only) Listens for incoming SMS/OTP.

