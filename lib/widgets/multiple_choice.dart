import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class MultipleChoice extends QuestionType {
  MultipleChoice({super.key, required this.label, required this.choices});

  String label;
  List<String> choices;

  @override
  State<MultipleChoice> createState() => MultipleChoiceState();

  @override
  Widget settings(void Function(QuestionType) onChanged) {
    // TODO: implement settings
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  factory MultipleChoice.fromJson(Map<String, dynamic> json, {Key? key}) {
    //TODO: implement fromJson
    return MultipleChoice(
      label: json['label'] as String,
      choices: List<String>.from(json['choices'] as List<dynamic>),
      key: key,
    );
  }
}

class MultipleChoiceState extends State<MultipleChoice> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(widget.label),
        Column(children: widget.choices.map((choice) => Text(choice)).toList()),
      ],
    );
  }
}

class Button extends StatelessWidget {
  final void Function() onPressed;
  final String title;
  final Color? color;

  const Button({
    super.key,
    required this.onPressed,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: color),
        child: Text(title),
      ),
    );
  }
}
