import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pomotimer/blocs/ticker.dart';
import 'package:pomotimer/blocs/time_event.dart';
import 'package:pomotimer/blocs/time_state.dart';
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

  StreamSubscription<int>? _tickerSubscription;

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  // tick, startService (state: TimerRunInProgress)
  void _onStarted(TimerStarted event, Emitter<TimerState> emit) {
    emit(TimerRunInProgress(
      event.duration,
      event.isBreak,
    ));
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker.tick(ticks: event.duration).listen(
        (duration) =>
            add(TimerTicked(duration: duration, isBreak: event.isBreak)));
    startService();
  }

  // "tick tock" or "Complete"
  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    if (event.duration > 0) {
      emit(TimerRunInProgress(
        event.duration,
        event.isBreak,
      ));
      service.invoke('sendTime',
          {'currentTime': event.duration, 'isBreak': event.isBreak});
    } else {
      if (event.duration > 0) {
        vibration([500, 1000, 500, 2000]);
      }
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
      serviceDispose();
      emit(TimerRunPause(
        state.duration,
        state.isBreak,
      ));
    }
  }

  // tick, startService (state: TimerRunInProgress)
  void _onResumed(TimerResumed resume, Emitter<TimerState> emit) {
    _tickerSubscription?.resume();
    emit(TimerRunInProgress(
      state.duration,
      state.isBreak,
    ));
    startService();
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _tickerSubscription?.cancel();
    serviceDispose();
    emit(TimerInitial(event.duration, false));
  }

  Future<void> serviceDispose() async {
    var isServiceRunning = await service.isRunning();
    if (isServiceRunning) {
      service.invoke("stopService");
    }
  }

  Future<void> startService() async {
    var isServiceRunning = await service.isRunning();
    if (!isServiceRunning) {
      service.startService();
    }
  }

  void vibration(List<int> pattern) async {
    bool? hadVibrator = await Vibration.hasVibrator();
    if (hadVibrator!) {
      Vibration.vibrate(pattern: pattern, duration: 1000);
    }
  }
}
