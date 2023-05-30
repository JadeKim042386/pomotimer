import 'dart:async';
import 'dart:isolate';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:pomotimer/blocs/ticker.dart';
import 'package:pomotimer/blocs/time_event.dart';
import 'package:pomotimer/blocs/time_state.dart';
import 'package:pomotimer/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc({
    required Ticker ticker,
    required this.prefs,
    required this.initDuration,
  })  : _ticker = ticker,
        super(TimerInitial(initDuration, false)) {
    on<TimerStarted>(_onStarted);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<TimerTicked>(_onTicked);
  }

  static const List<int> times = [1, 15, 20, 25, 30, 35];
  final Ticker _ticker;
  final SharedPreferences prefs;
  final int initDuration;
  final service = FlutterBackgroundService();

  bool init = true;
  SendPort? isolatePort;
  FlutterIsolate? isolate;
  StreamSubscription<int>? _tickerSubscription;

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  // tick, startService (state: TimerRunInProgress)
  void _onStarted(TimerStarted event, Emitter<TimerState> emit) async {
    emit(TimerRunInProgress(
      event.duration,
      event.isBreak,
    ));

    _tickerSubscription?.cancel();

    if (init == true) {
      List<dynamic> portAndIsolate =
          await startService([event.duration, event.isBreak]);
      isolatePort = await portAndIsolate[0];
      isolate = portAndIsolate[1];
      init = false;
    } else if (isolatePort != null) {
      isolatePort!.send([event.duration, event.isBreak]);
    }
    _tickerSubscription = _ticker.tick(ticks: event.duration).listen(
        (duration) =>
            add(TimerTicked(duration: duration, isBreak: event.isBreak)));
  }

  // "tick tock" or "Complete"
  void _onTicked(TimerTicked event, Emitter<TimerState> emit) async {
    if (event.duration > 0) {
      emit(TimerRunInProgress(
        event.duration,
        event.isBreak,
      ));
    } else {
      vibration([500, 1000, 500, 2000]);
      emit(TimerRunInProgress(
        event.duration,
        !event.isBreak,
      ));
    }
  }

  // serviceDispose (state: TimerRunPause)
  void _onPaused(TimerPaused event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      _tickerSubscription?.pause();
      if (isolate != null) {
        isolate!.pause();
      }
      emit(TimerRunPause(
        state.duration,
        state.isBreak,
      ));
    }
  }

  // tick, startService (state: TimerRunInProgress)
  void _onResumed(TimerResumed resume, Emitter<TimerState> emit) async {
    _tickerSubscription?.resume();
    emit(TimerRunInProgress(
      state.duration,
      state.isBreak,
    ));
    if (isolate != null) {
      isolate!.resume();
    }
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) async {
    _tickerSubscription?.cancel();
    if (isolatePort != null) {
      isolatePort!.send('stopService');
      init = true;
    }
    emit(TimerInitial(event.duration, false));
  }

  void vibration(List<int> pattern) async {
    bool? hadVibrator = await Vibration.hasVibrator();
    if (hadVibrator!) {
      Vibration.vibrate(pattern: pattern, duration: 1000);
    }
  }
}
