import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/question.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
import 'package:scouting_qr_maker/widgets/editing_enum.dart';
import 'package:scouting_qr_maker/widgets/section_divider.dart';
import 'package:flutter/services.dart';

class FormPage extends StatefulWidget {
  FormPage({
    super.key,
    required this.index,
    this.name = 'Empty Form Name',
    this.icon = Icons.article,
    this.color = Colors.blue,
    Map<int, (Question, dynamic)>? questions,
    this.isChangable = false,
    Future<Map<String, dynamic>> Function()? onSave,
    this.nextPage,
    this.previosPage,
  }) : questions = questions ?? {},
       onSave = onSave ?? (() => Future.value({}));

  int index;
  String name;
  IconData icon;
  Color color;

  Map<int, (Question, dynamic)> questions;
  bool isChangable;

  Future<Map<String, dynamic>> Function() onSave;

  Widget Function()? nextPage;
  Widget Function()? previosPage;

  @override
  State<StatefulWidget> createState() => FormPageState();

  Map<String, dynamic> toJson() => {
    'questions': questions.values.map((p0) {
      final q = p0.$1.toJson();
      q['answer'] = _encodeAnswer(p0.$2);
      return q;
    }).toList(),
    'index': index,
    'name': name,
    'icon': {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily},
    'color': {'a': color.a, 'r': color.r, 'g': color.g, 'b': color.b},
  };

  static dynamic _encodeAnswer(dynamic v) {
    if (v == null) return null;
    if (v is Color) return {'__t': 'color', 'a': v.a, 'r': v.r, 'g': v.g, 'b': v.b};
    if (v is IconData) return {'__t': 'icon', 'codePoint': v.codePoint, 'fontFamily': v.fontFamily};
    // Selection: אצלך זה לפעמים Set<Entry>
    if (v is Set<Entry>) {
      return {'__t': 'entrySet', 'items': v.map((e) => e.toJson()).toList()};
    }
    return v; // int/bool/double/String/List/Map וכו'
  }

  static dynamic _decodeAnswer(dynamic v) {
    if (v == null) return null;
    if (v is Map && v['__t'] == 'color') {
      return Color.fromARGB(
        ((v['a'] as num).clamp(0, 1) * 255).round(),
        ((v['r'] as num).clamp(0, 1) * 255).round(),
        ((v['g'] as num).clamp(0, 1) * 255).round(),
        ((v['b'] as num).clamp(0, 1) * 255).round(),
      );
    }
    if (v is Map && v['__t'] == 'icon') {
      return IconData(v['codePoint'], fontFamily: v['fontFamily']);
    }
    if (v is Map && v['__t'] == 'entrySet') {
      final items = (v['items'] as List).cast<Map<String, dynamic>>();
      return items.map((e) => Entry.fromJson(e)).toSet();
    }
    return v;
  }

  factory FormPage.fromJson(
    Map<String, dynamic> json, {
    bool isChangable = false,
    Future<Map<String, dynamic>> Function()? getJson,
    FormPage Function()? nextPage,
    FormPage Function()? previosPage,
    void Function(int, dynamic)? onChanged,
    required Map<int, dynamic Function()?>? Function() init,
  }) {
    Map<int, (Question, dynamic)> questions = {};

    for (var qJson in json['questions']) {
  final qIndex = qJson['index'] as int;
  final rawAnswer = qJson['answer'];
  final decoded = _decodeAnswer(rawAnswer);

  // זה ה-callback שיעדכן גם את "העולם החיצוני" (אם יש)
  // וגם את המפה המקומית כדי ש-toJson תמיד יכיל answer מעודכן
  void handleChanged(int idx, dynamic value) {
    onChanged?.call(idx, value);
    final existing = questions[idx];
    if (existing != null) {
      questions[idx] = (existing.$1, value);
    }
  }

  final questionWidget = Question.fromJson(
    qJson,
    isChangable: isChangable,
    onChanged: handleChanged,
    init: () => decoded,
  );

  questions[qIndex] = (questionWidget, decoded);
}

    return FormPage(
      questions: questions,
      isChangable: isChangable,
      index: json['index'] as int,
      name: json['name'] as String,
      icon: IconData(
        json['icon']['codePoint'] as int,
        fontFamily: json['icon']['fontFamily'] as String,
      ),
      color: Color.from(
        alpha: json['color']['a'],
        red: json['color']['r'],
        green: json['color']['g'],
        blue: json['color']['b'],
      ),
      onSave: getJson,
      previosPage: previosPage,
      nextPage: nextPage,
    );
  }

  void load(
    Map<String, dynamic> json,
    void Function(int, dynamic)? onChanged, Map<int, Function()?>? Function() param2,
  ) {
    final Map<int, (Question, dynamic)> newQuestions = {};

    void handleChanged(int idx, dynamic value) {
      onChanged?.call(idx, value);
      final existing = newQuestions[idx];
      if (existing != null) {
        newQuestions[idx] = (existing.$1, value);
      }
    }

    for (var qJson in json['questions']) {
      final qIndex = qJson['index'] as int;
      final decoded = _decodeAnswer(qJson['answer']);

      final questionWidget = Question.fromJson(
        qJson,
        isChangable: false,
        onChanged: handleChanged,
        init: () => decoded,
      );

      newQuestions[qIndex] = (questionWidget, decoded);
    }

    questions = newQuestions;
  }
}

