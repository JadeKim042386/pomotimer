import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pomotimer/apis/models/custom_time_model.dart';
import 'package:pomotimer/blocs/ticker.dart';
import 'package:pomotimer/blocs/time_bloc.dart';
import 'package:pomotimer/repositories/variable_repository.dart';
import 'package:pomotimer/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      int? settingType;
      while (true) {
        settingType = prefs.getInt('settingType');
        if (settingType != null) {
          break;
        }
      }
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
