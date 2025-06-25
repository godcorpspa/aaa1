import 'package:flutter/material.dart';

/// Logo widget che mostra l’immagine `assets/logo.png` centrata con
/// dimensione configurabile. Se vuoi aggiungere testo sotto il logo,
/// passa `showText: true`.
class LmsLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const LmsLogo({this.size = 120, this.showText = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ▼ Assicurati che l’asset sia elencato in pubspec.yaml sotto "assets:".
        Image.asset(
          'assets/logo.png',
          width: size,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            'LAST MAN STANDING',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Colors.white, height: 1, letterSpacing: 1),
          ),
        ]
      ],
    );
  }
}
