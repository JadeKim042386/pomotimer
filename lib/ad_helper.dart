import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6201577066467471/4070572879';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6201577066467471/4070572879';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6201577066467471/7770144736';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6201577066467471/7770144736';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6201577066467471/8603880105';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-6201577066467471/8603880105';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
