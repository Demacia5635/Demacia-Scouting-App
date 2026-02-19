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
    this.max = 12,
    this.divisions,
    double Function()? initValue,
    void Function(double value)? onChanged,
    this.isChangable = false,
  }) : onChanged = onChanged ?? ((p0) {}),
       initValue = initValue ?? (() => 1) {
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
  }) {
    double Function()? resolvedInit;
    try {
      if (init != null) {
        final candidate = init(); // call ONCE, capture result
        if (candidate is num) {
          final captured = candidate.toDouble(); // never call init() again
          resolvedInit = () => captured;
        }
      }
    } catch (_) {}

    // Safely parse min/max as double regardless of whether stored as int or double
    final min = (json['min'] as num).toDouble();
    final max = (json['max'] as num).toDouble();
    final initValRaw = (json['initValue'] as num).toDouble();

    return LevelSlider(
      key: key,
      label: json['label'] as String,
      textColor: Color.from(
        alpha: (json['textColor']['a'] as num).toDouble(),
        red: (json['textColor']['r'] as num).toDouble(),
        green: (json['textColor']['g'] as num).toDouble(),
        blue: (json['textColor']['b'] as num).toDouble(),
      ),
      sliderColor: Color.from(
        alpha: (json['sliderColor']['a'] as num).toDouble(),
        red: (json['sliderColor']['r'] as num).toDouble(),
        green: (json['sliderColor']['g'] as num).toDouble(),
        blue: (json['sliderColor']['b'] as num).toDouble(),
      ),
      thumbColor: Color.from(
        alpha: (json['thumbColor']['a'] as num).toDouble(),
        red: (json['thumbColor']['r'] as num).toDouble(),
        green: (json['thumbColor']['g'] as num).toDouble(),
        blue: (json['thumbColor']['b'] as num).toDouble(),
      ),
      min: min,
      max: max,
      divisions: json['divisions'] as int,
      // Clamp the stored initValue to [min, max] so the slider never starts
      // out of range after the user changes min/max in settings.
      initValue: resolvedInit ?? (() => initValRaw.clamp(min, max)),
      onChanged: onChanged,
      isChangable: isChangable,
    );
  }
}

class LevelSliderChangableState extends State<LevelSlider> {
  double value = 0;

  TextEditingController labelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    value = widget.initValue().clamp(widget.min, widget.max);
    labelController.text = widget.label;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(value);
    });
  }

  @override
  void didUpdateWidget(LevelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When min/max changes from settings, clamp the current value so the
    // Slider never receives a value outside its [min, max] range.
    if (oldWidget.min != widget.min || oldWidget.max != widget.max) {
      setState(() {
        value = value.clamp(widget.min, widget.max);
      });
    }
  }

  @override
  Widget build(final BuildContext context) => SizedBox(
    // FIX: Replace FittedBox(fit: BoxFit.fitWidth) with a fixed-width SizedBox.
    // FittedBox required an unbounded width measurement which caused a
    // RenderFlex overflow and Stack Overflow when nested inside a Row.
    width: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
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
    value = widget.initValue().clamp(widget.min, widget.max);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onChanged(value);
    });
  }

  @override
  void didUpdateWidget(LevelSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.min != widget.min || oldWidget.max != widget.max) {
      setState(() {
        value = value.clamp(widget.min, widget.max);
      });
    }
  }

  @override
  Widget build(final BuildContext context) => SizedBox(
    // FIX: Same as above — fixed width instead of FittedBox.
    width: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
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
          value: value.clamp(widget.min, widget.max),
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
    divisionsController.text = (widget.levelSlider.divisions ?? 0).toString();
  }

  /// Safely parses [text] as a double, returning [fallback] on failure.
  double _parseDouble(String text, double fallback) {
    try {
      return double.parse(text);
    } catch (_) {
      return fallback;
    }
  }

  /// Safely parses [text] as an int, returning [fallback] on failure.
  int? _parseInt(String text, int? fallback) {
    try {
      final v = int.parse(text);
      return v == 0 ? null : v;
    } catch (_) {
      return fallback;
    }
  }

  /// Rebuilds the LevelSlider from current field values and notifies parent.
  void _rebuild() {
    final newMin = _parseDouble(minController.text, widget.levelSlider.min);
    final newMax = _parseDouble(maxController.text, widget.levelSlider.max);

    // Guard: min must be less than max
    if (newMin >= newMax) return;

    final clampedInit = widget.levelSlider.initValue().clamp(newMin, newMax);

    widget.levelSlider = LevelSlider(
      label: widget.levelSlider.label,
      textColor: widget.levelSlider.textColor,
      sliderColor: widget.levelSlider.sliderColor,
      thumbColor: widget.levelSlider.thumbColor,
      min: newMin,
      max: newMax,
      divisions: _parseInt(
        divisionsController.text,
        widget.levelSlider.divisions,
      ),
      initValue: () => clampedInit,
      onChanged: widget.levelSlider.onChanged,
      isChangable: true,
    );
    widget.onChanged(widget.levelSlider);
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
          // Min field
          SizedBox(
            width: 80,
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: minController,
              onChanged: (_) => _rebuild(),
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(labelText: 'Min'),
            ),
          ),
          // Max field
          SizedBox(
            width: 80,
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: maxController,
              onChanged: (_) => _rebuild(),
              style: TextStyle(fontSize: 20),
              decoration: InputDecoration(labelText: 'Max'),
            ),
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select how much Divisions: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              controller: divisionsController,
              onChanged: (_) => _rebuild(),
              style: TextStyle(fontSize: 20),
            ),
          ),
          Text("Set to 0 for none"),
        ],
      ),
    ],
  );
}
