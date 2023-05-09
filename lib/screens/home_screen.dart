import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pomotimer/ad_helper.dart';
import 'package:pomotimer/blocs/time_bloc.dart';
import 'package:pomotimer/blocs/time_event.dart';
import 'package:pomotimer/blocs/time_state.dart';
import 'package:pomotimer/repositories/variable_repository.dart';
import 'package:pomotimer/screens/alert_screen.dart';
import 'package:pomotimer/widgets/sliding_number.dart';
import 'package:pomotimer/widgets/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FixedExtentScrollController listWheelController =
      FixedExtentScrollController();
  final double itemExtent = 60;
  DateTime? currentBackPressTime;
  BannerAd? _bannerAd;

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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
          ad.dispose();
        },
      ),
    ).load();
    controllerInit();
  }

  Future controllerInit() async {
    final prefs = await SharedPreferences.getInstance();
    final int selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    listWheelController.animateToItem(selectedIndex,
        duration: const Duration(seconds: 3), curve: Curves.linear);
    listWheelController.jumpToItem(selectedIndex);
  }

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  void showAlertScreen(BuildContext context, String text) async {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return AlertScreen(
              text: text,
            );
          },
        ),
      );
    }
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    int getFromRepo(String key) =>
        context.read<VariableRepository>().getInt(key);
    final TextEditingController roundTextController = TextEditingController();
    roundTextController.text = getFromRepo('totalRound').toString();
    final TextEditingController btTextController = TextEditingController();
    btTextController.text = ((getFromRepo('breakTime') - 3) ~/ 60).toString();

    int round = 0;

    Future<bool> onWillPop() {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        return Future.value(false);
      }
      context.read<TimerBloc>().serviceDispose();
      return Future.value(true);
    }

    int getDuration() {
      return TimerBloc.times[getFromRepo('selectedIndex')] * 60;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: TextButton(
          onPressed: () =>
              context.read<TimerBloc>().add(TimerReset(getDuration())),
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
                      actionsPadding: EdgeInsets.zero,
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
                              mainAxisSize: MainAxisSize.min,
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
                                    'BREAK TIME (Minute)',
                                    style: settingTextStyle,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
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
                            context.read<VariableRepository>().setInt(
                                'totalRound',
                                int.parse(roundTextController.text));
                            context.read<VariableRepository>().setInt(
                                'breakTime',
                                int.parse(btTextController.text) * 60 + 3);
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
      body: BlocConsumer<TimerBloc, TimerState>(
          listenWhen: (previous, current) =>
              getFromRepo('totalRound') > 1 &&
              previous.isBreak != current.isBreak &&
              (round + 1 != getFromRepo('totalRound') || !current.isBreak),
          listener: (context, state) {
            if (state.isBreak) {
              context.read<TimerBloc>().add(TimerStarted(
                    duration: getFromRepo('breakTime'),
                    isBreak: state.isBreak,
                  ));
              showAlertScreen(context, 'Break Time!');
              round++;
            } else {
              showAlertScreen(context, 'Working Time!');
              context.read<TimerBloc>().add(TimerStarted(
                    duration: getDuration(),
                    isBreak: state.isBreak,
                  ));
            }
          },
          builder: (context, state) {
            if (state.duration == 0 && round + 1 == getFromRepo('totalRound')) {
              context
                  .read<TimerBloc>()
                  .vibration([500, 1000, 500, 1000, 500, 1000]);
              // showAlertScreen(context, 'Complete!');
              context.read<TimerBloc>().add(TimerReset(getDuration()));
              round = 0;
            }
            return WillPopScope(
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
                        timeCard(context, state.duration ~/ 60),
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
                        timeCard(context, state.duration % 60),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 15,
                  ),
                  // TimeScroll
                  state.isBreak
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
                                  for (int i = 0;
                                      i < TimerBloc.times.length;
                                      i++)
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: Container(
                                        alignment: Alignment.center,
                                        width:
                                            MediaQuery.of(context).size.width /
                                                7,
                                        decoration: BoxDecoration(
                                          color:
                                              getFromRepo('selectedIndex') == i
                                                  ? Colors.black
                                                  : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 3,
                                          ),
                                        ),
                                        child: Text(
                                          '${TimerBloc.times[i]}',
                                          style: TextStyle(
                                            color:
                                                getFromRepo('selectedIndex') ==
                                                        i
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
                                  if (state is! TimerRunInProgress) {
                                    context
                                        .read<VariableRepository>()
                                        .setInt('selectedIndex', index);
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
                  // play button
                  if (!state.isBreak)
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
                                if (state.isBreak == false) {
                                  if (state is TimerRunInProgress) {
                                    context
                                        .read<TimerBloc>()
                                        .add(const TimerPaused());
                                  } else if (state is TimerInitial) {
                                    context.read<TimerBloc>().add(TimerStarted(
                                          duration: getDuration(),
                                          isBreak: state.isBreak,
                                        ));
                                  } else if (state is TimerRunPause) {
                                    context
                                        .read<TimerBloc>()
                                        .add(const TimerResumed());
                                  }
                                }
                              },
                              icon: Icon(
                                state is TimerRunInProgress
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: MediaQuery.of(context).size.width / 7,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(0,
                                MediaQuery.of(context).size.height / 60, 0, 0),
                            child: IconButton(
                              onPressed: state.isBreak
                                  ? null
                                  : () => context
                                      .read<TimerBloc>()
                                      .add(TimerReset(getDuration())),
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
                  // Progress Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$round/${getFromRepo('totalRound')}',
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
                    ],
                  ),
                  // AD
                  if (_bannerAd != null && state.isBreak)
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
            );
          }),
    );
  }

  Stack timeCard(BuildContext context, int duration) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Transform.translate(
          offset: Offset(0, -MediaQuery.of(context).size.height / 60),
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
          offset: Offset(0, -MediaQuery.of(context).size.height / 100),
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
            number: duration.toString().padLeft(2, '0'),
            style: timeTextStyle(context),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutQuint,
          ),
        ),
      ],
    );
  }
}
