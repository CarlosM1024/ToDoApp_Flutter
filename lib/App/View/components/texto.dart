import 'package:flutter/material.dart';

class Texto extends StatelessWidget {
  const Texto({super.key, required this.mitexto, this.micolor});

  final String mitexto;
  final Color? micolor;

  @override
  Widget build(BuildContext context) {
      return Text(
      mitexto,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 35,
          fontWeight: FontWeight.w600,
          color: micolor
        )
    );
  }
}

class textTask extends StatelessWidget {
  const textTask({super.key, required this.mitexto, this.micolor});

  final String mitexto;
  final Color? micolor;

  @override
  Widget build(BuildContext context) {
    return Text(
        mitexto,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: micolor
        )
    );
  }
}
