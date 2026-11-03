import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'empty_state.dart';

class SearchableOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SearchableOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class SearchableSelectField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<SearchableOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final bool allowCustomValue;
  final ValueChanged<String>? onCustomValueSubmitted;
  final bool isCompact;

  const SearchableSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.allowCustomValue = false,
    this.onCustomValueSubmitted,
    this.isCompact = false,
  });

  const SearchableSelectField.compact({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.allowCustomValue = false,
    this.onCustomValueSubmitted,
  }) : isCompact = true;

  String get _displayLabel {
    final match = options.where((o) => o.value == value).toList();
    if (match.isNotEmpty) {
      return match.first.label;
    }
    if (value != null && value.toString().isNotEmpty) {
      return value.toString();
    }
    return hintText ?? 'Select $label';
  }

  bool get _hasValue {
    if (value == null) return false;
    if (value is String && (value as String).trim().isEmpty) return false;
    return true;
  }

  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return _SearchableOptionsSheet<T>(
          label: label,
          currentValue: value,
          options: options,
          allowCustomValue: allowCustomValue,
          onCustomValueSubmitted: onCustomValueSubmitted,
          onSelected: (val) {
            Navigator.pop(ctx);
            onChanged(val);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return InkWell(
        onTap: () => _showSelectionSheet(context),
        borderRadius: BorderRadius.circular(AppRadius.inner),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hasValue ? AppColors.surface : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.inner),
            border: Border.all(
              color: _hasValue ? AppColors.borderStrong : AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[
                prefixIcon!,
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: Text(
                  _displayLabel,
                  style: AppText.bodySmall.copyWith(
                    fontWeight: _hasValue ? FontWeight.w700 : FontWeight.w500,
                    color: _hasValue ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label.toUpperCase(),
            style: AppText.micro.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: () => _showSelectionSheet(context),
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.borderSubtle, width: 1.0),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: AppSpacing.sm + 2),
                ],
                Expanded(
                  child: Text(
                    _displayLabel,
                    style: AppText.body.copyWith(
                      fontWeight: _hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: _hasValue ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchableOptionsSheet<T> extends StatefulWidget {
  final String label;
  final T? currentValue;
  final List<SearchableOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool allowCustomValue;
  final ValueChanged<String>? onCustomValueSubmitted;

  const _SearchableOptionsSheet({
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onSelected,
    this.allowCustomValue = false,
    this.onCustomValueSubmitted,
  });

  @override
  State<_SearchableOptionsSheet<T>> createState() => _SearchableOptionsSheetState<T>();
}

class _SearchableOptionsSheetState<T> extends State<_SearchableOptionsSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCustomSelect(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    if (widget.onCustomValueSubmitted != null) {
      widget.onCustomValueSubmitted!(clean);
    }
    if (T == String) {
      widget.onSelected(clean as T);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.85;
    final keyboardHeight = media.viewInsets.bottom;

    final q = _query.toLowerCase().trim();
    final filtered = q.isEmpty
        ? widget.options
        : widget.options.where((o) {
            final l = o.label.toLowerCase();
            final s = o.subtitle?.toLowerCase() ?? '';
            return l.contains(q) || s.contains(q);
          }).toList();

    final hasExactMatch = q.isNotEmpty &&
        widget.options.any((o) => o.label.toLowerCase() == q || o.value.toString().toLowerCase() == q);
    final showCustomOption = widget.allowCustomValue && q.isNotEmpty && !hasExactMatch;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),

            // Header Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select ${widget.label}',
                      style: AppText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Sticky Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: widget.allowCustomValue
                      ? 'Search or type new ${widget.label.toLowerCase()}...'
                      : 'Search ${widget.label}...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _query = val),
                onSubmitted: (val) {
                  final clean = val.trim();
                  if (clean.isEmpty) return;
                  if (filtered.isNotEmpty) {
                    widget.onSelected(filtered.first.value);
                  } else if (widget.allowCustomValue) {
                    _handleCustomSelect(clean);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.borderSubtle),

            // Custom Value Tile (if typed text is not in preset options)
            if (showCustomOption)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 6),
                child: AppCard.flat(
                  onTap: () => _handleCustomSelect(_query),
                  color: AppColors.primarySoft,
                  border: const BorderSide(color: AppColors.accent, width: 1.2),
                  child: Row(
                    children: [
                      const IconBox(
                        icon: Icons.add_circle_outline_rounded,
                        color: AppColors.accent,
                        isCompact: true,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Use "${_query.trim()}"',
                              style: AppText.bodyBold.copyWith(color: AppColors.accent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Tap or press Enter to apply this new ${widget.label.toLowerCase()}',
                              style: AppText.caption.copyWith(color: AppColors.accent),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.accent),
                    ],
                  ),
                ),
              ),

            // Option List
            Flexible(
              child: (filtered.isEmpty && !showCustomOption)
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No results found',
                      description: 'Try adjusting your search query.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                        vertical: 6,
                      ),
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final opt = filtered[index];
                        final isSelected = opt.value == widget.currentValue;

                        return AppCard.flat(
                          onTap: () => widget.onSelected(opt.value),
                          color: isSelected ? AppColors.primarySoft : AppColors.surfaceMuted,
                          border: isSelected
                              ? const BorderSide(color: AppColors.accent, width: 1.2)
                              : BorderSide.none,
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      opt.label,
                                      style: AppText.bodyBold.copyWith(
                                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (opt.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        opt.subtitle!,
                                        style: AppText.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: AppSpacing.sm),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
