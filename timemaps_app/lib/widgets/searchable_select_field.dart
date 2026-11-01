import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

class SearchableSelectField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<SearchableOption<T>> options;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final Widget? prefixIcon;

  const SearchableSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
  });

  @override
  State<SearchableSelectField<T>> createState() => _SearchableSelectFieldState<T>();
}

class _SearchableSelectFieldState<T> extends State<SearchableSelectField<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  void _openDropdown() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final overlay = Overlay.of(context);

    setState(() {
      _isOpen = true;
      _searchQuery = '';
      _searchController.clear();
    });

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            // Barrier to dismiss when tapping outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            // Anchored dropdown menu
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: SizedBox(
                width: size.width,
                child: Material(
                  elevation: 6,
                  shadowColor: AppTheme.primaryDark.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderStrong, width: 1.2),
                    ),
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: StatefulBuilder(
                      builder: (ctx, setMenuState) {
                        final query = _searchQuery.toLowerCase().trim();
                        final filtered = query.isEmpty
                            ? widget.options
                            : widget.options.where((o) {
                                final inLabel = o.label.toLowerCase().contains(query);
                                final inSub = o.subtitle?.toLowerCase().contains(query) ?? false;
                                return inLabel || inSub;
                              }).toList();

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Compact search input inside dropdown
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Filter ${widget.label}...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.accent),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setMenuState(() => _searchQuery = '');
                                          },
                                          child: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textMuted),
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.surfaceSubtle,
                                ),
                                onChanged: (val) {
                                  setMenuState(() => _searchQuery = val);
                                },
                              ),
                            ),

                            const Divider(height: 1, color: AppTheme.borderSubtle),

                            // Filtered options list
                            Flexible(
                              child: filtered.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Text(
                                        'No matching items found',
                                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      shrinkWrap: true,
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) => const Divider(
                                        height: 1,
                                        indent: 12,
                                        endIndent: 12,
                                        color: AppTheme.borderSubtle,
                                      ),
                                      itemBuilder: (context, index) {
                                        final opt = filtered[index];
                                        final isSelected = opt.value == widget.value;

                                        return InkWell(
                                          onTap: () {
                                            widget.onChanged(opt.value);
                                            _closeDropdown();
                                          },
                                          child: Container(
                                            color: isSelected ? AppTheme.infoBg.withOpacity(0.5) : null,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        opt.label,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                          color: isSelected ? AppTheme.accent : AppTheme.textMain,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (opt.subtitle != null) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          opt.subtitle!,
                                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.check_circle_rounded,
                                                    size: 16,
                                                    color: AppTheme.accent,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  String get _displayLabel {
    final match = widget.options.where((o) => o.value == widget.value).toList();
    if (match.isNotEmpty) {
      return match.first.label;
    }
    return widget.hintText ?? 'Select ${widget.label}';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.options.any((o) => o.value == widget.value);

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label.isNotEmpty ? widget.label : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                _isOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                color: _isOpen ? AppTheme.accent : AppTheme.textMuted,
                size: 24,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isOpen ? AppTheme.accent : AppTheme.borderSubtle,
                width: _isOpen ? 1.5 : 1.0,
              ),
            ),
            filled: true,
            fillColor: _isOpen ? Colors.white : AppTheme.surfaceSubtle,
          ),
          child: Text(
            _displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              color: hasValue ? AppTheme.textMain : AppTheme.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
