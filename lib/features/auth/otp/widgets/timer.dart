import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';
import 'package:orange_taxi_customer_app/core/custom_widgets/custom_text/custom_text.dart';

class AnimatedCountdownTimer extends StatefulWidget {
  const AnimatedCountdownTimer({super.key, required this.duration, required this.color, this.totalDuration});

  final Duration duration;
  final Duration? totalDuration;

  final Color color;

  @override
  State<AnimatedCountdownTimer> createState() => _AnimatedCountdownTimerState();
}

class _AnimatedCountdownTimerState extends State<AnimatedCountdownTimer> {
  late Timer timer;

  late Duration remaining;

  @override
  void initState() {
    super.initState();

    remaining = widget.duration;

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remaining.inSeconds > 0) {
        setState(() {
          remaining -= const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();

    super.dispose();
  }

  String twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final int totalSecs = widget.totalDuration?.inSeconds ?? widget.duration.inSeconds;
    final double progress = totalSecs > 0 ? remaining.inSeconds / totalSecs : 0;

    return Center(
      child: SizedBox(
        height: 100,
        width: 100,

        child: Stack(
          alignment: Alignment.center,

          children: [
            SizedBox(
              height: 100,
              width: 100,

              child: CircularProgressIndicator(value: 1, strokeWidth: 10, color: AppColors.grey300),
            ),

            SizedBox(
              height: 100,
              width: 100,

              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                color: widget.color,
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    if (remaining.inHours > 0) ...[
                      AnimatedFlipCounter(
                        value: remaining.inHours,

                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const CustomText(text: " h ", fontSize: 12),
                    ],

                    if (remaining.inHours > 0 || remaining.inMinutes > 0) ...[
                      AnimatedFlipCounter(
                        value: remaining.inMinutes.remainder(60),

                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const CustomText(text: " m ", fontSize: 12),
                    ],

                    if (remaining.inHours == 0) ...[
                      AnimatedFlipCounter(
                        value: remaining.inSeconds.remainder(60),

                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),

                      const CustomText(text: " s ", fontSize: 12),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
