import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/database_service.dart';
import 'package:scouting_qr_maker/main.dart';
import 'package:scouting_qr_maker/question.dart';
import 'package:scouting_qr_maker/widgets/demacia_app_bar.dart';
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
    this.currentFormId,
  }) : questions = questions ?? {},
       onSave = onSave ?? (() => Future.value({})) {
    print('🟦🟦🟦🟦🟦id: ${currentFormId}🟧🟧🟦🟦🟦🟦');
  }

  int index;
  String name;
  IconData icon;
  Color color;
  int? currentFormId;

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
    Widget Function()? nextPage,
    Widget Function()? previosPage,
    void Function(int, dynamic)? onChanged,
    int? id,
    required Map<int, dynamic Function()?>? Function() init,
  }) {
    Map<int, (Question, dynamic)> questions = {};
    print('🛑🛑🛑🛑🛑🛑🛑🛑🛑id: $id 🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑🛑');
    List? questionsList;
    print('question type: ${json['question'].runtimeType}');
    print('🛑🛑🛑JSON DATA IN FROMJSON: $json 🛑🛑🛑');
    if (json['questions'] != null && json['questions'] is List) {
      questionsList = json['questions'] as List;
    } else if (json['question'] != null && json['question'] is List) {
      questionsList = json['question'] as List;
    }

    if (questionsList != null && questionsList.isNotEmpty) {
      for (var question in questionsList) {
        if (question is! Map<String, dynamic>) continue;

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
    }

    print('🧸ྀི🧸ྀི🧸ྀི🧸ྀི🧸ྀི🧸ྀི name: ${json['name']}🧸ྀི🧸ྀི🧸ྀི🧸ྀི');
    return FormPage(
      questions: questions,
      isChangable: isChangable,
      index: json['index'] as int,
      name: json['name'] as String? ?? 'Untitled',
      icon: json['icon'] != null
          ? IconData(
              json['icon']['codePoint'] as int,
              fontFamily: json['icon']['fontFamily'] as String,
            )
          : Icons.article,
      color: json['color'] != null
          ? Color.from(
              alpha: json['color']['a'],
              red: json['color']['r'],
              green: json['color']['g'],
              blue: json['color']['b'],
            )
          : Colors.blue,
      onSave: getJson,
      previosPage: previosPage,
      nextPage: nextPage,
      currentFormId: id,
    );
  }

  load(
    Map<String, dynamic> json,
    void Function(int, dynamic)? onChanged,
    Map<int, dynamic Function()?>? Function() init,
  ) {
    questions = {};

    final List<dynamic> questionsList =
        (json['questions'] as List?) ??
        (json['question'] as List?) ??
        const [];

    for (final q in questionsList) {
      if (q is! Map<String, dynamic>) continue;

      final qIndex = q['index'] as int;
      final initMap = init();
      final innerFn = initMap?[qIndex];

      questions[qIndex] = (
        Question.fromJson(
          q,
          isChangable: false,
          onChanged: onChanged,
          init: innerFn != null ? () => innerFn() : () => null,
        ),
        '\u200B',
      );
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
                    print('form page!');
                    save(
                      widget.toJson(),
                      MainApp.currentSave,
                      widget.currentFormId,
                    );
                    print('form id: ${MainApp.currentSave.formId}');
                    print(
                      '🟧🟧🟧🟧🟧🟧form id: ${widget.currentFormId}🟧🟧🟧🟧🟧🟧',
                    );
                    await DatabaseService().updateForm(
                      formData: widget.toJson(),
                      id:
                          widget.currentFormId ??
                          MainApp
                              .currentSave
                              .formId!, //MainApp.currentSave.formId!,
                    );
                  }
                  as void Function(),
          onLongSave: () async {
            print('form page!');
            return longSave(
              await widget.onSave(),
              context,
              () => setState(() {}),
              widget.currentFormId,
            );
          },
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
