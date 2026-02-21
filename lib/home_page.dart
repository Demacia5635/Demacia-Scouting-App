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

class HomePage extends StatefulWidget {
  HomePage({super.key});

  Map<String, dynamic>? json;

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isLoading = true;

  // Lifted up so answers survive navigating back to home.
  // Outer key = screen index, inner key = question's JSON index.
  Map<int, Map<int, dynamic>> _previewData = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      DatabaseService databaseService = DatabaseService();

      // final savesWithForms = await databaseService
      //     .getThreeLatestSavesWithForms();

      // if (savesWithForms.isNotEmpty) {
      //   MainApp.saves = savesWithForms.map((saveData) {
      //     final save = Save.fromJson(saveData);
      //     final formData = saveData['form'];
      //     if (formData != null) {
      //       prefs.setString('app_data_${save.index}', jsonEncode(formData));
      //     }
      //     return save;
      //   }).toList();

      //   print('Reloaded ${MainApp.saves.length} saves');
      // }

      Map<String, dynamic>? formData;

      final saveKey = 'app_data_${MainApp.currentSave.index}';
      if (prefs.containsKey(saveKey)) {
        final savedJson = prefs.getString(saveKey);
        if (savedJson != null && savedJson.isNotEmpty) {
          formData = jsonDecode(savedJson);
          print(
            'Loaded form from SharedPreferences for save ${MainApp.currentSave.index}',
          );
        }
      }

      if (formData == null) {
        formData = await databaseService.getLatestFormData();
        print('Loaded latest form as fallback');
      }

      setState(() {
        widget.json = formData;
        _isLoading = false;
        _initPreviewData();
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

  /// Builds _previewData keyed by each question's actual JSON index,
  /// preserving any answers already filled in.
  void _initPreviewData() {
    if (widget.json == null || !widget.json!.containsKey('screens')) {
      _previewData = {};
      return;
    }

    final screens = widget.json!['screens'] as List;
    final updated = <int, Map<int, dynamic>>{};

    for (int i = 0; i < screens.length; i++) {
      final questions = screens[i]['questions'] as List;
      updated[i] = {};
      for (final q in questions) {
        // Use the question's real JSON index as the key — this is what
        // onChanged fires with, so the two must always match.
        final qIndex = q['index'] as int;
        updated[i]![qIndex] = _previewData[i]?[qIndex] ?? null;
      }
    }

    _previewData = updated;
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
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isPhone ? 16 : 20,
                      vertical: isPhone ? 8 : 10,
                    ),
                    child: Column(
                      spacing: isPhone ? 16 : 40,
                      children: [
                        // ── Editing Room ──────────────────────────────────
                        ElevatedButton(
                          onPressed:
                              widget.json != null && widget.json!.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        print(
                                          'contains key?: ${widget.json!.containsKey('screens')}',
                                        );
                                        if (widget.json!.containsKey(
                                          'screens',
                                        )) {
                                          return ScreenManagerPage.fromJson(
                                            widget.json!,
                                          );
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
                            minimumSize: Size(
                              double.infinity,
                              isPhone ? 60 : 70,
                            ),
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

                        // ── Preview Room ──────────────────────────────────
                        ElevatedButton(
                          onPressed:
                              widget.json != null && widget.json!.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        if (!widget.json!.containsKey(
                                          'screens',
                                        )) {
                                          return FormPage(index: 0);
                                        }

                                        List<FormPage> screens = [];

                                        // func returns the init map for screen i,
                                        // keyed by each question's real JSON index.
                                        Map<int, dynamic Function()?>? func(
                                          int i,
                                        ) {
                                          return _previewData[i]?.map<
                                            int,
                                            dynamic Function()?
                                          >((qIndex, savedValue) {
                                            return MapEntry(qIndex, () {
                                              if (savedValue != null) {
                                                // Mirror the saved value back into
                                                // JSON so fromJson picks it up as
                                                // initValue on re-entry.
                                                final screenJson =
                                                    widget.json!['screens'][i];
                                                final questionJson =
                                                    (screenJson['questions']
                                                            as List)
                                                        .firstWhere(
                                                          (q) =>
                                                              q['index'] ==
                                                              qIndex,
                                                          orElse: () => null,
                                                        );
                                                if (questionJson != null) {
                                                  if (savedValue is Set) {
                                                    questionJson['question']['initValue'] =
                                                        savedValue
                                                            .map(
                                                              (option) => option
                                                                  .toJson(),
                                                            )
                                                            .toList();
                                                  } else {
                                                    switch (savedValue
                                                        .runtimeType) {
                                                      case Color:
                                                        questionJson['question']['initValue'] =
                                                            {
                                                              'a': savedValue.a,
                                                              'r': savedValue.r,
                                                              'g': savedValue.g,
                                                              'b': savedValue.b,
                                                            };
                                                      case IconData:
                                                        questionJson['question']['initValue'] = {
                                                          'codePoint':
                                                              savedValue
                                                                  .codePoint,
                                                          'fontFamily':
                                                              savedValue
                                                                  .fontFamily,
                                                        };
                                                      default:
                                                        questionJson['question']['initValue'] =
                                                            savedValue;
                                                    }
                                                  }
                                                }
                                              }
                                              return _previewData[i]![qIndex];
                                            });
                                          });
                                        }

                                        for (
                                          int i = 0;
                                          i < widget.json!['screens'].length;
                                          i++
                                        ) {
                                          screens.add(
                                            FormPage.fromJson(
                                              widget.json!['screens'][i],
                                              isChangable: false,
                                              getJson: () async => widget.json!,
                                              onChanged: (qIndex, value) {
                                                // qIndex is the question's real
                                                // JSON index — matches our map key.
                                                setState(() {
                                                  _previewData[i]![qIndex] =
                                                      value;
                                                });
                                              },
                                              init: () => func(i),
                                            ),
                                          );
                                        }

                                        for (
                                          int i = 0;
                                          i < screens.length;
                                          i++
                                        ) {
                                          screens[i].previosPage = (i != 0)
                                              ? () {
                                                  screens[i - 1].load(
                                                    widget.json!['screens'][i -
                                                        1],
                                                    (qIndex, value) {
                                                      setState(() {
                                                        _previewData[i -
                                                                1]![qIndex] =
                                                            value;
                                                      });
                                                    },
                                                    () => func(i - 1),
                                                  );
                                                  return screens[i - 1];
                                                }
                                              : null;

                                          screens[i].nextPage =
                                              (i + 1 != screens.length)
                                              ? () {
                                                  screens[i + 1].load(
                                                    widget.json!['screens'][i +
                                                        1],
                                                    (qIndex, value) {
                                                      setState(() {
                                                        _previewData[i +
                                                                1]![qIndex] =
                                                            value;
                                                      });
                                                    },
                                                    () => func(i + 1),
                                                  );
                                                  return screens[i + 1];
                                                }
                                              : () => QrCode(
                                                  data: _previewData,
                                                  previosPage: () {
                                                    screens.last.load(
                                                      widget
                                                          .json!['screens'][screens
                                                              .length -
                                                          1],
                                                      (qIndex, value) {
                                                        setState(() {
                                                          _previewData[screens
                                                                      .length -
                                                                  1]![qIndex] =
                                                              value;
                                                        });
                                                      },
                                                      () => func(
                                                        screens.length - 1,
                                                      ),
                                                    );
                                                    return screens.last;
                                                  },
                                                );
                                        }

                                        return screens[0];
                                      },
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(
                              double.infinity,
                              isPhone ? 60 : 70,
                            ),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
