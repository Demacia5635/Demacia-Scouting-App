import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:scouting_qr_maker/widgets/color_input.dart";
import "package:scouting_qr_maker/widgets/question_type.dart";

class LevelSlider extends QuestionType {
  LevelSlider({
    super.key,
    required this.label,
    this.textColor = Colors.white,
    this.sliderColor = Colors.purple,
    this.thumbColor = Colors.purpleAccent,
    this.min = 1,
    this.max = 6,
    this.divisions,
    double Function()? initValue,
    void Function(double value)? onChanged,
    this.isChangable = false,
  }) : onChanged = onChanged ?? ((p0) {}),
       initValue = initValue ?? (() => 1)
  {
    if (divisions == 0) divisions = null;
  }

  String label;
  Color textColor;
  Color sliderColor;
  Color thumbColor;
  final double min;
  final double max;
  int? divisions;
  double Function() initValue;
  void Function(double) onChanged;
  final bool isChangable;

  @override
  State<StatefulWidget> createState() =>
      isChangable ? LevelSliderChangableState() : LevelSliderState();

  @override
  Widget settings(void Function(LevelSlider p1) onChanged) =>
      LevelSliderSettings(onChanged: onChanged, levelSlider: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'sliderColor': {
      'a': sliderColor.a,
      'r': sliderColor.r,
      'g': sliderColor.g,
      'b': sliderColor.b,
    },
    'thumbColor': {
      'a': thumbColor.a,
      'r': thumbColor.r,
      'g': thumbColor.g,
      'b': thumbColor.b,
    },
    'min': min,
    'max': max,
    'divisions': divisions ?? 0,
    'initValue': initValue(),
  };

  factory LevelSlider.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(double)? onChanged,
    bool isChangable = false,
    dynamic init,
  }) => LevelSlider(
    key: key,
    label: json['label'] as String,
    textColor: Color.from(
      alpha: json['textColor']['a'] as double,
      red: json['textColor']['r'] as double,
      green: json['textColor']['g'] as double,
      blue: json['textColor']['b'] as double,
    ),
    sliderColor: Color.from(
      alpha: json['sliderColor']['a'] as double,
      red: json['sliderColor']['r'] as double,
      green: json['sliderColor']['g'] as double,
      blue: json['sliderColor']['b'] as double,
    ),
    thumbColor: Color.from(
      alpha: json['thumbColor']['a'] as double,
      red: json['thumbColor']['r'] as double,
      green: json['thumbColor']['g'] as double,
      blue: json['thumbColor']['b'] as double,
    ),
    min: json['min'] as double,
    max: json['max'] as double,
    divisions: json['divisions'] as int,
    initValue: init != null && init() != null && init is double Function()? ? init : (() => json['initValue'] as double),
    onChanged: onChanged,
    isChangable: isChangable,
  );
}

class LevelSliderChangableState extends State<LevelSlider> {
  double value = 0;

  TextEditingController labelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    value = widget.initValue();

    labelController.text = widget.label;
  }

  @override
  Widget build(final BuildContext context) => FittedBox(
    fit: BoxFit.fitWidth,
    child: Column(
      spacing: 4,
      children: <Widget>[
        Container(
          constraints: BoxConstraints(maxWidth: 100),
          child: TextField(
            textAlign: TextAlign.center,
            controller: labelController,
            onChanged: (String text) => widget.label = text,
            style: TextStyle(color: widget.textColor, fontSize: 20),
          ),
        ),
        Slider(
          activeColor: widget.sliderColor,
          thumbColor: widget.thumbColor,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          value: value.clamp(widget.min, widget.max),
          label: value.round().toString(),
          onChanged: (p0) {
            setState(() {
              value = p0;
              widget.initValue = () => p0;
            });
            widget.onChanged.call(p0);
          },
        ),
      ],
    ),
  );
}

class LevelSliderState extends State<LevelSlider> {
  double value = 0;

  @override
  void initState() {
    super.initState();

    value = widget.initValue();
  }

