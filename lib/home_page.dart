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

      // Load all saves from Supabase
      final savesData = await databaseService.getAllSaves();
      print('Fetched saves data: $savesData');

      if (savesData.isNotEmpty) {
        print('Successfully loaded ${savesData.length} saves from Supabase');

        // Convert JSON data to Save objects
        MainApp.saves = savesData.map((saveJson) {
          print('Parsing save JSON: $saveJson');
          return Save.fromJson(saveJson);
        }).toList();

        print('Loaded saves: ${MainApp.saves.map((s) => s.title).join(", ")}');
      } else {
        print('No saves found in Supabase, using default saves');
      }

      // Load the form data for the current save
      Map<String, dynamic>? formData;

      // First try SharedPreferences
      if (prefs.containsKey('app_data_${MainApp.currentSave.index}')) {
        final savedJson = prefs.getString(
          'app_data_${MainApp.currentSave.index}',
        );
        if (savedJson != null && savedJson.isNotEmpty) {
          formData = jsonDecode(savedJson);
          print(
            'Loaded form from SharedPreferences for save ${MainApp.currentSave.index}',
          );
        }
      }

      // If not in SharedPreferences, load from Supabase
      if (formData == null) {
        formData = await databaseService.getForm();
        print('Loaded form from Supabase');
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
          // Reload data when a save is loaded
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
                        ElevatedButton(
                          onPressed:
                              widget.json != null && widget.json!.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
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
                        ElevatedButton(
                          onPressed:
                              widget.json != null && widget.json!.isNotEmpty
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) {
                                        if (widget.json!.containsKey(
                                          'screens',
                                        )) {
                                          List<FormPage> screens = [];
                                          Map<int, Map<int, dynamic>> data = {};

                                          Map<int, dynamic Function()?>? func(
                                            int i,
                                          ) {
                                            return data[i]?.map<
                                              int,
                                              dynamic Function()?
                                            >((qIndex, savedValue) {
                                              return MapEntry(qIndex, () {
                                                if (savedValue != null) {
                                                  if (savedValue
                                                      is Set<Entry>) {
                                                    widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] =
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
                                                        widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] =
                                                            {
                                                              'a': savedValue.a,
                                                              'r': savedValue.r,
                                                              'g': savedValue.g,
                                                              'b': savedValue.b,
                                                            };
                                                      case IconData:
                                                        widget
                                                            .json!['screens'][i]['questions'][qIndex]['question']['initValue'] = {
                                                          'codePoint':
                                                              savedValue
                                                                  .codePoint,
                                                          'fontFamily':
                                                              savedValue
                                                                  .fontFamily,
                                                        };
                                                      default:
                                                        widget.json!['screens'][i]['questions'][qIndex]['question']['initValue'] =
                                                            savedValue;
                                                    }
                                                  }
                                                }
                                                return data[i]![qIndex];
                                              });
                                            });
                                          }

                                          for (
                                            int i = 0;
                                            i < widget.json!['screens'].length;
                                            i++
                                          ) {
                                            data[i] = {};
                                            for (
                                              int j = 0;
                                              j <
                                                  widget
                                                      .json!['screens'][i]['questions']
                                                      .length;
                                              j++
                                            ) {
                                              data[i]!.addAll({j: null});
                                            }

                                            screens.add(
                                              FormPage.fromJson(
                                                widget.json!['screens'][i],
                                                isChangable: false,
                                                getJson: () async =>
                                                    widget.json!,
                                                onChanged: (p0, p1) {
                                                  setState(() {
                                                    data[i]![p0] = p1;
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
                                                      widget
                                                          .json!['screens'][i -
                                                          1],
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
                                            screens[i].nextPage =
                                                (i + 1 != screens.length)
                                                ? () {
                                                    screens[i + 1].load(
                                                      widget
                                                          .json!['screens'][i +
                                                          1],
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
                                                        widget
                                                            .json!['screens'][screens
                                                                .length -
                                                            1],
                                                        (p0, p1) {
                                                          setState(() {
                                                            data[screens.length -
                                                                    1]![p0] =
                                                                p1;
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
                                        }
                                        return FormPage(index: 0);
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
