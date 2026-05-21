import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../providers/matches_filter_provider.dart';
import '../services/matching_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../widgets/matches_widgets.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  Widget build(BuildContext context) {
    final allMatchesAsync = ref.watch(allMatchesProvider);
    final filteredAsync = ref.watch(filteredMatchesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: allMatchesAsync.when(
        data: (allMatches) {
          return filteredAsync.when(
            data: (filtered) {
              return _buildContent(context, ref, allMatches, filtered);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => _buildEmptyState(false),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (_, __) => _buildEmptyState(false),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<MatchResult> allMatches,
    List<MatchResult> filtered,
  ) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppTheme.bgPage,
          expandedHeight: allMatches.isEmpty ? 60 : 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(
              AppTheme.sp16,
              0,
              AppTheme.sp16,
              AppTheme.sp12,
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.compare_arrows_rounded,
                  color: AppTheme.accentGreen,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.sp8),
                const Text(
                  'لوحة التوافقات',
                  style: TextStyle(fontSize: AppTheme.fontLg),
                ),
                const Spacer(),
                if (allMatches.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.sp8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(
                        color: AppTheme.accentGreen.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${allMatches.length} توافق',
                      style: const TextStyle(
                        fontSize: AppTheme.fontXs,
                        color: AppTheme.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.bgPage, AppTheme.bgPage],
                ),
              ),
              child: allMatches.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.sp16,
                        AppTheme.sp16,
                        AppTheme.sp16,
                        56,
                      ),
                      child: StatsRow(matches: allMatches),
                    ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: FilterBar(
            scoreFilter: ref.watch(matchesFilterProvider).scoreFilter,
            selectedProvince: ref.watch(matchesFilterProvider).selectedProvince,
            onScoreChanged: (f) =>
                ref.read(matchesFilterProvider.notifier).setScoreFilter(f),
            onProvinceChanged: (p) =>
                ref.read(matchesFilterProvider.notifier).setProvince(p),
            availableProvinces: ref.watch(availableProvincesProvider).value ?? [],
          ),
        ),

        if (filtered.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(allMatches.isNotEmpty),
          )
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.sp16,
                AppTheme.sp8,
                AppTheme.sp16,
                4,
              ),
              child: Text(
                'يعرض ${filtered.length} من ${allMatches.length} توافق',
                style: const TextStyle(
                  fontSize: AppTheme.fontXs,
                  color: AppTheme.textLow,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => MatchPairCard(
                match: filtered[index],
                index: index,
              ),
              childCount: filtered.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.sp32)),
        ],
      ],
    );
  }
}

Widget _buildEmptyState(bool hasData) {
  return AppEmptyState(
    icon: Icons.compare_arrows_rounded,
    title: hasData ? 'لا نتائج تطابق الفلتر' : 'لا توجد توافقات بعد',
    subtitle: hasData
        ? 'جرّب تغيير معايير الفلترة'
        : 'أضف عروضاً وطلبات، وسيجري النظام التوافق تلقائياً',
  );
}