class FormPageState extends State<FormPage> {
  int currentIndex = -1;

  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    if (widget.isChangable) {
      for (Question question in widget.questions.values.map((p0) => p0.$1)) {
        question.onDelete = (int index) => setState(() {
          widget.questions.remove(index);
        });
      }
    }

    focusNode = FocusNode();

    final keyList = widget.questions.keys.toList();
    keyList.sort((p0, p1) => p0.compareTo(p1));
    currentIndex = keyList.isNotEmpty ? keyList.last : -1;
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
  }

  List<Widget> getQuestions() {
    List<Widget> x = [];
    List<(Question, dynamic)> questionList = widget.questions.values.toList();
    questionList.sort((p0, p1) => p0.$1.index.compareTo(p1.$1.index));

    if (widget.isChangable) {
      x.add(
        DragTarget<(Question, dynamic)>(
          onAcceptWithDetails: (data) {
            setState(() {
              for (var p0 in questionList) {
                p0.$1.index++;
              }
              data.data.$1.index = 0;
              questionList.sort((p0, p1) => p0.$1.index.compareTo(p1.$1.index));
              for (int i = 0; i < questionList.length; i++) {
                questionList[i].$1.index = i;
              }
            });
          },
          builder: (context, candidateData, rejectedData) {
            if (candidateData.isNotEmpty || rejectedData.isNotEmpty) {
              if (candidateData.first!.$1.index !=
                  questionList.first.$1.index) {
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 20),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.greenAccent.shade700,
                      width: 2,
                    ),
                  ),
                  constraints: BoxConstraints(minHeight: 50),
                );
              }
            }
            return Container(height: 50);
          },
        ),
      );
    }

    for ((Question, dynamic) question in questionList) {
      if (widget.isChangable) {
        x.add(
          Draggable<(Question, dynamic)>(
            data: question,
            feedback: IgnorePointer(child: Material(child: question.$1)),
            childWhenDragging: Opacity(opacity: 0.3, child: question.$1),
            child: question.$1,
          ),
        );
        x.add(
          DragTarget<(Question, dynamic)>(
            onAcceptWithDetails: (data) {
              setState(() {
                if (data.data.$1.index == question.$1.index) return;
                questionList
                    .where((p0) => p0.$1.index > question.$1.index)
                    .forEach((p0) => p0.$1.index++);
                data.data.$1.index = question.$1.index + 1;
                questionList.sort(
                  (p0, p1) => p0.$1.index.compareTo(p1.$1.index),
                );
                for (int i = 0; i < questionList.length; i++) {
                  questionList[i].$1.index = i;
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              if (candidateData.isNotEmpty) {
                if (candidateData.first!.$1.index != question.$1.index &&
                    candidateData.first!.$1.index != question.$1.index + 1) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 20),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.greenAccent.shade700,
                        width: 2,
                      ),
                    ),
                    constraints: BoxConstraints(minHeight: 50),
                  );
                }
              }
              return Container(height: 25);
            },
          ),
        );
      } else {
        x.add(question.$1);
      }
    }

    return x;
  }

  /// Handles raw keyboard events.
  void handleKeyEvent(RawKeyEvent event) {
    // Check if the event is a key down event and the pressed key is the Escape key.
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      // Check if there's a route to pop (i.e., not the very first screen)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Pop the current route
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // Check if there's a route to pop (i.e., not the very first screen)
      if (widget.nextPage != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.nextPage!()),
        );
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // Check if there's a route to pop (i.e., not the very first screen)
      if (widget.previosPage != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.previosPage!()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => RawKeyboardListener(
    focusNode: focusNode,
    onKey: handleKeyEvent,
    autofocus: true,
    child: Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: DemaciaAppBar(
        onSave:
            () async {
                  save(widget.toJson(), MainApp.currentSave);
                  await DatabaseService().uploadData(
                    table: 'data',
                    data: {'form': widget.toJson()},
                  );
                }
                as void Function(),
        onLongSave: () async =>
            longSave(await widget.onSave(), context, () => setState(() {})),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  SectionDivider(label: widget.name, lineColor: widget.color),

                  ...getQuestions(),

                  Row(
                    spacing: 10,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.isChangable
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentIndex++;
                                  widget.questions.addAll({
                                    currentIndex: (
                                      Question(
                                        key: Key((currentIndex).toString()),
                                        index: currentIndex,
                                        onDelete: (int index) {
                                          setState(() {
                                            widget.questions.remove(index);
                                          });
                                        },
                                        onDuplicate: (index) {
                                          setState(() {
                                            widget.questions.addAll({
                                              ++currentIndex: (
                                                Question.duplicate(
                                                  widget.questions[index]!.$1,
                                                  currentIndex,
                                                ),
                                                '',
                                              ),
                                            });
                                          });
                                        },
                                        isChangable: widget.isChangable,
                                        onChanged: (index, value) {
                                          widget.questions[index] = (
                                            widget.questions[index]!.$1,
                                            value,
                                          );
                                        },
                                      ),
                                      '\u200B',
                                    ),
                                  });
                                });
                              },
                              child: Icon(Icons.add),
                            )
                          : Container(),
                    ],
                  ),
                  SizedBox(height: 50),
                  Row(
                    spacing: 100,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: widget.previosPage != null
                            ? () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => widget.previosPage!(),
                                  ),
                                );
                              }
                            : null,
                        child: Icon(Icons.navigate_before),
                      ),
                      ElevatedButton(
                        onPressed: widget.nextPage != null
                            ? () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => widget.nextPage!(),
                                  ),
                                );
                              }
                            : null,
                        child: Icon(Icons.navigate_next),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
