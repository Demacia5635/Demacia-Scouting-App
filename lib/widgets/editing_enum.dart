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
                    setState(() => item.title = p0);
                    widget.onChanged(entries.values.toList());
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                    setState(() => item.sheetsTitle = p0);
                    widget.onChanged(entries.values.toList());
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Change/Add Icon: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: IconPicker(
                    onChanged: (p0) {
                      setState(() => item.icon = p0);
                      widget.onChanged(entries.values.toList());
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => item.icon = null);
                    widget.onChanged(entries.values.toList());
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
                    setState(() => item.color = color);
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
              child: const SizedBox(
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
            const SizedBox(width: 500),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const SizedBox(
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Entries list — drag-and-drop removed, just render chips directly.
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 1.0,
                runSpacing: 8.0,
                children: entriesList.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
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
                        if (item.icon != null)
                          Icon(item.icon, size: 14, color: item.color),
                        const SizedBox(width: 4),
                        Text(item.title, style: TextStyle(color: item.color)),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16),
                          onPressed: () => editingDialog(
                            context,
                            item,
                            () => setState(() {
                              if (entries.length > 1) {
                                entries.remove(item.index);
                              }
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
                    setState(() {
                      entries[++currentIndex] = Entry(
                        index: currentIndex,
                        title: text.isNotEmpty ? text : currentIndex.toString(),
                      );
                      widget.onChanged(entries.values.toList());
                      _newItemController.clear();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final text = _newItemController.text.trim();
                  setState(() {
                    entries[++currentIndex] = Entry(
                      index: currentIndex,
                      title: text.isNotEmpty ? text : currentIndex.toString(),
                    );
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
