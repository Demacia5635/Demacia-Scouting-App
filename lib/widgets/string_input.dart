import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class StringInput extends QuestionType {
  StringInput({
    super.key,
    required this.label,
    String Function()? initValue,
    this.textColor = Colors.white,
    this.labelColor = Colors.grey,
    void Function(String text)? onChanged,
    this.isChangable = false,
  }) : onChanged = onChanged ?? ((p0) {}),
       initValue = initValue ?? (() => '');

  String label;
  String Function() initValue;
  Color textColor;
  Color labelColor;
  void Function(String) onChanged;
  bool isChangable;

  @override
  State<StatefulWidget> createState() =>
      isChangable ? StringInputChangableState() : StringInputState();

  @override
  Widget settings(void Function(StringInput p1) onChanged) =>
      StringInputSettings(onChanged: onChanged, stringInput: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'initValue': initValue(),
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'labelColor': {
      'a': labelColor.a,
      'r': labelColor.r,
      'g': labelColor.g,
      'b': labelColor.b,
    },
  };

  factory StringInput.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(String)? onChanged,
    bool isChangable = false,
    dynamic init
  }) {
    return StringInput(
    key: key,
    label: json['label'] as String,
    initValue: () => init ?? (json['initValue'] ?? '').toString(),
    textColor: Color.from(
      alpha: json['textColor']['a'] as double,
      red: json['textColor']['r'] as double,
      green: json['textColor']['g'] as double,
      blue: json['textColor']['b'] as double,
    ),
    labelColor: Color.from(
      alpha: json['labelColor']['a'] as double,
      red: json['labelColor']['r'] as double,
      green: json['labelColor']['g'] as double,
      blue: json['labelColor']['b'] as double,
    ),
    onChanged: onChanged,
    isChangable: isChangable,
  );
  }
}

class StringInputChangableState extends State<StringInput> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.initValue();
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxWidth: 450, maxHeight: 300),

    child: TextField(
      controller: controller,
      onChanged: (value) {
        widget.initValue = () => value;
      },
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.labelColor),
      ),
      style: TextStyle(color: widget.textColor),
    ),
  );
}

class StringInputState extends State<StringInput> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.initValue();
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxWidth: 400, maxHeight: 300),

    child: TextField(
      controller: controller,
      onChanged: (value) => widget.onChanged(value),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.labelColor),
      ),
      style: TextStyle(color: widget.textColor),
    ),
  );
}

class StringInputSettings extends StatefulWidget {
  StringInputSettings({
    super.key,
    required this.onChanged,
    required this.stringInput,
  });

  void Function(StringInput) onChanged;
  StringInput stringInput;

  @override
  State<StatefulWidget> createState() => StringInputSettingsState();
}

class StringInputSettingsState extends State<StringInputSettings> {
  @override
  Widget build(BuildContext context) => Column(
    spacing: 14,
    children: [
      StringInput(
        label: "Enter the Label",
        initValue: () => widget.stringInput.label,
        onChanged: (p0) {
          widget.stringInput = StringInput(
            label: p0,
            initValue: widget.stringInput.initValue,
            textColor: widget.stringInput.textColor,
            labelColor: widget.stringInput.labelColor,
            onChanged: widget.stringInput.onChanged,
            isChangable: true,
          );
          widget.onChanged(widget.stringInput);
        },
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Text: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.stringInput.textColor,
            onChanged: (color) {
              widget.stringInput = StringInput(
                label: widget.stringInput.label,
                initValue: widget.stringInput.initValue,
                textColor: color,
                labelColor: widget.stringInput.labelColor,
                onChanged: widget.stringInput.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.stringInput);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Label: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.stringInput.labelColor,
            onChanged: (color) {
              widget.stringInput = StringInput(
                label: widget.stringInput.label,
                initValue: widget.stringInput.initValue,
                textColor: widget.stringInput.textColor,
                labelColor: color,
                onChanged: widget.stringInput.onChanged,
                isChangable: true,
              );
              widget.onChanged(widget.stringInput);
            },
          ),
        ],
      ),
    ],
  );
}
