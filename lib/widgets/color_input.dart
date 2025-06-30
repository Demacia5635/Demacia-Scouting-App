import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class ColorInput extends QuestionType {
  ColorInput({
    super.key,
    this.label = 'Select Color',
    Color Function()? initValue,
    void Function(Color color)? onChanged,
  }) : onChanged = onChanged ?? ((p0) {}),
       initValue = initValue ?? (() => Colors.red);

  String label;
  Color Function() initValue;
  void Function(Color color) onChanged;

  @override
  State<StatefulWidget> createState() => ColorInputState();

  @override
  Widget settings(void Function(ColorInput p1) onChanged) => Container();

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'initValue': {
      'a': initValue().a,
      'r': initValue().r,
      'g': initValue().g,
      'b': initValue().b,
    },
  };

  factory ColorInput.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(Color color)? onChanged,
    dynamic init,
  }) => ColorInput(
    key: key,
    label: json['label'] as String,
    initValue: init != null && init() != null && init is Color Function()?
        ? init
        : () => Color.from(
            alpha: json['initValue']['a'],
            red: json['initValue']['r'],
            green: json['initValue']['g'],
            blue: json['initValue']['b'],
          ),
    onChanged: onChanged,
  );
}

class ColorInputState extends State<ColorInput> {
  Color pickerColor = Colors.red;

  @override
  void initState() {
    super.initState();

    pickerColor = widget.initValue();
  }

  Future<void> colorDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          height: 250,
          child: HueRingPicker(
            pickerColor: pickerColor,
            onColorChanged: (Color color) => setState(() {
              pickerColor = color;
            }),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              widget.onChanged(pickerColor);
              Navigator.of(context).pop();
            },
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => colorDialog(context),
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(
        pickerColor.withAlpha((pickerColor.a * 255).toInt() - 200),
      ),
      foregroundColor: WidgetStatePropertyAll(pickerColor),
    ),
    child: Text(widget.label),
  );
}
