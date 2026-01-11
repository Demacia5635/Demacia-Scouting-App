import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/form_page.dart';

class ScreenManagerPage extends StatefulWidget {
  ScreenManagerPage({super.key, Map<int, FormPage>? screens})
    : screens = screens ?? {};

  Map<int, FormPage> screens;

  @override
  State<ScreenManagerPage> createState() => _ScreenManagerPageState();

  Map<String, dynamic> toJson() => {
    'screens': screens.values.map((p0) => p0.toJson()).toList(),
  };

  factory ScreenManagerPage.fromJson(Map<String, dynamic> json) {
    Map<int, FormPage> screens = {};
    // Create the widget instance first so getJson has a reference
    ScreenManagerPage widget = ScreenManagerPage(screens: screens);

    // 1. Fill the map
    for (var screenJson in json['screens']) {
      int index = screenJson['index'] as int;
      screens[index] = FormPage.fromJson(
        screenJson,
        isChangable: true,
        getJson: () async => widget.toJson(),
        init: () {},
      );
    }

    // 2. Safely link pages by sorting the existing keys
    final sortedKeys = screens.keys.toList()..sort();

    for (int i = 0; i < sortedKeys.length; i++) {
      int currentKey = sortedKeys[i];
      FormPage? currentPage = screens[currentKey];

      if (currentPage != null) {
        // Link to previous (if not the first in the sorted list)
        currentPage.previosPage = (i > 0)
            ? () => screens[sortedKeys[i - 1]]!
            : null;

        // Link to next (if not the last in the sorted list)
        currentPage.nextPage = (i < sortedKeys.length - 1)
            ? () => screens[sortedKeys[i + 1]]!
            : null;
      }
    }

    // Update the widget reference with the populated screens
    widget.screens = screens;
    return widget;
  }
}

class _ScreenManagerPageState extends State<ScreenManagerPage> {
  int currentIndex = -1;

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    focusNode = FocusNode();

    final keyList = widget.screens.keys.toList();
    keyList.sort((p0, p1) => p0.compareTo(p1));
    currentIndex = keyList.isNotEmpty ? keyList.last : -1;
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  void _addNewFormPage() {
    final newScreen = FormPage(
      index: ++currentIndex,
      name: 'Form Num $currentIndex',
      isChangable: true,
      onSave: () async => widget.toJson(),
    );

    setState(() {
      widget.screens.addAll({currentIndex: newScreen});
    });
  }

  void _navigateToScreen(FormPage screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _deleteScreen(FormPage screen) {
    setState(() {
      widget.screens.remove(screen.index);
    });
  }

  Future<void> _showRenameDialog(FormPage screen) async {
    final TextEditingController nameController = TextEditingController(
      text: screen.name,
    );
    IconData pickingIcon = screen.icon;
    Color pickingColor = screen.color;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Screen'),
          content: SizedBox(
            width: 700,
            height: 450,
            child: Column(
              spacing: 14,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    label: Text("Enter new Screen name"),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      "Change Icon:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      width: 500,
                      child: IconPicker(onChanged: (p0) => pickingIcon = p0),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          screen.icon = Icons.description;
                        });
                      },
                      icon: Icon(Icons.delete),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Text(
                      "Change color:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ColorInput(
                      initValue: () => pickingColor,
                      onChanged: (p0) => pickingColor = p0,
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Rename'),
              onPressed: () async {
                setState(() {
                  screen.name = nameController.text;
                  screen.icon = pickingIcon;
                  screen.color = pickingColor;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// Handles raw keyboard events.
  void _handleKeyEvent(RawKeyEvent event) {
    // Check if the event is a key down event and the pressed key is the Escape key.
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if there's a route to pop (i.e., not the very first screen)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Pop the current route
      }
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: focusNode,
    onKey: _handleKeyEvent,
    autofocus: true,
    child: Scaffold(
      appBar: DemaciaAppBar(
        onSave:
            () async {
                  save(widget.toJson(), MainApp.currentSave);
                  await DatabaseService().create(
                    path: 'data',
                    data: widget.toJson(),
                  );
                }
                as void Function(),
        onLongSave: () async =>
            longSave(widget.toJson(), context, () => setState(() {})),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.5625,
        ),
        itemCount: widget.screens.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.screens.length) {
            return Card(
              margin: EdgeInsets.all(8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _addNewFormPage(),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final screenList = widget.screens.values.toList();
          screenList.sort((p0, p1) => p0.index.compareTo(p1.index));
          final screen = screenList[index];

          if (index != 0) {
            screen.previosPage = () => screenList[index - 1];
          } else {
            screen.previosPage = null;
          }

          if (index != screenList.length - 1) {
            screen.nextPage = () => screenList[index + 1];
          } else {
            screen.nextPage = null;
          }

          card(isDragging) => Card(
            margin: EdgeInsets.all(8),
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onDoubleTap: () => _navigateToScreen(screen),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Icon(
                            screen.icon,
                            size: 48,
                            color: screen.color,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          screen.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: screen.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  !isDragging
                      ? Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteScreen(screen),
                            tooltip: 'Delete Screen',
                          ),
                        )
                      : Container(),
                  !isDragging
                      ? Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () => _showRenameDialog(screen),
                            tooltip: 'Rename Screen',
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          );
          return Row(
            children: [
              index == 0
                  ? DragTarget<FormPage>(
                      onAcceptWithDetails: (details) {
                        setState(() {
                          for (var p0 in screenList) {
                            p0.index++;
                          }
                          details.data.index = 0;
                          screenList.sort(
                            (p0, p1) => p0.index.compareTo(p1.index),
                          );
                          for (int i = 0; i < screenList.length; i++) {
                            screenList[i].index = i;
                          }
                          details.data.previosPage = null;
                          details.data.nextPage = () => screenList[1];
                        });
                      },
                      builder: (context, candidateData, rejectedData) {
                        if (candidateData.isNotEmpty ||
                            rejectedData.isNotEmpty) {
                          if (candidateData.first!.index !=
                              screenList.first.index) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              width: 25,
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
                        return Container(width: 25);
                      },
                    )
                  : Container(width: 25),

              Expanded(
                child: Draggable<FormPage>(
                  data: screen,
                  feedback: card(true),
                  childWhenDragging: Opacity(opacity: 0.3, child: card(false)),
                  child: card(false),
                ),
              ),

              DragTarget<FormPage>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    if (details.data.index == screen.index) return;
                    screenList
                        .where((p0) => p0.index > screen.index)
                        .forEach((p0) => p0.index++);
                    details.data.index = screen.index + 1;
                    screenList.sort((p0, p1) => p0.index.compareTo(p1.index));
                    for (int i = 0; i < screenList.length; i++) {
                      screenList[i].index = i;
                    }
                    details.data.previosPage = () =>
                        screenList[details.data.index - 1];
                    if (details.data.index != screenList.length - 1) {
                      details.data.nextPage = () =>
                          screenList[details.data.index + 1];
                    } else {
                      details.data.nextPage = null;
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  if (candidateData.isNotEmpty || rejectedData.isNotEmpty) {
                    if (candidateData.first!.index != screen.index &&
                        candidateData.first!.index != screen.index + 1) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        width: 25,
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
                  return Container(width: 25);
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}
