import 'package:flutter/material.dart';
import 'package:orbit_standard_library/orbit_standard_library.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:scouting_qr_maker/widgets/boolean_switch.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';
import 'package:scouting_qr_maker/widgets/string_input.dart';

class Selection extends QuestionType {
  Selection({
    super.key,
    required this.label,
    required this.options,
    this.textColor = Colors.white,
    this.placeHolder = "Enter your option",
    this.selectionOption = SelectionOptions.selector,
    void Function(Set<Entry>?)? onChanged,
    Set<Entry> Function()? initValue,
    this.isMultiSelect = false,
    this.isChangable = false,
    this.segments = const [],
  }) : initValue = initValue ?? (options.isNotEmpty ? () => {options.first} : () => {}),
       onChanged = onChanged ?? ((p0) {}) {
    if (isMultiSelect) selectionOption = SelectionOptions.segments;
    segments = [];
    for (var option in options) {
      segments.add((option, option.title));
    }
  }

  String label;
  Color textColor;
  String placeHolder;
  List<Entry> options;
  void Function(Set<Entry>?) onChanged;
  SelectionOptions selectionOption;
  Set<Entry> Function()? initValue;
  bool isMultiSelect;
  bool isChangable;
  List<(Entry, String)> segments;

  @override
  State<StatefulWidget> createState() =>
      isChangable ? SelectionChangableState() : SelectionState();

  @override
  Widget settings(void Function(Selection p1) onChanged) =>
      SelectionSettings(onChanged: onChanged, selection: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'placeHolder': placeHolder,
    'options': options.map((option) => option.toJson()).toList(),
    'selectionOption': selectionOption.index,
    'initValue': initValue != null ? initValue!().map((option) => option.toJson()).toList() : [],
    'isMultiSelect': isMultiSelect,
  };

  factory Selection.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(Set<Entry>?)? onChanged,
    bool isChangable = false,
    dynamic init
  }) {
    List<Entry> options = [];
    for (var entry in json['options']) {
      options.add(Entry.fromJson(entry));
    }

    Set<Entry> initValue = {};
    for (var entry in json['initValue']) {
      initValue.add(Entry.fromJson(entry));
    }

    return Selection(
      key: key,
      label: json['label'] as String,
      textColor: Color.from(
        alpha: json['textColor']['a'] as double,
        red: json['textColor']['r'] as double,
        green: json['textColor']['g'] as double,
        blue: json['textColor']['b'] as double,
      ),
      placeHolder: json['placeHolder'] as String,
      options: options,
      selectionOption: SelectionOptions.values.elementAt(
        json['selectionOption'] as int,
      ),
      initValue: init != null && init() != null && init is Set<Entry> Function()? ? init : (() => initValue),
      isMultiSelect: json['isMultiSelect'] as bool,
      onChanged: onChanged,
      isChangable: isChangable,
    );
  }
}

class SelectionChangableState extends State<Selection> {
  Entry? value;
  Set<Entry>? selected = {};

  TextEditingController labelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    selected = widget.initValue != null ? widget.initValue!() : null;
    if (!widget.isMultiSelect && selected != null && selected!.length > 1) {
      selected = {selected!.first};
    }
    // value = selected?.firstOrNull;

