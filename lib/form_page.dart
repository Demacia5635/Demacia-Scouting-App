import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/question.dart';
import 'package:scouting_qr_maker/save.dart';
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
    'questions': questions.values.map((p0) => p0.$1.toJson()).toList(),
    'index': index,
    'name': name,
    'icon': {'codePoint': icon.codePoint, 'fontFamily': icon.fontFamily},
    'color': {'a': color.a, 'r': color.r, 'g': color.g, 'b': color.b},
  };

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

    for (var question in json['questions']) {
      final qIndex = question['index'] as int;

      final initMap = init();
      final innerFn = initMap?[qIndex];

      questions.addAll({
        qIndex: (
          Question.fromJson(
            question,
            isChangable: isChangable,
            onChanged: onChanged,
            init: innerFn != null ? () => innerFn() : () => null,
          ),
          '\u200B',
        ),
      });
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

  load(
    json,
    void Function(int, dynamic)? onChanged,
    Map<int, dynamic Function()?>? Function() init,
  ) {
    questions = {};
    for (var question in json['questions']) {
      final qIndex = question['index'] as int;

      final initMap = init();
      final innerFn = initMap?[qIndex];

      questions.addAll({
        qIndex: (
          Question.fromJson(
            question,
            isChangable: false,
            onChanged: onChanged,
            init: innerFn != null ? () => innerFn() : () => null,
          ),
          '\u200B',
        ),
      });
    }
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

    // Drag-and-drop removed — just render questions directly.
    for ((Question, dynamic) question in questionList) {
      x.add(question.$1);
    }

    return x;
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (widget.nextPage != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.nextPage!()),
        );
      }
    }

    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (widget.previosPage != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.previosPage!()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('in form page');
    return RawKeyboardListener(
      focusNode: focusNode,
      onKey: handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: DemaciaAppBar(
          onSave:
              () async {
                    save(widget.toJson(), MainApp.currentSave);
                    await DatabaseService().updateForm(
                      formData: widget.toJson(),
                      id: MainApp.currentSave.formId!,
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
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
                                child: const Icon(Icons.add),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 50),
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
                                      builder: (context) =>
                                          widget.previosPage!(),
                                    ),
                                  );
                                }
                              : null,
                          child: const Icon(Icons.navigate_before),
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
                          child: const Icon(Icons.navigate_next),
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
}
