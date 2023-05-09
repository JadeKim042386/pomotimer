import 'package:equatable/equatable.dart';

abstract class TimerState extends Equatable {
  const TimerState(this.duration, this.isBreak);

  final int duration;
  final bool isBreak;

  @override
  List<Object> get props => [duration, isBreak];
}

class TimerInitial extends TimerState {
  const TimerInitial(super.duration, super.isBreak);

  @override
  String toString() => 'TimerInitial { duration: $duration }';
}

class TimerRunPause extends TimerState {
  const TimerRunPause(super.duration, super.isBreak);

  @override
  String toString() => 'TimerRunPause { duration: $duration }';
}

class TimerRunInProgress extends TimerState {
  const TimerRunInProgress(super.duration, super.isBreak);

  @override
  String toString() => 'TimerRunInProgress { duration: $duration }';
}

class TimerRunComplete extends TimerState {
  const TimerRunComplete() : super(0, false);
}
