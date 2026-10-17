import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import 'mu_chip.dart';
import 'mu_text_field.dart';

/// TagInput (components/TagInput.md): a field holding chips — zones, tags — with an inline text
/// to add one (Enter or a comma), Backspace removing the last, and a « 2/5 » counter.
class MuTagInput extends StatefulWidget {
  const MuTagInput({
    super.key,
    required this.label,
    required this.tags,
    required this.onChanged,
    this.max = 5,
    this.placeholder = 'Ajoute une zone',
    this.helper,
    this.suggestions = const [],
  });

  final String label;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final String placeholder;
  final String? helper;
  final List<String> suggestions;

  @override
  State<MuTagInput> createState() => _MuTagInputState();
}

class _MuTagInputState extends State<MuTagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final tag = raw.trim().replaceAll(',', '');
    _controller.clear();
    if (tag.isEmpty || widget.tags.contains(tag) || widget.tags.length >= widget.max) return;
    widget.onChanged([...widget.tags, tag]);
  }

  void _remove(String tag) => widget.onChanged([
    for (final t in widget.tags)
      if (t != tag) t,
  ]);

  @override
  Widget build(BuildContext context) {
    final c = context.mu;
    final full = widget.tags.length >= widget.max;
    final matching = [
      for (final s in widget.suggestions)
        if (!widget.tags.contains(s) &&
            _controller.text.isNotEmpty &&
            s.toLowerCase().startsWith(_controller.text.trim().toLowerCase()))
          s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MuFieldLabel(label: widget.label),
        const SizedBox(height: MuSpace.s2),
        GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: Container(
            constraints: const BoxConstraints(minHeight: MuSize.controlL),
            padding: const EdgeInsets.symmetric(horizontal: MuSpace.s3, vertical: MuSpace.s2),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: MuRadius.smAll,
              border: Border.all(color: _focus.hasFocus ? c.primary : c.borderControl),
            ),
            child: Wrap(
              spacing: MuSpace.s2,
              runSpacing: MuSpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final t in widget.tags)
                  MuChip(
                    label: t,
                    kind: MuChipKind.input,
                    size: MuChipSize.s,
                    onRemove: () => _remove(t),
                    removeLabel: 'Retirer $t',
                  ),
                if (!full)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120, minHeight: MuSize.controlS),
                    child: IntrinsicWidth(
                      child: Semantics(
                        textField: true,
                        label: widget.placeholder,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          style: MuType.body.copyWith(color: c.text),
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration.collapsed(
                            hintText: widget.tags.isEmpty ? widget.placeholder : null,
                            hintStyle: MuType.body.copyWith(color: c.textSecondary),
                          ),
                          inputFormatters: [LengthLimitingTextInputFormatter(24)],
                          onChanged: (v) {
                            if (v.endsWith(',')) {
                              _add(v);
                            } else {
                              setState(() {});
                            }
                          },
                          onSubmitted: _add,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (matching.isNotEmpty) ...[
          const SizedBox(height: MuSpace.s2),
          Wrap(
            spacing: MuSpace.s2,
            runSpacing: MuSpace.s2,
            children: [
              for (final s in matching.take(4))
                MuChip(label: s, size: MuChipSize.s, onSelected: (_) => _add(s)),
            ],
          ),
        ],
        const SizedBox(height: MuSpace.s1),
        Row(
          children: [
            if (widget.helper != null)
              Expanded(
                child: Text(widget.helper!, style: MuType.caption.copyWith(color: c.textSecondary)),
              )
            else
              const Spacer(),
            Text(
              '${widget.tags.length}/${widget.max}',
              style: MuType.caption.copyWith(color: full ? c.text : c.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
