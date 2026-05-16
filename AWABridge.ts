/**
 * AWABridge.ts
 * 
 * Enterprise-grade TypeScript service for the Avanti Web App (AWA).
 * This service provides a type-safe interface for the PWA to interact with 
 * the Flutter native shell.
 */

export enum BridgeMethod {
  GetLocation = 'location.current',
  TakePhoto = 'media.camera',
  PickFromGallery = 'media.gallery',
  PickFile = 'media.filePicker',
  SendSms = 'sms.send',
  ReceiveSms = 'sms.receive',
}

export interface BridgeRequest<P = any> {
  id: string;
  method: string;
  params: P;
}

export interface BridgeResponse<D = any> {
  id: string;
  data?: D;
  error?: {
    code: string;
    message: string;
  };
}

export interface LocationData {
  latitude: number;
  longitude: number;
  accuracy: number;
}

export interface MediaData {
  base64?: string;
  path?: string;
}

export interface SmsReceivedData {
  body: string;
  address: string;
}

export class AWABridgeError extends Error {
  code: string;
  
  constructor(error: { code: string; message: string }) {
    super(error.message);
    this.name = 'AWABridgeError';
    this.code = error.code;
  }
}

class AWABridgeService {
  /**
   * Checks if the application is running inside the AWA Flutter shell.
   */
  public get isNativeShell(): boolean {
    return !!(window as any).flutter_inappwebview;
  }

  /**
   * Core bridge caller.
   */
  private async call<P, D>(method: BridgeMethod, params: P = {} as P): Promise<D> {
    const id = crypto.randomUUID();

    if (!this.isNativeShell) {
      console.warn(`[AWABridge] Native shell not detected for method: ${method}. Invoking fallback.`);
      return this.handleFallback<D>(method, params);
    }

    const request: BridgeRequest<P> = { id, method, params };

    try {
      const response: BridgeResponse<D> = await (window as any).flutter_inappwebview.callHandler('AWABridge', request);
      
      if (response.error) {
        throw new AWABridgeError(response.error);
      }

      return response.data as D;
    } catch (error) {
      if (error instanceof AWABridgeError) {
        throw error;
      }
      throw new AWABridgeError({
        code: 'BRIDGE_COMMUNICATION_FAILED',
        message: error instanceof Error ? error.message : String(error)
      });
    }
  }

  /**
   * Graceful degradation fallback logic for standard browsers.
   */
  private async handleFallback<D>(method: BridgeMethod, params: any): Promise<D> {
    switch (method) {
      case BridgeMethod.GetLocation:
        return new Promise((resolve, reject) => {
          if (!navigator.geolocation) {
            reject(new AWABridgeError({ code: 'GEO_UNSUPPORTED', message: 'Geolocation not supported by browser' }));
            return;
          }
          navigator.geolocation.getCurrentPosition(
            (pos) => resolve({
              latitude: pos.coords.latitude,
              longitude: pos.coords.longitude,
              accuracy: pos.coords.accuracy
            } as any),
            (err) => reject(new AWABridgeError({ code: 'BROWSER_GEO_FAILED', message: err.message }))
          );
        });
      
      case BridgeMethod.TakePhoto:
      case BridgeMethod.PickFromGallery:
      case BridgeMethod.PickFile:
        // For local dev, we could trigger a hidden <input type="file">
        console.log('AWABridge: Mocking file selection for local development.');
        throw new AWABridgeError({ code: 'NOT_IMPLEMENTED_IN_BROWSER', message: 'Manual file input required in standard browser.' });

      default:
        throw new AWABridgeError({
          code: 'BRIDGE_UNAVAILABLE',
          message: `Method ${method} is only available within the AWA native shell.`
        });
    }
  }

  // --- Public Native API Methods ---
  
  /**
   * Fetches the current device location with high accuracy.
   */
  public async getLocation(): Promise<LocationData> {
    return this.call<void, LocationData>(BridgeMethod.GetLocation);
  }

  /**
   * Triggers the native camera to capture a photo.
   * @param quality Compression quality (0-100). Defaults to 80.
   */
  public async takePhoto(quality: number = 80): Promise<MediaData> {
    return this.call<{ quality: number }, MediaData>(BridgeMethod.TakePhoto, { quality });
  }

  /**
   * Opens the device gallery to select a photo.
   * @param quality Compression quality (0-100). Defaults to 80.
   */
  public async pickFromGallery(quality: number = 80): Promise<MediaData> {
    return this.call<{ quality: number }, MediaData>(BridgeMethod.PickFromGallery, { quality });
  }

  /**
   * Opens the native file picker.
   * @param allowedExtensions List of allowed extensions (e.g., ['pdf', 'doc']).
   */
  public async pickFile(allowedExtensions: string[] = []): Promise<MediaData> {
    return this.call<{ allowedExtensions: string[] }, MediaData>(BridgeMethod.PickFile, { allowedExtensions });
  }

  /**
   * Launches the native SMS composer.
   */
  public async sendSms(number: string, payload: string): Promise<{ status: string }> {
    return this.call<{ number: string; payload: string }, { status: string }>(BridgeMethod.SendSms, { number, payload });
  }

  /**
   * Listens for an incoming SMS (Android only).
   */
  public async receiveSms(): Promise<SmsReceivedData> {
    return this.call<void, SmsReceivedData>(BridgeMethod.ReceiveSms);
  }
}

export const AWABridge = new AWABridgeService();
