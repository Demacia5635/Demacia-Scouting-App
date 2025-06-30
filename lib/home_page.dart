import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/form_page.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/qr_code.dart';
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

class HomePageState extends State<HomePage> with RouteAware {
  @override
  void initState() {
    super.initState();

    loadData();
  }

  void loadData() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('app_data_${MainApp.currentSave.index}')) {
      setState(() {
        widget.json = jsonDecode(
          prefs.getString('app_data_${MainApp.currentSave.index}')!,
        );
      });
      return;
    }

    setState(() {
      widget.json = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    appBar: DemaciaAppBar(
      onSave: () =>
          widget.json != null ? save(widget.json!, MainApp.currentSave) : null,
      onLongSave: () => widget.json != null
          ? longSave(widget.json!, context, () => setState(() {}))
          : null,
    ),
    body: Stack(
      children: [
        SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              spacing: 40,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (widget.json != null && widget.json!.isNotEmpty) {
                            return ScreenManagerPage.fromJson(widget.json!);
                          }
                          return ScreenManagerPage();
                        },
                      ),
                    ).then((_) {
                      loadData();
                    });
                  },
                  child: ListTile(
                    title: Text("Editing Room"),
                    trailing: Icon(Icons.arrow_right_alt),
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          if (widget.json != null) {
                            List<FormPage> screens = [];

                            Map<int, Map<int, dynamic>> data = {};
                            Map<int, dynamic Function()?>? func(int i) {
                              return data[i]?.map<int, dynamic Function()?>((
                                qIndex,
                                savedValue,
                              ) {
                                return MapEntry(qIndex, () {
                                  if (savedValue != null) {
                                    if (savedValue is Set<Entry>) {
                                      widget.json!['screens'][i]['questions'][qIndex -
                                              1]['question']['initValue'] =
                                          savedValue
                                              .map((option) => option.toJson())
                                              .toList();
                                    } else {
                                      switch (savedValue.runtimeType) {
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
                                  getJson: () => widget.json!,
                                  onChanged: (p0, p1) {
                                    setState(() {
                                      data[i]![p0] = p1;
                                    });
                                  },
                                  // init: data[i]?.map<int, dynamic Function()?>((p0, p1) => MapEntry(p0, p1 != null ? () => 20.0 : () => 20.0)),
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
                                          widget.json!['screens'][screens
                                                  .length -
                                              1],
                                          (p0, p1) {
                                            setState(() {
                                              data[screens.length - 1]![p0] =
                                                  p1;
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
                  },
                  child: ListTile(
                    title: Text("Preview Room"),
                    trailing: Icon(Icons.arrow_right_alt),
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
