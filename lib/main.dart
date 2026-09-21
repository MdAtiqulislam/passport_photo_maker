import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/routes/app_pages.dart';
import 'core/services/ad_service.dart';
import 'core/services/premium_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Initialize Core Services
  final storageService = await Get.putAsync(() => StorageService().init());
  Get.put(PremiumService());
  Get.put(AdService());

  // Determine Initial Route based on Onboarding status
  final initialRoute = storageService.isOnboardingCompleted ? Routes.HOME : Routes.ONBOARDING;

  // Determine initial theme mode
  ThemeMode themeMode = ThemeMode.system;
  if (storageService.themeMode == 'light') {
    themeMode = ThemeMode.light;
  } else if (storageService.themeMode == 'dark') {
    themeMode = ThemeMode.dark;
  }

  runApp(
    GetMaterialApp(
      title: "Passport Photo Maker",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
}
