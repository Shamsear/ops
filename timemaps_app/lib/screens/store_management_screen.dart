import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
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

  Color _getRetailerColor(String retailer) {
    final r = retailer.toLowerCase();
    if (r.contains('lulu')) return AppTheme.success;
    if (r.contains('carrefour')) return AppTheme.accent;
    if (r.contains('coop')) return AppTheme.warning;
    if (r.contains('spinneys')) return AppTheme.accentTeal;
    return AppTheme.primaryDark;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final stores = _filteredStores;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Store Directory & Chains',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
            ),
            Text(
              '${_allStores.length} Hypermarket Branches Registered',
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
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
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
                  // Top Search & Filter Container
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
                    ),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                          decoration: InputDecoration(
                            hintText: 'Search branch name, code, chain, or area...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                            prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppTheme.accent),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 17, color: AppTheme.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            isDense: true,
                            filled: true,
                            fillColor: AppTheme.surfaceSubtle,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Filters Row: Emirate & Chain Dropdowns
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  border: Border.all(color: AppTheme.borderSubtle),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedEmirate,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                    items: _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedEmirate = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                  border: Border.all(color: AppTheme.borderSubtle),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _selectedChain,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                    items: _availableChains.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedChain = val);
                                    },
                                  ),
                                ),
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
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
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
                            child: const Text(
                              'Reset Filters',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent),
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
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.surfaceSubtle,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_off_rounded, size: 36, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No stores match your search criteria',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Try searching for another branch or onboard a new store',
                                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  onPressed: () => _openCreateOrEditStore(),
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Onboard New Store'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                            itemCount: stores.length,
                            itemBuilder: (ctx, idx) {
                              final store = stores[idx];
                              final chain = store.chain ?? store.retailer;
                              final retailerColor = _getRetailerColor(chain);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                  border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Emblem + Store Name + Customer Code
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: retailerColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: retailerColor.withOpacity(0.25)),
                                          ),
                                          child: Center(
                                            child: Text(
                                              chain.isNotEmpty ? chain[0] : 'S',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: retailerColor),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                store.storeName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13.5,
                                                  color: AppTheme.textMain,
                                                  letterSpacing: -0.2,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      chain,
                                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: retailerColor),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  const Text('•', style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                                                  const SizedBox(width: 5),
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
                                          maxWidth: 95,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 12),
                                    const Divider(height: 1, color: AppTheme.borderSubtle),
                                    const SizedBox(height: 10),

                                    // Row 2: Field Contacts & Leads
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppTheme.purpleBg,
                                                child: const Icon(Icons.supervisor_account_rounded, size: 14, color: AppTheme.purple),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'FIELD LEAD',
                                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.4),
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
                                                radius: 12,
                                                backgroundColor: AppTheme.infoBg,
                                                child: const Icon(Icons.person_pin_rounded, size: 14, color: AppTheme.info),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'SMN CONTACT',
                                                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.4),
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
                                    const SizedBox(height: 12),

                                    // Row 3: Action Buttons (Edit Store, Call)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            store.contactPerson != null ? 'Manager: ${store.contactPerson}' : 'Branch Manager Assigned',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (store.contactPhone != null && store.contactPhone!.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.phone_rounded, size: 18, color: AppTheme.success),
                                                visualDensity: VisualDensity.compact,
                                                tooltip: 'Call Manager',
                                                onPressed: () => launchUrl(Uri.parse('tel:${store.contactPhone}')),
                                              ),
                                            OutlinedButton.icon(
                                              onPressed: () => _openCreateOrEditStore(store),
                                              style: OutlinedButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                minimumSize: const Size(0, 32),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
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
