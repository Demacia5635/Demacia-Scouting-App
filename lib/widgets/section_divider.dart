import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:scouting_qr_maker/widgets/color_input.dart";
import "package:scouting_qr_maker/widgets/question_type.dart";

class SectionDivider extends QuestionType {
  SectionDivider({
    super.key,
    required this.label,
    this.lineColor = Colors.red,
    this.textColor = Colors.white,
    this.thickness = 2,
    this.isChangable = false,
  });

  Color textColor;
  Color lineColor;
  String label;
  double thickness;
  bool isChangable;

  @override
  State<StatefulWidget> createState() =>
      isChangable ? SectionDividerChangabelState() : SectionDividerState();

  @override
  Widget settings(void Function(SectionDivider p1) onChanged) =>
      SectionDividerSettings(onChanged: onChanged, sectionDivider: this);

  @override
  Map<String, dynamic> toJson() => {
    'label': label,
    'textColor': {
      'a': textColor.a,
      'r': textColor.r,
      'g': textColor.g,
      'b': textColor.b,
    },
    'lineColor': {
      'a': lineColor.a,
      'r': lineColor.r,
      'g': lineColor.g,
      'b': lineColor.b,
    },
    'thickness': thickness,
  };

  factory SectionDivider.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    bool isChangable = false,
  }) => SectionDivider(
    key: key,
    label: json['label'] as String,
    textColor: Color.from(
      alpha: json['textColor']['a'],
      red: json['textColor']['r'],
      green: json['textColor']['g'],
      blue: json['textColor']['b'],
    ),
    lineColor: Color.from(
      alpha: json['lineColor']['a'],
      red: json['lineColor']['r'],
      green: json['lineColor']['g'],
      blue: json['lineColor']['b'],
    ),
    thickness: json['thickness'],
    isChangable: isChangable,
  );
}

class SectionDividerChangabelState extends State<SectionDivider> {
  Expanded get line => horizontalLine();

  TextEditingController labelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    labelController.text = widget.label;
  }

  @override
  Widget build(final BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      widget.thickness != 0 ? line : Container(),
      Container(
        constraints: BoxConstraints(maxWidth: 100),
        child: TextField(
          textAlign: TextAlign.center,
          controller: labelController,
          onChanged: (String text) => widget.label = text,
          style: TextStyle(color: widget.textColor, fontSize: 20),
        ),
      ),
      widget.thickness != 0 ? line : Container(),
    ],
  );

  Expanded horizontalLine() => Expanded(
    child: Container(
      margin: const EdgeInsets.only(left: 15.0, right: 10.0),
      child: Divider(
        thickness: widget.thickness,
        color: widget.lineColor.withAlpha(200),
        height: 50,
      ),
    ),
  );
}

class SectionDividerState extends State<SectionDivider> {
  Expanded get line => horizontalLine();

  @override
  Widget build(final BuildContext context) => Row(
    children: <Widget>[
      line,
      Text(
        widget.label,
        style: TextStyle(color: widget.textColor, fontSize: 20),
      ),
      line,
    ],
  );

  Expanded horizontalLine() => Expanded(
    child: Container(
      margin: const EdgeInsets.only(left: 15.0, right: 10.0),
      child: Divider(
        thickness: widget.thickness,
        color: widget.lineColor.withAlpha(200),
        height: 50,
      ),
    ),
  );
}

class SectionDividerSettings extends StatefulWidget {
  SectionDividerSettings({
    super.key,
    required this.onChanged,
    required this.sectionDivider,
  });

  void Function(SectionDivider) onChanged;
  SectionDivider sectionDivider;

  @override
  State<StatefulWidget> createState() => SectionDividerSettingsState();
}

class SectionDividerSettingsState extends State<SectionDividerSettings> {
  TextEditingController thicknessController = TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();

    thicknessController.text = widget.sectionDivider.thickness.toString();
  }

  @override
  Widget build(BuildContext context) => Column(
    spacing: 15,
    children: [
      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Color of the Line: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ColorInput(
            initValue: () => widget.sectionDivider.lineColor,
            onChanged: (color) {
              widget.sectionDivider = SectionDivider(
                label: widget.sectionDivider.label,
                lineColor: color,
                textColor: widget.sectionDivider.textColor,
                thickness: widget.sectionDivider.thickness,
                isChangable: true,
              );
              widget.onChanged(widget.sectionDivider);
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
            initValue: () => widget.sectionDivider.textColor,
            onChanged: (color) {
              widget.sectionDivider = SectionDivider(
                label: widget.sectionDivider.label,
                lineColor: widget.sectionDivider.lineColor,
                textColor: color,
                thickness: widget.sectionDivider.thickness,
                isChangable: true,
              );
              widget.onChanged(widget.sectionDivider);
            },
          ),
        ],
      ),

      Row(
        spacing: 10,
        children: [
          Text(
            "Select the Thickness: ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          Container(
            constraints: BoxConstraints(maxWidth: 100),
            child: TextField(
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              controller: thicknessController,
              onChanged: (String text) {
                widget.sectionDivider = SectionDivider(
                  label: widget.sectionDivider.label,
                  lineColor: widget.sectionDivider.lineColor,
                  textColor: widget.sectionDivider.textColor,
                  thickness: () {
                    try {
                      return double.parse(text);
                    } on Exception catch (_) {
                      return widget.sectionDivider.thickness;
                    }
                  }.call(),
                  isChangable: true,
                );
                widget.onChanged(widget.sectionDivider);
              },
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    ],
  );
}
