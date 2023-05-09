abstract class TimerEvent {
  const TimerEvent();
}

class TimerStarted extends TimerEvent {
  const TimerStarted({
    required this.duration,
    required this.isBreak,
  });
  final int duration;
  final bool isBreak;
}

class TimerPaused extends TimerEvent {
  const TimerPaused();
}

class TimerResumed extends TimerEvent {
  const TimerResumed();
}

class TimerReset extends TimerEvent {
  const TimerReset(this.duration);
  final int duration;
}

class TimerTicked extends TimerEvent {
  const TimerTicked({
    required this.duration,
    required this.isBreak,
  });
  final int duration;
  final bool isBreak;
}
