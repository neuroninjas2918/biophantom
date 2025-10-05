import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device & App Info'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.apps),
            title: const Text('App Name'),
            subtitle: Text(_packageInfo.appName),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Package Name'),
            subtitle: Text(_packageInfo.packageName),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('App Version'),
            subtitle: Text(_packageInfo.version),
          ),
          ListTile(
            leading: const Icon(Icons.numbers),
            title: const Text('Build Number'),
            subtitle: Text(_packageInfo.buildNumber),
          ),
          ListTile(
            leading: const Icon(Icons.computer),
            title: const Text('Operating System'),
            subtitle: Text('${Platform.operatingSystem} ${Platform.operatingSystemVersion}'),
          ),
        ],
      ),
    );
  }
}
