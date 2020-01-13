// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_animations/simple_animations.dart';

/// A basic digital clock.
///
/// You can do better than this!
class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with SingleTickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;
  String _topRightString = '';
  String _topLeftString = '';
  bool _is24HourFormat = true;
  WeatherFactor _weatherFactor = WeatherFactor.build(WeatherCondition.sunny);

  @override
  void initState() {
    super.initState();

    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _topRightString = widget.model.location;
      _topLeftString =
          widget.model.temperatureString + ' | ' + widget.model.weatherString;
      _is24HourFormat = widget.model.is24HourFormat;
      _weatherFactor = WeatherFactor.build(widget.model.weatherCondition);
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String currentTime =
        DateFormat(_is24HourFormat ? 'HH:mm:ss a' : 'hh:mm:ss a')
            .format(_dateTime);
    String currentDate = DateFormat('yyyy-MM-dd').format(_dateTime);

    return Container(
      child: Center(
        child: DefaultTextStyle(
            style: TextStyle(fontFamily: 'CuteFont', color: Colors.white),
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: AnimatedBackground()),
                onBottom(AnimatedWave(
                  height: 250,
                  speed: 0.3 * _weatherFactor.waveSpeed,
                )),
                onBottom(AnimatedWave(
                  height: 120,
                  speed: 0.2 * _weatherFactor.waveSpeed,
                  offset: pi,
                )),
                onBottom(AnimatedWave(
                  height: 400,
                  speed: 0.1 * _weatherFactor.waveSpeed,
                  offset: pi / 2,
                )),
                onCenterText(currentTime),
                onCornerText(_topLeftString, Alignment.topLeft),
                onCornerText(currentDate, Alignment.topRight),
                onCornerText(_topRightString, Alignment.bottomLeft),
                Positioned.fill(
                    top: 5,
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: Icon(_weatherFactor.iconData,
                            color: Colors.white, size: 24))),
              ],
            )),
      ),
    );
  }

  onCenterText(String time) => Positioned.fill(
        left: 2,
        right: 2,
        top: 2,
        bottom: 2,
        child: Align(
            alignment: Alignment.center, child: Text(time, textScaleFactor: 9)),
      );

  onCornerText(String text, Alignment alignment) => Positioned.fill(
        child: Align(
          alignment: alignment,
          child: Text(text, textScaleFactor: 2),
        ),
      );

  onBottom(Widget child) => Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
}

class WeatherFactor {
  final double waveSpeed;
  final IconData iconData;

  WeatherFactor(this.waveSpeed, this.iconData);

  static WeatherFactor build(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.cloudy:
        return WeatherFactor(3, MdiIcons.weatherCloudy);
        break;
      case WeatherCondition.foggy:
        return WeatherFactor(2, MdiIcons.weatherFog);
        break;
      case WeatherCondition.rainy:
        return WeatherFactor(20, MdiIcons.weatherRainy);
        break;
      case WeatherCondition.snowy:
        return WeatherFactor(5, MdiIcons.weatherSnowy);
        break;

      case WeatherCondition.thunderstorm:
        return WeatherFactor(10, MdiIcons.weatherLightning);
        break;
      case WeatherCondition.windy:
        return WeatherFactor(8, MdiIcons.weatherWindy);
        break;
      default:
        return WeatherFactor(1, MdiIcons.weatherSunny);
        break;
    }
  }
}

class AnimatedWave extends StatelessWidget {
  final double height;
  final double speed;
  final double offset;

  AnimatedWave({this.height, this.speed, this.offset = 0.0});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: height,
        width: constraints.biggest.width,
        child: ControlledAnimation(
            playback: Playback.LOOP,
            duration: Duration(milliseconds: (5000 / speed).round()),
            tween: Tween(begin: 0.0, end: 2 * pi),
            builder: (context, value) {
              return CustomPaint(
                foregroundPainter: CurvePainter(value + offset),
              );
            }),
      );
    });
  }
}

class CurvePainter extends CustomPainter {
  final double value;

  CurvePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final white = Paint()..color = Colors.white.withAlpha(60);
    final path = Path();

    final y1 = sin(value);
    final y2 = sin(value + pi / 2);
    final y3 = sin(value + pi);

    final startPointY = size.height * (0.5 + 0.4 * y1);
    final controlPointY = size.height * (0.5 + 0.4 * y2);
    final endPointY = size.height * (0.5 + 0.4 * y3);

    path.moveTo(size.width * 0, startPointY);
    path.quadraticBezierTo(
        size.width * 0.5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, white);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class AnimatedBackground extends StatelessWidget {
  static const String FIRST_COLOR_NAME = "color1";
  static const String SECOND_COLOR_NAME = "color2";

  AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    final tween = buildMultiTrackTween();

    return ControlledAnimation(
      playback: Playback.MIRROR,
      tween: tween,
      duration: tween.duration,
      builder: (context, animation) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                animation[FIRST_COLOR_NAME],
                animation[SECOND_COLOR_NAME]
              ])),
        );
      },
    );
  }

  MultiTrackTween buildMultiTrackTween() {
    return MultiTrackTween([
      Track(AnimatedBackground.FIRST_COLOR_NAME).add(Duration(seconds: 10),
          ColorTween(begin: Colors.red, end: Colors.green.shade600)),
      Track(AnimatedBackground.SECOND_COLOR_NAME).add(Duration(seconds: 20),
          ColorTween(begin: Colors.blue, end: Colors.blue.shade600))
    ]);
  }
}
