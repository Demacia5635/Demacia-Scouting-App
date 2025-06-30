import 'package:flutter/material.dart';

abstract class QuestionType extends StatefulWidget {
  const QuestionType({super.key});

  Map<String, dynamic> toJson();
  Widget settings(void Function(QuestionType) onChanged);
}
