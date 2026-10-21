import 'package:flutter/material.dart';
import 'package:orange_taxi_customer_app/config/themes/app_colors.dart';

class CustomText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? letterSpacing;
  final TextDecoration? textDecoration;
  final double? height;

  const CustomText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color = AppColors.black,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
    this.letterSpacing,
    this.textDecoration,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double responsiveSize = fontSize - 2 * (screenWidth / 375).clamp(0.95, 1.15);

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,

      style: TextStyle(
        fontSize: responsiveSize,
        fontWeight: fontWeight,
        color: color,
        fontFamily: 'Poppins',
        decoration: textDecoration,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }
}
