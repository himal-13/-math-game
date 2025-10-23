import 'package:fill_num/home_page.dart';
import 'package:fill_num/utils/hint_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //initilize hive
  try {
    // Initialize Hive
    await Hive.initFlutter();
    await Hive.openBox('hints_countbox');
    await Hive.openBox("easy_mode_level");
    await Hive.openBox("medium_mode_level");
    await Hive.openBox("hard_mode_level");
    await Hive.openBox("expert_mode_level");

    // Initialize AdMob with error handling
    await MobileAds.instance.initialize();
    
    // Optional: Set request configuration for test ads during development
    final RequestConfiguration requestConfiguration = RequestConfiguration(
      testDeviceIds: <String>[], // Add your test device IDs here
    );
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

  } catch (e) {
    print('Initialization error: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HintService()),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Math Games',
      theme: ThemeData.dark(),
      home: const HomePage(), // Your home page
    );
  }
}
