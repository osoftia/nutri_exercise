import 'package:flutter/material.dart';

enum AppHeadingSize { h1, h2, h3 }

class AppHeading extends StatelessWidget {
  const AppHeading(this.text, {super.key, this.size = AppHeadingSize.h2});

  final String text;
  final AppHeadingSize size;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = switch (size) {
      AppHeadingSize.h1 => textTheme.displayLarge,
      AppHeadingSize.h2 => textTheme.displayMedium,
      AppHeadingSize.h3 => textTheme.titleLarge,
    };
    return Text(text, style: style);
  }
}

class AppText extends StatelessWidget {
  const AppText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style ?? Theme.of(context).textTheme.bodyLarge);
  }
}

class AppCaption extends StatelessWidget {
  const AppCaption(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}
