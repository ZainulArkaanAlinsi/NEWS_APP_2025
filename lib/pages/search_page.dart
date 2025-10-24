import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/news_card.dart';

class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final SearchController searchController = Get.put(SearchController());
  final NewsController newsController = Get.find<NewsController>();
  final ThemeController themeController = Get.find<ThemeController>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  // Color palette yang kreatif
  static const Color primaryColor = Color(0xFFFF6B6B);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color accentColor = Color(0xFFFFD166);
  static const Color darkBlue = Color(0xFF1A1F38);

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );
    
    _animationController.forward();
    
    // Request focus setelah animasi dimulai
    Future.delayed(const Duration(milliseconds: 300), () {
      searchController.searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context),
            Expanded(
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
                child: _buildSearchBody(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 🎨 SEARCH HEADER dengan Glass Morphism
  // ====================================================================

  Widget _buildSearchHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          _buildGlassButton(
            onTap: () => Get.back(),
            icon: Icons.arrow_back_rounded,
          ),
          const SizedBox(width: 16),
          
          // Search Field
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded, 
                      color: Colors.white.withOpacity(0.7), 
                      size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: searchController.searchTextController,
                      focusNode: searchController.searchFocusNode,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search news, topics, or stories...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (value) => searchController.performSearch(value),
                    ),
                  ),
                  Obx(() => searchController.searchTextController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, 
                                color: Colors.white.withOpacity(0.7)),
                          onPressed: searchController.clearSearch,
                        )
                      : const SizedBox()),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            onTap();
          },
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  // ====================================================================
  // 📱 SEARCH BODY dengan GetX Reactive
  // ====================================================================

  Widget _buildSearchBody(BuildContext context) {
    return Obx(() {
      if (newsController.isLoading.value) {
        return _buildLoadingState();
      }

      if (searchController.searchTextController.text.isEmpty) {
        return _buildInitialState();
      }

      if (newsController.articles.isEmpty) {
        return _buildEmptyState();
      }

      return _buildSearchResults();
    });
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('🔥 Trending Searches'),
          const SizedBox(height: 16),
          _buildTrendingSearches(),
          const SizedBox(height: 32),
          Obx(() => searchController.recentSearches.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('🕒 Recent Searches'),
                    const SizedBox(height: 16),
                    _buildRecentSearches(),
                  ],
                )
              : const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildTrendingSearches() {
    final trendingTopics = [
      {'icon': Icons.trending_up_rounded', 'text': 'Technology', 'color': primaryColor},
      {'icon': Icons.currency_bitcoin_rounded', 'text': 'Crypto', 'color': secondaryColor},
      {'icon': Icons.health_and_safety_rounded', 'text': 'Health', 'color': accentColor},
      {'icon': Icons.sports_esports_rounded', 'text': 'Gaming', 'color': Colors.purpleAccent},
      {'icon': Icons.business_rounded', 'text': 'Business', 'color': Colors.blueAccent},
      {'icon': Icons.science_rounded', 'text': 'Science', 'color': Colors.greenAccent},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: trendingTopics.map((topic) {
        return _buildTopicChip(
          icon: topic['icon'] as IconData,
          text: topic['text'] as String,
          color: topic['color'] as Color,
        );
      }).toList(),
    );
  }

  Widget _buildTopicChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => searchController.performSearch(text),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      children: searchController.recentSearches.map((search) {
        return _buildRecentSearchItem(search);
      }).toList(),
    );
  }

  Widget _buildRecentSearchItem(String search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => searchController.performSearch(search),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history_rounded, 
                    color: Colors.white.withOpacity(0.6), 
                    size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    search,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, 
                        color: Colors.white.withOpacity(0.4), 
                        size: 18),
                  onPressed: () => searchController.removeRecentSearch(search),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Searching...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Looking for "${searchController.searchTextController.text}"',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 50,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t find any matches for\n"${searchController.searchTextController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onPressed: searchController.clearSearch,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          'Browse Trending Topics',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // Header Results
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${newsController.articles.length} results found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sort_rounded, 
                         color: Colors.white.withOpacity(0.7), 
                         size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Relevance',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Results List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: newsController.articles.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: NewsCard(
                  article: newsController.articles[index],
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
}

class SearchController extends GetxController {
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  final RxList<String> recentSearches = <String>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load recent searches dari local storage
    _loadRecentSearches();
  }

  void _loadRecentSearches() {
    // Simulasi loading recent searches
    recentSearches.assignAll(['Technology', 'Flutter', 'AI', 'Startup']);
  }

  void performSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    searchTextController.text = trimmedQuery;
    
    // Add to recent searches
    if (!recentSearches.contains(trimmedQuery)) {
      recentSearches.insert(0, trimmedQuery);
      if (recentSearches.length > 8) {
        recentSearches.removeLast();
      }
    }

    // Perform search using NewsController
    final newsController = Get.find<NewsController>();
    newsController.searchNews(trimmedQuery);
    
    searchFocusNode.unfocus();
  }

  void clearSearch() {
    searchTextController.clear();
    searchFocusNode.requestFocus();
    Get.find<NewsController>().clearSearch();
  }

  void removeRecentSearch(String search) {
    recentSearches.remove(search);
  }

  @override
  void onClose() {
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}