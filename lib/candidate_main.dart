import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'widgets/candidate_popup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: CandidateApp(),
    ),
  );
}

class CandidateApp extends StatelessWidget {
  const CandidateApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: const CandidateWindow(),
    );
  }
}

class CandidateWindow extends StatelessWidget {
  const CandidateWindow({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CandidatePopup(
        candidates: const [
          "বাংলা",
          "বাংলাদেশ",
          "বাংলার",
        ],
      ),
    );
  }
}
