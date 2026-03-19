import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:scouting_qr_maker/widgets/boolean_switch.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/widgets/multiple_choice.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';
import 'package:scouting_qr_maker/widgets/score_counter.dart';
import 'package:scouting_qr_maker/widgets/section_divider.dart';
import 'package:scouting_qr_maker/widgets/level_slider.dart';
import 'package:scouting_qr_maker/widgets/selection.dart';
import 'package:scouting_qr_maker/widgets/space.dart';
import 'package:scouting_qr_maker/widgets/string_input.dart';

class Question extends StatefulWidget {
  Question({
    super.key,
    required this.index,
    QuestionType? question,
    Set<Types>? selected,
    this.isChangable = false,
    void Function(int index)? onDelete,
    void Function(int index)? onDuplicate,
    void Function(int, dynamic)? onChanged,
  }) : onDelete = onDelete ?? ((p0) {}),
       onDuplicate = onDuplicate ?? ((p0) {}),
       question = question ?? Space(),
       selected = selected ?? {Types.spacer},
       onChanged = onChanged ?? ((p0, p1) {});

  void Function(int index) onDelete;
  void Function(int index) onDuplicate;
  int index;
  QuestionType question;
  Set<Types> selected;
  bool isChangable;
  void Function(int, dynamic) onChanged;

  @override
  State<StatefulWidget> createState() => QuestionState();

  Map<String, dynamic> toJson() => {
    'index': index,
    'question': question.toJson(),
    'selected': selected.first.index,
  };

  factory Question.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(int, dynamic)? onChanged,
    bool isChangable = false,
    void Function(int index)? onDelete,
    void Function(int index)? onDuplicate,
    required dynamic Function() init,
  }) {
    QuestionType question = switch (Types.values.elementAt(
      json['selected'] as int,
    )) {
      Types.spacer => Space.fromJson(json['question']),
      Types.boolean => BooleanSwitch.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ),
      Types.int => ScoreCounter.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ),
      Types.multipleChoice => MultipleChoice.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ),
      // ✅ Fix: cast onChanged to the correct type
      Types.slider => LevelSlider.fromJson(
        json['question'],
        onChanged: (double p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ) as QuestionType,
      Types.divider => SectionDivider.fromJson(
        json['question'],
        isChangable: isChangable,
      ),
      Types.color => ColorInput.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        init: init(),
      ),
      Types.icon => IconPicker.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        init: init(),
      ),
      Types.string => StringInput.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ),
      Types.selectable => Selection.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init(),
      ),
    };
    return Question(
      key: key,
      index: json['index'] as int,
      question: question,
      selected: {Types.values.elementAt(json['selected'] as int)},
      isChangable: isChangable,
      onDelete: onDelete,
      onDuplicate: onDuplicate,
      onChanged: onChanged,
    );
  }

  factory Question.duplicate(
    Question question,
    int index, {
    Key? key,
    void Function(int, dynamic)? onChanged,
  }) => Question(
    key: key,
    index: index,
    question: question.question,
    selected: question.selected,
    isChangable: question.isChangable,
    onDelete: question.onDelete,
    onDuplicate: question.onDuplicate,
    onChanged: onChanged,
  );
}

const List<(Types, String)> segments = <(Types, String)>[
  (Types.spacer, 'Spacer'),
  (Types.boolean, 'Boolean Switch'),
  (Types.int, 'Counter'),
  (Types.slider, 'Slider'),
  (Types.divider, 'Divider'),
  (Types.color, 'Color'),
  (Types.icon, 'Icon'),
  (Types.string, 'String'),
  (Types.selectable, 'Selection'),
  (Types.multipleChoice, 'Multiple Choice'),
];

class QuestionState extends State<Question> {
  Widget settings = Container();

  @override
  void initState() {
    super.initState();
    setState(() {
      settings = widget.question.settings(
        (p0) => setState(() => widget.question = p0),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.symmetric(vertical: 20),
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: widget.isChangable
          ? Border.all(color: Colors.pink, width: 2)
          : null,
    ),
    constraints: BoxConstraints(minHeight: 50),
    child: Column(
      spacing: 15,
      children: [
        widget.isChangable
            ? SegmentedButton<Types>(
                selected: widget.selected,
                onSelectionChanged: (Set<Types> types) {
                  setState(() {
                    widget.selected = types;
                    switch (types.first) {
                      case Types.boolean:
                        BooleanSwitch booleanSwitch = BooleanSwitch(
                          label: "Label",
                          isChangable: true,
                          onChanged: (p0) => {
                            widget.onChanged(widget.index, p0),
                          },
                        );
                        widget.question = booleanSwitch;
                        settings = BooleanSwitchSettings(
                          onChanged: (p0) {
                            setState(() => widget.question = p0);
                          },
                          booleanSwitch: booleanSwitch,
                        );
                      case Types.int:
                        ScoreCounter scoreCounter = ScoreCounter(
                          label: "Label",
                          icon: Icons.score,
                          isChangable: true,
                          onChanged: (p0) => {
                            widget.onChanged(widget.index, p0),
                          },
                        );
                        widget.question = scoreCounter;
                        settings = ScoreCounterSettings(
                          onChanged: (ScoreCounter p0) {
                            setState(() => widget.question = p0);
                          },
                          scoreCounter: scoreCounter,
                        );
                      case Types.multipleChoice:
                        MultipleChoice multipleChoice = MultipleChoice(
                          label: "Label",
                          icon: Icons.check_box,
                          isChangable: true,
                          onChanged: (p0) => {
                            widget.onChanged(widget.index, p0),
                          },
                        );
                        widget.question = multipleChoice;
                        settings = MultipleChoiceSettings(
                          onChanged: (MultipleChoice p0) {
                            setState(() => widget.question = p0);
                          },
                          multipleChoice: multipleChoice,
                        );
                      case Types.slider:
                        // ✅ Fix: explicitly type onChanged as void Function(double)
                        LevelSlider levelSlider = LevelSlider(
                          label: "Label",
                          isChangable: true,
                          onChanged: (double p0) => {
                            widget.onChanged(widget.index, p0),
                          },
                        );
                        widget.question = levelSlider as QuestionType;
                        settings = LevelSliderSettings(
                          onChanged: (LevelSlider p0) {
                            setState(() => widget.question = p0 as QuestionType);
                          },
                          levelSlider: levelSlider,
                        );