  @override
  Widget build(final BuildContext context) => FittedBox(
    fit: BoxFit.fitWidth,
    child: Column(
      spacing: 4,
      children: <Widget>[
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.textColor, fontSize: 18),
        ),
        Slider(
          activeColor: widget.sliderColor,
          thumbColor: widget.thumbColor,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          value: value,
          label: value.round().toString(),
          onChanged: (p0) {
            setState(() {
              value = p0;
            });
            widget.onChanged.call(p0);
          },
        ),
      ],
    ),
  );
}

class LevelSliderSettings extends StatefulWidget {
  LevelSliderSettings({
    super.key,
    required this.onChanged,
    required this.levelSlider,
  });

  void Function(LevelSlider) onChanged;
  LevelSlider levelSlider;

  @override
  State<StatefulWidget> createState() => LevelSliderSettingsState();
}

class LevelSliderSettingsState extends State<LevelSliderSettings> {
  TextEditingController minController = TextEditingController(text: '0');
  TextEditingController maxController = TextEditingController(text: '6');
  TextEditingController divisionsController = TextEditingController(text: '5');

  @override
  void initState() {
    super.initState();

    minController.text = widget.levelSlider.min.toString();
    maxController.text = widget.levelSlider.max.toString();
    divisionsController.text = widget.levelSlider.divisions.toString();
    if (divisionsController.text == 'null') {
      divisionsController.text = '0';
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: 15,
    children: [
      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Text: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.levelSlider.textColor,
            onChanged: (color) {
              widget.levelSlider = LevelSlider(
                label: widget.levelSlider.label,
                textColor: color,
                sliderColor: widget.levelSlider.sliderColor,
                thumbColor: widget.levelSlider.thumbColor,
                min: widget.levelSlider.min,
                max: widget.levelSlider.max,
                divisions: widget.levelSlider.divisions,
                initValue: widget.levelSlider.initValue,
                onChanged: widget.levelSlider.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.levelSlider);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Slider: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.levelSlider.sliderColor,
            onChanged: (color) {
              widget.levelSlider = LevelSlider(
                label: widget.levelSlider.label,
                textColor: widget.levelSlider.textColor,
                sliderColor: color,
                thumbColor: widget.levelSlider.thumbColor,
                min: widget.levelSlider.min,
                max: widget.levelSlider.max,
                divisions: widget.levelSlider.divisions,
                initValue: widget.levelSlider.initValue,
                onChanged: widget.levelSlider.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.levelSlider);
            },
          ),
        ],
      ),
      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Thumb: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.levelSlider.thumbColor,
            onChanged: (color) {
              widget.levelSlider = LevelSlider(
                label: widget.levelSlider.label,
                textColor: widget.levelSlider.textColor,
                sliderColor: widget.levelSlider.sliderColor,
                thumbColor: color,
                min: widget.levelSlider.min,
                max: widget.levelSlider.max,
                divisions: widget.levelSlider.divisions,
                initValue: widget.levelSlider.initValue,
                onChanged: widget.levelSlider.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.levelSlider);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Min and Max value: ",
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
                widget.levelSlider = LevelSlider(
                  label: widget.levelSlider.label,
                  textColor: widget.levelSlider.textColor,
                  sliderColor: widget.levelSlider.sliderColor,
                  thumbColor: widget.levelSlider.thumbColor,
                  min: () {
                    try {
                      if (double.parse(text) > widget.levelSlider.max) {
                        throw Exception();
                      }
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.levelSlider.min;
                    }
                  }.call(),
                  max: () {
                    try {
                      if (double.parse(maxController.text) <
                          () {
                            try {
                              if (double.parse(text) > widget.levelSlider.max) {
                                throw Exception();
                              }
                              return double.parse(text);
                            } on Exception catch (_) {
                              return widget.levelSlider.min;
                            }
                          }.call()) {
                        throw Exception();
                      }
                      return double.parse(maxController.text);
                    } on Exception catch (_) {
                      return widget.levelSlider.max;
                    }
                  }.call(),
                  divisions: widget.levelSlider.divisions,
                  initValue: () => clampDouble(
                    widget.levelSlider.initValue(),
                    () {
                      try {
                        if (double.parse(text) > widget.levelSlider.max) {
                          throw Exception();
                        }
                        return double.parse(text);
                      } on Exception catch (_) {
                        return widget.levelSlider.min;
                      }
                    }.call(),
                    () {
                      try {
                        if (double.parse(maxController.text) <
                            () {
                              try {
                                if (double.parse(text) >
                                    widget.levelSlider.max) {
                                  throw Exception();
                                }
                                return double.parse(text);
                              } on Exception catch (_) {
                                return widget.levelSlider.min;
                              }
                            }.call()) {
                          throw Exception();
                        }
                        return double.parse(maxController.text);
                      } on Exception catch (_) {
                        return widget.levelSlider.max;
                      }
                    }.call(),
                  ),
                  onChanged: widget.levelSlider.onChanged,
                  isChangable: true,
                );
                widget.onChanged(widget.levelSlider);
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
                widget.levelSlider = LevelSlider(
                  label: widget.levelSlider.label,
                  textColor: widget.levelSlider.textColor,
                  sliderColor: widget.levelSlider.sliderColor,
                  thumbColor: widget.levelSlider.thumbColor,
                  min: () {
                    try {
                      if (double.parse(minController.text) >
                          () {
                            try {
                              if (double.parse(text) < widget.levelSlider.min) {
                                throw Exception();
                              }
                              return double.parse(text);
                            } on Exception catch (_) {
                              return widget.levelSlider.max;
                            }
                          }.call()) {
                        throw Exception();
                      }
                      return double.parse(minController.text);
                    } on Exception catch (_) {
                      return widget.levelSlider.min;
                    }
                  }.call(),
                  max: () {
                    try {
                      if (double.parse(text) < widget.levelSlider.min) {
                        throw Exception();
                      }
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.levelSlider.max;
                    }
                  }.call(),
                  divisions: widget.levelSlider.divisions,
                  initValue: () => clampDouble(
                    widget.levelSlider.initValue(),
                    () {
                      try {
                        if (double.parse(minController.text) >
                            () {
                              try {
                                if (double.parse(text) <
                                    widget.levelSlider.min) {
                                  throw Exception();
                                }
                                return double.parse(text);
                              } on Exception catch (_) {
                                return widget.levelSlider.max;
                              }
                            }.call()) {
                          throw Exception();
                        }
                        return double.parse(minController.text);
                      } on Exception catch (_) {
                        return widget.levelSlider.min;
                      }
                    }.call(),
                    () {
                      try {
                        if (double.parse(text) < widget.levelSlider.min) {
                          throw Exception();
                        }
                        return double.parse(text);
                      } on Exception catch (_) {
                        return widget.levelSlider.max;
                      }
                    }.call(),
                  ),
                  onChanged: widget.levelSlider.onChanged,
                  isChangable: true,
                );
                widget.onChanged(widget.levelSlider);
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
            "Select how much Divisons: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: divisionsController,
              onChanged: (String text) {
                widget.levelSlider = LevelSlider(
                  label: widget.levelSlider.label,
                  textColor: widget.levelSlider.textColor,
                  sliderColor: widget.levelSlider.sliderColor,
                  thumbColor: widget.levelSlider.thumbColor,
                  min: widget.levelSlider.min,
                  max: widget.levelSlider.max,
                  divisions: () {
                    try {
                      if (int.parse(text) == 0) {
                        return null;
                      } else {
                        return int.parse(text);
                      }
                    } on Exception catch (_) {
                      return widget.levelSlider.divisions;
                    }
                  }.call(),
                  initValue: widget.levelSlider.initValue,
                  onChanged: widget.levelSlider.onChanged,
                  isChangable: true,
                );
                widget.onChanged(widget.levelSlider);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),

          Text("Set to 0 for none"),
        ],
      ),
    ],
  );
}
