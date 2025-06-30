import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class ScoreCounter extends QuestionType {
  ScoreCounter({
    super.key,
    required this.label,
    required this.icon,
    void Function(double value)? onChanged,
    this.plus = Colors.green,
    this.minus = Colors.red,
    this.textColor = Colors.white,
    this.numberColor = Colors.white,
    this.iconColor = Colors.blue,
    this.stepValue = 1,
    this.longPressedValue = 2,
    this.max = 100,
    this.min = 0,
    double Function()? initValue,
    this.isChangable = false,
  }) : onChanged = onChanged ?? ((p0) {}),
       initValue = initValue ?? (() => 0.0);

  String label;
  final IconData icon;
  final Color plus;
  final Color minus;
  final Color textColor;
  final Color numberColor;
  final Color iconColor;
  final double stepValue;
  final double max;
  final double min;
  final double longPressedValue;
  double Function() initValue;
  void Function(double) onChanged;
  bool isChangable;

  @override
  State<StatefulWidget> createState() =>
      isChangable ? ScoreCounterChangableState() : ScoreCounterState();

  @override
  Widget settings(void Function(ScoreCounter p1) onChanged) =>
      ScoreCounterSettings(onChanged: onChanged, scoreCounter: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'icon': {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily},
    'plus': {'a': plus.a, 'r': plus.r, 'g': plus.g, 'b': plus.b},
    'minus': {'a': minus.a, 'r': minus.r, 'g': minus.g, 'b': minus.b},
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'numberColor': {
      'a': numberColor.a,
      'r': numberColor.r,
      'g': numberColor.g,
      'b': numberColor.b,
    },
    'iconColor': {
      'a': iconColor.a,
      'r': iconColor.r,
      'g': iconColor.g,
      'b': iconColor.b,
    },
    'stepValue': stepValue,
    'max': max,
    'min': min,
    'longPressedValue': longPressedValue,
    'initValue': initValue(),
  };

  factory ScoreCounter.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(double)? onChanged,
    bool isChangable = false,
    dynamic init
  }) {

    return ScoreCounter(
    key: key,
    label: json['label'] as String,
    icon: IconData(
      json['icon']['codePoint'] as int,
      fontFamily: json['icon']['fontFamily'] as String,
    ),
    plus: Color.from(
      alpha: json['plus']['a'] as double,
      red: json['plus']['r'] as double,
      green: json['plus']['g'] as double,
      blue: json['plus']['b'] as double,
    ),
    minus: Color.from(
      alpha: json['minus']['a'] as double,
      red: json['minus']['r'] as double,
      green: json['minus']['g'] as double,
      blue: json['minus']['b'] as double,
    ),
    textColor: Color.from(
      alpha: json['textColor']['a'] as double,
      red: json['textColor']['r'] as double,
      green: json['textColor']['g'] as double,
      blue: json['textColor']['b'] as double,
    ),
    numberColor: Color.from(
      alpha: json['numberColor']['a'] as double,
      red: json['numberColor']['r'] as double,
      green: json['numberColor']['g'] as double,
      blue: json['numberColor']['b'] as double,
    ),
    iconColor: Color.from(
      alpha: json['iconColor']['a'] as double,
      red: json['iconColor']['r'] as double,
      green: json['iconColor']['g'] as double,
      blue: json['iconColor']['b'] as double,
    ),
    stepValue: json['stepValue'] as double,
    max: json['max'] as double,
    min: json['min'] as double,
    longPressedValue: json['longPressedValue'] as double,
    initValue: init != null && init() != null && init is double Function()? ? init : (() => json['initValue'] as double),
    onChanged: onChanged,
    isChangable: isChangable,
  );
  }
}

class ScoreCounterChangableState extends State<ScoreCounter> {
  double count = 0;

  TextEditingController labelController = TextEditingController(text: '');
  TextEditingController initValueController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();

    count = widget.initValue();

