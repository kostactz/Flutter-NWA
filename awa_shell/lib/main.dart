import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bridge/command_dispatcher.dart';
import 'core/cache_manager.dart';
import 'ui/debug_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await CacheManager.clearTemporaryCache();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  runApp(const AWAShellApp());
}

class AWAShellApp extends StatelessWidget {
  const AWAShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWA Shell',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AWAShellScreen(),
    );
  }
}

class AWAShellScreen extends StatefulWidget {
  const AWAShellScreen({super.key});

  @override
  State<AWAShellScreen> createState() => _AWAShellScreenState();
}

class _AWAShellScreenState extends State<AWAShellScreen> {
  final GlobalKey webViewKey = GlobalKey();
  
  // Define the target PWA domain
  static const String _defaultPwaDomain = 'awa-app.example.com';
  static const String _defaultPwaUrl = 'https://$_defaultPwaDomain/';
  
  String get _pwaUrl => const String.fromEnvironment('PWA_URL', defaultValue: _defaultPwaUrl);

  InAppWebViewController? webViewController;
  late InAppWebViewSettings settings;

  bool _showDebugOverlay = false;
  int _tapCount = 0;
  DateTime _lastTapTime = DateTime.now();

  void _handleSecretTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds > 500) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= 5) {
      setState(() {
        _showDebugOverlay = !_showDebugOverlay;
      });
      _tapCount = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    
    settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      supportZoom: false,
      builtInZoomControls: false,
      displayZoomControls: false,
      overScrollMode: OverScrollMode.NEVER, // Android
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,
      useShouldOverrideUrlLoading: true, // Crucial for routing
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri(_pwaUrl)),
              initialSettings: settings,
              onWebViewCreated: (controller) {
                webViewController = controller;
                final dispatcher = CommandDispatcher();
                dispatcher.registerHandler(controller);
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final uri = navigationAction.request.url;
                final expectedHost = Uri.parse(_pwaUrl).host;

                if (uri != null) {
                  final host = uri.host;
                  
                  // Allow navigation if the host matches our whitelisted PWA domain
                  if (host == expectedHost || host.endsWith('.$expectedHost')) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  // Block navigation and route to external browser
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri, 
                      mode: LaunchMode.externalApplication,
                    );
                  }
                }

                return NavigationActionPolicy.CANCEL;
              },
              onConsoleMessage: (controller, consoleMessage) {
                if (kDebugMode) {
                  print('PWA Console: ${consoleMessage.message}');
                }
              },
            ),
            if (_showDebugOverlay) const DebugOverlay(),
            // Invisible gesture detector on top for secret tap
            if (kDebugMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 50, // Top 50 pixels acts as the secret tap area
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _handleSecretTap,
                  child: const SizedBox(
                    height: 50,
                    width: double.infinity,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
