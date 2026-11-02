import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'create_store_page.dart';

class StoreManagementScreen extends StatefulWidget {
  final bool isEmbedded;
  const StoreManagementScreen({super.key, this.isEmbedded = false});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<StoreModel> _allStores = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedEmirate = 'All';
  String _selectedChain = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _emirates = [
    'All',
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Al Ain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    final stores = await ApiService.getStores();
    if (mounted) {
      setState(() {
        _allStores = stores;
        _isLoading = false;
      });
    }
  }

  List<String> get _availableChains {
    final chains = <String>{'All'};
    for (final s in _allStores) {
      final c = s.chain ?? s.retailer;
      if (c.isNotEmpty) chains.add(c);
    }
    return chains.toList()..sort();
  }

  List<StoreModel> get _filteredStores {
    return _allStores.where((s) {
      if (_selectedEmirate != 'All' && s.emirate != _selectedEmirate) return false;
      if (_selectedChain != 'All' && (s.chain ?? s.retailer) != _selectedChain) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.storeName.toLowerCase().contains(q);
        final matchCode = (s.customerCode ?? '').toLowerCase().contains(q);
        final matchChain = (s.chain ?? s.retailer).toLowerCase().contains(q);
        final matchCity = (s.city ?? '').toLowerCase().contains(q);
        if (!matchName && !matchCode && !matchChain && !matchCity) return false;
      }
      return true;
    }).toList();
  }

  void _openCreateOrEditStore([StoreModel? store]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateStorePage(storeToEdit: store),
      ),
    );
    if (result == true) {
      _loadStores();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stores = _filteredStores;

    return AppScreenScaffold(
      title: 'Store Network Directory',
      subtitle: '${_allStores.length} Hypermarket Branches Registered',
      leading: widget.isEmbedded ? null : const BackButton(color: AppColors.textPrimary),
      bottomClearance: widget.isEmbedded,
      onRefresh: _loadStores,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Refresh Stores',
          onPressed: _loadStores,
        ),
        AppButton(
          label: 'Add Store',
          icon: Icons.add_rounded,
          height: 36,
          width: 110,
          onPressed: () => _openCreateOrEditStore(),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Search Controls
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.cardPadCompact),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Input
                AppTextField(
                  controller: _searchController,
                  hint: 'Search branch name, code, chain, or area...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Horizontal Chain Filters
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableChains.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final chain = _availableChains[i];
                      return FilterPill(
                        label: chain,
                        isSelected: _selectedChain == chain,
                        onTap: () => setState(() => _selectedChain = chain),
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Horizontal Emirate Filters
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emirates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final em = _emirates[i];
                      return FilterPill(
                        label: em,
                        isSelected: _selectedEmirate == em,
                        onTap: () => setState(() => _selectedEmirate = em),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Count & Reset Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${stores.length} of ${_allStores.length} Stores',
                  style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                ),
                if (_selectedEmirate != 'All' || _selectedChain != 'All' || _searchQuery.isNotEmpty)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedEmirate = 'All';
                        _selectedChain = 'All';
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      'Reset Filters',
                      style: AppText.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Content Area
          if (_isLoading)
            const AppSkeletonList(count: 5)
          else if (stores.isEmpty)
            EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No stores found',
              description: 'Try adjusting your filters or search terms, or add a new supermarket branch.',
              actionLabel: 'Add New Store',
              onAction: () => _openCreateOrEditStore(),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
              itemBuilder: (ctx, idx) {
                final store = stores[idx];
                final chain = store.chain ?? store.retailer;

                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar, Store Name & Location, Badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InitialsAvatar(name: chain, size: 40),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  store.storeName,
                                  style: AppText.bodyBold,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        chain,
                                        style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('•', style: AppText.caption),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${store.emirate}${store.city != null ? " • ${store.city}" : ""}',
                                        style: AppText.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge(
                            label: store.customerCode != null
                                ? '#${store.customerCode}'
                                : (store.branchCode != null ? 'Br #${store.branchCode}' : store.emirate),
                            variant: StatusVariant.info,
                            maxWidth: 100,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Contacts Inner Tile
                      AppCard.flat(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const IconBox(
                                    icon: Icons.supervisor_account_rounded,
                                    color: AppColors.purple,
                                    isCompact: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('FIELD LEAD', style: AppText.micro.copyWith(color: AppColors.textMuted)),
                                        Text(
                                          store.merchandiserLead ?? 'Assigned Lead',
                                          style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  const IconBox(
                                    icon: Icons.person_pin_rounded,
                                    color: AppColors.accent,
                                    isCompact: true,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SMN CONTACT', style: AppText.micro.copyWith(color: AppColors.textMuted)),
                                        Text(
                                          store.smnContact ?? 'Coordinating',
                                          style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Footer Row: Branch Manager info & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              store.contactPerson != null ? 'Manager: ${store.contactPerson}' : 'Store Manager Assigned',
                              style: AppText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (store.contactPhone != null && store.contactPhone!.isNotEmpty) ...[
                                IconButton(
                                  icon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.success),
                                  tooltip: 'Call Manager',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                  onPressed: () => launchUrl(Uri.parse('tel:${store.contactPhone}')),
                                ),
                                const SizedBox(width: 4),
                              ],
                              AppButton.secondary(
                                label: 'Edit',
                                icon: Icons.edit_outlined,
                                height: 32,
                                width: 78,
                                onPressed: () => _openCreateOrEditStore(store),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
