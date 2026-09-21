import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:passport_photo_maker/core/services/ai_restore_api_service.dart';
import 'package:passport_photo_maker/core/services/premium_service.dart';
import 'package:passport_photo_maker/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  group('AI Restore Pro & Credit System Tests', () {
    late StorageService storageService;
    late PremiumService premiumService;

    setUp(() async {
      Get.testMode = true;
      Get.reset();

      await GetStorage.init();
      final box = GetStorage();
      await box.erase();

      storageService = StorageService();
      await storageService.init(box);
      Get.put<StorageService>(storageService);

      premiumService = PremiumService();
      Get.put<PremiumService>(premiumService);
    });

    tearDown(() {
      Get.reset();
    });

    test('New user starts with 2 free AI credits', () {
      expect(storageService.aiCredits, equals(2));
      expect(storageService.hasAiCredits, isTrue);
      expect(premiumService.aiCredits.value, equals(2));
      expect(premiumService.canUseAiRestore, isTrue);
    });

    test('Consuming AI credit deducts credit count', () async {
      expect(premiumService.aiCredits.value, equals(2));

      await premiumService.consumeAiCredit();
      expect(premiumService.aiCredits.value, equals(1));
      expect(storageService.aiCredits, equals(1));

      await premiumService.consumeAiCredit();
      expect(premiumService.aiCredits.value, equals(0));
      expect(storageService.aiCredits, equals(0));
      expect(storageService.hasAiCredits, isFalse);
      expect(premiumService.canUseAiRestore, isFalse);
    });

    test('Adding credits increases credit count', () async {
      await storageService.addCredits(3);
      premiumService.refreshCredits();

      expect(storageService.aiCredits, equals(5));
      expect(premiumService.aiCredits.value, equals(5));
      expect(premiumService.canUseAiRestore, isTrue);
    });

    test('Pro user can always use AI restore even with 0 credits', () async {
      // Drain credits
      await storageService.deductCredit();
      await storageService.deductCredit();
      premiumService.refreshCredits();
      expect(premiumService.aiCredits.value, equals(0));
      expect(premiumService.canUseAiRestore, isFalse);

      // Unlock Pro
      await premiumService.unlockPro();
      expect(premiumService.isPro.value, isTrue);
      expect(premiumService.canUseAiRestore, isTrue);

      // Consuming credit as Pro does not decrease below 0 or fail
      await premiumService.consumeAiCredit();
      expect(premiumService.aiCredits.value, equals(0));
    });

    test('AiRestoreApiService isConfigured checks token presence', () {
      expect(AiRestoreApiService.isConfigured, isTrue);
    });
  });
}
