import 'package:flutter/material.dart';

class Quotes extends StatefulWidget {
  const Quotes({super.key});

  @override
  State<Quotes> createState() =>_QuotesState();
}

class _QuotesState extends State<Quotes> {

  @override
  Widget build(BuildContext context) {
    return
      Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
            const Text("Speed:"),
      ],
    );
  }
}