    labelController.text = widget.label;
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxHeight: 150),
    child: Column(
      spacing: 4,
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

        getSelectionOption(widget.selectionOption),
      ],
    ),
  );

  Widget getSelectionOption(SelectionOptions option) {
    switch (option) {
      case SelectionOptions.selector:
        return Selector(
          options: widget.options,
          placeholder: widget.placeHolder,
          value: value,
          makeItem: (Entry t) => t.title,
          // makeItem: (Entry t) => Row(
          //   spacing: 4,
          //   children: [
          //     t.icon != null ? Icon(t.icon, color: t.color) : Container(),
          //     Text(t.title, style: TextStyle(color: t.color)),
          //   ],
          // ),
          onChange: (Entry t) {
            setState(() {
              value = t;
              selected = {t};
              widget.initValue = () => {t};
            });
            widget.onChanged(value != null ? {value!} : null);
          },
          validate: always2(null),
        );

      case SelectionOptions.segments:
        return SegmentedButton<int>(
          emptySelectionAllowed: true,
          multiSelectionEnabled: widget.isMultiSelect,
          selected: () {
            if (selected!.length > 1 && !widget.isMultiSelect) {
              selected = {selected!.first};
            }
            return selected!.map((entry) => entry.index).toSet();
          }(),
          onSelectionChanged: (Set<int> t) {
            setState(() {
              selected = widget.options
                  .where((entry) => t.contains(entry.index))
                  .toSet();
              value = selected?.lastOrNull;
              widget.initValue = selected != null ? () => selected! : null;
              widget.onChanged(selected);
            });
          },
          segments: widget.segments.map<ButtonSegment<int>>((
            (Entry, String) p0,
          ) {
            return ButtonSegment<int>(
              icon: Icon(p0.$1.icon, color: p0.$1.color),
              value: p0.$1.index,
              label: Text(p0.$1.title, style: TextStyle(color: p0.$1.color)),
            );
          }).toList(),
        );
    }
  }
}

class SelectionState extends State<Selection> {
  Entry? value;
  Set<Entry>? selected = {};

  @override
  void initState() {
    super.initState();

    selected = widget.initValue != null ? widget.initValue!() : null;
    if (!widget.isMultiSelect && selected != null && selected!.length > 1) {
      selected = {selected!.first};
    }
    // value = selected?.firstOrNull;
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(maxHeight: 100),
    child: Column(
      spacing: 4,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        getSelectionOption(widget.selectionOption),
      ],
    ),
  );

  Widget getSelectionOption(SelectionOptions option) {
    switch (option) {
      case SelectionOptions.selector:
        return Selector(
          options: widget.options,
          placeholder: widget.placeHolder,
          value: value,
          makeItem: (Entry t) => t.title,
          // makeItem: (Entry t) => Row(
          //   spacing: 4,
          //   children: [
          //     t.icon != null ? Icon(t.icon, color: t.color) : Container(),
          //     Text(t.title, style: TextStyle(color: t.color)),
          //   ],
          // ),
          onChange: (Entry t) {
            setState(() {
              value = t;
              selected = {t};
            });
            widget.onChanged(value != null ? {value!} : null);
          },
          validate: always2(null),
        );

      case SelectionOptions.segments:
        return SegmentedButton<int>(
          emptySelectionAllowed: true,
          multiSelectionEnabled: widget.isMultiSelect,
          selected: () {
            if (selected!.length > 1 && !widget.isMultiSelect) {
              selected = {selected!.first};
            }
            return selected!.map((entry) => entry.index).toSet();
          }(),
          onSelectionChanged: (Set<int> t) {
            setState(() {
              selected = widget.options
                  .where((entry) => t.contains(entry.index))
                  .toSet();
              value = selected?.lastOrNull;
              widget.onChanged(selected);
            });
          },
          segments: widget.segments.map<ButtonSegment<int>>((
            (Entry, String) p0,
          ) {
            return ButtonSegment<int>(
              icon: Icon(p0.$1.icon, color: p0.$1.color),
              value: p0.$1.index,
              label: Text(p0.$1.title, style: TextStyle(color: p0.$1.color)),
            );
          }).toList(),
        );
    }
  }
}

enum SelectionOptions { selector, segments }

class SelectionSettings extends StatefulWidget {
  SelectionSettings({
    super.key,
    required this.onChanged,
    required this.selection,
  });

  void Function(Selection) onChanged;
  Selection selection;

  @override
  State<StatefulWidget> createState() => SelectionSettingsState();
}

class SelectionSettingsState extends State<SelectionSettings> {
  bool isMulti = false;
  bool isSegment = false;

  @override
  void initState() {
    super.initState();

    isMulti = widget.selection.isMultiSelect;
    isSegment = widget.selection.selectionOption == SelectionOptions.segments;
  }

