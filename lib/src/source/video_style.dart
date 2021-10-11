import 'package:flutter/material.dart';

import 'quality_style.dart';

/// Video Player Icon style
class VideoStyle {
  VideoStyle({
    this.play = const Icon(Icons.play_arrow, color: Colors.white),
    this.pause = const Icon(Icons.pause, color: Colors.white),
    this.fullscreen = const Icon(Icons.fullscreen, color: Colors.white),
    this.fullscreenExit = const Icon(Icons.fullscreen_exit, color: Colors.white),
    this.forward = const Icon(Icons.fast_forward_rounded,color: Colors.white),
    this.backward = const Icon(Icons.fast_rewind_rounded,color: Colors.white),
    this.next = const Icon(Icons.skip_next_rounded, color: Colors.white),
    this.previous = const Icon(Icons.skip_previous_rounded, color: Colors.white),
    this.playedColor = Colors.green,
    this.thumbColor = Colors.white,
    this.sliderColor = Colors.transparent,
    this.qualitystyle = const QualityStyle(),
    this.spaceBetweenControls = 50
  });

  final Widget play;
  final Widget pause;
  final Widget fullscreen;
  final Widget fullscreenExit;
  final Widget forward;
  final Widget backward;
  final Widget next;
  final Widget previous;
  final double spaceBetweenControls;
  final Color playedColor;
  final Color sliderColor;
  final Color thumbColor;
  final QualityStyle  qualitystyle;
}
