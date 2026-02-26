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
    Set<Types>? questionType,
    this.isChangable = false,
    void Function(int index)? onDelete,
    void Function(int index)? onDuplicate,
    void Function(int, dynamic)? onChanged,
  }) : onDelete = onDelete ?? ((p0) {}),
       onDuplicate = onDuplicate ?? ((p0) {}),
       question = question ?? Space(),
       questionType = questionType ?? {Types.spacer},
       onChanged = onChanged ?? ((p0, p1) {});

  void Function(int index) onDelete;
  void Function(int index) onDuplicate;
  int index;
  QuestionType question;
  Set<Types> questionType;
  bool isChangable;
  void Function(int, dynamic) onChanged;

  @override
  State<StatefulWidget> createState() => QuestionState();

  Map<String, dynamic> toJson() => {
    'index': index,
    'question': question.toJson(),
    'selected': questionType.first.index,
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
        init: init,
      ),
      Types.int => ScoreCounter.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init,
      ),
      Types.multipleCounter => MultipleChoice.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init,
      ),
      Types.slider => LevelSlider.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init,
      ),
      Types.divider => SectionDivider.fromJson(
        json['question'],
        isChangable: isChangable,
      ),
      Types.color => ColorInput.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        init: init,
      ),
      Types.icon => IconPicker.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        init: init,
      ),
      Types.string => StringInput.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init,
      ),
      Types.selectable => Selection.fromJson(
        json['question'],
        onChanged: (p0) => {
          if (onChanged != null) onChanged(json['index'], p0),
        },
        isChangable: isChangable,
        init: init,
      ),
    };

    return Question(
      key: key,
      index: json['index'] as int,
      question: question,
      questionType: {Types.values.elementAt(json['selected'] as int)},
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
    questionType: question.questionType,
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
  (Types.multipleCounter, 'Multiple Counter'),
];

class QuestionState extends State<Question> {
  Widget settings = const SizedBox.shrink();

  @override
  @override
  void initState() {
    super.initState();
    _rebuildSettings();
  }

  void _rebuildSettings() {
    settings = widget.question.settings(
      (p0) => setState(() {
        widget.question = p0;
        _rebuildSettings();
      }),
    );
  }

  Widget get _menu => PopupMenuButton(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) {
      switch (value) {
        case Options.delete:
          setState(() => widget.onDelete(widget.index));
        case Options.duplicate:
          setState(() => widget.onDuplicate(widget.index));
      }
    },
    itemBuilder: (context) => <PopupMenuEntry<Options>>[
      const PopupMenuItem<Options>(
        value: Options.delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline),
          title: Text("Delete"),
        ),
      ),
      const PopupMenuItem<Options>(
        value: Options.duplicate,
        child: ListTile(
          leading: Icon(Icons.control_point_duplicate),
          title: Text("Duplicate"),
        ),
      ),
    ],
  );

  // FIX: Removed maxWidth: 600 cap — SelectionSettings needs more room for its
  // two-column layout. Each settings widget self-constrains as needed.
  Widget get _settingsPanel => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Padding(padding: const EdgeInsets.all(16), child: settings),
  );

  // The question widget, always width-capped.
  Widget get _questionPanel => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 1500),
    child: widget.question,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth <= 600;

    // KEY FIX: The outermost widget has an explicit maxWidth equal to the
    // screen width. This gives every child (including SectionDivider's
    // Expanded lines and SelectionSettings' Row) a finite width to work
    // against, eliminating all "unbounded width" and ParentDataWidget errors.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: screenWidth, minHeight: 50),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: widget.isChangable
              ? Border.all(color: Colors.pink, width: 2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type-selector bar — always scrollable so it never overflows.
            if (widget.isChangable)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<Types>(
                  selected: widget.questionType,
                  onSelectionChanged: (Set<Types> types) {
                    setState(() {
                      widget.questionType = types;
                      switch (types.first) {
                        case Types.boolean:
                          final w = BooleanSwitch(
                            label: "Label",
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = BooleanSwitchSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            booleanSwitch: w,
                          );
                        case Types.int:
                          final w = ScoreCounter(
                            label: "Label",
                            icon: Icons.score,
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = ScoreCounterSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            scoreCounter: w,
                          );
                        case Types.multipleCounter:
                          final w = MultipleChoice(
                            label: "Label",
                            icon: Icons.check_box,
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = MultipleChoiceSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            multipleChoice: w,
                          );
                        //_rebuildSettings();
                        case Types.slider:
                          final w = LevelSlider(
                            label: "Label",
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = LevelSliderSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            levelSlider: w,
                          );
                        case Types.divider:
                          final w = SectionDivider(
                            label: "Label",
                            isChangable: true,
                          );
                          widget.question = w;
                          settings = SectionDividerSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            sectionDivider: w,
                          );
                        case Types.color:
                          final w = ColorInput(
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = const SizedBox.shrink();
                        case Types.icon:
                          final w = IconPicker(
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = const SizedBox.shrink();
                        case Types.spacer:
                          final w = Space();
                          widget.question = w;
                          settings = SpaceSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            space: w,
                          );
                        case Types.string:
                          final w = StringInput(
                            label: "Label",
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = StringInputSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            stringInput: w,
                          );
                        case Types.selectable:
                          final entries = [
                            Entry(index: 0),
                            Entry(index: 1),
                            Entry(index: 2),
                          ];
                          final w = Selection(
                            label: "label",
                            options: entries,
                            isChangable: true,
                            onChanged: (p0) =>
                                widget.onChanged(widget.index, p0),
                          );
                          widget.question = w;
                          settings = SelectionSettings(
                            onChanged: (p0) {
                              if (p0 != widget.question) {
                                setState(() => widget.question = p0);
                              }
                            },
                            selection: w,
                          );
                      }
                    });
                  },
                  segments: segments
                      .map<ButtonSegment<Types>>(
                        (s) => ButtonSegment<Types>(
                          value: s.$1,
                          label: Text(s.$2),
                        ),
                      )
                      .toList(),
                ),
              ),

            const SizedBox(height: 15),

            // Body: narrow = Column, wide = Row.
            // mainAxisSize.min on the Row stops it from claiming infinite width.
            if (isNarrow)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isChangable) _settingsPanel,
                  _questionPanel,
                  if (widget.isChangable) _menu,
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isChangable) _settingsPanel,
                  _questionPanel,
                  if (widget.isChangable) _menu,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

enum Types {
  spacer,
  boolean,
  int,
  slider,
  divider,
  color,
  icon,
  string,
  selectable,
  multipleCounter,
}

enum Options { delete, duplicate }
