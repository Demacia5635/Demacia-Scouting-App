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
  }) : initValue =
           initValue ?? (options.isNotEmpty ? () => {options.first} : () => {}),
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
    'initValue': initValue != null
        ? initValue!().map((option) => option.toJson()).toList()
        : [],
    'isMultiSelect': isMultiSelect,
  };

  factory Selection.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(Set<Entry>?)? onChanged,
    bool isChangable = false,
    dynamic init,
  }) {
    List<Entry> options = [];
    for (var entry in json['options']) {
      options.add(Entry.fromJson(entry));
    }

    Set<Entry> jsonInitValue = {};
    for (var entry in json['initValue']) {
      jsonInitValue.add(Entry.fromJson(entry));
    }

    final optionsByIndex = {for (final e in options) e.index: e};

    Set<Entry> normalise(Set<Entry> raw) =>
        raw.map((e) => optionsByIndex[e.index]).whereType<Entry>().toSet();

    Set<Entry> Function()? resolvedInit;
    try {
      if (init != null) {
        final candidate = init();
        if (candidate is Set<Entry>) {
          resolvedInit = () => normalise(init() as Set<Entry>);
        }
      }
    } catch (_) {}

    final normalisedJsonInit = normalise(jsonInitValue);

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
      initValue: resolvedInit ?? () => normalisedJsonInit,
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

    if (selected != null && selected!.isNotEmpty) {
      value = selected!.first;
    }

    if (selected != null && selected!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(selected);
      });
    }

    labelController.text = widget.label;
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 150),
    child: Column(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: TextField(
            textAlign: TextAlign.center,
            controller: labelController,
            onChanged: (String text) => widget.label = text,
            style: TextStyle(color: widget.textColor, fontSize: 20),
          ),
        ),
        Flexible(child: getSelectionOption(widget.selectionOption)),
      ],
    ),
  );

  Widget getSelectionOption(SelectionOptions option) {
    switch (option) {
      case SelectionOptions.selector:
        return Selector(
          options: widget.options,
          placeholder: (widget.placeHolder),
          value: value,
          makeItem: (Entry t) => t.title,
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
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
          ),
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

    if (selected != null && selected!.isNotEmpty) {
      value = selected!.first;
    }

    if (selected != null && selected!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600, maxHeight: 100),
    child: Column(
      spacing: 4,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Flexible(child: getSelectionOption(widget.selectionOption)),
      ],
    ),
  );

  Widget getSelectionOption(SelectionOptions option) {
    switch (option) {
      case SelectionOptions.selector:
        return Selector(
          options: widget.options,
          placeholder: (widget.placeHolder),
          value: value,
          makeItem: (Entry t) => t.title,
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
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
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
          ),
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

  // FIX: Helper to rebuild a Selection with updated fields, keeping all other
  // fields intact. Avoids repeating the full constructor on every change.
  Selection _rebuild({
    String? label,
    List<Entry>? options,
    Color? textColor,
    String? placeHolder,
    SelectionOptions? selectionOption,
    void Function(Set<Entry>?)? onChanged,
    Set<Entry> Function()? initValue,
    bool? isMultiSelect,
  }) => Selection(
    label: label ?? widget.selection.label,
    options: options ?? widget.selection.options,
    textColor: textColor ?? widget.selection.textColor,
    placeHolder: placeHolder ?? widget.selection.placeHolder,
    selectionOption: selectionOption ?? widget.selection.selectionOption,
    onChanged: onChanged ?? widget.selection.onChanged,
    initValue: initValue ?? widget.selection.initValue,
    isMultiSelect: isMultiSelect ?? widget.selection.isMultiSelect,
    isChangable: true,
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    // FIX: Removed ConstrainedBox(maxWidth: 800) — let content size itself.
    scrollDirection: Axis.horizontal,
    child: IntrinsicHeight(
      // FIX: IntrinsicHeight lets both columns size to each other's height
      // without going unbounded, fixing the collapsed-column issue.
      child: Row(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Left column: settings controls ---
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 260),
            child: Column(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color picker row
                Row(
                  spacing: 10,
                  children: [
                    const Text(
                      "Select the Color of the Label: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ColorInput(
                      initValue: () => widget.selection.textColor,
                      onChanged: (color) {
                        widget.selection = _rebuild(textColor: color);
                        widget.onChanged(widget.selection);
                      },
                    ),
                  ],
                ),

                // Placeholder input — only shown for selector mode
                if (!isSegment)
                  StringInput(
                    label: "Enter the placeHolder",
                    initValue: () => widget.selection.placeHolder,
                    onChanged: (p0) {
                      widget.selection = _rebuild(placeHolder: p0);
                      widget.onChanged(widget.selection);
                    },
                  ),

                // Multi-select toggle
                BooleanSwitch(
                  label: "select if you want multi choice",
                  initValue: () => widget.selection.isMultiSelect,
                  onChanged: (value) {
                    setState(() {
                      isMulti = value;
                      if (isMulti) isSegment = true;
                    });
                    widget.selection = _rebuild(
                      isMultiSelect: value,
                      initValue: !value && widget.selection.initValue != null
                          ? () => {widget.selection.initValue!().first}
                          : widget.selection.initValue,
                    );
                    widget.onChanged(widget.selection);
                  },
                ),

                // Selector / Segments toggle — hidden in multi-select mode
                if (!isMulti)
                  Row(
                    spacing: 4,
                    children: [
                      const Text("Selector"),
                      BooleanSwitch(
                        label: "select the type of selection",
                        selectedColor: Colors.red,
                        initValue: () =>
                            widget.selection.selectionOption ==
                            SelectionOptions.segments,
                        onChanged: (value) {
                          setState(() => isSegment = value);
                          widget.selection = _rebuild(
                            selectionOption: value
                                ? SelectionOptions.segments
                                : SelectionOptions.selector,
                          );
                          widget.onChanged(widget.selection);
                        },
                      ),
                      const Text("Segments"),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // --- Right column: option list editor ---
          // FIX: Wrapped in IntrinsicWidth so EditableEnumSelector is never
          // squeezed to zero width when the parent Row has mainAxisSize.min.
          IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EditableEnumSelector(
                  init: widget.selection.options,
                  onChanged: (value) {
                    widget.selection = _rebuild(options: value);
                    widget.onChanged(widget.selection);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
