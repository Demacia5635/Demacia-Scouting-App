import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/widgets/string_input.dart';

class EditableEnumSelector extends StatefulWidget {
  const EditableEnumSelector({
    super.key,
    required this.onChanged,
    this.init = const [],
  });

  final void Function(List<Entry>) onChanged;
  final List<Entry> init;

  @override
  State<EditableEnumSelector> createState() => _EditableEnumSelectorState();
}

class _EditableEnumSelectorState extends State<EditableEnumSelector> {
  Map<int, Entry> entries = {};
  int currentIndex = 0;

  final double dropZoneSize = 25;

  final TextEditingController _newItemController = TextEditingController();

  @override
  void initState() {
    super.initState();

    entries = {};
    for (int i = 0; i < widget.init.length; i++) {
      entries.addAll({i: widget.init[i]});
    }
    if (widget.init.isNotEmpty) {
      currentIndex = widget.init.last.index;
    }
  }

  Future<void> editingDialog(
    BuildContext context,
    Entry item,
    void Function() onDelete,
  ) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SizedBox(
        height: 350,
        width: 750,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Rename: ", style: TextStyle(fontWeight: FontWeight.bold)),
                StringInput(
                  label: "enter new name",
                  initValue: () => item.title,
                  onChanged: (p0) {
                    setState(() {
                      item.title = p0;
                    });
                    widget.onChanged(entries.values.toList());
                  },
                ),
              ],
            ),
            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Rename Sheet Name: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                StringInput(
                  label: "enter new name",
                  initValue: () => item.sheetsTitle,
                  onChanged: (p0) {
                    setState(() {
                      item.sheetsTitle = p0;
                    });
                    widget.onChanged(entries.values.toList());
                  },
                ),
              ],
            ),
            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Change/Add Icon: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  constraints: BoxConstraints(maxWidth: 500),
                  child: IconPicker(
                    onChanged: (p0) {
                      setState(() {
                        item.icon = p0;
                      });
                      widget.onChanged(entries.values.toList());
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      item.icon = null;
                    });
                    widget.onChanged(entries.values.toList());
                  },
                  icon: Icon(Icons.delete),
                ),
              ],
            ),
            SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Change text color",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ColorInput(
                  initValue: () => item.color,
                  onChanged: (color) {
                    setState(() {
                      item.color = color;
                    });
                    widget.onChanged(entries.values.toList());
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                onDelete();
                widget.onChanged(entries.values.toList());
                Navigator.of(context).pop();
              },
              child: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 5),
                    Text("Delete"),
                  ],
                ),
              ),
            ),
            SizedBox(width: 500),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("Go Back"),
                    Icon(Icons.subdirectory_arrow_right),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final entriesList = entries.values.toList();
    entriesList.sort((p0, p1) => p0.index.compareTo(p1.index));

    return Container(
      constraints: BoxConstraints(maxHeight: 300, maxWidth: 500),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 1.0,
                runSpacing: 8.0,
                children: () {
                  final list = entriesList.map((item) {
                    Widget itemWidget = Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey.shade800,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          item.icon != null
                              ? Icon(item.icon, size: 14, color: item.color)
                              : Container(),
                          SizedBox(width: 4),
                          Text(item.title, style: TextStyle(color: item.color)),
                          IconButton(
                            icon: Icon(Icons.edit, size: 16),
                            onPressed: () => editingDialog(
                              context,
                              item,
                              () => setState(() {
                                if (entries.length > 1)
                                  entries.remove(item.index);
                              }),
                            ),
                          ),
                        ],
                      ),
                    );

                    return [
                      // FIX: The "before first item" drop target now uses
                      // SizedBox.shrink() in its idle state so it takes up
                      // zero space, making item 0 look identical to items 1, 2, etc.
                      if (item.index == 0)
                        DragTarget<Entry>(
                          onAcceptWithDetails: (details) {
                            setState(() {
                              entriesList.forEach((p0) => p0.index++);
                              details.data.index = 0;
                              entriesList.sort(
                                (p0, p1) => p0.index.compareTo(p1.index),
                              );
                              for (int i = 0; i < entriesList.length; i++) {
                                entriesList[i].index = i;
                              }
                            });
                          },
                          builder: (context, candidateData, rejectedData) {
                            if (candidateData.isNotEmpty ||
                                rejectedData.isNotEmpty) {
                              if (candidateData.first!.index !=
                                  entriesList.first.index) {
                                // Only show the drop indicator while dragging
                                return Container(
                                  margin: EdgeInsets.all(5),
                                  width: dropZoneSize,
                                  height: dropZoneSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.greenAccent.shade700,
                                      width: 2,
                                    ),
                                  ),
                                );
                              }
                            }
                            // FIX: zero-size idle state instead of 25x25
                            return SizedBox.shrink();
                          },
                        )
                      else
                        Container(),

                      Draggable<Entry>(
                        data: item,
                        feedback: IgnorePointer(
                          child: Material(child: itemWidget),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: itemWidget,
                        ),
                        child: itemWidget,
                      ),

                      DragTarget<Entry>(
                        onAcceptWithDetails: (details) {
                          setState(() {
                            if (details.data.index == item.index) return;
                            entriesList
                                .where((p0) => p0.index > item.index)
                                .forEach((p0) => p0.index++);
                            details.data.index = item.index + 1;
                            entriesList.sort(
                              (p0, p1) => p0.index.compareTo(p1.index),
                            );
                            for (int i = 0; i < entriesList.length; i++) {
                              entriesList[i].index = i;
                            }
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          if (candidateData.isNotEmpty ||
                              rejectedData.isNotEmpty) {
                            if (candidateData.first!.index != item.index &&
                                candidateData.first!.index != item.index + 1) {
                              return Container(
                                margin: EdgeInsets.all(5),
                                height: dropZoneSize,
                                width: dropZoneSize,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.greenAccent.shade700,
                                    width: 2,
                                  ),
                                ),
                              );
                            }
                          }
                          return Container(
                            width: dropZoneSize,
                            height: dropZoneSize,
                          );
                        },
                      ),
                    ];
                  }).toList();

                  List<Widget> widgetList = [];
                  for (var i in list) {
                    widgetList.addAll(i);
                  }
                  return widgetList;
                }(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  decoration: const InputDecoration(labelText: 'New item'),
                  onSubmitted: (String text) {
                    final value = text;
                    setState(() {
                      if (value.isNotEmpty) {
                        entries.addAll({
                          ++currentIndex: Entry(
                            index: currentIndex,
                            title: value,
                          ),
                        });
                      } else {
                        entries.addAll({
                          ++currentIndex: Entry(index: currentIndex),
                        });
                      }
                      widget.onChanged(entries.values.toList());
                      _newItemController.clear();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final value = _newItemController.text.trim();
                  setState(() {
                    if (value.isNotEmpty) {
                      entries.addAll({
                        ++currentIndex: Entry(
                          index: currentIndex,
                          title: value,
                        ),
                      });
                    } else {
                      entries.addAll({
                        ++currentIndex: Entry(index: currentIndex),
                      });
                    }
                    widget.onChanged(entries.values.toList());
                    _newItemController.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Entry {
  Entry({
    required this.index,
    this.title = '',
    this.sheetsTitle = '',
    this.color = Colors.white,
    this.icon,
  }) {
    if (title.isEmpty) title = index.toString();
    if (sheetsTitle.isEmpty) sheetsTitle = title;
  }

  int index;
  String title;
  String sheetsTitle;
  Color color;
  IconData? icon;

  @override
  bool operator ==(Object other) => other is Entry && other.index == index;

  @override
  int get hashCode => index.hashCode;

  Map<String, dynamic> toJson() => {
    'index': index,
    'title': title,
    'sheetsTitle': sheetsTitle,
    'color': {'a': color.a, 'r': color.r, 'g': color.g, 'b': color.b},
    'icon': {
      'codePoint': icon?.codePoint ?? '',
      'fontFamily': icon?.fontFamily ?? '',
    },
  };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
    index: json['index'] as int,
    title: json['title'] as String,
    sheetsTitle: json['sheetsTitle'] as String,
    color: Color.from(
      alpha: json['color']['a'] as double,
      red: json['color']['r'] as double,
      green: json['color']['g'] as double,
      blue: json['color']['b'] as double,
    ),
    icon: (json['icon']['codePoint'] != '')
        ? IconData(
            json['icon']['codePoint'] as int,
            fontFamily: json['icon']['fontFamily'] as String,
          )
        : null,
  );
}
