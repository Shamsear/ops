# Phase 0: UI/UX Audit & Inconsistency Baseline

**Baseline static analysis**: `flutter analyze` reported **0 issues found**.

## 1. LiquidGlassNavBar References (Read-Only)
- `lib/widgets/liquid_glass.dart:177`: Class definition of `LiquidGlassNavBar` (DO NOT TOUCH).
- `lib/screens/ops_dashboard_screen.dart:124`: Instantiation of `LiquidGlassNavBar` inside `Scaffold.bottomNavigationBar`.

## 2. Screen-by-Screen Inconsistency Matrix

| Screen | BackdropFilter | ImageFilter | LinearGradient | Color(0x | Colors. | fontSize: | Radius.circular | EdgeInsets.all |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `badge_tracker_screen.dart` | 0 | 0 | 0 | 0 | 9 | 18 | 0 | 3 |
| `create_badge_page.dart` | 0 | 0 | 0 | 0 | 7 | 13 | 0 | 5 |
| `create_collection_page.dart` | 1 | 1 | 0 | 1 | 9 | 28 | 15 | 11 |
| `create_drop_page.dart` | 1 | 1 | 0 | 1 | 9 | 28 | 15 | 11 |
| `create_project_page.dart` | 0 | 0 | 0 | 0 | 5 | 7 | 0 | 2 |
| `create_promoter_page.dart` | 0 | 0 | 0 | 0 | 8 | 12 | 0 | 3 |
| `create_schedule_page.dart` | 1 | 1 | 0 | 1 | 19 | 35 | 26 | 12 |
| `create_store_page.dart` | 0 | 0 | 0 | 0 | 9 | 16 | 0 | 4 |
| `login_screen.dart` | 0 | 0 | 0 | 1 | 4 | 11 | 0 | 3 |
| `operations_menu_page.dart` | 1 | 1 | 0 | 6 | 4 | 7 | 4 | 4 |
| `ops_dashboard_screen.dart` | 1 | 1 | 1 | 1 | 19 | 35 | 12 | 7 |
| `promoter_audit_page.dart` | 1 | 1 | 0 | 5 | 7 | 16 | 11 | 5 |
| `promoter_home_screen.dart` | 1 | 1 | 2 | 4 | 16 | 23 | 4 | 6 |
| `store_management_screen.dart` | 0 | 0 | 0 | 0 | 4 | 23 | 1 | 2 |
| `supervisor_hub_screen.dart` | 1 | 1 | 0 | 0 | 12 | 28 | 0 | 12 |
| `timemap_calendar_screen.dart` | 1 | 1 | 0 | 0 | 11 | 42 | 2 | 8 |

## 3. Findings & Unification Targets
- **Hardcoded Colors & Gradients**: Multiple screens use arbitrary `Colors.white`, `Colors.black.withOpacity`, and raw `Color(0x...)` constants instead of design system tokens.
- **Mismatched Backgrounds**: `login_screen`, `create_drop_page`, and `create_collection_page` use `AmbientMeshBackground` and `BackdropFilter` glass cards, whereas `create_project_page` and `create_store_page` use opaque white cards.
- **Typography Inconsistency**: Font sizes range arbitrarily from 8 to 20 with scattered weights rather than consuming `AppText` scale tokens.
- **Spacing & Radius Variance**: Border radii vary between 6, 8, 10, 12, 14, 16, 18, 20, 22, 28.
