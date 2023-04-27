import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pomotimer/ad_helper.dart';
import 'package:pomotimer/break_screen.dart';
import 'package:pomotimer/sliding_number.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int breakTime = 5 * 60 + 3;
  final List<int> times = [15, 20, 25, 30, 35];
  bool isRunning = false;
  bool isBreak = false;
  int totalRound = 4;
  int round = 0;
  int totalGoal = 12;
  int goal = 0;
  double itemExtent = 60;
  late int selectedMinute = 15;
  int totalSeconds = 15 * 60;
  late int selectedIndex = 0;
  late Timer timer;
  late SharedPreferences prefs;
  DateTime? currentBackPressTime;

  final TextEditingController roundTextController = TextEditingController();
  final TextEditingController goalTextController = TextEditingController();
  final TextEditingController btTextController = TextEditingController();
  final FixedExtentScrollController listWheelController =
      FixedExtentScrollController();

  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    serviceDispose();
    super.dispose();
  }

  Future<void> serviceDispose() async {
    final service = FlutterBackgroundService();
    var isServiceRunning = await service.isRunning();
    if (isServiceRunning) {
      service.invoke("stopService");
    }
  }

  @override
  void initState() {
    super.initState();
    _initGoogleMobileAds();
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _bannerAd = ad as BannerAd;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Failed to load a banner ad: ${err.message}');
          ad.dispose();
        },
      ),
    ).load();
    initPrefs();
  }

  Future initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final prefTotalRound = prefs.getInt('totalRound');
    final prefTotalGoal = prefs.getInt('totalGoal');
    final prefBreakTime = prefs.getInt('breakTime');
    final prefSelectedIndex = prefs.getInt('selectedIndex');

    totalRound = prefTotalRound ?? totalRound;
    totalGoal = prefTotalGoal ?? totalGoal;
    breakTime = prefBreakTime ?? breakTime;
    selectedIndex = prefSelectedIndex ?? selectedIndex;
    totalSeconds = times[selectedIndex] * 60;
    listWheelController.animateToItem(selectedIndex,
        duration: const Duration(seconds: 3), curve: Curves.linear);
    listWheelController.jumpToItem(selectedIndex);
    roundTextController.text = totalRound.toString();
    goalTextController.text = totalGoal.toString();
    btTextController.text = ((breakTime - 3) ~/ 60).toString();

    if (prefTotalRound == null) {
      await prefs.setInt('totalRound', totalRound);
    }
    if (prefTotalGoal == null) {
      await prefs.setInt('totalGoal', totalGoal);
    }
    if (prefBreakTime == null) {
      await prefs.setInt('breakTime', breakTime);
    }
    if (prefSelectedIndex == null) {
      await prefs.setInt('selectedIndex', selectedIndex);
    }
  }

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  void onTick(Timer timer) async {
    // finished round
    if (totalSeconds == 0) {
      if (isBreak) {
        // vibration
        bool? hadVibrator = await Vibration.hasVibrator();
        if (hadVibrator!) {
          Vibration.vibrate();
        }
        totalSeconds = selectedMinute * 60;
        isBreak = false;
      } else {
        totalSeconds = selectedMinute * 60;
        if (round + 1 == totalRound) {
          goal++;
        }
        round = (round + 1) % totalRound;
        if (goal == totalGoal) {
          timer.cancel();
          round = 0;
          goal = 0;
        } else {
          // vibration
          bool? hadVibrator = await Vibration.hasVibrator();
          if (hadVibrator!) {
            Vibration.vibrate();
          }
          isBreak = true;
          totalSeconds = breakTime;
          // _loadInterstitialAd();
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const BreakScreen();
                },
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) Navigator.of(context).pop();
        }
      }
      setState(() {});
    }
    // tick! tock!
    else {
      setState(() {
        totalSeconds = totalSeconds - 1;
        FlutterBackgroundService()
            .invoke('sendTime', {'currentTime': totalSeconds});
      });
    }
  }

  Future<void> onStartPressed() async {
    if (!isRunning) {
      final service = FlutterBackgroundService();
      var isServiceRunning = await service.isRunning();
      if (!isServiceRunning) {
        service.startService();
      }
      timer = Timer.periodic(
        const Duration(seconds: 1),
        onTick,
      );
    }
    setState(() {
      isRunning = true;
    });
  }

  Future<void> onPausePressed() async {
    serviceDispose();
    timer.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void onTimeResetPressed() {
    onPausePressed();
    setState(() {
      totalSeconds = selectedMinute * 60;
    });
  }

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      return Future.value(false);
    }
    serviceDispose();
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle timeTextStyle = TextStyle(
      fontSize: MediaQuery.of(context).size.height / 9,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    TextStyle topTextStyle = TextStyle(
      fontSize: 25,
      color: Colors.black.withOpacity(0.5),
      fontWeight: FontWeight.bold,
    );

    TextStyle bottomTextStyle = const TextStyle(
      fontSize: 16,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    TextStyle settingTextStyle = const TextStyle(
      fontSize: 15,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    TextStyle alertButtonTextStyle = const TextStyle(
      fontSize: 13,
      color: Colors.black,
      fontWeight: FontWeight.bold,
    );

    InputDecoration settingTextField = const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.all(5),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.black,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: Colors.black,
          width: 2.5,
        ),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: TextButton(
          onPressed: () {
            if (isRunning == true) {
              onPausePressed();
              totalSeconds = times[selectedIndex] * 60;
            }
            if (isBreak) {
              isBreak = false;
              if (round > 0) {
                round--;
              } else {
                goal--;
                round = totalRound - 1;
              }
            }
            setState(() {});
          },
          child: const Text(
            'POMOTIMER',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                        'Settings',
                        textAlign: TextAlign.center,
                      ),
                      content: SizedBox(
                        height: MediaQuery.of(context).size.height / 4.5,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'TOTAL ROUND',
                                    style: settingTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'TOTAL GOAL',
                                    style: settingTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'BREAK TIME (Minute)',
                                    style: settingTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  width: MediaQuery.of(context).size.width / 5,
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    controller: roundTextController,
                                    style: settingTextStyle,
                                    decoration: settingTextField,
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  width: MediaQuery.of(context).size.width / 5,
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    controller: goalTextController,
                                    style: settingTextStyle,
                                    decoration: settingTextField,
                                  ),
                                ),
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.07,
                                  width: MediaQuery.of(context).size.width / 5,
                                  alignment: Alignment.center,
                                  child: TextFormField(
                                    textAlign: TextAlign.center,
                                    controller: btTextController,
                                    style: settingTextStyle,
                                    decoration: settingTextField,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            totalRound = int.parse(roundTextController.text);
                            totalGoal = int.parse(goalTextController.text);
                            breakTime =
                                int.parse(btTextController.text) * 60 + 3;
                            await prefs.setInt('totalRound', totalRound);
                            await prefs.setInt('totalGoal', totalGoal);
                            await prefs.setInt('breakTime', breakTime);
                            if (mounted) Navigator.pop(context, 'OK');
                          },
                          child: Text(
                            'OK',
                            style: alertButtonTextStyle,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'Cancel'),
                          child: Text(
                            'Cancel',
                            style: alertButtonTextStyle,
                          ),
                        ),
                      ],
                      buttonPadding: EdgeInsets.zero,
                      contentPadding: EdgeInsets.zero,
                      actionsAlignment: MainAxisAlignment.center,
                    );
                  });
            },
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: WillPopScope(
        onWillPop: onWillPop,
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 10,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 11,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //minute card
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Transform.translate(
                        offset:
                            Offset(0, -MediaQuery.of(context).size.height / 60),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 4,
                          height: MediaQuery.of(context).size.height / 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                            0, -MediaQuery.of(context).size.height / 100),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3.5,
                          height: MediaQuery.of(context).size.height / 4.5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 3,
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: SlidingNumber(
                          number:
                              (totalSeconds ~/ 60).toString().padLeft(2, '0'),
                          style: timeTextStyle,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuint,
                        ),
                      ),
                    ],
                  ),
                  // :
                  Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width / 40,
                        height: MediaQuery.of(context).size.height / 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 80,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 40,
                        height: MediaQuery.of(context).size.height / 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  //second card
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Transform.translate(
                        offset:
                            Offset(0, -MediaQuery.of(context).size.height / 60),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 4,
                          height: MediaQuery.of(context).size.height / 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(
                            0, -MediaQuery.of(context).size.height / 100),
                        child: Container(
                          width: MediaQuery.of(context).size.width / 3.5,
                          height: MediaQuery.of(context).size.height / 4.5,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width / 3,
                        height: MediaQuery.of(context).size.height / 4,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: SlidingNumber(
                          number:
                              (totalSeconds % 60).toString().padLeft(2, '0'),
                          style: timeTextStyle,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuint,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 15,
            ),
            // TimeScroll
            isBreak == true
                ? Padding(
                    padding: const EdgeInsets.only(
                      bottom: 20,
                    ),
                    child: Text(
                      "Break Time...",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(1, 1),
                              blurRadius: 10,
                            ),
                          ]),
                    ),
                  )
                : SizedBox(
                    height: MediaQuery.of(context).size.height / 15,
                    child: ShaderMask(
                      shaderCallback: (Rect rect) {
                        return const LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.transparent,
                            Colors.transparent,
                            Colors.white,
                          ],
                          stops: [0.0, 0.4, 0.6, 1.0],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstOut,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: ListWheelScrollView(
                          itemExtent: itemExtent,
                          squeeze: 0.7,
                          diameterRatio: 10,
                          controller: listWheelController,
                          children: [
                            for (int i = 0; i < times.length; i++)
                              RotatedBox(
                                quarterTurns: 1,
                                child: Container(
                                  alignment: Alignment.center,
                                  width: MediaQuery.of(context).size.width / 7,
                                  decoration: BoxDecoration(
                                    color: selectedIndex == i
                                        ? Colors.black
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                  ),
                                  child: Text(
                                    '${times[i]}',
                                    style: TextStyle(
                                      color: selectedIndex == i
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                          ],
                          onSelectedItemChanged: (int index) async {
                            if (!isRunning) {
                              selectedIndex = index;
                              await prefs.setInt(
                                  'selectedIndex', selectedIndex);
                              selectedMinute = times[index];
                              totalSeconds = selectedMinute * 60;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                  ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 50,
            ),
            if (!isBreak)
              Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width / 15, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: MediaQuery.of(context).size.height / 4,
                      width: MediaQuery.of(context).size.width / 4,
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          if (isRunning == true && isBreak == false) {
                            return onPausePressed();
                          } else if (isRunning == false && isBreak == false) {
                            return onStartPressed();
                          }
                        },
                        icon: Icon(
                          isRunning ? Icons.pause : Icons.play_arrow,
                          size: MediaQuery.of(context).size.width / 7,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          0, MediaQuery.of(context).size.height / 60, 0, 0),
                      child: IconButton(
                        onPressed: isBreak ? null : onTimeResetPressed,
                        icon: Icon(
                          Icons.autorenew,
                          size: MediaQuery.of(context).size.width / 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      '$round/$totalRound',
                      style: topTextStyle,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 100,
                    ),
                    Text(
                      'ROUND',
                      style: bottomTextStyle,
                    ),
                  ],
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 5,
                ),
                Column(
                  children: [
                    Text(
                      '$goal/$totalGoal',
                      style: topTextStyle,
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 100,
                    ),
                    Text(
                      'GOAL',
                      style: bottomTextStyle,
                    ),
                  ],
                ),
              ],
            ),
            if (_bannerAd != null && isBreak)
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble() * 2,
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
