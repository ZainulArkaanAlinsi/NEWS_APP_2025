import 'package:flutter/material.dart';
import 'package:get/get.dart';
// Asumsikan path controllers dan widget sudah benar
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final NewsController controller = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Animasi untuk transisi Body
  late AnimationController bodyAnimationController;
  late Animation<double> bodyFadeAnimation; // <-- VARIABEL INI YANG ERROR

  // Data
  final List<String> popularSearches = [
    'AI',
    'Startup',
    'Crypto',
    'Politics',
    'Space',
    'HealthTech',
    'Climate',
    'Gaming',
  ];
  final RxList<String> recentSearches = <String>[].obs;

  static const Color accentColor = Color(0xFF4A4E69);
  static const Color lightAccentColor = Color(0xFF9A8C98);

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi controller dan animasi HARUS di sini
    bodyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    bodyFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: bodyAnimationController, curve: Curves.easeOut),
    );
    bodyAnimationController.forward();

    // 2. Sinkronisasi Controller/Listener BARU BOLEH di sini
    // Masalahnya kemungkinan besar terjadi di sini karena listener dieksekusi
    // secara tak terduga sebelum inisialisasi animasi selesai.
    searchController.addListener(() {
      // Pastikan hanya memperbarui state GetX saat teks benar-benar berbeda
      final newQuery = searchController.text.trim();
      if (controller.searchQuery.value != newQuery) {
        controller.searchQuery.value = newQuery;
      }
    });

    // 3. Request focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }

  // --- (sisanya sama) ---

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    bodyAnimationController.dispose();
    super.dispose();
  }

  // ====================================================================
  // 🔨 BUILD METHODS
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(
              // Pastikan bodyFadeAnimation digunakan DI SINI setelah diinisialisasi di initState
              child: FadeTransition(
                opacity: bodyFadeAnimation,
                child: _buildSearchBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- (sisa fungsi widget lainnya tetap sama) ---

  Widget _buildSearchHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Get.back(),
            isPrimary: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.15),
                    offset: const Offset(3, 3),
                    blurRadius: 10,
                  ),
                  BoxShadow(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    offset: const Offset(-3, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.transparent,
                  hintText: 'Search articles or topics...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 15,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Icon(
                      Icons.search_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  suffixIcon: Obx(
                    () => controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.5,
                              ),
                            ),
                            onPressed: () {
                              searchController.clear();
                              controller.clearSearch();
                              searchFocusNode.requestFocus();
                            },
                          )
                        : const SizedBox(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                onSubmitted: (value) => _performSearch(value),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            context: context,
            icon: Icons.send_rounded,
            onTap: () => _performSearch(searchController.text),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    final theme = Theme.of(context);

    final Color buttonColor = isPrimary
        ? accentColor
        : theme.colorScheme.onSurface.withOpacity(0.1);
    final Color iconColor = isPrimary
        ? Colors.white
        : theme.colorScheme.onSurface;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isPrimary ? accentColor : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Icon(icon, size: 24, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildSearchBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildLoadingState(context);
      }

      if (controller.searchQuery.value.isEmpty || controller.articles.isEmpty) {
        return _buildInitialAndEmptyState(context);
      }

      if (controller.errorMessage.isNotEmpty) {
        return _buildErrorState(context);
      }

      return _buildSearchResults(context);
    });
  }

  Widget _buildInitialAndEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    if (controller.searchQuery.value.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('🔥 Popular Topics', theme),
            const SizedBox(height: 16),
            _buildPopularSearches(context),
            const SizedBox(height: 32),

            if (recentSearches.isNotEmpty) ...[
              _buildSectionTitle('🕒 Recent Activity', theme),
              const SizedBox(height: 16),
              _buildRecentSearches(context),
            ],
          ],
        ),
      );
    }

    return _buildNoResultsState(context);
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildPopularSearches(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: popularSearches.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _buildPillChip(
            context,
            popularSearches[index],
            isTrending: true,
          );
        },
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context) {
    return Column(
      children: recentSearches
          .map((search) => _buildRecentSearchItem(context, search))
          .toList(),
    );
  }

  Widget _buildPillChip(
    BuildContext context,
    String text, {
    bool isTrending = false,
  }) {
    final theme = Theme.of(context);
    final Color backgroundColor = isTrending
        ? accentColor.withOpacity(0.1)
        : theme.colorScheme.surface;
    final Color textColor = isTrending
        ? accentColor
        : theme.colorScheme.onSurface.withOpacity(0.8);
    final IconData icon = isTrending
        ? Icons.local_fire_department_rounded
        : Icons.history_rounded;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _performSearch(text),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor.withOpacity(0.7)),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(BuildContext context, String search) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          onTap: () => _performSearch(search),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    search,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  onPressed: () => recentSearches.remove(search),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching for "${controller.searchQuery.value}"...',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: lightAccentColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: lightAccentColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Matches Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any articles matching\n**"${controller.searchQuery.value}"**\nTry a different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                searchController.clear();
                controller.clearSearch();
                searchFocusNode.requestFocus();
              },
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
              label: const Text('View Popular Topics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.redAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load search results. Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _performSearch(controller.searchQuery.value),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Found '),
                    TextSpan(
                      text: '${controller.articles.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    const TextSpan(text: ' results for '),
                    TextSpan(
                      text: '"${controller.searchQuery.value}"',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: lightAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: lightAccentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Relevance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: lightAccentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.articles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewsCard(
                  article: controller.articles[index],
                  showFavoriteButton: true,
                  isGrid: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    searchController.text = trimmedQuery;
    controller.searchNews(trimmedQuery);

    if (recentSearches.contains(trimmedQuery)) {
      recentSearches.remove(trimmedQuery);
    }
    recentSearches.insert(0, trimmedQuery);

    if (recentSearches.length > 8) {
      recentSearches.removeLast();
    }

    searchFocusNode.unfocus();
  }
}
