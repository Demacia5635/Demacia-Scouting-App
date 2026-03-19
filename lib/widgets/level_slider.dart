import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class LevelSlider extends QuestionType {
  LevelSlider({
    super.key,
    this.label = "Label",
    this.min = 0.0,
    this.max = 10.0,
    this.initValue = 0.0,
    this.isChangable = false,
    void Function(double)? onChanged,
  }) : onChanged = onChanged ?? ((p0) {});

  final String label;
  final double min;
  final double max;
  final double initValue;
  final bool isChangable;
  final void Function(double) onChanged;

  @override
  State<StatefulWidget> createState() => _LevelSliderState();

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'min': min,
    'max': max,
    'initValue': initValue,
  };

  static LevelSlider fromJson(
    Map<String, dynamic> json, {
    void Function(double)? onChanged,
    bool isChangable = false,
    dynamic init,
  }) => LevelSlider(
    label: json['label'] as String? ?? "Label",
    min: (json['min'] as num?)?.toDouble() ?? 0.0,
    max: (json['max'] as num?)?.toDouble() ?? 10.0,
    initValue: (init ?? json['initValue'] as num?)?.toDouble() ?? 0.0,
    isChangable: isChangable,
    onChanged: onChanged,
  );

  @override
  Widget settings(void Function(QuestionType) onChanged) =>
      LevelSliderSettings(
        levelSlider: this,
        onChanged: (p0) => onChanged(p0),
      );
}

class _LevelSliderState extends State<LevelSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        Slider(
          value: _value,
          min: widget.min,
          max: widget.max,
          divisions: (widget.max - widget.min).toInt(),
          label: _value.toStringAsFixed(0),
          onChanged: widget.isChangable
              ? null
              : (double value) {
                  setState(() {
                    _value = value;
                  });
                  widget.onChanged(value);
                },
        ),
        Text(
          '${_value.toStringAsFixed(0)} / ${widget.max.toStringAsFixed(0)}',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class LevelSliderSettings extends StatefulWidget {
  const LevelSliderSettings({
    super.key,
    required this.levelSlider,
    required this.onChanged,
  });

  final LevelSlider levelSlider;
  final void Function(LevelSlider) onChanged;

  @override
  State<LevelSliderSettings> createState() => _LevelSliderSettingsState();
}

class _LevelSliderSettingsState extends State<LevelSliderSettings> {
  late TextEditingController _labelController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.levelSlider.label);
    _minController = TextEditingController(text: widget.levelSlider.min.toString());
    _maxController = TextEditingController(text: widget.levelSlider.max.toString());
  }

  @override
  void dispose() {
    _labelController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(LevelSlider(
      label: _labelController.text,
      min: double.tryParse(_minController.text) ?? 0.0,
      max: double.tryParse(_maxController.text) ?? 10.0,
      isChangable: widget.levelSlider.isChangable,
      onChanged: widget.levelSlider.onChanged,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        TextField(
          controller: _labelController,
          decoration: InputDecoration(labelText: 'Label'),
          onChanged: (_) => _notify(),
        ),
        TextField(
          controller: _minController,
          decoration: InputDecoration(labelText: 'Min'),
          keyboardType: TextInputType.number,
          onChanged: (_) => _notify(),
        ),
        TextField(
          controller: _maxController,
          decoration: InputDecoration(labelText: 'Max'),
          keyboardType: TextInputType.number,
          onChanged: (_) => _notify(),
        ),
      ],
    );
  }
}