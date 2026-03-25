import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'xp_card.dart';
import 'xp_input.dart';
import 'xp_premium.dart';

class XPMultiSelectField extends StatelessWidget {
  const XPMultiSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.values,
    required this.onChanged,
    this.minSelection = 0,
    this.maxSelection = 999,
  });

  final String label;
  final String hint;
  final List<String> options;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final int minSelection;
  final int maxSelection;

  Future<void> _open(BuildContext context) async {
    final searchController = TextEditingController();
    final selected = values.toSet();
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = options.where((option) {
              if (query.trim().isEmpty) return true;
              return option.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return XPPremiumSheet(
              title: label,
              subtitle: 'Select $minSelection-$maxSelection options.',
              footer: FilledButton(
                onPressed: selected.length < minSelection
                    ? null
                    : () {
                        onChanged(selected.toList()..sort());
                        Navigator.pop(sheetContext);
                      },
                child: const Text('Apply selection'),
              ),
              child: Column(
                children: [
                  XPTextField(
                    controller: searchController,
                    labelText: 'Search',
                    hintText: 'Filter options',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => setModalState(() => query = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final option in filtered)
                    CheckboxListTile(
                      value: selected.contains(option),
                      contentPadding: EdgeInsets.zero,
                      title: Text(option),
                      subtitle: selected.length >= maxSelection &&
                              !selected.contains(option)
                          ? const Text('Maximum reached')
                          : null,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            if (selected.length < maxSelection) {
                              selected.add(option);
                            }
                          } else {
                            selected.remove(option);
                          }
                        });
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return XPSection(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              values.isEmpty ? hint : values.join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: values.isEmpty ? AppTheme.textMuted : AppTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPSingleSelectField extends StatelessWidget {
  const XPSingleSelectField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  Future<void> _open(BuildContext context) async {
    final searchController = TextEditingController();
    String query = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = options.where((option) {
              if (query.trim().isEmpty) return true;
              return option.toLowerCase().contains(query.trim().toLowerCase());
            }).toList();

            return XPPremiumSheet(
              title: label,
              subtitle: 'Pick the best fit.',
              child: Column(
                children: [
                  XPTextField(
                    controller: searchController,
                    labelText: 'Search',
                    hintText: 'Filter options',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (value) => setModalState(() => query = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final option in filtered)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(option),
                      trailing: Icon(
                        value == option
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: value == option
                            ? AppTheme.primaryDeep
                            : AppTheme.textMuted,
                      ),
                      onTap: () {
                        onChanged(option);
                        Navigator.pop(sheetContext);
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return XPSection(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value ?? hint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: value == null ? AppTheme.textMuted : AppTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
