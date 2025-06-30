import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class BooleanSwitch extends QuestionType {
  BooleanSwitch({
    super.key,
    required this.label,
    this.textColor = Colors.white,
    this.selectedColor = Colors.purpleAccent,
    bool Function()? initValue,
    void Function(bool value)? onChanged,
    this.isChangable = false,
  }) : onChanged = onChanged ?? ((bool p0) {}),
       initValue = initValue ?? (() => false);

  String label;
  Color textColor;
  Color selectedColor;
  bool Function() initValue;
  void Function(bool value) onChanged;
  bool isChangable;

  @override
  State<BooleanSwitch> createState() =>
      isChangable ? BooleanSwitchChangableState() : BooleanSwitchState();

  @override
  Widget settings(void Function(BooleanSwitch p1) onChanged) =>
      BooleanSwitchSettings(onChanged: onChanged, booleanSwitch: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'selectedColor': {
      'a': selectedColor.a,
      'r': selectedColor.r,
      'g': selectedColor.g,
      'b': selectedColor.b,
    },
    'initValue': initValue(),
  };

  factory BooleanSwitch.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(bool vaue)? onChanged,
    bool isChangable = false,
    dynamic init,
  }) {
    return BooleanSwitch(
    key: key,
    label: json['label'] as String,
    textColor: Color.from(
      alpha: json['textColor']['a'] as double,
      red: json['textColor']['r'] as double,
      green: json['textColor']['g'] as double,
      blue: json['textColor']['b'] as double,
    ),
    selectedColor: Color.from(
      alpha: json['selectedColor']['a'] as double,
      red: json['selectedColor']['r'] as double,
      green: json['selectedColor']['g'] as double,
      blue: json['selectedColor']['b'] as double,
    ),
    initValue: init != null && init() != null && init is bool Function()? ? init : (() => json['initValue'] as bool),
    onChanged: onChanged,
    isChangable: isChangable,
  );
  }
}

class BooleanSwitchChangableState extends State<BooleanSwitch> {
  bool light = true;

  TextEditingController labelController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();

    light = widget.initValue();

    labelController.text = widget.label;
  }

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 100),
          child: TextField(
            textAlign: TextAlign.center,
            controller: labelController,
            onChanged: (String text) => widget.label = text,
            style: TextStyle(color: widget.textColor, fontSize: 20),
          ),
        ),
        Switch(
          activeColor: widget.selectedColor,
          value: light,
          thumbIcon: thumbIcon,
          onChanged: (bool value) {
            setState(() {
              light = value;
              widget.initValue = () => light;
              widget.onChanged.call(value);
            });
          },
        ),
      ],
    ),
  );
}

class BooleanSwitchState extends State<BooleanSwitch> {
  bool light = true;

  @override
  void initState() {
    super.initState();

    light = widget.initValue();
  }

  static const WidgetStateProperty<Icon> thumbIcon =
      WidgetStateProperty<Icon>.fromMap(<WidgetStatesConstraint, Icon>{
        WidgetState.selected: Icon(Icons.check),
        WidgetState.any: Icon(Icons.close),
      });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 200,
    child: Column(
      spacing: 4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.center,
          style: TextStyle(color: widget.textColor, fontSize: 18),
        ),
        Switch(
          activeColor: widget.selectedColor,
          value: light,
          thumbIcon: thumbIcon,
          onChanged: (bool value) {
            setState(() {
              light = value;
              widget.onChanged.call(value);
            });
          },
        ),
      ],
    ),
  );
}

class BooleanSwitchSettings extends StatefulWidget {
  BooleanSwitchSettings({
    super.key,
    required this.onChanged,
    required this.booleanSwitch,
  });

  void Function(BooleanSwitch) onChanged;
  BooleanSwitch booleanSwitch;

  @override
  State<BooleanSwitchSettings> createState() => BooleanSwitchSettingsState();
}

class BooleanSwitchSettingsState extends State<BooleanSwitchSettings> {
  @override
  Widget build(BuildContext context) => Column(
    spacing: 15,
    children: [
      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color when active: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.booleanSwitch.selectedColor,
            onChanged: (color) {
              widget.booleanSwitch = BooleanSwitch(
                label: widget.booleanSwitch.label,
                textColor: widget.booleanSwitch.textColor,
                selectedColor: color,
                initValue: widget.booleanSwitch.initValue,
                onChanged: widget.booleanSwitch.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.booleanSwitch);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Text: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.booleanSwitch.textColor,
            onChanged: (color) {
              widget.booleanSwitch = BooleanSwitch(
                label: widget.booleanSwitch.label,
                textColor: color,
                selectedColor: widget.booleanSwitch.selectedColor,
                initValue: widget.booleanSwitch.initValue,
                onChanged: widget.booleanSwitch.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.booleanSwitch);
            },
          ),
        ],
      ),
    ],
  );
}
