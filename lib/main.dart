import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pomotimer/apis/localstorage_variable_api.dart';
import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/blocs/ticker.dart';
import 'package:pomotimer/blocs/time_bloc.dart';
import 'package:pomotimer/screens/home_screen.dart';
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
  final variableApi =
      LocalStorageVariableApi(plugin: await SharedPreferences.getInstance());
  final variableRepository = VariableRepository(variableApi: variableApi);
  runApp(PomoTimer(
    prefs: prefs,
    variableRepository: variableRepository,
  ));
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
      initialNotificationTitle: 'pomotimer',
      initialNotificationContent: 'Initializing',
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
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          /// OPTIONAL for use custom notification
          /// the notification id must be equals with AndroidConfiguration when you call configure() method.
          flutterLocalNotificationsPlugin.show(
            888,
            'POMOTIMER',
            '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}',
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

class PomoTimer extends StatelessWidget {
  const PomoTimer({
    super.key,
    required this.prefs,
    required this.variableRepository,
  });

  final SharedPreferences prefs;
  final VariableRepository variableRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
        value: variableRepository,
        child: PomoTimerView(
          prefs: prefs,
        ));
  }
}

class PomoTimerView extends StatelessWidget {
  const PomoTimerView({
    super.key,
    required this.prefs,
  });
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    Future<int> getInitDuration() async {
      final int settingType = prefs.getInt('settingType')!;
      if (settingType == 0) {
        return Future.value(
            TimerBloc.times[prefs.getInt('selectedIndex')!] * 60);
      } else if (settingType == 1) {
        final int totalRound = prefs.getInt('totalRound')!;
        final int breakTime = (prefs.getInt('breakTime')! - 3) ~/ 60;
        final int totalWorkingTime = prefs.getInt('totalWorkingTime')!;
        final int intervalTime =
            (totalWorkingTime - (breakTime * totalRound)) ~/ totalRound;
        return Future.value(intervalTime < 0 ? 0 : intervalTime * 60);
      } else if (settingType == 2) {
        final List<CustomTimeModel> customTimeModels =
            context.read<VariableRepository>().getCustomTimeModels();
        return customTimeModels.isNotEmpty
            ? customTimeModels[0].workingTime * 60
            : 0;
      }
      return 0;
    }

    return FutureBuilder(
        future: getInitDuration(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return BlocProvider<TimerBloc>.value(
              value: TimerBloc(
                ticker: const Ticker(),
                prefs: prefs,
                initDuration: snapshot.data!,
              ),
              child: const MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'POMOTIMER',
                home: HomeScreen(),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
  }
}
