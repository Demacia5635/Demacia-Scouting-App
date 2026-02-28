import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/widgets/color_input.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/icon_picker.dart';
import 'package:scouting_qr_maker/form_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScreenManagerPage extends StatefulWidget {
  ScreenManagerPage({
    super.key,
    Map<int, FormPage>? screens,
    int? currentFormId,
  }) : screens = screens ?? {},
       currentFormId = currentFormId ?? 1;

  Map<int, FormPage> screens;
  int? currentFormId;

  @override
  State<ScreenManagerPage> createState() => _ScreenManagerPageState();

  Map<String, dynamic> toJson() => {
    'screens': screens.values.map((p0) => p0.toJson()).toList(),
  };

  factory ScreenManagerPage.fromJson(Map<String, dynamic> json, int id) {
    Map<int, FormPage> screens = {};
    print('id in fromJson: $id');

    ScreenManagerPage widget = ScreenManagerPage(
      screens: screens,
      currentFormId: id,
    );
    print(
      '🟧🟧🟧🟧🟧🟧screen manager default widget id: ${widget.currentFormId}🟧🟧🟧🟧🟧🟧🟧',
    );

    print('screen is null?: ${json['screens'] == null}');
    print('🟧🟧🟧🟧🟧🟧🟧questions: ${json['questions']}🟧🟧🟧🟧🟧🟧🟧');
    if (json['screens'] == null && json['questions'] == null) {
      print('🟧🟧🟧🟧🟧🟧RETURNED WIDGET EARLY🟧🟧🟧🟧🟧🟧');
      return widget;
    }
    if ((json['screens'] is List && (json['screens'] as List).isEmpty)) {
      print('🟧🟧🟧🟧🟧🟧RETURNED WIDGET🟧🟧🟧🟧🟧🟧');
      return widget;
    }

    if (json['screens'] != null && json['screens'] is List) {
      final screensList = json['screens'] as List;

      for (var screenJson in screensList) {
        if (screenJson == null) continue;
        if (screenJson is! Map<String, dynamic>) continue;

        // Skip screens that have no valid questions key at all
        final hasQuestions =
            screenJson['questions'] != null && screenJson['questions'] is List;
        final hasLegacyQuestion =
            screenJson['question'] != null && screenJson['question'] is List;

        if (!hasQuestions && !hasLegacyQuestion) {
          // Still add the screen, just with no questions
          final index = screenJson['index'] as int? ?? screens.length;
          screens[index] = FormPage.fromJson(
            // Inject a proper empty questions list so fromJson doesn't crash
            {...screenJson, 'questions': []},
            isChangable: true,
            getJson: () async => widget.toJson(),
            id: id,
            init: () => null,
          );
          continue;
        }

        final index = screenJson['index'] as int? ?? screens.length;
        screens[index] = FormPage.fromJson(
          screenJson,
          isChangable: true,
          getJson: () async => widget.toJson(),
          id: id,
          init: () => null,
        );
      }
    } else if (json['questions'] != null) {
      // Legacy: single screen stored as root
      screens[0] = FormPage.fromJson(
        json,
        isChangable: true,
        getJson: () async => widget.toJson(),
        id: id,
        init: () => null,
      );
    }

    // Wire up prev/next navigation
    final sortedKeys = screens.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      int currentKey = sortedKeys[i];
      FormPage? currentPage = screens[currentKey];

      if (currentPage != null) {
        currentPage.previosPage = (i > 0)
            ? () => screens[sortedKeys[i - 1]]!
            : null;

        currentPage.nextPage = (i < sortedKeys.length - 1)
            ? () => screens[sortedKeys[i + 1]]!
            : null;
      }
    }

    widget.screens = screens;
    widget.currentFormId = id;
    return widget;
  }
}

class _ScreenManagerPageState extends State<ScreenManagerPage> {
  int currentIndex = -1;

  @override
  void initState() {
    super.initState();

    final keyList = widget.screens.keys.toList();
    keyList.sort((p0, p1) => p0.compareTo(p1));
    currentIndex = keyList.isNotEmpty ? keyList.last : -1;
  }

