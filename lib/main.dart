import 'package:boiler_plate/presentation/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

void main() {
  runApp(ProviderScope(child: Sizer(
    builder:
        (BuildContext context, Orientation orientation, DeviceType deviceType) {
      return MaterialApp(
          title: 'Boiler Plate',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: SplashScreen());
    },
  )));
}
