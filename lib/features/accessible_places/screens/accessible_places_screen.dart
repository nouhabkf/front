import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/accessibility/accessible_place.dart';
import '../../../providers/accessibility_places_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../community/widgets/community_accessible_map.dart';
import 'accessible_place_detail_screen.dart';

/// Écran "Accès & Lieux accessibles" : carte OSM, filtres et fiche détail IA.
class AccessiblePlacesScreen extends ConsumerStatefulWidget {
  const AccessiblePlacesScreen({super.key});

  @override
  ConsumerState<AccessiblePlacesScreen> createState() =>
      _AccessiblePlacesScreenState();
}

class _AccessiblePlacesScreenState
    extends ConsumerState<AccessiblePlacesScreen> {
  String _query = '';
  PlaceCategory? _categoryFilter;
  DisabilityType? _disabilityFilter;
  int _minScore = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final placesAsync = ref.watch(accessiblePlacesCatalogProvider);
    final backendOnlineAsync =
        ref.watch(accessibilityBackendOnlineProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.accessibilityMapPlacesTitle),
        actions: [
          IconButton(
            tooltip: 'Rafraîchir',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(accessiblePlacesCatalogProvider);
              ref.invalidate(accessibilityBackendOnlineProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _BackendStatusBar(online: backendOnlineAsync),
          _FiltersBar(
            query: _query,
            category: _categoryFilter,
            disability: _disabilityFilter,
            minScore: _minScore,
            onQueryChanged: (v) => setState(() => _query = v),
            onCategoryChanged: (v) => setState(() => _categoryFilter = v),
            onDisabilityChanged: (v) => setState(() => _disabilityFilter = v),
            onMinScoreChanged: (v) => setState(() => _minScore = v),
          ),
          Expanded(
            child: placesAsync.when(
              data: (all) {
                final filtered = _applyFilters(all);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(accessiblePlacesCatalogProvider);
                        ref.invalidate(accessibilityBackendOnlineProvider);
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: constraints.maxHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: CommunityAccessibleMap(
                                  locations: filtered
                                      .map((p) => p.toLocationModel())
                                      .toList(),
                                  onLocationTap: (loc) {
                                    final place = filtered.firstWhere(
                                      (p) => p.id == loc.id,
                                    );
                                    _openDetail(place);
                                  },
                                ),
                              ),
                              if (filtered.isEmpty)
                                Align(
                                  alignment: Alignment.center,
                                  child: _EmptyState(
                                    hasAny: all.isNotEmpty,
                                    onReset: () => setState(() {
                                      _query = '';
                                      _categoryFilter = null;
                                      _disabilityFilter = null;
                                      _minScore = 0;
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Impossible de charger le catalogue',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<AccessiblePlace> _applyFilters(List<AccessiblePlace> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (_categoryFilter != null && p.category != _categoryFilter) {
        return false;
      }
      if (_disabilityFilter != null &&
          !p.adaptedFor.contains(_disabilityFilter)) {
        return false;
      }
      if (p.accessibilityScore < _minScore) return false;
      if (q.isNotEmpty) {
        final hay = '${p.name} ${p.city} ${p.description}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.accessibilityScore.compareTo(a.accessibilityScore));
  }

  void _openDetail(AccessiblePlace place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccessiblePlaceDetailScreen(place: place),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Bandeau de statut backend
// ────────────────────────────────────────────────────────────────────────────
class _BackendStatusBar extends StatelessWidget {
  const _BackendStatusBar({required this.online});

  final AsyncValue<bool> online;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return online.when(
      data: (isOn) {
        if (isOn) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: cs.errorContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: cs.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Service IA Accessibilité hors ligne. Les scores temps réel ne seront pas disponibles.',
                  style: TextStyle(
                    color: cs.onErrorContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Barre de filtres
// ────────────────────────────────────────────────────────────────────────────
class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.query,
    required this.category,
    required this.disability,
    required this.minScore,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onDisabilityChanged,
    required this.onMinScoreChanged,
  });

  final String query;
  final PlaceCategory? category;
  final DisabilityType? disability;
  final int minScore;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PlaceCategory?> onCategoryChanged;
  final ValueChanged<DisabilityType?> onDisabilityChanged;
  final ValueChanged<int> onMinScoreChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un lieu (nom, ville, description)…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: onQueryChanged,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'Toutes catégories',
                  selected: category == null,
                  onTap: () => onCategoryChanged(null),
                ),
                for (final c in PlaceCategory.values)
                  _Chip(
                    label: c.label,
                    selected: category == c,
                    onTap: () =>
                        onCategoryChanged(category == c ? null : c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: 'Tous handicaps',
                  selected: disability == null,
                  onTap: () => onDisabilityChanged(null),
                ),
                for (final d in DisabilityType.values)
                  _Chip(
                    label: d.label,
                    selected: disability == d,
                    onTap: () =>
                        onDisabilityChanged(disability == d ? null : d),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Score min.'),
              Expanded(
                child: Slider(
                  value: minScore.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 10,
                  label: '$minScore',
                  onChanged: (v) => onMinScoreChanged(v.round()),
                ),
              ),
              SizedBox(width: 32, child: Text('$minScore')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: cs.primaryContainer,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAny, required this.onReset});

  final bool hasAny;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              hasAny
                  ? 'Aucun lieu ne correspond à vos filtres.'
                  : 'Catalogue vide.',
              style: theme.textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            if (hasAny) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Réinitialiser les filtres'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Permet une navigation programmatique depuis ailleurs dans l'app.
extension AccessiblePlacesNav on GoRouter {
  void goAccessiblePlaces() => go('/accessible-places');
}
