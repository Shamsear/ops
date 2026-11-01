import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'create_store_page.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
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
    final stores = _filteredStores;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Store Directory & Chains',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            Text(
              '${_allStores.length} Hypermarket Branches Active',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Stores',
            onPressed: _loadStores,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateOrEditStore(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Top Filter & Search Container
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search branch name, code, chain, or area...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.accent),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filters Row: Emirate & Chain Dropdowns
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedEmirate,
                                decoration: const InputDecoration(
                                  labelText: 'Filter Emirate',
                                  prefixIcon: Icon(Icons.location_city_outlined, size: 18),
                                ),
                                items: _emirates.map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedEmirate = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedChain,
                                decoration: const InputDecoration(
                                  labelText: 'Filter Chain',
                                  prefixIcon: Icon(Icons.shopping_bag_outlined, size: 18),
                                ),
                                items: _availableChains.map((c) {
                                  return DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedChain = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Results Summary Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: AppTheme.surfaceSubtle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${stores.length} of ${_allStores.length} Stores',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                        ),
                        if (_selectedEmirate != 'All' || _selectedChain != 'All')
                          InkWell(
                            onTap: () {
                              setState(() {
                                _selectedEmirate = 'All';
                                _selectedChain = 'All';
                              });
                            },
                            child: const Text(
                              'Reset Filters',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Store Cards List
                  Expanded(
                    child: stores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 44, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                const Text(
                                  'No stores match your search',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 6),
                                TextButton.icon(
                                  onPressed: () => _openCreateOrEditStore(),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Onboard New Store'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: stores.length,
                            itemBuilder: (ctx, idx) {
                              final store = stores[idx];
                              final chain = store.chain ?? store.retailer;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Row 1: Store Name & Customer Code Badge
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  store.storeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 14,
                                                    color: AppTheme.textMain,
                                                    letterSpacing: -0.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(Icons.storefront, size: 13, color: AppTheme.accent),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      chain,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        color: AppTheme.accent,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${store.emirate}${store.city != null ? " • ${store.city}" : ""}',
                                                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            label: store.customerCode != null
                                                ? '#${store.customerCode}'
                                                : (store.branchCode != null ? 'Br #${store.branchCode}' : store.emirate),
                                            variant: StatusVariant.info,
                                            fontSize: 10,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Divider(height: 1, color: AppTheme.borderSubtle),
                                      const SizedBox(height: 10),

                                      // Row 2: Field Contacts & Leads
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: AppTheme.purpleBg,
                                                  child: const Icon(Icons.supervisor_account, size: 14, color: AppTheme.purple),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'FIELD LEAD',
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.4),
                                                      ),
                                                      Text(
                                                        store.merchandiserLead ?? 'Supervisor Babar',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor: AppTheme.infoBg,
                                                  child: const Icon(Icons.person_pin, size: 14, color: AppTheme.info),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'SMN CONTACT',
                                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.4),
                                                      ),
                                                      Text(
                                                        store.smnContact ?? 'Assigned',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
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
                                      const SizedBox(height: 10),

                                      // Row 3: Action Buttons (Edit Store, Call)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              store.contactPerson != null ? 'Manager: ${store.contactPerson}' : 'Branch Manager Assigned',
                                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (store.contactPhone != null && store.contactPhone!.isNotEmpty)
                                                IconButton(
                                                  icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.success),
                                                  visualDensity: VisualDensity.compact,
                                                  tooltip: 'Call Manager',
                                                  onPressed: () => launchUrl(Uri.parse('tel:${store.contactPhone}')),
                                                ),
                                              OutlinedButton.icon(
                                                onPressed: () => _openCreateOrEditStore(store),
                                                style: OutlinedButton.styleFrom(
                                                  visualDensity: VisualDensity.compact,
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  minimumSize: const Size(0, 32),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                ),
                                                icon: const Icon(Icons.edit_outlined, size: 13),
                                                label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
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