    labelController.text = widget.label;
    initValueController.text = count.toString();
  }

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        children: <Widget>[
          const Spacer(),
          Expanded(child: Icon(widget.icon, color: widget.iconColor, size: 30)),
          Expanded(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 100),
                  child: TextField(
                    textAlign: TextAlign.center,
                    controller: labelController,
                    onChanged: (String text) => widget.label = text,
                    style: TextStyle(color: widget.textColor, fontSize: 20),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 6,
              child: RoundedIconButton(
                color: widget.minus,
                icon: Icons.remove,
                onPress: () {
                  setState(() {
                    count = max(widget.min, count - widget.stepValue);
                    widget.initValue = () => count;
                    initValueController.text = count.toString();
                  });
                  widget.onChanged(count);
                },
                onLongPress: () {
                  setState(() {
                    count = max(widget.min, count - widget.longPressedValue);
                    initValueController.text = count.toString();
                    widget.initValue = () => count;
                  });
                  widget.onChanged(count);
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                constraints: BoxConstraints(maxWidth: 100),
                child: TextField(
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
                  ],
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  controller: initValueController,
                  onChanged: (String text) {
                    count = (String text) {
                      try {
                        return double.parse(text);
                      } on Exception catch (_) {
                        return count;
                      }
                    }.call(text);
                    widget.initValue = () => count;
                  },
                  style: TextStyle(color: widget.numberColor, fontSize: 20),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: RoundedIconButton(
                color: widget.plus,
                icon: Icons.add,
                onPress: () {
                  setState(() {
                    count = min(widget.max, count + widget.stepValue);
                    initValueController.text = count.toString();
                    widget.initValue = () => count;
                  });
                  widget.onChanged(min(widget.max, count + widget.stepValue));
                },
                onLongPress: () {
                  setState(() {
                    count = min(widget.max, count + widget.longPressedValue);
                    initValueController.text = count.toString();
                    widget.initValue = () => count;
                  });
                  widget.onChanged(
                    min(widget.max, count + widget.longPressedValue),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton({
    super.key,
    required this.icon,
    required this.onPress,
    required this.onLongPress,
    final Color? color,
  }) : color = color ?? Colors.amber;

  final IconData icon;
  final void Function() onPress;
  final void Function() onLongPress;
  final Color color;

  @override
  Widget build(final BuildContext context) => RawMaterialButton(
    elevation: 6.0,
    onPressed: onPress,
    onLongPress: onLongPress,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    fillColor: color,
    child: Icon(icon, color: Colors.white, size: 40),
  );
}

class ScoreCounterState extends State<ScoreCounter> {
  double count = 0;

  @override
  void initState() {
    super.initState();

    count = widget.initValue();
  }

  @override
  Widget build(final BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Row(
        children: <Widget>[
          const Spacer(),
          Expanded(child: Icon(widget.icon, color: widget.iconColor, size: 30)),
          Expanded(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: widget.textColor),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 6,
              child: RoundedIconButton(
                color: widget.minus,
                icon: Icons.remove,
                onPress: () {
                  setState(() {
                    count = max(widget.min, count - widget.stepValue);
                  });
                  widget.onChanged(count);
                },
                onLongPress: () {
                  setState(() {
                    count = max(widget.min, count - widget.longPressedValue);
                  });
                  widget.onChanged(count);
                },
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                count.toString(),
                style: const TextStyle(fontSize: 40),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 6,
              child: RoundedIconButton(
                color: widget.plus,
                icon: Icons.add,
                onPress: () {
                  setState(() {
                    count = min(widget.max, count + widget.stepValue);
                  });
                  widget.onChanged(count);
                },
                onLongPress: () {
                  setState(() {
                    count = min(widget.max, count + widget.longPressedValue);
                  });
                  widget.onChanged(count);
                },
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class ScoreCounterSettings extends StatefulWidget {
  ScoreCounterSettings({
    super.key,
    required this.onChanged,
    required this.scoreCounter,
  });

  void Function(ScoreCounter) onChanged;
  ScoreCounter scoreCounter;

  @override
  State<StatefulWidget> createState() => ScoreCounterSettingsState();
}

class ScoreCounterSettingsState extends State<ScoreCounterSettings> {
  TextEditingController stepController = TextEditingController(text: '1');
  TextEditingController longStepController = TextEditingController(text: '2');
  TextEditingController maxController = TextEditingController(text: '100');
  TextEditingController minController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();

    stepController.text = widget.scoreCounter.stepValue.toString();
    longStepController.text = widget.scoreCounter.longPressedValue.toString();
    maxController.text = widget.scoreCounter.max.toString();
    minController.text = widget.scoreCounter.min.toString();
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: 15,
    children: [
      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Text and Number: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.scoreCounter.textColor,
            onChanged: (color) {
              widget.scoreCounter = ScoreCounter(
                label: widget.scoreCounter.label,
                icon: widget.scoreCounter.icon,
                onChanged: widget.scoreCounter.onChanged,
                plus: widget.scoreCounter.plus,
                minus: widget.scoreCounter.minus,
                textColor: color,
                numberColor: widget.scoreCounter.numberColor,
                iconColor: widget.scoreCounter.iconColor,
                stepValue: widget.scoreCounter.stepValue,
                longPressedValue: widget.scoreCounter.longPressedValue,
                initValue: widget.scoreCounter.initValue,
                isChangable: true,
              );
              widget.onChanged(widget.scoreCounter);
            },
          ),

          ColorInput(
            initValue: () => widget.scoreCounter.numberColor,
            onChanged: (color) {
              widget.scoreCounter = ScoreCounter(
                label: widget.scoreCounter.label,
                icon: widget.scoreCounter.icon,
                onChanged: widget.scoreCounter.onChanged,
                plus: widget.scoreCounter.plus,
                minus: widget.scoreCounter.minus,
                textColor: widget.scoreCounter.textColor,
                numberColor: color,
                iconColor: widget.scoreCounter.iconColor,
                stepValue: widget.scoreCounter.stepValue,
                longPressedValue: widget.scoreCounter.longPressedValue,
                initValue: widget.scoreCounter.initValue,
                isChangable: true,
              );
              widget.onChanged(widget.scoreCounter);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Icon: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.scoreCounter.iconColor,
            onChanged: (color) {
              widget.scoreCounter = ScoreCounter(
                label: widget.scoreCounter.label,
                icon: widget.scoreCounter.icon,
                onChanged: widget.scoreCounter.onChanged,
                plus: widget.scoreCounter.plus,
                minus: widget.scoreCounter.minus,
                textColor: widget.scoreCounter.textColor,
                numberColor: widget.scoreCounter.numberColor,
                iconColor: color,
                stepValue: widget.scoreCounter.stepValue,
                longPressedValue: widget.scoreCounter.longPressedValue,
                initValue: widget.scoreCounter.initValue,
                isChangable: true,
              );
              widget.onChanged(widget.scoreCounter);
            },
          ),

          Container(
            constraints: BoxConstraints(maxHeight: 300, maxWidth: 400),
            child: IconPicker(
              onChanged: (icon) {
                widget.scoreCounter = ScoreCounter(
                  label: widget.scoreCounter.label,
                  icon: icon,
                  onChanged: widget.scoreCounter.onChanged,
                  plus: widget.scoreCounter.plus,
                  minus: widget.scoreCounter.minus,
                  textColor: widget.scoreCounter.textColor,
                  numberColor: widget.scoreCounter.numberColor,
                  iconColor: widget.scoreCounter.iconColor,
                  stepValue: widget.scoreCounter.stepValue,
                  longPressedValue: widget.scoreCounter.longPressedValue,
                  initValue: widget.scoreCounter.initValue,
                  isChangable: true,
                );
                widget.onChanged(widget.scoreCounter);
              },
            ),
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Plus and Minus: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.scoreCounter.minus,
            onChanged: (color) {
              widget.scoreCounter = ScoreCounter(
                label: widget.scoreCounter.label,
                icon: widget.scoreCounter.icon,
                onChanged: widget.scoreCounter.onChanged,
                plus: widget.scoreCounter.plus,
                minus: color,
                textColor: widget.scoreCounter.textColor,
                numberColor: widget.scoreCounter.numberColor,
                iconColor: widget.scoreCounter.iconColor,
                stepValue: widget.scoreCounter.stepValue,
                longPressedValue: widget.scoreCounter.longPressedValue,
                initValue: widget.scoreCounter.initValue,
                isChangable: true,
              );
              widget.onChanged(widget.scoreCounter);
            },
          ),
          ColorInput(
            initValue: () => widget.scoreCounter.plus,
            onChanged: (color) {
              widget.scoreCounter = ScoreCounter(
                label: widget.scoreCounter.label,
                icon: widget.scoreCounter.icon,
                onChanged: widget.scoreCounter.onChanged,
                plus: color,
                minus: widget.scoreCounter.minus,
                textColor: widget.scoreCounter.textColor,
                numberColor: widget.scoreCounter.numberColor,
                iconColor: widget.scoreCounter.iconColor,
                stepValue: widget.scoreCounter.stepValue,
                longPressedValue: widget.scoreCounter.longPressedValue,
                initValue: widget.scoreCounter.initValue,
                isChangable: true,
              );
              widget.onChanged(widget.scoreCounter);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the step and long step",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: stepController,
              onChanged: (String text) {
                widget.scoreCounter = ScoreCounter(
                  label: widget.scoreCounter.label,
                  icon: widget.scoreCounter.icon,
                  onChanged: widget.scoreCounter.onChanged,
                  plus: widget.scoreCounter.plus,
                  minus: widget.scoreCounter.minus,
                  textColor: widget.scoreCounter.textColor,
                  numberColor: widget.scoreCounter.numberColor,
                  iconColor: widget.scoreCounter.iconColor,
                  stepValue: () {
                    try {
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.stepValue;
                    }
                  }.call(),
                  longPressedValue: widget.scoreCounter.longPressedValue,
                  max: widget.scoreCounter.max,
                  min: widget.scoreCounter.min,
                  initValue: widget.scoreCounter.initValue,
                  isChangable: true,
                );
                widget.onChanged(widget.scoreCounter);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: longStepController,
              onChanged: (String text) {
                widget.scoreCounter = ScoreCounter(
                  label: widget.scoreCounter.label,
                  icon: widget.scoreCounter.icon,
                  onChanged: widget.scoreCounter.onChanged,
                  plus: widget.scoreCounter.plus,
                  minus: widget.scoreCounter.minus,
                  textColor: widget.scoreCounter.textColor,
                  numberColor: widget.scoreCounter.numberColor,
                  iconColor: widget.scoreCounter.iconColor,
                  stepValue: widget.scoreCounter.stepValue,
                  longPressedValue: () {
                    try {
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.longPressedValue;
                    }
                  }.call(),
                  max: widget.scoreCounter.max,
                  min: widget.scoreCounter.min,
                  initValue: widget.scoreCounter.initValue,
                  isChangable: true,
                );
                widget.onChanged(widget.scoreCounter);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the lower and upper limits",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: minController,
              onChanged: (String text) {
                widget.scoreCounter = ScoreCounter(
                  label: widget.scoreCounter.label,
                  icon: widget.scoreCounter.icon,
                  onChanged: widget.scoreCounter.onChanged,
                  plus: widget.scoreCounter.plus,
                  minus: widget.scoreCounter.minus,
                  textColor: widget.scoreCounter.textColor,
                  numberColor: widget.scoreCounter.numberColor,
                  iconColor: widget.scoreCounter.iconColor,
                  stepValue: widget.scoreCounter.stepValue,
                  longPressedValue: widget.scoreCounter.longPressedValue,
                  min: () {
                    try {
                      if (double.parse(text) > widget.scoreCounter.max) {
                        throw Exception();
                      }
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.min;
                    }
                  }.call(),
                  max: () {
                    try {
                      if (double.parse(maxController.text) <
                          () {
                            try {
                              if (double.parse(text) >
                                  widget.scoreCounter.max) {
                                throw Exception();
                              }
                              return double.parse(text);
                            } on Exception catch (_) {
                              return widget.scoreCounter.min;
                            }
                          }.call()) {
                        throw Exception();
                      }
                      return double.parse(maxController.text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.max;
                    }
                  }.call(),
                  initValue: () => clampDouble(
                    widget.scoreCounter.initValue(),
                    () {
                      try {
                        if (double.parse(text) > widget.scoreCounter.max) {
                          throw Exception();
                        }
                        return double.parse(text);
                      } on Exception catch (_) {
                        return widget.scoreCounter.min;
                      }
                    }.call(),
                    () {
                      try {
                        if (double.parse(maxController.text) <
                            () {
                              try {
                                if (double.parse(text) >
                                    widget.scoreCounter.max) {
                                  throw Exception();
                                }
                                return double.parse(text);
                              } on Exception catch (_) {
                                return widget.scoreCounter.min;
                              }
                            }.call()) {
                          throw Exception();
                        }
                        return double.parse(maxController.text);
                      } on Exception catch (_) {
                        return widget.scoreCounter.max;
                      }
                    }.call(),
                  ),
                  isChangable: true,
                );
                widget.onChanged(widget.scoreCounter);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: maxController,
              onChanged: (String text) {
                widget.scoreCounter = ScoreCounter(
                  label: widget.scoreCounter.label,
                  icon: widget.scoreCounter.icon,
                  onChanged: widget.scoreCounter.onChanged,
                  plus: widget.scoreCounter.plus,
                  minus: widget.scoreCounter.minus,
                  textColor: widget.scoreCounter.textColor,
                  numberColor: widget.scoreCounter.numberColor,
                  iconColor: widget.scoreCounter.iconColor,
                  stepValue: widget.scoreCounter.stepValue,
                  longPressedValue: widget.scoreCounter.longPressedValue,
                  min: () {
                    try {
                      if (double.parse(minController.text) >
                          () {
                            try {
                              if (double.parse(text) <
                                  widget.scoreCounter.min) {
                                throw Exception();
                              }
                              return double.parse(text);
                            } on Exception catch (_) {
                              return widget.scoreCounter.max;
                            }
                          }.call()) {
                        throw Exception();
                      }
                      return double.parse(minController.text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.min;
                    }
                  }.call(),
                  max: () {
                    try {
                      if (double.parse(text) < widget.scoreCounter.min) {
                        throw Exception();
                      }
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.scoreCounter.max;
                    }
                  }.call(),
                  initValue: () => clampDouble(
                    widget.scoreCounter.initValue(),
                    () {
                      try {
                        if (double.parse(minController.text) >
                            () {
                              try {
                                if (double.parse(text) <
                                    widget.scoreCounter.min) {
                                  throw Exception();
                                }
                                return double.parse(text);
                              } on Exception catch (_) {
                                return widget.scoreCounter.max;
                              }
                            }.call()) {
                          throw Exception();
                        }
                        return double.parse(minController.text);
                      } on Exception catch (_) {
                        return widget.scoreCounter.min;
                      }
                    }.call(),
                    () {
                      try {
                        if (double.parse(text) < widget.scoreCounter.min) {
                          throw Exception();
                        }
                        return double.parse(text);
                      } on Exception catch (_) {
                        return widget.scoreCounter.max;
                      }
                    }.call(),
                  ),
                  isChangable: true,
                );
                widget.onChanged(widget.scoreCounter);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    ],
  );
}
