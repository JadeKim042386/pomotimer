import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/repositories/variable_repository.dart';
import 'package:toggle_switch/toggle_switch.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    ValueNotifier<int> toggleIndex =
        ValueNotifier(context.read<VariableRepository>().getInt('settingType'));
    TextStyle toggleTextStyle = const TextStyle(
      fontWeight: FontWeight.w500,
    );
    TextStyle sliderTextStyle = const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButton: toggleIndex.value == 2
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    ValueNotifier<int> breakTime = ValueNotifier(0);
                    ValueNotifier<int> workingTime = ValueNotifier(0);
                    return AlertDialog(
                      contentPadding: const EdgeInsets.only(top: 30.0),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Break Time',
                            style: sliderTextStyle,
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              tickMarkShape: SliderTickMarkShape.noTickMark,
                            ),
                            child: ValueListenableBuilder(
                                valueListenable: breakTime,
                                builder: (context, value, child) {
                                  return Slider(
                                    max: 30.0,
                                    divisions: 30,
                                    activeColor: Colors.black,
                                    inactiveColor: Colors.grey,
                                    thumbColor: Colors.black,
                                    value: ((breakTime.value - 3) ~/ 60)
                                        .toDouble(),
                                    label: ((breakTime.value - 3) ~/ 60)
                                        .toString(),
                                    onChanged: (double value) {
                                      setState(() {
                                        breakTime.value =
                                            value.toInt() * 60 + 3;
                                      });
                                    },
                                  );
                                }),
                          ),
                          Text(
                            'Working Time',
                            style: sliderTextStyle,
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              tickMarkShape: SliderTickMarkShape.noTickMark,
                            ),
                            child: ValueListenableBuilder(
                                valueListenable: workingTime,
                                builder: (context, value, child) {
                                  return Slider(
                                    max: 60.0 * 10,
                                    divisions: 60 * 2,
                                    activeColor: Colors.black,
                                    inactiveColor: Colors.grey,
                                    thumbColor: Colors.black,
                                    value: workingTime.value.toDouble(),
                                    label: timeToString(workingTime.value),
                                    onChanged: (double value) {
                                      setState(() {
                                        workingTime.value = value.toInt();
                                      });
                                    },
                                  );
                                }),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            if (breakTime.value > 0 || workingTime.value > 0) {
                              await context
                                  .read<VariableRepository>()
                                  .setCustomTimeModels(CustomTimeModel(
                                      breakTime: breakTime.value,
                                      workingTime: workingTime.value));
                            }
                            if (mounted) Navigator.of(context).pop();
                            setState(() {});
                          },
                          child: const Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        )
                      ],
                    );
                  },
                );
              },
              backgroundColor: Colors.black,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            )
          : null,
      body: ValueListenableBuilder<int>(
          valueListenable: toggleIndex,
          builder: (context, value, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ToggleSwitch(
                        minWidth: 100,
                        animate: true,
                        animationDuration: 300,
                        borderColor: const [
                          Colors.black,
                          Colors.black,
                        ],
                        borderWidth: 2,
                        activeBgColor: const [
                          Colors.black,
                          Colors.black,
                        ],
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.white,
                        inactiveFgColor: Colors.black,
                        labels: const ['ROUND', 'TIME', 'CUSTOM'],
                        customTextStyles: [
                          toggleTextStyle,
                          toggleTextStyle,
                          toggleTextStyle
                        ],
                        initialLabelIndex: toggleIndex.value,
                        totalSwitches: 3,
                        onToggle: (index) {
                          context
                              .read<VariableRepository>()
                              .setInt('settingType', index ?? 0);
                          toggleIndex.value = index ?? 0;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  // BreakTime, Round
                  Visibility(
                    visible: toggleIndex.value == 0 || toggleIndex.value == 1,
                    child: SizedBox(
                      child: Column(
                        children: [
                          // Break Time (display: minute, save: second)
                          Text(
                            'Break Time',
                            style: sliderTextStyle,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          valueBoxContainer(((context
                                          .read<VariableRepository>()
                                          .getInt('breakTime') -
                                      3) ~/
                                  60)
                              .toString()),
                          settingSlider(30.0, 'breakTime'),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          // Total Round
                          Text(
                            'Total Round',
                            style: sliderTextStyle,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          valueBoxContainer(context
                              .read<VariableRepository>()
                              .getInt('totalRound')
                              .toString()),
                          settingSlider(30.0, 'totalRound'),
                        ],
                      ),
                    ),
                  ),
                  // Working Total Time
                  Visibility(
                    visible: toggleIndex.value == 1,
                    child: SizedBox(
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.05,
                          ),
                          Text(
                            'Total Working Time',
                            style: sliderTextStyle,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          valueBoxContainer(context
                              .read<VariableRepository>()
                              .getInt('totalWorkingTime')
                              .toString()),
                          settingSlider(60.0 * 10, 'totalWorkingTime'),
                        ],
                      ),
                    ),
                  ),
                  // Custom Data
                  Visibility(
                    visible: toggleIndex.value == 2,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ListView(
                        children: context
                            .read<VariableRepository>()
                            .getCustomTimeModels()
                            .map((CustomTimeModel customTimeModel) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: UniqueKey(),
                              onDismissed: (_) => context
                                  .read<VariableRepository>()
                                  .deleteCustomTimeModel(customTimeModel.id),
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Working Time',
                                          style: sliderTextStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'Break Time',
                                          style: sliderTextStyle,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      width: 50,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          timeToString(
                                              customTimeModel.workingTime),
                                          style: sliderTextStyle,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          timeToString(
                                              (customTimeModel.breakTime - 3) ~/
                                                  60),
                                          style: sliderTextStyle,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }

  Container valueBoxContainer(String text) {
    return Container(
      height: 30,
      width: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.black,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  SliderTheme settingSlider(double max, String key) {
    double getMinValue(String key) {
      if (key == 'totalWorkingTime') {
        final int breakTime =
            (context.read<VariableRepository>().getInt('breakTime') - 3) ~/ 60;
        final int totalRound =
            context.read<VariableRepository>().getInt('totalRound');
        return (breakTime * totalRound).toDouble();
      }
      return 0.0;
    }

    double getValue(key) {
      switch (key) {
        case 'breakTime':
          {
            return ((context.read<VariableRepository>().getInt(key) - 3) ~/ 60)
                .toDouble();
          }
        case 'totalWorkingTime':
          {
            final double totalWorkingTime =
                context.read<VariableRepository>().getInt(key).toDouble();
            final double minValue = getMinValue(key);
            return totalWorkingTime < minValue ? minValue : totalWorkingTime;
          }
        case 'totalRound':
          {
            return context.read<VariableRepository>().getInt(key).toDouble();
          }
        default:
          {
            return 0.0;
          }
      }
    }

    String getLabel(key) {
      switch (key) {
        case 'breakTime':
          {
            return timeToString(
                (context.read<VariableRepository>().getInt(key) - 3) ~/ 60);
          }
        case 'totalWorkingTime':
          {
            final int totalWorkingTime =
                context.read<VariableRepository>().getInt(key);
            final int minValue = getMinValue(key).toInt();
            return timeToString(
                totalWorkingTime < minValue ? minValue : totalWorkingTime);
          }
        case 'totalRound':
          {
            return context.read<VariableRepository>().getInt(key).toString();
          }
        default:
          {
            return '0';
          }
      }
    }

    void getChanged(key, value) {
      switch (key) {
        case 'breakTime':
          {
            context
                .read<VariableRepository>()
                .setInt(key, value.toInt() == 0 ? 0 : value.toInt() * 60 + 3);
          }
          break;
        case 'totalRound':
          {
            context.read<VariableRepository>().setInt(key, value.toInt());
          }
          break;
        case 'totalWorkingTime':
          {
            context.read<VariableRepository>().setInt(key, value.toInt());
          }
      }
    }

    return SliderTheme(
      data: SliderThemeData(
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      child: Slider(
        min: getMinValue(key),
        max: max,
        divisions: key == 'totalWorkingTime'
            ? (max.toInt() - getMinValue(key)) ~/ 5
            : max.toInt(),
        activeColor: Colors.black,
        inactiveColor: Colors.grey,
        thumbColor: Colors.black,
        value: getValue(key),
        label: getLabel(key),
        onChanged: (double value) {
          setState(() {
            getChanged(key, value);
          });
        },
      ),
    );
  }
}

String timeToString(int value) {
  if (value >= 60) {
    if (value % 60 > 0) {
      return '${value ~/ 60}h ${value % 60}m';
    } else {
      return '${value ~/ 60}h';
    }
  } else {
    return value == 0 ? '0' : '${value % 60}m';
  }
}
