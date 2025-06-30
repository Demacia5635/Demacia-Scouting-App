import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/level_slider.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class Space extends QuestionType {
  Space({super.key, this.height = 50});

  double height;

  @override
  State<StatefulWidget> createState() => SpaceState();

  @override
  Widget settings(void Function(Space p1) onChanged) =>
      SpaceSettings(onChanged: onChanged, space: this);

  @override
  Map<String, dynamic> toJson() => {'height': height};

  factory Space.fromJson(Map<String, dynamic> json, {Key? key}) =>
      Space(key: key, height: json['height'] as double);
}

class SpaceState extends State<Space> {
  @override
  Widget build(BuildContext context) => SizedBox(height: widget.height);
}

class SpaceSettings extends StatefulWidget {
  SpaceSettings({super.key, required this.onChanged, required this.space});

  void Function(Space) onChanged;
  Space space;

  @override
  State<StatefulWidget> createState() => SpaceSettingsState();
}

class SpaceSettingsState extends State<SpaceSettings> {
  @override
  Widget build(BuildContext context) => Column(
    spacing: 14,
    children: [
      LevelSlider(
        label: "Select the Height: ",
        max: 1000,
        min: 10,
        initValue: () => 50,
        onChanged: (p0) {
          widget.space = Space(height: p0);
          widget.onChanged(widget.space);
        },
      ),
    ],
  );
}
