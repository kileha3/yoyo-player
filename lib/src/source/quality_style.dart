import 'package:flutter/material.dart';

/// Video Player Icon style
class QualityStyle {
  const QualityStyle({
    this.qualitystyle = const TextStyle(
      color: Colors.white,
    ),
    this.dropDownText = const TextStyle(
      color: Colors.black,
    ),
    this.qualityColor = Colors.black38,
    this.dropDownColor = Colors.white
  });
  final Color qualityColor;
  final TextStyle qualitystyle;
  final Color dropDownColor;
  final TextStyle dropDownText;
}
