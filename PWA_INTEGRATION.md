# AWA Shell - PWA Integration Guide

This document outlines the protocol and methods for the Progressive Web App (PWA) to securely communicate with the AWA Flutter shell.

## The AWA Bridge

The AWA shell exposes a bidirectional JSON-RPC style bridge via `window.flutter_inappwebview.callHandler`. It uses `AWABridge` as the handler name.

### JavaScript Wrapper

Use the following wrapper to facilitate communication and handle graceful degradation when running outside the shell (e.g., in a desktop browser for local development).

```javascript
// awa_bridge.js
const AWABridge = {
  call: async function(method, params = {}) {
    const requestId = crypto.randomUUID();
    
    // Check if we are inside the Flutter shell
    if (!window.flutter_inappwebview) {
        console.warn('AWA Bridge not found. Running in standard browser.');
        return this._mockFallback(method); // Graceful degradation for local web dev
    }

    const requestPayload = { id: requestId, method, params };
    
    try {
        const response = await window.flutter_inappwebview.callHandler('AWABridge', requestPayload);
        
        if (response.error) {
            throw new Error(`AWA Error: ${JSON.stringify(response.error)}`);
        }
        return response.data;
    } catch (err) {
        console.error('Bridge communication failed:', err);
        throw err;
    }
  },

  _mockFallback: function(method) {
      console.log(`Mocking fallback for ${method}`);
      // Implement fallback behavior here (e.g., HTML5 Geolocation, standard `<input type="file">`)
      return null;
  },

  // --- Supported Methods ---
  
  // Media & Files
  takePhoto: (quality = 80) => AWABridge.call('media.camera', { quality }),
  pickFile: (allowedExtensions = []) => AWABridge.call('media.filePicker', { allowedExtensions }),

  // Location
  getLocation: () => AWABridge.call('location.current'),

  // SMS
  sendSms: (number, text) => AWABridge.call('sms.send', { number, payload: text }),
  receiveSms: () => AWABridge.call('sms.receive')
};

export default AWABridge;
```

### Supported API Methods

#### 1. `media.camera`
Opens the device camera to capture an image.
* **Params**: `{ "quality": number }`
* **Returns**: A local file URI `file://...` or Base64 representation.

#### 2. `media.filePicker`
Opens the native file picker to select a document.
* **Params**: `{ "allowedExtensions": string[] }` (Optional, e.g., `["pdf", "doc"]`)
* **Returns**: A local file URI `file://...`.

#### 3. `location.current`
Requests the current high-accuracy device location. Handles OS-level permissions automatically.
* **Params**: None
* **Returns**: `{ "latitude": number, "longitude": number, "accuracy": number }`
* **Error**: Throws `PERMISSION_DENIED` if the user rejects location access.

#### 4. `sms.send`
Opens the OS messaging composer pre-filled with the target number and message.
* **Params**: `{ "number": string, "payload": string }`
* **Returns**: `{ "success": boolean }`

#### 5. `sms.receive`
Listens for an incoming SMS (primarily for OTP autofill).
* **Params**: None
* **Returns**: `{ "body": string }` (The text of the received SMS).
* **Note**: On iOS, due to Apple privacy sandboxing, this method instantly throws `UNSUPPORTED_PLATFORM`. The PWA must catch this and show a standard manual OTP input field.

### Error Handling

The bridge guarantees all errors are structured. The `response.error` object will always conform to:
```json
{
  "code": "STRING_IDENTIFIER",
  "message": "Human readable reason."
}
```
Ensure your PWA catches these and displays fallback UI where necessary (e.g., if GPS is permanently disabled).
