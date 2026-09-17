import 'dart:async';

import 'package:flutter/material.dart';

import '../ritual/daily_drop.dart';
import '../theme.dart';

/// Live "expires in 4h 12m" countdown for today's Drop. Ticks every second
/// and stops itself on dispose.
class DropCountdown extends StatefulWidget {
  final TextStyle? style;
  const DropCountdown({super.key, this.style});

  @override
  State<DropCountdown> createState() => _DropCountdownState();
}

class _DropCountdownState extends State<DropCountdown> {
  Timer? _timer;
  Duration _left = Duration.zero;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _left = dropTimeLeft(DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 13, color: context.colors.amberLight),
        const SizedBox(width: 4),
        Text(
          'expires in ${dropCountdownLabel(_left)}',
          style: widget.style ??
              TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colors.amberLight,
              ),
        ),
      ],
    );
  }
}
