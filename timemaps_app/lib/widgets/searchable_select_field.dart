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
              offset: Offset(0, size.height + 4),
              child: SizedBox(
                width: size.width,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderStrong, width: 1.2),
                    ),
                    constraints: const BoxConstraints(maxHeight: 240),
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
                            // Compact search input directly inside popup
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: 'Search ${widget.label}...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
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
                                  ? Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'No matching results',
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                                      if (opt.subtitle != null)
                                                        Text(
                                                          opt.subtitle!,
                                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    size: 16,
                                                    color: AppTheme.accent,
                                                  ),
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
            contentPadding: widget.label.isEmpty ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14) : null,
            prefixIcon: widget.prefixIcon,
            suffixIcon: Icon(
              _isOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: AppTheme.textMuted,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isOpen ? AppTheme.accent : AppTheme.borderSubtle,
                width: _isOpen ? 1.5 : 1.0,
              ),
            ),
            filled: true,
            fillColor: AppTheme.surfaceSubtle,
          ),
          child: Text(
            _displayLabel,
            style: TextStyle(
              fontSize: 14,
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
