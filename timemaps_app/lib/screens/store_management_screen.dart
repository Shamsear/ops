import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Store Directory & Chains',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('${_allStores.length} Hypermarket Branches Active',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Stores',
            onPressed: _loadStores,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateOrEditStore(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Search and Filters Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search bar
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search stores, codes, chains, or areas...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          filled: true,
                          fillColor: AppTheme.surfaceSubtle,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.borderSubtle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filters Row: Emirate & Chain Dropdowns
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedEmirate,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedChain,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                  items: _availableChains.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
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

                // Count Header Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.surfaceSubtle,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${stores.length} of ${_allStores.length} Stores',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                      ),
                      Text(
                        'Emirates: $_selectedEmirate • Chain: $_selectedChain',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),

                // Store Cards List
                Expanded(
                  child: stores.isEmpty
                      ? const Center(
                          child: Text(
                            'No stores match your search criteria.\nTap "+ Add Store" to onboard a new hypermarket.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
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
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: AppTheme.borderSubtle),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Store Name & Chain Badge
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
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '$chain • ${store.emirate}${store.city != null ? " • ${store.city}" : ""}',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Text(
                                            store.customerCode != null ? 'Cus #${store.customerCode}' : (store.branchCode != null ? 'Br #${store.branchCode}' : store.emirate),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary, fontFamily: 'monospace'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(color: AppTheme.borderSubtle, height: 1),
                                    const SizedBox(height: 8),

                                    // Row 2: Field Contacts & Leads
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('FIELD LEAD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                                              Text(store.merchandiserLead ?? 'Supervisor Babar', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('SMN CONTACT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textMuted)),
                                              Text(store.smnContact ?? 'Assigned', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Row 3: Action Buttons (Edit Store, Call)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          store.contactPerson != null ? 'In-Charge: ${store.contactPerson}' : 'Branch Manager Assigned',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                        ),
                                        Row(
                                          children: [
                                            if (store.contactPhone != null && store.contactPhone!.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.phone_outlined, size: 18, color: AppTheme.accentEmerald),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => launchUrl(Uri.parse('tel:${store.contactPhone}')),
                                              ),
                                            TextButton.icon(
                                              onPressed: () => _openCreateOrEditStore(store),
                                              style: TextButton.styleFrom(
                                                visualDensity: VisualDensity.compact,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              ),
                                              icon: const Icon(Icons.edit_outlined, size: 14),
                                              label: const Text('Edit Store', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
    );
  }
}
