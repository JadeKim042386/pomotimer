import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pomotimer/apis/variable_db.dart';
import 'package:pomotimer/app/app.dart';
import 'package:pomotimer/blocs/ticker.dart';
import 'package:pomotimer/repositories/variable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  await initializeService();
  final prefs = await SharedPreferences.getInstance();
  final variableApi = LocalStorageVariableApi(plugin: prefs);
  final variableRepository = VariableRepository(variableApi: variableApi);
  runApp(PomoTimer(
    prefs: prefs,
    variableRepository: variableRepository,
  ));
}

Future<List<dynamic>> startService(args) async {
  Completer completer = Completer<SendPort>();
  final mainPort = ReceivePort();
  final isolate =
      await FlutterIsolate.spawn(onService, [...args, mainPort.sendPort]);
  mainPort.listen((message) {
    if (message is SendPort) {
      SendPort servicePort = message;
      completer.complete(servicePort);
    } else {
      isolate.pause();
    }
  });
  return [completer.future, isolate];
}

@pragma('vm:entry-point')
Future<void> onService(args) async {
  final service = FlutterBackgroundService();
  final servicePort = ReceivePort();
  var isServiceRunning = await service.isRunning();
  StreamSubscription<int>? tickerSubscription;
  const ticker = Ticker();

  Future<void> disposeService(String message) async {
    var isServiceRunning = await service.isRunning();
    if (isServiceRunning) {
      service.invoke(message);
    }
  }

  if (!isServiceRunning) {
    await service.startService();
  }
  tickerSubscription = ticker.tick(ticks: args[0]).listen((duration) async {
    var isServiceRunning = await service.isRunning();
    if (isServiceRunning) {
      service.invoke('sendTime', {'currentTime': duration, 'isBreak': args[1]});
    } else {
      args[2].send('pause');
    }
  });

  servicePort.listen((message) async {
    if (message == 'stopService') {
      await disposeService(message);
    } else if (message is List) {
      tickerSubscription = ticker.tick(ticks: message[0]).listen((duration) =>
          service.invoke(
              'sendTime', {'currentTime': duration, 'isBreak': message[1]}));
    } else if (message == 'exit') {
      await disposeService('stopService');
      tickerSubscription!.cancel();
    }
  });
  args[2].send(servicePort.sendPort);
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  /// OPTIONAL, using custom notification channel id
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground', // id
    'pomotimer', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      autoStart: false,
      autoStartOnBoot: false,
      isForegroundMode: true,

      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'POMOTIMER',
      initialNotificationContent: 'Preparing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  // service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // SharedPreferences preferences = await SharedPreferences.getInstance();
  // await preferences.reload();
  // final log = preferences.getStringList('log') ?? <String>[];
  // log.add(DateTime.now().toIso8601String());
  // await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  /// OPTIONAL when use custom notification
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('sendTime').listen((event) async {
    if (event!.containsKey('currentTime') && event['currentTime'] > 0) {
      int seconds = event['currentTime'];
      bool isBreak = event['isBreak'];
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          /// OPTIONAL for use custom notification
          /// the notification id must be equals with AndroidConfiguration when you call configure() method.
          flutterLocalNotificationsPlugin.show(
            888,
            'POMOTIMER',
            '${isBreak ? 'Break Time:' : ''} ${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'my_foreground',
                'MY FOREGROUND SERVICE',
                icon: 'pomotimer_icon',
                ongoing: true,
                playSound: false,
              ),
            ),
          );
        }
      }
    }
  });
}
