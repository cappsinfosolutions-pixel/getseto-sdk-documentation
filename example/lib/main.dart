import 'package:flutter/material.dart';
import 'package:getseto_sdk/getseto_sdk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'My Broker App', home: HomeScreen());
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _startKyc(BuildContext context) async {
    await GetsetoKyc.launch(
      context,
      config: const GetsetoKycConfig(
        // Switch to KycEnvironment.production for live builds.
        environment: KycEnvironment.uat,
        apiKey: 'YOUR_API_KEY',
        tenantName: 'Your Brand Name',
        // Use AssetImage, NetworkImage, or MemoryImage for your logo.
        logo: NetworkImage('https://example.com/logo.png'),
        locale: 'en',
        theme: GetsetoKycTheme(
          brightness: Brightness.light,
          primaryColor: Color(0xFF066AFF),
          backgroundColor: Color(0xFFFFFFFF),
          button: KycButtonTheme(borderRadius: 10),
        ),
      ),
      callbacks: GetsetoKycCallbacks(
        onComplete: (result) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('KYC submitted — Application #${result.applicationId} (${result.status})')));
          }
        },
        onError: (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('KYC error: $error')));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Broker App')),
      body: Center(
        child: ElevatedButton(onPressed: () => _startKyc(context), child: const Text('Start KYC')),
      ),
    );
  }
}
