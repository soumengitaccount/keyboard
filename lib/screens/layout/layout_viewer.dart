import 'package:flutter/material.dart';

import '../../app/colors.dart';

class LayoutViewer extends StatefulWidget {
  const LayoutViewer({
    super.key,
  });

  @override
  State<LayoutViewer> createState() => _LayoutViewerState();
}

class _LayoutViewerState extends State<LayoutViewer> {
  String selectedLayout = "Avro Phonetic";

  final layouts = [
    "Avro Phonetic",
    "Probhat",
    "National",
  ];

  final keyboardRows = [
    [
      KeyMapping(
        key: "Q",
        value: "ক",
      ),
      KeyMapping(
        key: "W",
        value: "ও",
      ),
      KeyMapping(
        key: "E",
        value: "এ",
      ),
      KeyMapping(
        key: "R",
        value: "র",
      ),
      KeyMapping(
        key: "T",
        value: "ত",
      ),
      KeyMapping(
        key: "Y",
        value: "য়",
      ),
      KeyMapping(
        key: "U",
        value: "উ",
      ),
      KeyMapping(
        key: "I",
        value: "ই",
      ),
      KeyMapping(
        key: "O",
        value: "অ",
      ),
      KeyMapping(
        key: "P",
        value: "প",
      ),
    ],
    [
      KeyMapping(
        key: "A",
        value: "আ",
      ),
      KeyMapping(
        key: "S",
        value: "স",
      ),
      KeyMapping(
        key: "D",
        value: "দ",
      ),
      KeyMapping(
        key: "F",
        value: "ফ",
      ),
      KeyMapping(
        key: "G",
        value: "গ",
      ),
      KeyMapping(
        key: "H",
        value: "হ",
      ),
      KeyMapping(
        key: "J",
        value: "জ",
      ),
      KeyMapping(
        key: "K",
        value: "ক",
      ),
      KeyMapping(
        key: "L",
        value: "ল",
      ),
    ],
    [
      KeyMapping(
        key: "Z",
        value: "য",
      ),
      KeyMapping(
        key: "X",
        value: "শ",
      ),
      KeyMapping(
        key: "C",
        value: "চ",
      ),
      KeyMapping(
        key: "V",
        value: "ভ",
      ),
      KeyMapping(
        key: "B",
        value: "ব",
      ),
      KeyMapping(
        key: "N",
        value: "ন",
      ),
      KeyMapping(
        key: "M",
        value: "ম",
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          "Keyboard Layout",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(
          height: 20,
        ),
        DropdownButtonFormField<String>(
          initialValue: selectedLayout,
          decoration: const InputDecoration(
            labelText: "Layout",
            border: OutlineInputBorder(),
          ),
          items: layouts
              .map(
                (layout) => DropdownMenuItem(
                  value: layout,
                  child: Text(layout),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedLayout = value;
              });
            }
          },
        ),
        const SizedBox(
          height: 30,
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            children: keyboardRows
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Wrap(
                      spacing: 10,
                      children: row
                          .map(
                            (key) => KeyboardKey(
                              mapping: key,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class KeyMapping {
  final String key;

  final String value;

  const KeyMapping({
    required this.key,
    required this.value,
  });
}

class KeyboardKey extends StatefulWidget {
  final KeyMapping mapping;

  const KeyboardKey({
    super.key,
    required this.mapping,
  });

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          pressed = true;
        });
      },
      onExit: (_) {
        setState(() {
          pressed = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 120,
        ),
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: pressed
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.mapping.key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              widget.mapping.value,
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
