import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/form_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/qr_code.dart';
import 'package:scouting_qr_maker/save.dart';
import 'package:scouting_qr_maker/screen_manager_page.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

class typeGameChoose extends StatefulWidget {
  const typeGameChoose({super.key});

  @override
  State<typeGameChoose> createState() => _typeGameChoose();
}

class _typeGameChoose extends State<typeGameChoose> {
  String? _selected;

  final List<String> _opsean = ['qual', 'Playoff', "final"];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      hint: const Text("choose game type"),
      value: _selected,
      items: _opsean.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selected = value;
        });
      },
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});
  Map<String, dynamic>? json;
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  String _extractGameNumber(Map<String, dynamic> json) {
    if (!json.containsKey('screens')) return '';
    for (final screen in (json['screens'] as List)) {
      final questions = (screen['questions'] as List);
      for (final q in questions) {
        final qMap = q as Map<String, dynamic>;
        final question = qMap['question'] as Map<String, dynamic>;
        final label = (question['label'] ?? '').toString().trim();
        if (label == 'מספר משחק' || label.toLowerCase() == 'game number') {
          final ans = qMap['answer'];
          if (ans is String && ans.trim().isNotEmpty) return ans.trim();
          if (ans is num) return ans.toString();
          final initValue = question['initValue'];
          if (initValue is String && initValue.trim().isNotEmpty) return initValue.trim();
          if (initValue is num) return initValue.toString();
        }
      }
    }
    return '';
  }

  Future<void> _saveAsNew() async {
    if (widget.json == null) return;
    final prefs = await SharedPreferences.getInstance();
    final db = DatabaseService();
    final gameNum = _extractGameNumber(widget.json!);
    final nextIndex = MainApp.saves.isEmpty
        ? 0
        : (MainApp.saves.map((s) => s.index).reduce((a, b) => a > b ? a : b) + 1);
    final title = (gameNum.isNotEmpty)
        ? 'save משחק $gameNum'
        : 'save${nextIndex + 1}';
    final formRow = await db.uploadData(table: 'data', data: {'form': widget.json!});
    final formId = formRow?['id'] as int?;
    final newSave = Save(index: nextIndex, title: title, formId: formId);
    await db.uploadSave(newSave.toJson());
    await prefs.setString('app_data_${newSave.index}', jsonEncode(widget.json!));
    setState(() {
      MainApp.saves.add(newSave);
      MainApp.currentSave = newSave;
    });
    await prefs.setInt('current_save', newSave.index);
  }

  void loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      DatabaseService databaseService = DatabaseService();
      final savesWithForms = await databaseService.getThreeLatestSavesWithForms();
      if (savesWithForms.isNotEmpty) {
        MainApp.saves = savesWithForms.map((saveData) {
          final save = Save.fromJson(saveData);
          final formData = saveData['form'];
          if (formData != null) {
            prefs.setString('app_data_${save.index}', jsonEncode(formData));
          }
          return save;
        }).toList();
        print('Reloaded ${MainApp.saves.length} saves');
      }
      Map<String, dynamic>? formData;
      final saveKey = 'app_data_${MainApp.currentSave.index}';
      if (prefs.containsKey(saveKey)) {
        final savedJson = prefs.getString(saveKey);
        if (savedJson != null && savedJson.isNotEmpty) {
          formData = jsonDecode(savedJson);
          print('Loaded form from SharedPreferences for save ${MainApp.currentSave.index}');
        }
      }
      if (formData == null) {
        formData = await databaseService.getLatestFormData();
        print('Loaded latest form as fallback');
      }
      setState(() {
        widget.json = formData;
        _isLoading = false;
      });
      print('Final json state: ${widget.json != null ? "loaded" : "null"}');
      if (widget.json != null && widget.json!.containsKey('screens')) {
        print('Form has ${widget.json!['screens']?.length ?? 0} screens');
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        widget.json = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: DemaciaAppBar(
        onSave: () async {
          if (widget.json != null) {
            save(widget.json!, MainApp.currentSave);
            await DatabaseService().uploadData(
              table: 'data',
              data: {'form': widget.json!},
            );
          }
        },
        onLongSave: () async {
          if (widget.json != null) {
            longSave(widget.json!, context, () => setState(() {}));
          }
        },
        onLoadSave: () {
          loadData();
        },
        onSaveAsNew: () async {
          await _saveAsNew();
        },
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading...'),
                ],
              ),
            )
          : Column(
              children: [
                // Editing Room button
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isPhone ? 16 : 20,
                      vertical: isPhone ? 8 : 10,
                    ),
                    child: ElevatedButton(
                      onPressed: widget.json != null && widget.json!.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    if (widget.json!.containsKey('screens')) {
                                      return ScreenManagerPage.fromJson(widget.json!);
                                    }
                                    return ScreenManagerPage();
                                  },
                                ),
                              ).then((_) {
                                loadData();
                              });
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(double.infinity, double.infinity),
                      ),
                      child: ListTile(
                        title: Text(
                          "Editing Room",
                          style: TextStyle(fontSize: isPhone ? 16 : 18),
                        ),
                        trailing: Icon(Icons.arrow_right_alt),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 12 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // Preview Room button
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isPhone ? 16 : 20,
                      vertical: isPhone ? 8 : 10,
                    ),
                    child: ElevatedButton(
                      onPressed: widget.json != null && widget.json!.isNotEmpty
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    if (widget.json!.containsKey('screens')) {
                                      List<FormPage> screens = [];
                                      Map<int, Map<int, dynamic>> data = {};
                                      Map<int, dynamic Function()?>? func(int i) {
                                        return data[i]?.map<int, dynamic Function()?>(
                                          (qIndex, savedValue) {
                                            return MapEntry(qIndex, () {
                                              if (savedValue != null) {
                                                if (savedValue is Set<Entry>) {
                                                  widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] =
                                                      savedValue
                                                          .map((option) => option.toJson())
                                                          .toList();
                                                } else {
                                                  switch (savedValue.runtimeType) {
                                                    case Color:
                                                      widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] = {
                                                        'a': savedValue.a,
                                                        'r': savedValue.r,
                                                        'g': savedValue.g,
                                                        'b': savedValue.b,
                                                      };
                                                    case IconData:
                                                      widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] = {
                                                        'codePoint': savedValue.codePoint,
                                                        'fontFamily': savedValue.fontFamily,
                                                      };
                                                    default:
                                                      widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] =
                                                          savedValue;
                                                  }
                                                }
                                              }
                                              return data[i]![qIndex];
                                            });
                                          },
                                        );
                                      }

                                      for (int i = 0; i < widget.json!['screens'].length; i++) {
                                        data[i] = {};
                                        for (int j = 0; j < widget.json!['screens'][i]['questions'].length; j++) {
                                          data[i]!.addAll({j: null});
                                        }
                                        screens.add(
                                          FormPage.fromJson(
                                            widget.json!['screens'][i],
                                            isChangable: false,
                                            getJson: () async => widget.json!,
                                            onChanged: (p0, p1) {
                                              setState(() {
                                                data[i]![p0] = p1;
                                              });
                                            },
                                            init: () => func(i),
                                          ),
                                        );
                                      }

                                      for (int i = 0; i < screens.length; i++) {
                                        screens[i].previosPage = (i != 0)
                                            ? () {
                                                screens[i - 1].load(
                                                  widget.json!['screens'][i - 1],
                                                  (p0, p1) {
                                                    setState(() {
                                                      data[i]![p0] = p1;
                                                    });
                                                  },
                                                  () => func(i - 1),
                                                );
                                                return screens[i - 1];
                                              }
                                            : null;
                                        screens[i].nextPage = (i + 1 != screens.length)
                                            ? () {
                                                screens[i + 1].load(
                                                  widget.json!['screens'][i + 1],
                                                  (p0, p1) {
                                                    setState(() {
                                                      data[i + 1]![p0] = p1;
                                                    });
                                                  },
                                                  () => func(i + 1),
                                                );
                                                return screens[i + 1];
                                              }
                                            : () => QrCode(
                                                  data: data,
                                                  previosPage: () {
                                                    screens.last.load(
                                                      widget.json!['screens'][screens.length - 1],
                                                      (p0, p1) {
                                                        setState(() {
                                                          data[screens.length - 1]![p0] = p1;
                                                        });
                                                      },
                                                      () => func(screens.length - 1),
                                                    );
                                                    return screens.last;
                                                  },
                                                );
                                      }
                                      return screens[0];
                                    }
                                    return FormPage(index: 0);
                                  },
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size(double.infinity, double.infinity),
                      ),
                      child: ListTile(
                        title: Text(
                          "Preview Room",
                          style: TextStyle(fontSize: isPhone ? 16 : 18),
                        ),
                        trailing: Icon(Icons.arrow_right_alt),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isPhone ? 12 : 16,
                        ),
                      ),
                    ),
                  ),
                ),
                // Game type dropdown
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isPhone ? 16 : 20,
                    vertical: isPhone ? 8 : 10,
                  ),
                  child: typeGameChoose(),
                ),
              ],
            ),
    );
  }
}