import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/icons_list.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class IconPicker extends QuestionType {
  IconPicker({super.key, void Function(IconData icon)? onChanged, this.initValue})
    : onChanged = onChanged ?? ((p0) {});

  void Function(IconData icon) onChanged;
  IconData Function()? initValue;

  @override
  State<IconPicker> createState() => _IconPickerState();

  @override
  Map<String, dynamic> toJson() => {
    'initValue': {
      'codePoint': initValue != null ? initValue!().codePoint : '',
      'fontFamily': initValue != null ? initValue!().fontFamily : '',
    }
  };

  factory IconPicker.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(IconData)? onChanged,
    dynamic init
  }) => IconPicker(
    key: key, 
    onChanged: onChanged,
    initValue: init != null && init() != null && init is IconData Function()? 
    ? init 
    : (json['initValue']['codePoint'] != '')
      ? () => IconData(
          json['icon']['codePoint'] as int,
          fontFamily: json['icon']['codePoint'] as String,
        )
      : null,
  );

  @override
  Widget settings(void Function(IconPicker p1) onChanged) => Container();
}

class _IconPickerState extends State<IconPicker> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder: (context, controller) {
        if (widget.initValue != null) {
          setState(() {
            controller.text = icons.entries.where((p0) => p0.value == widget.initValue!).firstOrNull?.key ?? '';
          });
        }
        return SearchBar(
          controller: controller,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          onTap: () => controller.openView(),
          onChanged: (value) => controller.openView(),
          leading: const Icon(Icons.search),
        );
      },
      suggestionsBuilder: (context, controller) {
        final filteredIcons = icons.entries
            .where(
              (e) =>
                  e.key.toLowerCase().contains(controller.text.toLowerCase()),
            )
            .toList();

        return [
          SizedBox(
            height: 720,
            child: GridView.builder(
              itemCount: filteredIcons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final e = filteredIcons[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      controller.closeView(e.key);
                      widget.onChanged(e.value);
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value, size: 30),
                      Text(
                        e.key,
                        style: TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ];
      },
    );
  }
}