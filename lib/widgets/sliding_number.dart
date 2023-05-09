import 'package:flutter/cupertino.dart';

class SlidingNumber extends StatelessWidget {
  const SlidingNumber({
    super.key,
    required this.number,
    this.style = const TextStyle(),
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.linear,
  });

  final String number;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < number.length; i++)
          _SlidingDigit(
            digit: int.parse(number[i]),
            style: style,
            duration: duration,
            curve: curve,
          ),
      ],
    );
  }
}

class _SlidingDigit extends StatefulWidget {
  const _SlidingDigit({
    required this.digit,
    required this.style,
    required this.duration,
    required this.curve,
  }) : assert(digit >= 0 && digit <= 9);

  final int digit;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  @override
  _SlidingDigitState createState() => _SlidingDigitState();
}

class _SlidingDigitState extends State<_SlidingDigit> {
  final _scrollController = ScrollController();
  double _digitHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _slide(initialization: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SlidingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    _slide();
  }

  void _slide({bool initialization = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final divider = initialization ? 10 : 9;
      if (!mounted) {
        return;
      }
      setState(() {
        _digitHeight = _scrollController.position.maxScrollExtent / divider;
      });
      _scrollController.animateTo(
        _digitHeight * widget.digit,
        duration: widget.duration,
        curve: widget.curve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: _digitHeight),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (digit) {
              return Text('$digit', style: widget.style);
            }),
          ),
        ),
      ),
    );
  }
}
