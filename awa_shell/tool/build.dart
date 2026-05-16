import 'dart:io';
import 'package:args/args.dart';
import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'platform',
      mandatory: true,
      allowed: ['android', 'ios'],
      help: 'Target platform',
    )
    ..addOption('pwa-url', mandatory: true, help: 'URL of the PWA')
    ..addOption(
      'package-name',
      mandatory: true,
      help: 'Package name (e.g., com.example.app)',
    )
    ..addOption('app-name', mandatory: true, help: 'Display name of the app')
    ..addOption(
      'version',
      mandatory: true,
      help: 'Version string (e.g., 1.0.0+1)',
    )
    ..addOption('icon-url', help: 'URL of the icon image')
    ..addOption(
      'permissions',
      help:
          'Comma-separated list of permissions (camera,location,sms,gallery,files)',
      defaultsTo: '',
    )
    ..addOption('keystore', help: 'Path to keystore file')
    ..addOption('keystore-password', help: 'Keystore password')
    ..addOption('key-alias', help: 'Key alias')
    ..addOption('key-password', help: 'Key password');

  late final ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    print(e);
    print(parser.usage);
    exit(1);
  }

  final platform = results['platform'] as String;
  final pwaUrl = results['pwa-url'] as String;
  final packageName = results['package-name'] as String;
  final appName = results['app-name'] as String;
  final version = results['version'] as String;
  final iconUrl = results['icon-url'] as String?;
  final permissions = (results['permissions'] as String)
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  print('==> Starting White-Label Generation Engine');

  // 1. Icon Pre-processing
  if (iconUrl != null) {
    print('==> Fetching icon...');
    final response = await http.get(Uri.parse(iconUrl));
    if (response.statusCode == 200) {
      final assetsDir = Directory('assets');
      if (!await assetsDir.exists()) await assetsDir.create();
      final iconFile = File('assets/icon.png');
      await iconFile.writeAsBytes(response.bodyBytes);

      final iconConfig = File('flutter_launcher_icons.yaml');
      await iconConfig.writeAsString('''
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon.png"
''');
      print('==> Generating icons...');
      final iconResult = await Process.run('dart', [
        'run',
        'flutter_launcher_icons',
        '-f',
        'flutter_launcher_icons.yaml',
      ]);
      if (iconResult.exitCode != 0) {
        print('Icon generation failed: ${iconResult.stderr}');
        exit(1);
      }
    } else {
      print('Failed to download icon: HTTP ${response.statusCode}');
      exit(1);
    }
  }

  // 2. Version in pubspec.yaml
  print('==> Updating version...');
  final pubspecFile = File('pubspec.yaml');
  String pubspecContent = await pubspecFile.readAsString();
  pubspecContent = pubspecContent.replaceAll(
    RegExp(r'^version: .*$', multiLine: true),
    'version: $version',
  );
  await pubspecFile.writeAsString(pubspecContent);

  // 3. Android Mutators
  print('==> Mutating Android files...');
  final buildGradleFile = File('android/app/build.gradle.kts');
  if (await buildGradleFile.exists()) {
    String gradleContent = await buildGradleFile.readAsString();
    gradleContent = gradleContent.replaceAll(
      RegExp(r'namespace\s*=\s*".*"'),
      'namespace = "$packageName"',
    );
    gradleContent = gradleContent.replaceAll(
      RegExp(r'applicationId\s*=\s*".*"'),
      'applicationId = "$packageName"',
    );
    await buildGradleFile.writeAsString(gradleContent);
  }

  final manifestFile = File('android/app/src/main/AndroidManifest.xml');
  if (await manifestFile.exists()) {
    final manifestDoc = XmlDocument.parse(await manifestFile.readAsString());
    final applicationElem = manifestDoc.findAllElements('application').first;
    applicationElem.setAttribute('android:label', appName);

    // Permission mappings
    final requiredAndroidPermissions = {'android.permission.INTERNET'};
    if (permissions.contains('camera')) {
      requiredAndroidPermissions.add('android.permission.CAMERA');
    }
    if (permissions.contains('location')) {
      requiredAndroidPermissions.add('android.permission.ACCESS_FINE_LOCATION');
    }
    if (permissions.contains('sms')) {
      requiredAndroidPermissions.add('android.permission.READ_SMS');
      requiredAndroidPermissions.add('android.permission.SEND_SMS');
    }
    if (permissions.contains('gallery') || permissions.contains('files')) {
      requiredAndroidPermissions.add(
        'android.permission.READ_EXTERNAL_STORAGE',
      );
    }

    final manifestElem = manifestDoc.findElements('manifest').first;
    final usesPermissions = manifestElem
        .findElements('uses-permission')
        .toList();
    for (var perm in usesPermissions) {
      final name = perm.getAttribute('android:name');
      if (name != null && !requiredAndroidPermissions.contains(name)) {
        perm.remove();
      }
    }
    await manifestFile.writeAsString(manifestDoc.toXmlString(pretty: true));
  }

  // 4. iOS Mutators
  print('==> Mutating iOS files...');
  final pbxprojFile = File('ios/Runner.xcodeproj/project.pbxproj');
  if (await pbxprojFile.exists()) {
    String pbxContent = await pbxprojFile.readAsString();
    pbxContent = pbxContent.replaceAll(
      RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*.*?;'),
      'PRODUCT_BUNDLE_IDENTIFIER = $packageName;',
    );
    await pbxprojFile.writeAsString(pbxContent);
  }

  final infoPlistFile = File('ios/Runner/Info.plist');
  if (await infoPlistFile.exists()) {
    final plistDoc = XmlDocument.parse(await infoPlistFile.readAsString());
    final dictElem = plistDoc.findAllElements('dict').first;

    // Replace App Name
    final nameKey = dictElem.children.whereType<XmlElement>().firstWhere(
      (e) => e.name.local == 'key' && e.innerText == 'CFBundleDisplayName',
      orElse: () => throw Exception('CFBundleDisplayName key not found'),
    );
    final nameValueElem = nameKey.nextElementSibling;
    if (nameValueElem != null && nameValueElem.name.local == 'string') {
      nameValueElem.innerText = appName;
    }

    // Handle permissions
    final requiredIosKeys = <String>{};
    if (permissions.contains('camera')) {
      requiredIosKeys.add('NSCameraUsageDescription');
    }
    if (permissions.contains('gallery')) {
      requiredIosKeys.add('NSPhotoLibraryUsageDescription');
    }
    if (permissions.contains('location')) {
      requiredIosKeys.add('NSLocationWhenInUseUsageDescription');
    }

    final keysToRemove = [
      'NSCameraUsageDescription',
      'NSPhotoLibraryUsageDescription',
      'NSLocationWhenInUseUsageDescription',
    ].where((k) => !requiredIosKeys.contains(k));

    for (var keyToRemove in keysToRemove) {
      try {
        final keyNode = dictElem.children.whereType<XmlElement>().firstWhere(
          (e) => e.name.local == 'key' && e.innerText == keyToRemove,
        );
        final valueNode = keyNode.nextElementSibling;
        if (valueNode != null) {
          valueNode.remove();
        }
        keyNode.remove();
      } catch (e) {
        // Key not found, ignore
      }
    }
    await infoPlistFile.writeAsString(plistDoc.toXmlString(pretty: true));
  }

  // 5. Secure Build Orchestration
  final keystorePath = results['keystore'] as String?;
  final keyPropsFile = File('android/key.properties');
  if (keystorePath != null) {
    print('==> Configuring Keystore...');
    final keyPassword = results['key-password'] as String?;
    final keystorePassword = results['keystore-password'] as String?;
    final keyAlias = results['key-alias'] as String?;
    await keyPropsFile.writeAsString('''
storePassword=$keystorePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=$keystorePath
''');
  }

  try {
    print('==> Executing Flutter Build for $platform...');
    final buildTarget = platform == 'android' ? 'apk' : 'ipa';
    final process = await Process.start('flutter', [
      'build',
      buildTarget,
      '--release',
      '--dart-define=PWA_URL=$pwaUrl',
    ]);
    await stdout.addStream(process.stdout);
    await stderr.addStream(process.stderr);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      print('Build failed with exit code $exitCode');
      exit(exitCode);
    }
  } finally {
    if (await keyPropsFile.exists()) {
      print('==> Cleaning up keystore properties...');
      await keyPropsFile.delete();
    }
  }
  print('==> Build completed successfully!');
}
