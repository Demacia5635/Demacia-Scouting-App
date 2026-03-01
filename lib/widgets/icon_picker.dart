import 'package:flutter/material.dart';
import 'package:scouting_qr_maker/widgets/icons_list.dart';
import 'package:scouting_qr_maker/widgets/question_type.dart';

class IconPicker extends QuestionType {
  IconPicker({
    super.key,
    void Function(IconData icon)? onChanged,
    this.initValue,
  }) : onChanged = onChanged ?? ((p0) {});

  void Function(IconData icon) onChanged;
  IconData Function()? initValue;

  @override
  State<IconPicker> createState() => _IconPickerState();

  @override
  Map<String, dynamic> toJson() => {
    'initValue': {
      'codePoint': initValue != null ? initValue!().codePoint : '',
      'fontFamily': initValue != null ? initValue!().fontFamily : '',
    },
  };

  factory IconPicker.fromJson(
    Map<String, dynamic> json, {
    Key? key,
    void Function(IconData)? onChanged,
    dynamic init,
  }) {
    // Dart erases generic types at runtime so `init is IconData Function()?`
    // always fails. Call init() and check if the result is an IconData instead.
    IconData Function()? resolvedInit;
    try {
      if (init != null) {
        final candidate = init();
        if (candidate is IconData) {
          resolvedInit = () => init() as IconData;
        }
      }
    } catch (_) {}
    //print('chose ICON 🟦🟦🟦🟦🟦🟦');
    return IconPicker(
      key: key,
      onChanged: onChanged,
      initValue:
          resolvedInit ??
          (json['initValue']['codePoint'] != ''
              ? () => IconData(
                  json['initValue']['codePoint'] as int,
                  fontFamily: json['initValue']['fontFamily'] as String,
                )
              : null),
    );
  }

  @override
  Widget settings(void Function(IconPicker p1) onChanged) => Container();
}

class _IconPickerState extends State<IconPicker> {
  // Own the SearchController here so we can set its text safely in initState,
  // before any build pass runs. Never mutate a controller inside builder().
  late final SearchController _searchController;

  @override
  void initState() {
    super.initState();

    _searchController = SearchController();

    // Set the initial text once, outside of any build callback.
    if (widget.initValue != null) {
      _searchController.text =
          icons.entries
              .where((p0) => p0.value == widget.initValue!())
              .firstOrNull
              ?.key ??
          '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: _searchController,
      builder: (context, controller) {
        // Never mutate controller.text here — it triggers AnimatedBuilder
        // during build and causes the "setState during build" error.
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
                    controller.closeView(e.key);
                    widget.onChanged(e.value);
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
