import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zernews/models/article.dart';

import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';
import '../widgets/category_chips.dart';

import 'search_page.dart';
import 'favorites_page.dart';
import 'trending_page.dart';
import 'latest_stories_page.dart';
import 'detail_page.dart';

class HomePage extends StatelessWidget {
  final NewsController newsController = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Color palette yang lebih kreatif
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFFD166);
  static const Color backgroundColor = Color(0xFFF7FFF7);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Panggil load news saat pertama kali build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newsController.articles.isEmpty) {
        newsController.loadNews();
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await newsController.refreshNews();
          },
          color: primaryColor,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildCreativeAppBar(context),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: _buildBreakingNewsSection(context)),
              SliverToBoxAdapter(child: _buildQuickActions(context)),
              SliverToBoxAdapter(child: _buildCategorySection(context)),
              SliverToBoxAdapter(child: _buildLatestNewsHeader(context)),
              _buildNewsListSection(context),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: newsController.isLoading.value
              ? _buildLoadingFAB(context)
              : _buildRefreshFAB(context),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ====================================================================
  // 🎨 APP BAR KREATIF
  // ====================================================================

  SliverAppBar _buildCreativeAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final opacity = (top - kToolbarHeight) / (140 - kToolbarHeight);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface.withOpacity(opacity.clamp(0, 1)),
                  theme.colorScheme.surface.withOpacity(
                    opacity.clamp(0, 1) * 0.8,
                  ),
                ],
              ),
              boxShadow: [
                if (opacity > 0.5)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1 * opacity),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                50 + (40 * (1 - opacity)),
                20,
                16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo dan Brand
                  _buildBrandSection(context, opacity),

                  // Menu Button
                  _buildMenuButton(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandSection(BuildContext context, double opacity) {
    final theme = Theme.of(context);

    return Transform.translate(
      offset: Offset(0, -20 * (1 - opacity)),
      child: Row(
        children: [
          // Animated Logo
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.4 * value),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Z',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Brand Text dengan animasi
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 600),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-20 * (1 - value), 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ZerNews',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'Stay Informed. Stay Ahead.',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceVariant.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<int>(
        icon: Icon(
          Icons.menu_rounded,
          color: theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
        tooltip: 'Menu',
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: _buildCreativeMenuListItem(
              context: context,
              icon: Icons.search_rounded,
              title: 'Search News',
              color: Colors.blue,
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: _buildCreativeMenuListItem(
              context: context,
              icon: Icons.favorite_rounded,
              title: 'My Favorites',
              color: Colors.pink,
            ),
          ),
          PopupMenuItem(
            value: 3,
            child: Obx(
              () => _buildCreativeMenuListItem(
                context: context,
                icon: themeController.isDarkMode.value
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                title: themeController.isDarkMode.value
                    ? 'Light Mode'
                    : 'Dark Mode',
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 1:
              Get.to(() => SearchPage());
              break;
            case 2:
              Get.to(() => FavoritesPage());
              break;
            case 3:
              themeController.toggleTheme();
              break;
          }
        },
      ),
    );
  }

  Widget _buildCreativeMenuListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 🚨 BREAKING NEWS SECTION
  // ====================================================================

  Widget _buildBreakingNewsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Breaking News Badge
              _buildBreakingNewsBadge(context),

              // Loading Indicator
              Obx(() {
                if (newsController.isLoading.value) {
                  return _buildCreativeLoadingIndicator();
                }
                return const SizedBox();
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Carousel
        Obx(() {
          if (newsController.isLoading.value &&
              newsController.articles.isEmpty) {
            return _buildCarouselShimmer(context);
          }

          if (newsController.articles.isEmpty) {
            return _buildEmptyCarousel(context);
          }

          final articles = newsController.articles.take(5).toList();
          return _buildNewsCarousel(context, articles);
        }),
      ],
    );
  }

  Widget _buildCarouselShimmer(BuildContext context) {
    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakingNewsBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, Colors.orange]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'BREAKING NEWS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeLoadingIndicator() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }

  Widget _buildNewsCarousel(BuildContext context, List<Article> articles) {
    return CarouselSlider(
      items: articles
          .map((article) => _buildCreativeNewsCard(context, article))
          .toList(),
      options: CarouselOptions(
        height: 240,
        viewportFraction: 0.85,
        initialPage: 0,
        enableInfiniteScroll: articles.length > 1,
        autoPlay: articles.length > 1,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOut,
        enlargeCenterPage: true,
        enlargeFactor: 0.18,
        scrollDirection: Axis.horizontal,
        onPageChanged: (index, reason) {
          // Optional: Add page change callback
        },
      ),
    );
  }

  Widget _buildCreativeNewsCard(BuildContext context, Article article) {
    final _ = Theme.of(context);

    return GestureDetector(
      onTap: () => Get.to(() => DetailPage(article: article)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar berita dengan loading state
              _buildCarouselImage(context, article),

              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source dan waktu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                article.source,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(article.publishedAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselImage(BuildContext context, Article article) {
    if (article.urlToImage != null && article.urlToImage!.isNotEmpty) {
      return Image.network(
        article.urlToImage!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageShimmer(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder(context);
        },
      );
    } else {
      return _buildImagePlaceholder(context);
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    );
  }

  // ====================================================================
  // ⚡ QUICK ACTIONS
  // ====================================================================

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCreativeQuickActionItem(
            context: context,
            icon: Icons.search_rounded,
            label: 'Search',
            onTap: () => Get.to(() => SearchPage()),
            color: Colors.blue,
          ),
          _buildCreativeQuickActionItem(
            context: context,
            icon: Icons.favorite_rounded,
            label: 'Favorites',
            onTap: () => Get.to(() => FavoritesPage()),
            color: Colors.pink,
          ),
          _buildCreativeQuickActionItem(
            context: context,
            icon: Icons.trending_up_rounded,
            label: 'Trending',
            onTap: () => Get.to(() => TrendingPage()),
            color: Colors.green,
          ),
          Obx(
            () => _buildCreativeQuickActionItem(
              context: context,
              icon: themeController.isDarkMode.value
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              label: 'Theme',
              onTap: () => themeController.toggleTheme(),
              color: Colors.amber.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeQuickActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // 📚 CATEGORY SECTION
  // ====================================================================

  Widget _buildCategorySection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Browse Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  'Swipe →',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CategoryChips(),
        ],
      ),
    );
  }

  // ====================================================================
  // 📰 LATEST NEWS HEADER
  // ====================================================================

  Widget _buildLatestNewsHeader(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Get.to(() => LatestStoriesPage()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.primary.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latest Stories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        '${newsController.articles.length} fresh articles',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 📱 NEWS LIST SECTION
  // ====================================================================

  Widget _buildNewsListSection(BuildContext context) {
    return Obx(() {
      if (newsController.isLoading.value && newsController.articles.isEmpty) {
        return SliverToBoxAdapter(child: _buildCreativeLoadingState(context));
      }

      if (newsController.errorMessage.isNotEmpty) {
        return SliverToBoxAdapter(child: _buildCreativeErrorState(context));
      }

      if (newsController.articles.isEmpty) {
        return SliverToBoxAdapter(child: _buildCreativeEmptyState(context));
      }

      // Skip artikel pertama karena sudah ditampilkan di carousel
      final articlesToShow = newsController.articles.skip(1).toList();

      if (articlesToShow.isEmpty) {
        return SliverToBoxAdapter(child: _buildCreativeEmptyState(context));
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Container(
            margin: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 0, 20, 16),
            child: NewsCard(article: articlesToShow[index], isGrid: false),
          );
        }, childCount: articlesToShow.length),
      );
    });
  }

  Widget _buildEmptyCarousel(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceVariant,
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_rounded,
              size: 50,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No breaking news',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pull to refresh',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativeLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeWidth: 3,
                  ),
                  Center(
                    child: Icon(
                      Icons.newspaper_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Curating Your News Feed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fetching the latest stories...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreativeErrorState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off_rounded, size: 50, color: Colors.orange),
          ),
          const SizedBox(height: 20),
          Text(
            'Connection Lost',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              newsController.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () => _handleRefresh(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreativeEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 50,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Articles Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check your connection and pull to refresh',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () => _handleRefresh(context),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 🔄 FLOATING ACTION BUTTONS
  // ====================================================================

  Widget _buildLoadingFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: null,
      backgroundColor: Colors.grey.shade300,
      foregroundColor: Colors.grey.shade600,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildRefreshFAB(BuildContext context) {
    final _ = Theme.of(context);

    return FloatingActionButton(
      onPressed: () => _handleRefresh(context),
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.refresh_rounded, size: 26),
    );
  }

  // ====================================================================
  // 🔧 UTILITY FUNCTIONS
  // ====================================================================

  void _handleRefresh(BuildContext context) {
    newsController.refreshNews();
    Get.snackbar(
      'Refreshing',
      'Getting latest updates...',
      backgroundColor: primaryColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${(difference.inDays / 7).floor()}w ago';
      }
    } catch (e) {
      return 'Recent';
    }
  }
}

extension on NewsController {
  void loadNews() {
    fetchTopHeadlines();
  }
}
