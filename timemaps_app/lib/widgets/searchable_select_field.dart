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
            // Backdrop to dismiss
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            // Floating anchored dropdown
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: SizedBox(
                width: size.width,
                child: Material(
                  elevation: 12,
                  shadowColor: AppTheme.primaryDark.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      border: Border.all(color: AppTheme.borderStrong, width: 1.2),
                    ),
                    constraints: const BoxConstraints(maxHeight: 280),
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
                            // Search field inside dropdown
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMain, fontWeight: FontWeight.w600),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search ${widget.label}...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.accent),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
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
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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

                            // Filtered option list
                            Flexible(
                              child: filtered.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.search_off_rounded, size: 28, color: AppTheme.textLight),
                                          SizedBox(height: 6),
                                          Text(
                                            'No matching items found',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
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
                                            color: isSelected ? AppTheme.infoBg.withOpacity(0.6) : null,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                          color: isSelected ? AppTheme.accent : AppTheme.textMain,
                                                          letterSpacing: -0.1,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      if (opt.subtitle != null) ...[
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          opt.subtitle!,
                                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: const BoxDecoration(
                                                      color: AppTheme.accent,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.check_rounded,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
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
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: widget.label.isNotEmpty ? widget.label : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: widget.prefixIcon,
                  )
                : null,
            prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                _isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: _isOpen ? AppTheme.accent : AppTheme.textMuted,
                size: 22,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(
                color: _isOpen ? AppTheme.accent : AppTheme.borderSubtle,
                width: _isOpen ? 1.8 : 1.0,
              ),
            ),
            filled: true,
            fillColor: _isOpen ? Colors.white : AppTheme.surfaceSubtle,
          ),
          child: Text(
            _displayLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
              color: hasValue ? AppTheme.textMain : AppTheme.textLight,
              letterSpacing: -0.1,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
