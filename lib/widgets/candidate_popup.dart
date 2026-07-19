import 'package:flutter/material.dart';

class CandidatePopup extends StatefulWidget {
  final List<String> candidates;

  final ValueChanged<String>? onSelected;

  const CandidatePopup({
    super.key,
    required this.candidates,
    this.onSelected,
  });

  @override
  State<CandidatePopup> createState() => _CandidatePopupState();
}

class _CandidatePopupState extends State<CandidatePopup> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return const SizedBox();
    }

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: Colors.black12,
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.candidates.length,
          itemBuilder: (context, index) {
            final selected = index == selectedIndex;

            return InkWell(
              onTap: () {
                widget.onSelected?.call(
                  widget.candidates[index],
                );
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 120,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: selected
                    ? Theme.of(context).colorScheme.primary.withValues(
                          alpha: .12,
                        )
                    : Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.candidates[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
