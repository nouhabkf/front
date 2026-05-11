import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../data/models/location_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';
import '../widgets/community_accessible_map.dart';

/// Écran principal du module Communauté : carte OSM + marqueurs filtrables (comme Transport).
class CommunityLocationsScreen extends ConsumerStatefulWidget {
  const CommunityLocationsScreen({super.key});

  @override
  ConsumerState<CommunityLocationsScreen> createState() =>
      _CommunityLocationsScreenState();
}

class _CommunityLocationsScreenState
    extends ConsumerState<CommunityLocationsScreen> {
  LocationCategory? _selectedCategory;
  String _searchQuery = '';

  List<LocationModel> _filterLocations(List<LocationModel> locations) {
    var filtered = locations.toList();
    if (_selectedCategory != null) {
      filtered = filtered
          .where((loc) => loc.categorie == _selectedCategory)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((loc) =>
              loc.nom.toLowerCase().contains(query) ||
              loc.ville.toLowerCase().contains(query) ||
              loc.adresse.toLowerCase().contains(query))
          .toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final locationsAsync = ref.watch(locationsProvider);

    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
          // Barre d'actions (remplace AppBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  strings.communityPlaces,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => context.push('/submit-location'),
                  tooltip: strings.submitNewPlace,
                ),
              ],
            ),
          ),
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: strings.searchAccessiblePlaces,
                prefixIcon: Icon(Icons.search, color: primary),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          // Filtres par catégorie
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: strings.allCategories,
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...LocationCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _CategoryChip(
                      label: category.displayName,
                      selected: _selectedCategory == category,
                      onTap: () => setState(() => _selectedCategory = category),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Carte + marqueurs (filtres = recherche + catégories)
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                final filtered = _filterLocations(locations);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(locationsProvider);
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
                                  locations: filtered,
                                  onLocationTap: (loc) => context.push(
                                    '/location-detail/${loc.id}',
                                  ),
                                ),
                              ),
                              if (filtered.isEmpty)
                                Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(16),
                                      color: theme.colorScheme.surface
                                          .withValues(alpha: 0.94),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_off,
                                              size: 48,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              strings.noPlacesFound,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              strings.tryDifferentFilters,
                                              textAlign: TextAlign.center,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.errorLoadingPlaces,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(locationsProvider),
                      child: Text(strings.retry),
                    ),
                  ],
                ),
              ),
            ),
          ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              minimum: EdgeInsets.zero,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/submit-location'),
                icon: const Icon(Icons.add),
                label: Text(strings.submitNewPlace),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
