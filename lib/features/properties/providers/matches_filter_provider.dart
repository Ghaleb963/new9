import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/matching_service.dart';
import 'property_provider.dart';
import '../../../core/theme/app_theme.dart';

enum ScoreFilter { all, excellent, good, partial }

extension ScoreFilterExt on ScoreFilter {
  String get label {
    switch (this) {
      case ScoreFilter.all:
        return 'الكل';
      case ScoreFilter.excellent:
        return 'ممتاز ≥85%';
      case ScoreFilter.good:
        return 'جيد 70-84%';
      case ScoreFilter.partial:
        return 'جزئي <70%';
    }
  }

  Color get color {
    switch (this) {
      case ScoreFilter.all:
        return AppTheme.textHigh;
      case ScoreFilter.excellent:
        return AppTheme.accentGreen;
      case ScoreFilter.good:
        return AppTheme.accentGreenGlow;
      case ScoreFilter.partial:
        return AppTheme.accentAmber;
    }
  }
}

class MatchesFilterState {
  final ScoreFilter scoreFilter;
  final String? selectedProvince;

  const MatchesFilterState({
    this.scoreFilter = ScoreFilter.all,
    this.selectedProvince,
  });

  MatchesFilterState copyWith({
    ScoreFilter? scoreFilter,
    String? Function()? selectedProvince,
  }) {
    return MatchesFilterState(
      scoreFilter: scoreFilter ?? this.scoreFilter,
      selectedProvince:
          selectedProvince != null ? selectedProvince() : this.selectedProvince,
    );
  }
}

class MatchesFilterNotifier extends StateNotifier<MatchesFilterState> {
  MatchesFilterNotifier() : super(const MatchesFilterState());

  void setScoreFilter(ScoreFilter filter) {
    state = state.copyWith(scoreFilter: filter);
  }

  void setProvince(String? province) {
    state = state.copyWith(selectedProvince: () => province);
  }
}

final matchesFilterProvider =
    StateNotifierProvider<MatchesFilterNotifier, MatchesFilterState>((ref) {
  return MatchesFilterNotifier();
});

/// Filters matches by score and province.
/// Returns AsyncValue since allMatchesProvider is now a FutureProvider.
final filteredMatchesProvider =
    FutureProvider<List<MatchResult>>((ref) async {
  final allMatchesAsync = ref.watch(allMatchesProvider);
  final filter = ref.watch(matchesFilterProvider);

  return allMatchesAsync.when(
    data: (allMatches) {
      return allMatches.where((m) {
        switch (filter.scoreFilter) {
          case ScoreFilter.excellent:
            if (m.score < 0.85) return false;
          case ScoreFilter.good:
            if (m.score < 0.70 || m.score >= 0.85) return false;
          case ScoreFilter.partial:
            if (m.score >= 0.70) return false;
          case ScoreFilter.all:
            break;
        }
        if (filter.selectedProvince != null &&
            m.offer.province != filter.selectedProvince) {
          return false;
        }
        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Extracts unique provinces from all matches.
final availableProvincesProvider = FutureProvider<List<String>>((ref) async {
  final allMatchesAsync = ref.watch(allMatchesProvider);

  return allMatchesAsync.when(
    data: (allMatches) {
      return allMatches.map((m) => m.offer.province).toSet().toList()..sort();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
