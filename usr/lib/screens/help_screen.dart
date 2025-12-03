import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("How to use"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            "1. Enable Developer Options",
            "Go to Settings > About Phone and tap 'Build Number' 7 times until you see 'You are now a developer'.",
          ),
          _buildSection(
            "2. Select Mock Location App",
            "Go to Settings > Developer Options > Select mock location app > Choose 'Stealth GPS'.",
          ),
          _buildSection(
            "3. Select Location",
            "Open this app, tap on the map to select your desired fake location.",
          ),
          _buildSection(
            "4. Anti-Detection Mode",
            "Ensure 'Humanized' toggle is ON. This adds random micro-movements (jitter) to your location. Static GPS coordinates are easily detected by anti-cheat systems. Real GPS always drifts slightly.",
          ),
          const Divider(color: Colors.white24),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "DISCLAIMER",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
          const Text(
            "This application is for educational and testing purposes only. While 'Humanized' mode makes detection harder by simulating natural GPS drift, advanced system-level checks (like checking for the 'Mock Location' flag) can still detect this app on non-rooted devices. True invisibility requires root access and system-level modules.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}
