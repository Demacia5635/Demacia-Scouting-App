import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/form_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/qr_code.dart';
import 'package:scouting_qr_maker/save.dart';
import 'package:scouting_qr_maker/screen_manager_page.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  Map<String, dynamic>? json;

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isLoading = true;
  late int currentFormId;

  Map<int, Map<int, dynamic>> _previewData = {};

  StreamSubscription? _savesSubscription;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _subscribeToSaves();
  }

  @override
  void dispose() {
    _savesSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToSaves() {
    setState(() => _isLoading = true);

    _savesSubscription?.cancel();
    _savesSubscription = _databaseService.getThreeLatestSavesStream().listen(
      (savesWithForms) async {
        int count = 0;
        // print('stream data: $savesWithForms');
        final prefs = await SharedPreferences.getInstance();
        print('is empty? ${savesWithForms.isEmpty}');
        if (savesWithForms.isNotEmpty) {
          MainApp.saves = savesWithForms.map((saveData) {
            final save = Save.fromJson(saveData);
            final formData = saveData['form'];
            print('is null? ${formData == null}');
            //print('form data: $formData');
            if (formData != null) {
              prefs.setString('app_data_${save.index}', jsonEncode(formData));
            }
            return save;
          }).toList();

          print('Stream update: ${MainApp.saves.length} saves');
          // print(
          //   'current save: ${MainApp.currentSave.formId}, idx: ${MainApp.currentSave.index}',
          // );

          currentFormId = savesWithForms[MainApp.currentSave.index]['id'];
          print('current form id: $currentFormId');
          count++;
        } else {
          print('Stream returned empty saves');
          print('idddddd: $currentFormId');
          currentFormId = await DatabaseService().getLatestFormId();
          print('current id: $currentFormId');
          /**'index': i,
            'title': 'Save #${i + 1}',
            'color': i == 0
                ? {'a': 1.0, 'r': 1.0, 'g': 0.0, 'b': 0.0} // Red
                : i == 1
                ? {'a': 1.0, 'r': 0.0, 'g': 1.0, 'b': 0.0} // Green
                : {'a': 1.0, 'r': 0.0, 'g': 0.0, 'b': 1.0}, // Blue
            'icon': {
              'codePoint': i == 0
                  ? Icons.filter_1.codePoint
                  : i == 1
                  ? Icons.filter_2.codePoint
                  : Icons.filter_3.codePoint,
              'fontFamily': 'MaterialIcons',
            },
            'form': sharedPreferences.getString('app_data_$i') != null
                ? (sharedPreferences.getString('app_data_$i')!)
                : "",
            'created_at': DateTime.now(),
          }); */
          Map<String, dynamic> saveforEmptyForm = {
            'index': count,
            'title': 'Save #${count + 1}',
            'color': count == 0
                ? {'a': 1.0, 'r': 1.0, 'g': 0.0, 'b': 0.0}
                : count == 1
                ? {'a': 1.0, 'r': 0.0, 'g': 1.0, 'b': 0.0}
                : {'a': 1.0, 'r': 0.0, 'g': 0.0, 'b': 1.0},
            'icon': {
              'codePoint': count == 0
                  ? Icons.filter_1.codePoint
                  : count == 1
                  ? Icons.filter_2.codePoint
                  : Icons.filter_3.codePoint,
              'fontFamily': 'MaterialIcons',
            },
            'form': prefs.getString('app_data_$count') ?? "",
            'created_at': DateTime.now().toIso8601String(),
          };
          MainApp.saves.add(Save.fromJson(saveforEmptyForm));
          count++;
        }

        Map<String, dynamic>? formData;

        final saveKey = 'app_data_${MainApp.currentSave.index}';
        if (prefs.containsKey(saveKey)) {
          final savedJson = prefs.getString(saveKey);
          print('saved data from pref: $savedJson');
          if (savedJson != null && savedJson.isNotEmpty) {
            formData = jsonDecode(savedJson);
            print('\n form data from prefs: $formData');
            // print(
            //   'Loaded form from SharedPreferences for save ${MainApp.currentSave.index}',
            // );
          }
        }

        if (formData == null) {
          formData = await _databaseService.getLatestFormData();
          print('Loaded latest form as fallback');
        }

        if (mounted) {
          setState(() {
            widget.json = formData;
            _isLoading = false;
            _initPreviewData();
          });

          print('Final json state: ${widget.json != null ? "loaded" : "null"}');
          if (widget.json != null && widget.json!.containsKey('screens')) {
            print('Form has ${widget.json!['screens']?.length ?? 0} screens');
          }
        }
      },
      onError: (e) {
        print('Stream error: $e');
        if (mounted) {
          setState(() {
            widget.json = null;
            _isLoading = false;
          });
        }
      },
    );
  }

  void loadData() {
    _subscribeToSaves();
  }

  void _initPreviewData() {
    print('json: ${widget.json}');
    if (widget.json == null ||
        (!widget.json!.containsKey('screens') &&
            !widget.json!.containsKey('questions'))) {
      _previewData = {};
      print('No screens found in JSON, preview data initialized as empty');
      return;
    }
    for (int i = 0; i < MainApp.saves.length; i++) {
      print('❗❗❗❗❗❗❗❗save: $i data: ${MainApp.saves[i].toJson()}❗❗❗❗❗❗');
    }
    print('Initializing preview data from JSON');
    final screens = widget.json!['screens'] == null
        ? widget.json!['questions'] as List
        : widget.json!['screens'] as List;
    print('screens: $screens');
    final updated = <int, Map<int, dynamic>>{};
    if (screens == widget.json!['screens']) {
      for (int i = 0; i < screens.length; i++) {
        print('questions in home page crash: ${screens[i]['questions']}');
        print('type: ${screens[i]['questions'].runtimeType}');

        if (screens[i]['questions'] == null) {
          for (int i = 0; i < updated.length; i++) {
            updated[i] = {};
          }
        } else {
          final questions = screens[i]['questions'] as List;
          updated[i] = {};
          for (final q in questions) {
            final qIndex = q['index'] as int;
            print('question index: $qIndex');
            print('\n');
            print('preview data before init: ${_previewData[i]?[qIndex]}');
            updated[i]![qIndex] = _previewData[i]?[qIndex];
          }
        }
      }
    } else if (screens == widget.json!['questions']) {
      updated[0] = {};
      for (final q in screens) {
        final qIndex = q['index'] as int;
        updated[0]![qIndex] = _previewData[0]?[qIndex];
      }
    }
    print('🛑🛑🛑🛑🛑🛑updated data $updated 🛑🛑🛑🛑🛑🛑');
    _previewData = updated;
    print('\n \n \n');
    print('Preview data initialized: $_previewData');
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
            print('home page!');
            save(widget.json!, MainApp.currentSave, currentFormId);
          }
        },
        onLongSave: () async {
          if (widget.json != null) {
            print('home page!');
            longSave(
              widget.json!,
              context,
              () => setState(() {}),
              currentFormId,
            );
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  if (widget.json != null &&
                                      widget.json!.isNotEmpty &&
                                      (widget.json!.containsKey('screens') ||
                                          widget.json!.containsKey(
                                            'questions',
                                          ))) {
                                    print(
                                      '🟧🟧🟧🟧🟧🟧🟧🟧home page id to screen manager $currentFormId🟧🟧🟧🟧🟧🟧🟧🟧🟧🟧',
                                    );
                                    return ScreenManagerPage.fromJson(
                                      widget.json!,
                                      currentFormId,
                                    );
                                  }
                                  // Empty/null form — open blank ScreenManagerPage
                                  return ScreenManagerPage(
                                    currentFormId: currentFormId,
                                  );
                                },
                              ),
                            ).then((_) => loadData());
                          },
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
                          onPressed: () {
                            if (widget.json == null ||
                                widget.json!.isEmpty ||
                                !widget.json!.containsKey('screens') ||
                                (widget.json!['screens'] as List).isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No form to preview yet. Create one in the Editing Room.',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  if (!widget.json!.containsKey('screens')) {
                                    return FormPage(index: 0);
                                  }

                                  List<FormPage> screens = [];

                                  // Simplified: just return saved values directly,
                                  // no JSON mutation needed.
                                  Map<int, dynamic Function()?>? func(int i) {
                                    print('func called for screen $i');
                                    print(
                                      'previewData[$i]: ${_previewData[i]}',
                                    );
                                    return _previewData[i]?.map<
                                      int,
                                      dynamic Function()?
                                    >(
                                      (qIndex, _) => MapEntry(qIndex, () {
                                        print(
                                          'init called for screen $i, question $qIndex, value: ${_previewData[i]?[qIndex]}',
                                        );
                                        return _previewData[i]?[qIndex];
                                      }),
                                    );
                                  }

                                  for (
                                    int i = 0;
                                    i < widget.json!['screens'].length;
                                    i++
                                  ) {
                                    print(
                                      '✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨b4 crash enter home page: ✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨',
                                    );
                                    screens.add(
                                      FormPage.fromJson(
                                        widget.json!['screens'][i],
                                        isChangable: false,
                                        getJson: () async => widget.json!,
                                        onChanged: (qIndex, value) {
                                          setState(() {
                                            print(
                                              'onChanged called: screen $i, question $qIndex, value: $value',
                                            );
                                            _previewData[i]![qIndex] = value;
                                          });
                                        },
                                        id: currentFormId,
                                        init: () => func(i),
                                      ),
                                    );
                                  }

                                  for (int i = 0; i < screens.length; i++) {
                                    screens[i].previosPage = (i != 0)
                                        ? () {
                                            screens[i - 1].load(
                                              widget.json!['screens'][i - 1],
                                              (qIndex, value) {
                                                setState(() {
                                                  _previewData[i - 1]![qIndex] =
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
                                              widget.json!['screens'][i + 1],
                                              (qIndex, value) {
                                                setState(() {
                                                  _previewData[i + 1]![qIndex] =
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
                                                widget.json!['screens'][screens
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
                                                () => func(screens.length - 1),
                                              );
                                              return screens.last;
                                            },
                                          );
                                  }

                                  return screens[0];
                                },
                              ),
                            );
                          },
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
