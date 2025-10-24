import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';

class LatestStoriesPage extends StatelessWidget {
  final NewsController newsController = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Color palette yang kreatif
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFFD166);

  LatestStoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: Theme.of(context).colorScheme.surface,
        color: primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [_buildCreativeAppBar(context), _buildContentSection()],
        ),
      ),
      floatingActionButton: _buildCreativeFAB(context),
    );
  }

  // ====================================================================
  // 🎨 CREATIVE APP BAR dengan GetX Reactive
  // ====================================================================

  SliverAppBar _buildCreativeAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final expandedHeight = isTablet ? 220.0 : 180.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      flexibleSpace: _buildFlexibleSpaceBar(context, isTablet, expandedHeight),
    );
  }

  Widget _buildFlexibleSpaceBar(
    BuildContext context,
    bool isTablet,
    double expandedHeight,
  ) {
    return FlexibleSpaceBar(
      collapseMode: CollapseMode.pin,
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor, accentColor],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBarHeader(isTablet),
                const Spacer(),
                _buildMainTitle(context, isTablet),
                const SizedBox(height: 12),
                _buildArticleCounter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarHeader(bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGlassButton(
          onTap: () => Get.back(),
          icon: Icons.arrow_back_rounded,
          isTablet: isTablet,
        ),
        Row(
          children: [
            _buildGlassButton(
              onTap: _handleRefresh,
              icon: Icons.refresh_rounded,
              isTablet: isTablet,
            ),
            const SizedBox(width: 12),
            _buildGlassButton(
              onTap: _showFilterSheet,
              icon: Icons.filter_list_rounded,
              isTablet: isTablet,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onTap,
    required IconData icon,
    required bool isTablet,
  }) {
    final size = isTablet ? 50.0 : 44.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Icon(icon, color: Colors.white, size: size * 0.5),
        ),
      ),
    );
  }

  Widget _buildMainTitle(BuildContext context, bool isTablet) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Stories',
                  style:
                      Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: isTablet ? 42 : 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ) ??
                      TextStyle(
                        fontSize: isTablet ? 42 : 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArticleCounter(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Obx(() {
              final articleCount = newsController.articles.length;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '$articleCount ${articleCount == 1 ? 'story' : 'stories'} collected',
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ) ??
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ====================================================================
  // 📱 CONTENT SECTION dengan GetX Reactive
  // ====================================================================

  Widget _buildContentSection() {
    return Obx(() {
      if (newsController.isLoading.value && newsController.articles.isEmpty) {
        return _buildCreativeShimmerLoading();
      }

      if (newsController.articles.isEmpty) {
        return _buildCreativeEmptyState();
      }

      return _buildStoriesGrid();
    });
  }

  Widget _buildStoriesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1200;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
        final spacing = isTablet ? 20.0 : 16.0;
        final padding = isTablet ? 24.0 : 16.0;

        if (crossAxisCount == 1) {
          return SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final article = newsController.articles[index];
                return _buildAnimatedStoryCard(
                  index,
                  NewsCard(
                    article: article,
                    showFavoriteButton: true,
                    isGrid: false,
                  ),
                );
              }, childCount: newsController.articles.length),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: isDesktop ? 0.8 : 0.85,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final article = newsController.articles[index];
              return _buildAnimatedStoryCard(
                index,
                NewsCard(
                  article: article,
                  showFavoriteButton: true,
                  isGrid: true,
                ),
              );
            }, childCount: newsController.articles.length),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedStoryCard(int index, Widget child) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: Transform.scale(scale: 0.95 + (value * 0.05), child: child),
          ),
        );
      },
      child: child,
    );
  }

  // ====================================================================
  // ⏳ LOADING STATE
  // ====================================================================

  Widget _buildCreativeShimmerLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final padding = isTablet ? 24.0 : 16.0;
        final crossAxisCount = isTablet ? 2 : 1;

        if (crossAxisCount == 1) {
          return SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildShimmerCard(isTablet),
                childCount: 6,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: EdgeInsets.all(padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildShimmerCard(isTablet),
              childCount: 6,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard(bool isTablet) {
    final theme = Theme.of(Get.context!);

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant,
      highlightColor: theme.colorScheme.surface,
      child: Container(
        height: isTablet ? 200 : 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: isTablet ? 120 : 80,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: Colors.grey[300]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 🎭 EMPTY STATE
  // ====================================================================

  Widget _buildCreativeEmptyState() {
    return SliverToBoxAdapter(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final theme = Theme.of(context);

          return TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Container(
                    height: isTablet ? 500 : 400,
                    margin: EdgeInsets.all(isTablet ? 32 : 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEmptyStateIcon(isTablet),
                        SizedBox(height: isTablet ? 40 : 32),
                        _buildEmptyStateText(context, theme),
                        SizedBox(height: isTablet ? 40 : 32),
                        _buildAnimatedRefreshButton(isTablet),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateIcon(bool isTablet) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1000),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: isTablet ? 140 : 120,
            height: isTablet ? 140 : 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.article_outlined,
              size: isTablet ? 60 : 50,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateText(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        Text(
          'No Stories Found',
          style:
              Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ) ??
              TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'It seems like there are no stories available at the moment. '
            'Check your connection or try refreshing to discover new content.',
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.6,
                ) ??
                TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedRefreshButton(bool isTablet) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: ElevatedButton.icon(
            onPressed: _handleRefresh,
            icon: Icon(Icons.refresh_rounded, size: isTablet ? 24 : 20),
            label: Text(
              'Refresh Stories',
              style: TextStyle(
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 24,
                vertical: isTablet ? 18 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
              shadowColor: primaryColor.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCreativeFAB(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: value,
            child: FloatingActionButton(
              onPressed: _showSearchSheet,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.search_rounded, size: 26),
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // 🔧 UTILITY FUNCTIONS dengan GetX
  // ====================================================================

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();

    // Show snackbar menggunakan GetX
    Get.showSnackbar(
      GetSnackBar(
        message: 'Getting latest stories...',
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        duration: const Duration(seconds: 2),
        backgroundColor: primaryColor,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        snackPosition: SnackPosition.BOTTOM,
      ),
    );

    await newsController.refreshNews();
  }

  void _showFilterSheet() {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  Get.context!,
                ).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Filter Stories',
              style:
                  Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ) ??
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Advanced filtering options coming soon!',
                style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      isScrollControlled: false,
    );
  }

  void _showSearchSheet() {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      Container(
        height: Get.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(
                  Get.context!,
                ).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search stories...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Theme.of(Get.context!).colorScheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Theme.of(
                        Get.context!,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Search functionality\ncoming soon!',
                      textAlign: TextAlign.center,
                      style: Theme.of(Get.context!).textTheme.bodyLarge
                          ?.copyWith(
                            color: Theme.of(
                              Get.context!,
                            ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
