import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:zernews/models/article.dart';
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';

class FavoritesPage extends StatelessWidget {
  final NewsController controller = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  // Color palette yang lebih kreatif dan dinamis
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFFD166);
  static const Color darkPurple = Color(0xFF6A0572);

  get Lottie => null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Background gradient yang dinamis
          _buildAnimatedBackground(context),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // AppBar dengan efek glassmorphism
              _buildGlassAppBar(context),

              // Konten utama dengan berbagai state
              Obx(() {
                if (controller.isLoading.value) {
                  return _buildCreativeLoadingState(context);
                }
                if (controller.favoriteArticles.isEmpty) {
                  return _buildCreativeEmptyState(context);
                }
                return _buildCreativeFavoritesList();
              }),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // 🎨 BACKGROUND & APPBAR KREATIF
  // ====================================================================

  // Background dengan animasi gradient yang halus
  Widget _buildAnimatedBackground(BuildContext context) {
    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 1000),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.black, darkPurple.withOpacity(0.3), Colors.black87]
                : [Color(0xFFFFF9E6), Color(0xFFE6F7FF), Color(0xFFF0E6FF)],
          ),
        ),
      );
    });
  }

  // AppBar dengan efek glassmorphism
  SliverAppBar _buildGlassAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                Theme.of(context).colorScheme.surface.withOpacity(0.6),
              ],
            ),
          ),
          child: BackdropFilter(
            filter: ColorFilter.mode(
              Colors.white.withOpacity(0.1),
              BlendMode.srcOver,
            ),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // Back button dengan animasi
                        _buildAnimatedBackButton(context),
                        const SizedBox(width: 16),

                        // Title dengan animasi
                        Expanded(child: _buildAnimatedTitleSection(context)),

                        // Clear All button dengan kondisi
                        Obx(() {
                          if (controller.favoriteArticles.isEmpty) {
                            return const SizedBox(width: 44);
                          }
                          return _buildAnimatedClearButton(context);
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // 🔘 BUTTONS & INTERACTIVE ELEMENTS
  // ====================================================================

  // Back button dengan animasi hover
  Widget _buildAnimatedBackButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(44),
                  onTap: () => Get.back(),
                  onHover: (hovering) {
                    // Hover effect bisa ditambahkan dengan state management
                  },
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Clear button dengan animasi
  Widget _buildAnimatedClearButton(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 500),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(44),
                  onTap: _showCreativeClearAllDialog,
                  child: Icon(
                    Icons.delete_sweep_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Title section dengan animasi
  Widget _buildAnimatedTitleSection(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Reading Sanctuary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Obx(() {
                  final count = controller.favoriteArticles.length;
                  return Text(
                    count == 0
                        ? 'Your wisdom collection awaits'
                        : '${count} precious insight${count > 1 ? 's' : ''} collected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // 📚 FAVORITES LIST KREATIF
  // ====================================================================

  Widget _buildCreativeFavoritesList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: Obx(() {
        return SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final article = controller.favoriteArticles[index];
            return _buildAnimatedNewsCard(article, index);
          }, childCount: controller.favoriteArticles.length),
        );
      }),
    );
  }

  // News card dengan animasi staggered
  Widget _buildAnimatedNewsCard(Article article, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 200)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Transform.scale(
              scale: 0.95 + (value * 0.05),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: NewsCard(
                      article: article,
                      showFavoriteButton: true,
                      isGrid: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // 🎭 EMPTY STATE KREATIF
  // ====================================================================

  SliverToBoxAdapter _buildCreativeEmptyState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            SizedBox(
              height: 200,
              child: Lottie.asset(
                'assets/animations/empty-favorites.json', // Ganti dengan path Lottie Anda
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 30),

            // Animated Title
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Text(
                      'Your Reading Oasis Awaits',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            // Animated Description
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1200),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: Text(
                      'This is your personal knowledge sanctuary. Every article you save becomes a building block in your castle of wisdom.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),

            // Animated Button
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 30),
                    child: ElevatedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.explore_rounded, size: 20),
                      label: const Text('Begin Your Journey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 8,
                        shadowColor: primaryColor.withOpacity(0.4),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // ⏳ LOADING STATE KREATIF
  // ====================================================================

  SliverToBoxAdapter _buildCreativeLoadingState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Animation
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Typing Animation Text
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        'Curating Your Wisdom Collection',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preparing insights tailored just for you...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 🗑️ DIALOG KREATIF
  // ====================================================================

  void _showCreativeClearAllDialog() {
    final theme = Theme.of(Get.context!);

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Icon
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 600),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_delete_rounded,
                          size: 40,
                          color: primaryColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 25),

                // Title dengan animasi
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 10),
                        child: Text(
                          'Clear Your Sanctuary?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),

                // Description
                Text(
                  'This will remove all ${controller.favoriteArticles.length} carefully collected articles from your personal library. This journey cannot be reversed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // Action Buttons dengan animasi staggered
                Row(
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset((1 - value) * -20, 0),
                              child: OutlinedButton(
                                onPressed: () => Get.back(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 1200),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset((1 - value) * 20, 0),
                              child: ElevatedButton(
                                onPressed: () {
                                  controller.clearAllFavorites();
                                  Get.back();
                                  _showCreativeSuccessSnackbar();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Clear All',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Snackbar dengan animasi
  void _showCreativeSuccessSnackbar() {
    Get.snackbar(
      'Sanctuary Cleansed!',
      'Your reading space is now fresh and empty',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: secondaryColor.withOpacity(0.9),
      colorText: Colors.white,
      borderRadius: 20,
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: secondaryColor.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }
}
