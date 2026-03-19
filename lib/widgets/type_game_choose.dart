import 'package:flutter/material.dart';

class typeGameChoose extends StatefulWidget {
  const typeGameChoose({super.key});

  @override
  State<typeGameChoose> createState() => _typeGameChoose();
}

class _typeGameChoose extends State<typeGameChoose>{
  String? _selected;

  final List<String> _opsean =['qual','Playoof', "final"];

  @override
  Widget build(BuildContext context){
    return DropdownButton<String>(
      hint: const Text("cose game type"),
      value: _selected,
      items: _opsean.map((option){
        return DropdownMenuItem<String>(
          value:option,
          child: Text(option),
        );
      }).toList(),
        onChanged: (value){
          setState((){
            _selected =value;
          });
        }
      );
  }
}