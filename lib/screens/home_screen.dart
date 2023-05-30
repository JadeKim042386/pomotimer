import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:pomotimer/ad_helper.dart';
import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/blocs/time_bloc.dart';
import 'package:pomotimer/blocs/time_event.dart';
import 'package:pomotimer/blocs/time_state.dart';
import 'package:pomotimer/repositories/variable_repository.dart';
import 'package:pomotimer/screens/alert_screen.dart';
import 'package:pomotimer/screens/setting_screen.dart';
import 'package:pomotimer/widgets/sliding_number.dart';
import 'package:pomotimer/widgets/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const settingTypeString = ['ROUND', 'TIME', 'COUNT'];
  FixedExtentScrollController listWheelController =
      FixedExtentScrollController();
  final double itemExtent = 60;
  DateTime? currentBackPressTime;
  DateTime? currentResetPressTime;
  BannerAd? _bannerAd;
  int round = 0;
  int time = 0;
  int index = 0;
  AppLifecycleState lifecycleState = AppLifecycleState.inactive;

  @override
  void dispose() {
    _bannerAd?.dispose();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lifecycleState = state;
    super.didChangeAppLifecycleState(state);
  }

  Future controllerInit() async {
    final prefs = await SharedPreferences.getInstance();
    final int selectedIndex = prefs.getInt('selectedIndex') ?? 0;
    listWheelController.jumpToItem(selectedIndex);
    // final double oneExtent = listWheelController.position.maxScrollExtent / 5;
    // listWheelController.animateTo(oneExtent * selectedIndex,
    //     duration: const Duration(milliseconds: 200), curve: Curves.linear);
    await listWheelController.animateToItem(selectedIndex,
        duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }

  Future<InitializationStatus> _initGoogleMobileAds() {
    return MobileAds.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    int getFromRepo(String key) =>
        context.read<VariableRepository>().getInt(key);
    final TextEditingController roundTextController = TextEditingController();
    roundTextController.text = getFromRepo('totalRound').toString();
    final TextEditingController btTextController = TextEditingController();
    btTextController.text = ((getFromRepo('breakTime') - 3) ~/ 60).toString();

    void showAlertScreen(String text) async {
      if (lifecycleState == AppLifecycleState.inactive) {
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
    }

    Future<bool> onWillPop() {
      DateTime now = DateTime.now();
      if (currentBackPressTime == null ||
          now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
        currentBackPressTime = now;
        return Future.value(false);
      }
      final isolatePort = context.read<TimerBloc>().isolatePort;
      if (isolatePort != null) {
        isolatePort.send('exit');
      }
      return Future.value(true);
    }

    String getCurrentValue() {
      final int settingType = getFromRepo('settingType');
      if (settingType == 0) {
        return '$round/${getFromRepo('totalRound')}';
      } else if (settingType == 1) {
        return '${timeToString(time, false)}/${timeToString(getFromRepo('totalWorkingTime') - (((getFromRepo('breakTime') - 3) ~/ 60) * getFromRepo('totalRound')), true)}';
      } else if (settingType == 2) {
        final List<CustomTimeModel> customTimeModels =
            context.read<VariableRepository>().getCustomTimeModels();
        return '$index/${customTimeModels.length}';
      }
      return '0';
    }

    int getDuration() {
      final int settingType = getFromRepo('settingType');
      if (settingType == 0) {
        return TimerBloc.times[getFromRepo('selectedIndex')] * 60;
      } else if (settingType == 1) {
        final int totalRound = getFromRepo('totalRound');
        final int breakTime = getFromRepo('breakTime') == 0
            ? 0
            : getFromRepo('breakTime') - 3; // second
        final int totalWorkingTime =
            getFromRepo('totalWorkingTime') * 60; // second
        final int intervalTime =
            (totalWorkingTime - (breakTime * totalRound)) ~/ totalRound;
        return intervalTime < 0 ? 0 : intervalTime;
      } else if (settingType == 2) {
        final List<CustomTimeModel> customTimeModels =
            context.read<VariableRepository>().getCustomTimeModels();
        return customTimeModels.isNotEmpty
            ? customTimeModels[index].workingTime * 60
            : 0;
      }
      return 0;
    }

    void onResetPressed() {
      DateTime now = DateTime.now();
      if (currentResetPressTime == null ||
          now.difference(currentResetPressTime!) > const Duration(seconds: 2)) {
        currentResetPressTime = now;
        context.read<TimerBloc>().add(TimerReset(getDuration()));
      } else {
        round = 0;
        time = 0;
        index = 0;
        setState(() {});
      }
    }

    bool getListenWhen(previous, current) {
      final int settingType = getFromRepo('settingType');
      if (settingType == 0) {
        return getFromRepo('totalRound') > 1 &&
            previous.isBreak != current.isBreak &&
            (round + 1 != getFromRepo('totalRound') || !current.isBreak);
      } else if (settingType == 1) {
        final int totalRound = getFromRepo('totalRound');
        final int breakTime = getFromRepo('breakTime') == 0
            ? 0
            : getFromRepo('breakTime') - 3; // second
        int totalWorkingTime = getFromRepo('totalWorkingTime') * 60;
        final int intervalTime =
            (totalWorkingTime - (breakTime * totalRound)) ~/ totalRound;
        totalWorkingTime = intervalTime * totalRound;
        return totalWorkingTime > intervalTime &&
            previous.isBreak != current.isBreak &&
            (time + intervalTime != totalWorkingTime || !current.isBreak);
      } else if (settingType == 2) {
        final List<CustomTimeModel> customTimeModels =
            context.read<VariableRepository>().getCustomTimeModels();
        return customTimeModels.length > 1 &&
            previous.isBreak != current.isBreak &&
            (index + 1 != customTimeModels.length || !current.isBreak);
      }
      return false;
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
            onPressed: () async {
              final isolate = context.read<TimerBloc>().isolate;
              if (isolate != null) {
                isolate.pause();
              }
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const SettingScreen();
                  },
                ),
              );
              if (result == null && mounted) {
                if (isolate != null) {
                  isolate.resume();
                }
                setState(() {
                  context.read<TimerBloc>().add(TimerReset(getDuration()));
                });
              }
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
          listenWhen: (previous, current) => getListenWhen(previous, current),
          listener: (context, state) {
            if (state.isBreak) {
              final int settingType = getFromRepo('settingType');
              bool isBreakTime = true;
              // set break time
              if (settingType == 2) {
                final breakTime = context
                    .read<VariableRepository>()
                    .getCustomTimeModels()[index]
                    .breakTime;

                if (breakTime == 0) {
                  isBreakTime = false;
                  context.read<TimerBloc>().add(TimerStarted(
                        duration: 0,
                        isBreak: !state.isBreak,
                      ));
                } else {
                  context.read<TimerBloc>().add(TimerStarted(
                        duration: breakTime,
                        isBreak: state.isBreak,
                      ));
                }
              } else {
                if (getFromRepo('breakTime') == 0) {
                  isBreakTime = false;
                  context.read<TimerBloc>().add(TimerStarted(
                        duration: 0,
                        isBreak: !state.isBreak,
                      ));
                } else {
                  context.read<TimerBloc>().add(TimerStarted(
                        duration: getFromRepo('breakTime'),
                        isBreak: state.isBreak,
                      ));
                }
              }
              // current value update
              if (settingType == 0) {
                round++;
                if (round == getFromRepo('totalRound')) {
                  isBreakTime = false;
                }
              } else if (settingType == 1) {
                final int totalRound = getFromRepo('totalRound');
                final int breakTime = getFromRepo('breakTime') == 0
                    ? 0
                    : getFromRepo('breakTime') - 3; // second
                final int totalWorkingTime =
                    getFromRepo('totalWorkingTime') * 60;
                final int intervalTime =
                    (totalWorkingTime - (breakTime * totalRound)) ~/ totalRound;
                time = time + intervalTime;
                if (time == intervalTime * totalRound) {
                  isBreakTime = false;
                }
              } else if (settingType == 2) {
                index++;
                if (index ==
                    context
                        .read<VariableRepository>()
                        .getCustomTimeModels()
                        .length) {
                  isBreakTime = false;
                }
              }
              if (isBreakTime) {
                showAlertScreen('Break Time!');
              }
            } else if (!state.isBreak &&
                (index != 0 || time != 0 || round != 0)) {
              showAlertScreen('Working Time!');
              context.read<TimerBloc>().add(TimerStarted(
                    duration: getDuration(),
                    isBreak: state.isBreak,
                  ));
            }
          },
          builder: (context, state) {
            // reset when complete
            if (state.duration == 0 && state.isBreak) {
              final int settingType = getFromRepo('settingType');
              final int totalRound = getFromRepo('totalRound');
              final int breakTime = getFromRepo('breakTime') == 0
                  ? 0
                  : getFromRepo('breakTime') - 3; // second
              final int totalWorkingTime = getFromRepo('totalWorkingTime') * 60;
              final int intervalTime =
                  (totalWorkingTime - (breakTime * totalRound)) ~/ totalRound;
              final List<CustomTimeModel> customTimeModels =
                  context.read<VariableRepository>().getCustomTimeModels();
              bool showScreen = false;
              if (settingType == 0 && round + 1 == getFromRepo('totalRound')) {
                round = 0;
                showScreen = true;
              } else if (settingType == 1 &&
                  time + intervalTime == intervalTime * totalRound) {
                time = 0;
                showScreen = true;
              } else if (settingType == 2 &&
                  index + 1 == customTimeModels.length) {
                index = 0;
                showScreen = true;
              }
              if (showScreen) {
                context.read<TimerBloc>().vibration([500, 1000, 500, 1000]);
                context.read<TimerBloc>().add(TimerReset(getDuration()));
              }
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
                    height: MediaQuery.of(context).size.height / 20,
                  ),
                  // TimeScroll
                  state.isBreak
                      ? Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10,
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
                      : getFromRepo('settingType') == 0
                          ? SizedBox(
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
                                  child: BlocBuilder<TimerBloc, TimerState>(
                                      buildWhen: (previous, current) =>
                                          previous != current &&
                                          current is TimerInitial,
                                      builder: (context, state) {
                                        controllerInit();
                                        return ListWheelScrollView(
                                          itemExtent: itemExtent,
                                          squeeze: 0.7,
                                          diameterRatio: 10,
                                          controller: listWheelController,
                                          physics:
                                              const FixedExtentScrollPhysics(),
                                          children: [
                                            for (int i = 0;
                                                i < TimerBloc.times.length;
                                                i++)
                                              RotatedBox(
                                                quarterTurns: 1,
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width /
                                                      7,
                                                  decoration: BoxDecoration(
                                                    color: getFromRepo(
                                                                'selectedIndex') ==
                                                            i
                                                        ? Colors.black
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                      color: Colors.black,
                                                      width: 3,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${TimerBloc.times[i]}',
                                                    style: TextStyle(
                                                      color: getFromRepo(
                                                                  'selectedIndex') ==
                                                              i
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: 23,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              )
                                          ],
                                          onSelectedItemChanged:
                                              (int index) async {
                                            if (state is! TimerRunInProgress) {
                                              context
                                                  .read<VariableRepository>()
                                                  .setInt(
                                                      'selectedIndex', index);
                                              context.read<TimerBloc>().add(
                                                  TimerReset(getDuration()));
                                              setState(() {});
                                            }
                                          },
                                        );
                                      }),
                                ),
                              ),
                            )
                          : const SizedBox(),
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
                              onPressed:
                                  state.isBreak ? null : () => onResetPressed(),
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
                  if (state.isBreak)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Icon(
                        Icons.emoji_food_beverage_rounded,
                        size: MediaQuery.of(context).size.width / 5,
                        color: Colors.black,
                      ),
                    ),
                  // Progress Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            getCurrentValue(),
                            style: topTextStyle,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height / 100,
                          ),
                          Text(
                            settingTypeString[getFromRepo('settingType')],
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