  @override
  Widget build(BuildContext context) => Row(
    spacing: 10,
    children: [
      Column(
        spacing: 4,
        children: [
          Row(
            spacing: 10,
            children: [
              Text(
                "Select the Color of the Label: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ColorInput(
                initValue: () => widget.selection.textColor,
                onChanged: (color) {
                  widget.selection = Selection(
                    label: widget.selection.label,
                    options: widget.selection.options,
                    textColor: color,
                    placeHolder: widget.selection.placeHolder,
                    selectionOption: widget.selection.selectionOption,
                    onChanged: widget.selection.onChanged,
                    initValue: widget.selection.initValue,
                    isMultiSelect: widget.selection.isMultiSelect,
                    isChangable: true,
                  );
                  widget.onChanged(widget.selection);
                },
              ),
            ],
          ),

          !isSegment
              ? StringInput(
                  label: "Enter the placeHolder",
                  initValue: () => widget.selection.placeHolder,
                  onChanged: (p0) {
                    widget.selection = Selection(
                      label: widget.selection.label,
                      options: widget.selection.options,
                      textColor: widget.selection.textColor,
                      placeHolder: p0,
                      selectionOption: widget.selection.selectionOption,
                      onChanged: widget.selection.onChanged,
                      initValue: widget.selection.initValue,
                      isMultiSelect: widget.selection.isMultiSelect,
                      isChangable: true,
                    );
                    widget.onChanged(widget.selection);
                  },
                )
              : Container(),

          Row(
            spacing: 4,
            children: [
              BooleanSwitch(
                label: "select if you want multi choice",
                initValue: () => widget.selection.isMultiSelect,
                onChanged: (value) {
                  setState(() {
                    isMulti = value;
                    if (isMulti) {
                      isSegment = true;
                    }
                  });
                  widget.selection = Selection(
                    label: widget.selection.label,
                    options: widget.selection.options,
                    placeHolder: widget.selection.placeHolder,
                    textColor: widget.selection.textColor,
                    selectionOption: widget.selection.selectionOption,
                    onChanged: widget.selection.onChanged,
                    initValue: !value && widget.selection.initValue != null
                        ? () => {widget.selection.initValue!().first}
                        : widget.selection.initValue,
                    isMultiSelect: value,
                    isChangable: true,
                  );
                  widget.onChanged(widget.selection);
                },
              ),
            ],
          ),

          !isMulti
              ? Row(
                  spacing: 4,
                  children: [
                    Text("Selector"),
                    BooleanSwitch(
                      label: "select the type of selection",
                      selectedColor: Colors.red,
                      initValue: () =>
                          widget.selection.selectionOption ==
                          SelectionOptions.segments,
                      onChanged: (value) {
                        setState(() {
                          isSegment = value;
                        });
                        widget.selection = Selection(
                          label: widget.selection.label,
                          options: widget.selection.options,
                          placeHolder: widget.selection.placeHolder,
                          textColor: widget.selection.textColor,
                          selectionOption: value
                              ? SelectionOptions.segments
                              : SelectionOptions.selector,
                          onChanged: widget.selection.onChanged,
                          initValue: widget.selection.initValue,
                          isMultiSelect: widget.selection.isMultiSelect,
                          isChangable: true,
                        );
                        widget.onChanged(widget.selection);
                      },
                    ),
                    Text("segments"),
                  ],
                )
              : Container(),
        ],
      ),

      SizedBox(width: 10),

      Column(
        spacing: 4,
        children: [
          EditableEnumSelector(
            init: widget.selection.options,
            onChanged: (value) {
              widget.selection = Selection(
                label: widget.selection.label,
                options: value,
                placeHolder: widget.selection.placeHolder,
                textColor: widget.selection.textColor,
                selectionOption: widget.selection.selectionOption,
                onChanged: widget.selection.onChanged,
                initValue: widget.selection.initValue,
                isMultiSelect: widget.selection.isMultiSelect,
                isChangable: true,
              );
              widget.onChanged(widget.selection);
            },
          ),
        ],
      ),
    ],
  );
}