  void _addNewFormPage() {
    final newScreen = FormPage(
      index: ++currentIndex,
      name: 'Form Num $currentIndex',
      isChangable: true,
      onSave: () async => widget.toJson(),
      currentFormId: widget.currentFormId,
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

    // Get screen size for responsive dialog
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rename Screen'),
          content: SizedBox(
            width: isPhone ? screenWidth * 0.9 : 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 14,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      label: Text("Enter new Screen name"),
                    ),
                  ),
                  // Icon picker section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Change Icon:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                screen.icon = Icons.description;
                                pickingIcon = Icons.description;
                              });
                            },
                            icon: Icon(Icons.delete),
                            tooltip: "Reset Icon",
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: IconPicker(onChanged: (p0) => pickingIcon = p0),
                      ),
                    ],
                  ),
                  // Color picker section
                  Row(
                    mainAxisAlignment: isPhone
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        "Change color:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: ColorInput(
                          initValue: () => pickingColor,
                          onChanged: (p0) => pickingColor = p0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive grid
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 400
        ? 2
        : screenWidth < 600
        ? 2
        : screenWidth < 900
        ? 3
        : screenWidth < 1200
        ? 4
        : 5;

    return Scaffold(
      appBar: DemaciaAppBar(
        onSave:
            () async {
                  print('screen page short save');
                  print('id under screen page: ${widget.currentFormId}');
                  save(
                    widget.toJson(),
                    MainApp.currentSave,
                    widget.currentFormId,
                  );
                }
                as void Function(),
        onLongSave: () async {
          print('screen page');
          return longSave(
            widget.toJson(),
            context,
            () => setState(() {}),
            widget.currentFormId,
          );
        },
        onLoadSave: () async {
          // נטען מחדש את אותו screen manager לפי save שנבחר
          final prefs = await SharedPreferences.getInstance();
          final key = 'app_data_${MainApp.currentSave.index}';
          final savedJson = prefs.getString(key);

          if (savedJson != null && savedJson.isNotEmpty) {
            final formData = jsonDecode(savedJson) as Map<String, dynamic>;
            if (!mounted) return;

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ScreenManagerPage.fromJson(
                  formData,
                  widget.currentFormId ?? 1,
                ),
              ),
            );
          }
        },
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: screenWidth < 600 ? 8.0 : 16.0,
          mainAxisSpacing: screenWidth < 600 ? 8.0 : 16.0,
          childAspectRatio: 0.65,
        ),
        itemCount: widget.screens.length + 1,
        itemBuilder: (context, index) {
          if (index == widget.screens.length) {
            return Card(
              margin: EdgeInsets.all(4),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _addNewFormPage(),
                child: Center(
                  child: Icon(
                    Icons.add,
                    size: screenWidth < 600 ? 36 : 48,
                    color: Colors.grey.shade300,
                  ),
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

          Widget card(bool isDragging) => Card(
            margin: EdgeInsets.all(4),
            elevation: isDragging ? 8.0 : 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => _navigateToScreen(screen),
              onLongPress: screenWidth < 600
                  ? () => _showRenameDialog(screen)
                  : null,
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
                            size: screenWidth < 600 ? 36 : 48,
                            color: screen.color,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          screen.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth < 600 ? 14 : 18,
                            fontWeight: FontWeight.bold,
                            color: screen.color,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isDragging)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                          size: screenWidth < 600 ? 20 : 24,
                        ),
                        onPressed: () => _deleteScreen(screen),
                        tooltip: 'Delete Screen',
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  if (!isDragging && screenWidth >= 600)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.grey,
                          size: screenWidth < 600 ? 20 : 24,
                        ),
                        onPressed: () => _showRenameDialog(screen),
                        tooltip: 'Rename Screen',
                        padding: EdgeInsets.all(4),
                        constraints: BoxConstraints(),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          //screen.isSpecialForm = !screen.isSpecialForm;
                        });
                      },
                      icon: Icon(
                        Icons.star,
                        // color: screen.isSpecialForm
                        //     ? Colors.yellow
                        //     : Colors.grey,
                        size: screenWidth < 600 ? 20 : 24,
                      ),
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Simplified drag-and-drop for phones
          if (screenWidth < 600) {
            return LongPressDraggable<FormPage>(
              data: screen,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: screenWidth / crossAxisCount - 16,
                  height: (screenWidth / crossAxisCount - 16) / 0.65,
                  child: card(true),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: card(false)),
              child: DragTarget<FormPage>(
                onAcceptWithDetails: (details) {
                  setState(() {
                    if (details.data.index == screen.index) return;

                    final oldIndex = details.data.index;
                    final newIndex = screen.index;

                    if (oldIndex < newIndex) {
                      for (var s in screenList) {
                        if (s.index > oldIndex && s.index <= newIndex) {
                          s.index--;
                        }
                      }
                    } else {
                      for (var s in screenList) {
                        if (s.index >= newIndex && s.index < oldIndex) {
                          s.index++;
                        }
                      }
                    }

                    details.data.index = newIndex;
                    screenList.sort((p0, p1) => p0.index.compareTo(p1.index));

                    for (int i = 0; i < screenList.length; i++) {
                      screenList[i].index = i;
                      screenList[i].previosPage = i > 0
                          ? () => screenList[i - 1]
                          : null;
                      screenList[i].nextPage = i < screenList.length - 1
                          ? () => screenList[i + 1]
                          : null;
                    }
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return card(false);
                },
              ),
            );
          }

          // Desktop drag-and-drop with drop zones
          return Row(
            children: [
              if (index == 0)
                DragTarget<FormPage>(
                  onAcceptWithDetails: (details) {
                    setState(() {
                      for (var p0 in screenList) {
                        p0.index++;
                      }
                      details.data.index = 0;
                      screenList.sort((p0, p1) => p0.index.compareTo(p1.index));
                      for (int i = 0; i < screenList.length; i++) {
                        screenList[i].index = i;
                      }
                      details.data.previosPage = null;
                      details.data.nextPage = () => screenList[1];
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    if (candidateData.isNotEmpty || rejectedData.isNotEmpty) {
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
              else
                Container(width: 25),

              Expanded(
                child: Draggable<FormPage>(
                  data: screen,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(width: 200, height: 300, child: card(true)),
                  ),
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
    );
  }
}
