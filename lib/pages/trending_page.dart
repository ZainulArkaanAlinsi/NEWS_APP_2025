import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';

class TrendingPage extends StatefulWidget {
  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage>
    with SingleTickerProviderStateMixin {
  final NewsController newsController = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final TrendingController trendingController = Get.put(TrendingController());

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Enhanced color scheme dengan gradient yang lebih menarik
  static const Color primaryTrendColor = Color(0xFFFF6B6B);
  static const Color secondaryTrendColor = Color(0xFF4ECDC4);
  static const Color accentTrendColor = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Auto refresh saat membuka halaman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newsController.articles.isEmpty) {
        newsController.fetchTopHeadlines();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    trendingController.scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: () async => trendingController.handleRefresh(),
        color: primaryTrendColor,
        backgroundColor: Theme.of(context).colorScheme.surface,
        strokeWidth: 3,
        displacement: 40,
        child: CustomScrollView(
          controller: trendingController.scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [_buildEnhancedAppBar(context), _buildContentSection()],
        ),
      ),
      floatingActionButton: _buildFloatingActions(context),
    );
  }

  // ====================================================================
  // 🎨 ENHANCED APP BAR WITH GLASS MORPHISM
  // ====================================================================

  SliverAppBar _buildEnhancedAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.background.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back & Title Section
                          Row(
                            children: [
                              _buildGlassActionButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Get.back(),
                                context: context,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trending Now',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      foreground: Paint()
                                        ..shader =
                                            const LinearGradient(
                                              colors: [
                                                primaryTrendColor,
                                                accentTrendColor,
                                              ],
                                            ).createShader(
                                              const Rect.fromLTWH(
                                                0,
                                                0,
                                                200,
                                                70,
                                              ),
                                            ),
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildArticleCount(context),
                                ],
                              ),
                            ],
                          ),
                          // Enhanced Refresh Button
                          _buildGlassActionButton(
                            icon: Icons.autorenew_rounded,
                            onTap: trendingController.handleRefresh,
                            context: context,
                            isRefresh: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Article Count dengan animasi
  Widget _buildArticleCount(BuildContext context) {
    return Obx(() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Text(
          newsController.articles.isEmpty
              ? 'Discover hot topics 🔥'
              : '${newsController.articles.length} trending stories',
          key: ValueKey<int>(newsController.articles.length),
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }

  // ====================================================================
  // 🎯 CONTENT SECTION dengan GetX Reactive
  // ====================================================================

  Widget _buildContentSection() {
    return Obx(() {
      if (newsController.isLoading.value && newsController.articles.isEmpty) {
        return _buildShimmerLoading();
      }

      if (newsController.hasError.value) {
        return _buildErrorState();
      }

      if (newsController.articles.isEmpty && !newsController.isLoading.value) {
        return _buildEnhancedEmptyState(context);
      }

      return _buildEnhancedTrendingList();
    });
  }

  // ====================================================================
  // 🔥 GLASS MORPHISM ACTION BUTTONS
  // ====================================================================

  Widget _buildGlassActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required BuildContext context,
    bool isRefresh = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ]
                  : [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isRefresh
                ? (isDarkMode ? accentTrendColor : primaryTrendColor)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 📈 ENHANCED TRENDING LIST WITH STAGGERED ANIMATIONS
  // ====================================================================

  Widget _buildEnhancedTrendingList() {
    return Obx(() {
      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = newsController.articles[index];

          return AnimatedContainer(
            duration: Duration(milliseconds: 400 + (index * 100)),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.fromLTRB(
              20,
              index == 0 ? 20 : 8,
              20,
              index == newsController.articles.length - 1 ? 20 : 8,
            ),
            child: _buildTrendingCard(article, index, context),
          );
        }, childCount: newsController.articles.length),
      );
    });
  }

  Widget _buildTrendingCard(article, int index, BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          NewsCard(article: article, isGrid: false),
          // Trending badge untuk top 3
          if (index < 3) _buildTrendingBadge(index),
        ],
      ),
    );
  }

  Widget _buildTrendingBadge(int index) {
    final badgeColors = [
      [const Color(0xFFFFD700), const Color(0xFFFFA000)], // Gold
      [const Color(0xFFC0C0C0), const Color(0xFF808080)], // Silver
      [const Color(0xFFCD7F32), const Color(0xFF8B4513)], // Bronze
    ];

    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: badgeColors[index],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: badgeColors[index][0].withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              '#${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // ⏳ SHIMMER LOADING EFFECT
  // ====================================================================

  Widget _buildShimmerLoading() {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceVariant,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ),
        );
      }, childCount: 6),
    );
  }

  // ====================================================================
  // 🎭 ENHANCED EMPTY STATE
  // ====================================================================

  Widget _buildEnhancedEmptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Container(
                height: 500,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEmptyStateIllustration(),
                    const SizedBox(height: 40),
                    Text(
                      'No Trending Stories',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'The news cycle is quiet right now. Check back later for breaking stories and viral content!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildEnhancedRefreshButton(context),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyStateIllustration() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsating circles
          ...List.generate(3, (index) {
            return AnimatedContainer(
              duration: Duration(seconds: 2 + index),
              curve: Curves.easeInOut,
              width: 180 - (index * 40),
              height: 180 - (index * 40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryTrendColor.withOpacity(0.1 - (index * 0.03)),
                border: Border.all(
                  color: primaryTrendColor.withOpacity(0.2 - (index * 0.06)),
                  width: 2,
                ),
              ),
            );
          }),
          // Main icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryTrendColor, secondaryTrendColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryTrendColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRefreshButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: trendingController.handleRefresh,
      icon: const Icon(Icons.autorenew_rounded, size: 22),
      label: const Text('Refresh Feed'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTrendColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 8,
        shadowColor: primaryTrendColor.withOpacity(0.4),
      ),
    );
  }

  // ====================================================================
  // ⚠️ ERROR STATE
  // ====================================================================

  Widget _buildErrorState() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Container(
                height: 400,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Connection Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Unable to load trending news. Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: trendingController.handleRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ====================================================================
  // 🎯 FLOATING ACTION BUTTONS
  // ====================================================================

  Widget _buildFloatingActions(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Scroll to top button
                FloatingActionButton(
                  onPressed: trendingController.scrollToTop,
                  mini: true,
                  backgroundColor: primaryTrendColor,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.arrow_upward_rounded),
                ),
                const SizedBox(height: 12),
                // Quick filter button
                FloatingActionButton(
                  onPressed: trendingController.showFilterOptions,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  child: const Icon(Icons.filter_list_rounded),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TrendingController extends GetxController {
  final NewsController newsController = Get.find<NewsController>();
  final ScrollController scrollController = ScrollController();

  final RxBool showScrollToTop = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to scroll events
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (scrollController.offset > 400 && !showScrollToTop.value) {
      showScrollToTop.value = true;
    } else if (scrollController.offset <= 400 && showScrollToTop.value) {
      showScrollToTop.value = false;
    }
  }

  Future<void> handleRefresh() async {
    await newsController.fetchTopHeadlines();

    // Enhanced GetX Snackbar
    Get.showSnackbar(
      GetSnackBar(
        message: 'Updating trending stories...',
        backgroundColor: TrendingPage.primaryTrendColor.withOpacity(0.9),
        borderRadius: 15,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 400),
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.autorenew_rounded, color: Colors.white),
        shouldIconPulse: true,
        mainButton: TextButton(
          onPressed: () => Get.back(),
          child: const Text(
            'DISMISS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    Get.snackbar(
      'Scrolling to Top',
      'Taking you back to the latest stories',
      backgroundColor: TrendingPage.primaryTrendColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void showFilterOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  Get.context!,
                ).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Filter Trends',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            // Filter options
            ListTile(
              leading: Icon(
                Icons.trending_up_rounded,
                color: TrendingPage.primaryTrendColor,
              ),
              title: Text(
                'Top Stories',
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onSurface,
                ),
              ),
              trailing: const Icon(Icons.radio_button_checked_rounded),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: Icon(
                Icons.schedule_rounded,
                color: TrendingPage.primaryTrendColor,
              ),
              title: Text(
                'Latest',
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onSurface,
                ),
              ),
              trailing: const Icon(Icons.radio_button_unchecked_rounded),
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TrendingPage.primaryTrendColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
