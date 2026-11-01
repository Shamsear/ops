import 'package:flutter_test/flutter_test.dart';
import 'package:timemaps_app/services/api_service.dart';

void main() {
  test('ApiService verifies live Supabase connectivity and data', () async {
    // 1. Auth Login Test
    final user = await ApiService.login('ops@imlme.com', 'admin123');
    expect(user, isNotNull);
    expect(user!.role, 'OPS_ADMIN');
    print('✅ Verified Login: ${user.name} (${user.role})');

    // 2. Stores Test
    final stores = await ApiService.getStores();
    expect(stores.length, greaterThanOrEqualTo(70));
    print('✅ Verified Stores count: ${stores.length}');

    // 3. Projects Test
    final projects = await ApiService.getProjects();
    expect(projects, isNotEmpty);
    print('✅ Verified Projects count: ${projects.length}');

    // 4. Badges Test
    final badges = await ApiService.getBadges();
    expect(badges, isNotEmpty);
    print('✅ Verified Badges count: ${badges.length}');
    print('   First badge: ${badges.first.promoterName} - ${badges.first.status} at ${badges.first.storeName}');

    // 5. Live Dashboard Test
    final dash = await ApiService.getLiveDashboard(date: '2026-11-01');
    expect(dash['kpis'], isNotNull);
    final kpis = dash['kpis'] as Map<String, dynamic>;
    print('✅ Verified Live Dashboard KPIs: $kpis');
    expect(kpis['live_stores_count'], greaterThan(0));
    expect(kpis['active_promoters_count'], greaterThan(0));
  });
}
