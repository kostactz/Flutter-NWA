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

  // Helper methods
  takePhoto: (quality = 80) => AWABridge.call('media.camera', { quality }),
  pickFile: (allowedExtensions = []) => AWABridge.call('media.filePicker', { allowedExtensions }),
  getLocation: () => AWABridge.call('location.current'),
  sendSms: (number, text) => AWABridge.call('sms.send', { number, payload: text }),
  receiveSms: () => AWABridge.call('sms.receive')
};

export default AWABridge;
