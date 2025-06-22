import 'package:flutter/material.dart';

class UnitDetailsPage extends StatelessWidget {
  final String unitId;

  const UnitDetailsPage({Key? key, required this.unitId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Unit Details')),
      body: Center(child: Text('Details for unit: $unitId')),
    );
  }
}
