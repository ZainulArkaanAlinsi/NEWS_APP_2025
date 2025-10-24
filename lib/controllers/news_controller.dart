import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:zernews/services/news_services.dart';
import '../models/article.dart';
import '../models/news_category.dart';

class NewsController extends GetxController {
  // Observable variables dengan GetX
  var isLoading = false.obs;
  var articles = <Article>[].obs;
  var favoriteArticles = <Article>[].obs;
  var errorMessage = ''.obs;
  var selectedCategory = 'general'.obs;
  var categories = <NewsCategory>[].obs;
  var searchQuery = ''.obs;
  var isSearching = false.obs;
  var topArticles = <Article>[].obs;
  var isRefreshing = false.obs;
  var lastFetchTime = DateTime.now().obs;
  var hasError = false.obs;
  var currentCountry = 'us'.obs;
  var currentPage = 1.obs;
  var canLoadMore = true.obs;
  var isLoadingMore = false.obs;
  var totalArticlesFetched = 0.obs;

  final _storage = GetStorage();
  final _favoritesKey = 'favorite_articles';
  final _lastFetchKey = 'last_fetch_time';
  final _cachedArticlesKey = 'cached_articles';
  final _selectedCountryKey = 'selected_country';

  @override
  void onInit() {
    super.onInit();
    initializeCategories();
    _loadFavoritesFromStorage();
    _loadLastFetchTime();
    _loadSelectedCountry();

    // Auto-fetch dengan delay untuk memberikan waktu inisialisasi
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_shouldAutoRefresh() || !_hasCachedArticles()) {
        fetchEnhancedHeadlines();
      } else {
        _loadCachedArticles();
        if (_shouldAutoRefresh()) {
          refreshNews();
        }
      }
    });
  }

  void initializeCategories() {
    categories.value = NewsCategory.getAllCategories();
  }

  bool _shouldAutoRefresh() {
    final now = DateTime.now();
    final difference = now.difference(lastFetchTime.value);
    return difference.inMinutes > 20; // Reduced from 30 minutes
  }

  bool _hasCachedArticles() {
    return _storage.hasData(_cachedArticlesKey);
  }

  // Enhanced favorites management
  void _loadFavoritesFromStorage() {
    try {
      final storedFavorites = _storage.read<List>(_favoritesKey);
      if (storedFavorites != null) {
        final loadedFavorites = storedFavorites
            .map((item) => Article.fromJson(item))
            .where((article) => article.title.isNotEmpty)
            .toList();

        favoriteArticles.assignAll(loadedFavorites);
        print('❤️ Loaded ${favoriteArticles.length} favorites from storage');
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }

  void _saveFavoritesToStorage() {
    try {
      final favoritesJson = favoriteArticles
          .map((article) => article.toJson())
          .toList();
      _storage.write(_favoritesKey, favoritesJson);
    } catch (e) {
      print('❌ Error saving favorites: $e');
    }
  }

  void _loadLastFetchTime() {
    final storedTime = _storage.read<String>(_lastFetchKey);
    if (storedTime != null) {
      try {
        lastFetchTime.value = DateTime.parse(storedTime);
      } catch (_) {
        lastFetchTime.value = DateTime.now().subtract(const Duration(hours: 1));
      }
    }
  }

  void _saveLastFetchTime() {
    _storage.write(_lastFetchKey, DateTime.now().toIso8601String());
    lastFetchTime.value = DateTime.now();
  }

  void _loadSelectedCountry() {
    final storedCountry = _storage.read<String>(_selectedCountryKey);
    if (storedCountry != null &&
        NewsService.getAvailableCountries().contains(storedCountry)) {
      currentCountry.value = storedCountry;
    } else {
      currentCountry.value = 'us';
    }
  }

  void _saveSelectedCountry() {
    _storage.write(_selectedCountryKey, currentCountry.value);
  }

  void _loadCachedArticles() {
    try {
      final cachedArticles = _storage.read<List>(_cachedArticlesKey);
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        final loadedArticles = cachedArticles
            .map((item) => Article.fromJson(item))
            .where((article) => article.title.isNotEmpty)
            .toList();

        for (var article in loadedArticles) {
          article.isFavorite.value = isFavorite(article);
        }

        articles.assignAll(loadedArticles);
        _updateTopArticles();

        print('📁 Loaded ${loadedArticles.length} cached articles');
      }
    } catch (e) {
      print('❌ Error loading cached articles: $e');
      _storage.remove(_cachedArticlesKey);
    }
  }

  void _saveArticlesToCache(List<Article> articlesToCache) {
    try {
      final articlesJson = articlesToCache
          .map((article) => article.toJson())
          .toList();
      _storage.write(_cachedArticlesKey, articlesJson);
    } catch (e) {
      print('❌ Error saving articles to cache: $e');
    }
  }

  void _updateTopArticles() {
    final articlesWithImage = articles
        .where((a) => a.urlToImage != null && a.urlToImage!.isNotEmpty)
        .toList();

    if (articlesWithImage.length >= 8) {
      topArticles.assignAll(articlesWithImage.sublist(0, 8));
    } else {
      topArticles.assignAll(articlesWithImage);
    }
  }

  // Enhanced fetch dengan lebih banyak artikel
  Future<void> fetchEnhancedHeadlines({bool loadMore = false}) async {
    if (loadMore) {
      if (!canLoadMore.value || isLoadingMore.value) return;
      isLoadingMore(true);
      currentPage.value++;
    } else {
      if (isLoading.value) return;
      isLoading(true);
      currentPage(1);
      canLoadMore(true);
      articles.clear();
      totalArticlesFetched(0);
    }

    try {
      if (!loadMore) {
        errorMessage('');
        hasError(false);
      }

      print(
        '🌐 Fetching enhanced headlines for ${currentCountry.value} (Page ${currentPage.value})',
      );

      List<Article> result = await NewsService.getTopHeadlines(
        country: currentCountry.value,
        pageSize: 50, // Increased page size
        page: currentPage.value,
      );

      // Update favorite status
      for (var article in result) {
        article.isFavorite.value = isFavorite(article);
      }

      if (result.isNotEmpty) {
        if (loadMore) {
          articles.addAll(result);
          final seenUrls = <String>{};
          articles.retainWhere(
            (article) => article.url.isNotEmpty && seenUrls.add(article.url),
          );
        } else {
          articles.assignAll(result);
        }

        totalArticlesFetched(totalArticlesFetched.value + result.length);

        if (!loadMore) {
          _saveArticlesToCache(articles);
          _saveLastFetchTime();
        }
        _updateTopArticles();

        canLoadMore(result.length >= 50);

        print('✅ Loaded ${result.length} articles (Total: ${articles.length})');

        if (!loadMore) {
          _showEnhancedSnackbar(
            '📰 News Updated',
            'Loaded ${articles.length} fresh articles',
            Colors.green,
            Icons.article,
          );
        }
      } else {
        if (loadMore) {
          canLoadMore(false);
          _showEnhancedSnackbar(
            'All Articles Loaded',
            'No more articles available',
            Colors.blue,
            Icons.check_circle,
          );
        } else {
          errorMessage('No articles available at the moment');
          hasError(true);
        }
      }
    } on NewsApiException catch (e) {
      _handleEnhancedApiError(e, 'fetching headlines', loadMore: loadMore);
    } catch (e) {
      _handleEnhancedGenericError(e, 'fetching headlines', loadMore: loadMore);
    } finally {
      if (loadMore) {
        isLoadingMore(false);
      } else {
        isLoading(false);
        isRefreshing(false);
      }
    }
  }

  // Enhanced load more dengan GetX
  Future<void> loadMoreArticles() async {
    if (searchQuery.value.isEmpty && selectedCategory.value == 'general') {
      await fetchEnhancedHeadlines(loadMore: true);
    } else if (isSearching.value) {
      await enhancedSearchNews(searchQuery.value, loadMore: true);
    } else {
      await fetchNewsByCategory(selectedCategory.value, loadMore: true);
    }
  }

  // Enhanced category fetch dengan load more support
  Future<void> fetchNewsByCategory(
    String category, {
    bool loadMore = false,
  }) async {
    if (loadMore) {
      if (!canLoadMore.value || isLoadingMore.value) return;
      isLoadingMore(true);
      currentPage.value++;
    } else {
      isLoading(true);
      errorMessage('');
      hasError(false);
      selectedCategory(category);
      currentPage(1);
      canLoadMore(true);
      if (!loadMore) articles.clear();
    }

    try {
      print('🌐 Fetching $category news (Page ${currentPage.value})...');

      List<Article> result = await NewsService.getNewsByCategory(
        category,
        country: currentCountry.value,
        pageSize: 40,
      );

      for (var article in result) {
        article.isFavorite.value = isFavorite(article);
      }

      if (result.isNotEmpty) {
        if (loadMore) {
          articles.addAll(result);
        } else {
          articles.assignAll(result);
        }

        canLoadMore(result.length >= 40);

        print('✅ Loaded ${result.length} $category articles');

        if (!loadMore) {
          _showEnhancedSnackbar(
            'Category News',
            'Fetched ${articles.length} ${category} articles',
            _getCategoryColor(category),
            _getCategoryIcon(category),
          );
        }
      } else {
        if (!loadMore) {
          errorMessage('No news found for $category category');
          hasError(true);
        } else {
          canLoadMore(false);
        }
      }
    } on NewsApiException catch (e) {
      _handleEnhancedApiError(e, 'fetching $category news', loadMore: loadMore);
    } catch (e) {
      _handleEnhancedGenericError(
        e,
        'fetching $category news',
        loadMore: loadMore,
      );
    } finally {
      if (loadMore) {
        isLoadingMore(false);
      } else {
        isLoading(false);
      }
    }
  }

  // Enhanced search dengan GetX
  Future<void> enhancedSearchNews(String query, {bool loadMore = false}) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty && !loadMore) {
      clearSearch();
      return;
    }

    if (loadMore) {
      if (!canLoadMore.value || isLoadingMore.value) return;
      isLoadingMore(true);
      currentPage.value++;
    } else {
      isLoading(true);
      isSearching(true);
      errorMessage('');
      hasError(false);
      searchQuery(cleanQuery);
      currentPage(1);
      canLoadMore(true);
      articles.clear();
    }

    try {
      List<Article> result = await NewsService.searchNews(
        searchQuery.value,
        pageSize: 50,
        page: currentPage.value,
      );

      for (var article in result) {
        article.isFavorite.value = isFavorite(article);
      }

      if (result.isNotEmpty) {
        if (loadMore) {
          articles.addAll(result);
          final seenUrls = <String>{};
          articles.retainWhere(
            (article) => article.url.isNotEmpty && seenUrls.add(article.url),
          );
        } else {
          articles.assignAll(result);
        }
        canLoadMore(result.length >= 50);

        print('✅ Found ${result.length} results for "${searchQuery.value}"');

        if (!loadMore) {
          _showEnhancedSnackbar(
            '🔍 Search Complete',
            'Found ${articles.length} articles for "$cleanQuery"',
            Colors.purple,
            Icons.search,
          );
        }
      } else {
        if (!loadMore) {
          errorMessage('No results found for "$cleanQuery"');
          hasError(true);
        } else {
          canLoadMore(false);
        }
      }
    } on NewsApiException catch (e) {
      _handleEnhancedApiError(e, 'searching news', loadMore: loadMore);
    } catch (e) {
      _handleEnhancedGenericError(e, 'searching news', loadMore: loadMore);
    } finally {
      if (loadMore) {
        isLoadingMore(false);
      } else {
        isLoading(false);
      }
    }
  }

  // Enhanced multiple categories fetch
  Future<void> fetchEnhancedMultipleCategories() async {
    try {
      isLoading(true);
      errorMessage('');
      hasError(false);
      currentPage(1);
      canLoadMore(false);
      articles.clear();

      print('🎯 Fetching from enhanced multiple categories...');

      List<Article> result = await NewsService.getMultipleCategoriesNews(
        country: currentCountry.value,
        categories: [
          'general',
          'technology',
          'business',
          'sports',
          'entertainment',
          'health',
          'science',
        ],
        articlesPerCategory: 15,
      );

      for (var article in result) {
        article.isFavorite.value = isFavorite(article);
      }

      if (result.isNotEmpty) {
        articles.assignAll(result);
        _saveArticlesToCache(articles);
        _updateTopArticles();

        print('✅ Loaded ${result.length} articles from multiple categories');

        _showEnhancedSnackbar(
          'Diverse News',
          'Fetched ${result.length} articles from 7 categories',
          Colors.deepPurple,
          Icons.diversity_3,
        );
      } else {
        errorMessage('No articles available from multiple categories');
        hasError(true);
      }
    } on NewsApiException catch (e) {
      _handleEnhancedApiError(e, 'fetching multiple categories');
    } catch (e) {
      _handleEnhancedGenericError(e, 'fetching multiple categories');
    } finally {
      isLoading(false);
    }
  }

  // Enhanced error handling
  void _handleEnhancedApiError(
    NewsApiException e,
    String operation, {
    bool loadMore = false,
  }) {
    String errorMsg = _parseEnhancedErrorMessage(e);
    errorMessage('Failed to load news: $errorMsg');
    hasError(true);
    print('❌ API Error $operation: ${e.message}');

    if (loadMore) {
      currentPage.value--;
    } else {
      if (articles.isEmpty) {
        _loadCachedArticles();
        if (articles.isNotEmpty) {
          errorMessage('Showing cached news. $errorMsg');
          hasError(false);
          _showEnhancedSnackbar(
            '⚠️ Using Cached Data',
            'Showing previously saved articles',
            Colors.orange,
            Icons.cached,
          );
        }
      }
    }
  }

  void _handleEnhancedGenericError(
    dynamic e,
    String operation, {
    bool loadMore = false,
  }) {
    String errorMsg = _parseEnhancedErrorMessage(e);
    errorMessage('Failed to load news: $errorMsg');
    hasError(true);
    print('❌ Error $operation: $e');

    if (loadMore) {
      currentPage.value--;
    } else {
      if (articles.isEmpty) {
        _loadCachedArticles();
        if (articles.isNotEmpty) {
          errorMessage('Showing cached news. $errorMsg');
          hasError(false);
          _showEnhancedSnackbar(
            '⚠️ Using Cached Data',
            'Showing previously saved articles',
            Colors.orange,
            Icons.cached,
          );
        }
      }
    }
  }

  String _parseEnhancedErrorMessage(dynamic error) {
    if (error is NewsApiException) {
      if (error.code == 401) {
        return 'API key invalid or expired.';
      } else if (error.code == 429) {
        return 'Too many requests. Please wait.';
      }
      return error.message;
    }

    String errorString = error.toString();
    errorString = errorString.replaceAll('Exception: ', '');

    if (errorString.contains('SocketException') ||
        errorString.contains('Network is unreachable')) {
      return 'No internet connection.';
    } else if (errorString.contains('Timeout')) {
      return 'Connection timeout.';
    }

    return 'Unable to load news. Please try again.';
  }

  // Enhanced favorites management dengan GetX
  void addToFavorites(Article article) {
    if (!favoriteArticles.any((item) => item.url == article.url)) {
      final favoriteArticle = article.copyWith(isFavorite: true);
      favoriteArticles.add(favoriteArticle);
      _saveFavoritesToStorage();

      final original = articles.firstWhereOrNull(
        (item) => item.url == article.url,
      );
      if (original != null) {
        original.isFavorite.value = true;
      } else {
        article.isFavorite.value = true;
      }

      _showEnhancedSnackbar(
        '❤️ Added to Favorites',
        'Article saved to your favorites',
        Colors.pink,
        Icons.favorite,
      );
    }
  }

  void removeFromFavorites(Article article) {
    favoriteArticles.removeWhere((item) => item.url == article.url);
    _saveFavoritesToStorage();

    final original = articles.firstWhereOrNull(
      (item) => item.url == article.url,
    );
    if (original != null) {
      original.isFavorite.value = false;
    } else {
      article.isFavorite.value = false;
    }

    _showEnhancedSnackbar(
      '🗑️ Removed from Favorites',
      'Article removed from favorites',
      Colors.grey,
      Icons.favorite_border,
    );
  }

  void toggleFavorite(Article article) {
    if (isFavorite(article)) {
      removeFromFavorites(article);
    } else {
      addToFavorites(article);
    }
  }

  bool isFavorite(Article article) {
    return favoriteArticles.any((item) => item.url == article.url);
  }

  void clearAllFavorites() {
    if (favoriteArticles.isNotEmpty) {
      for (var article in articles) {
        if (isFavorite(article)) {
          article.isFavorite.value = false;
        }
      }

      favoriteArticles.clear();
      _saveFavoritesToStorage();

      _showEnhancedSnackbar(
        '🧹 All Favorites Cleared',
        'All articles removed from favorites',
        Colors.blue,
        Icons.delete_sweep,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Enhanced snackbar dengan GetX
  void _showEnhancedSnackbar(
    String title,
    String message,
    Color color,
    IconData icon, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      backgroundColor: color,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(20),
      icon: Icon(icon, color: Colors.white),
      shouldIconPulse: true,
      snackStyle: SnackStyle.FLOATING,
    );
  }

  // Enhanced refresh dengan GetX
  Future<void> refreshNews({bool force = false}) async {
    if (isRefreshing.value && !force) return;

    isRefreshing(true);
    errorMessage('');
    hasError(false);
    currentPage(1);

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      if (searchQuery.value.isNotEmpty) {
        await enhancedSearchNews(searchQuery.value);
      } else if (selectedCategory.value != 'general') {
        await fetchNewsByCategory(selectedCategory.value);
      } else {
        await fetchEnhancedHeadlines();
      }
    } catch (e) {
      errorMessage('Refresh failed: ${_parseEnhancedErrorMessage(e)}');
      hasError(true);
    } finally {
      isRefreshing(false);
    }
  }

  // Enhanced country change
  Future<void> changeCountry(String countryCode) async {
    if (currentCountry.value != countryCode) {
      currentCountry.value = countryCode;
      _saveSelectedCountry();

      await refreshNews(force: true);

      _showEnhancedSnackbar(
        'Country Changed',
        'News updated for ${countryCode.toUpperCase()}',
        Colors.blue,
        Icons.public,
      );
    }
  }

  void clearSearch() {
    searchQuery('');
    isSearching(false);
    selectedCategory('general');
    currentPage(1);
    canLoadMore(true);
    fetchEnhancedHeadlines();
  }

  // Utility methods
  List<Article> get displayArticles => articles;

  bool get hasArticles => articles.isNotEmpty;
  bool get hasFavorites => favoriteArticles.isNotEmpty;

  List<Article> getTrendingArticles() {
    if (topArticles.length < 5) return topArticles;
    return topArticles.sublist(0, 5);
  }

  List<Article> getArticlesBySource(String source) {
    return articles
        .where(
          (article) =>
              article.source.toLowerCase().contains(source.toLowerCase()),
        )
        .toList();
  }

  List<Article> getTodaysArticles() {
    final today = DateTime.now();
    return articles.where((article) {
      if (article.publishedAt.isEmpty) return false;
      try {
        final articleDate = DateTime.parse(article.publishedAt).toLocal();
        return articleDate.year == today.year &&
            articleDate.month == today.month &&
            articleDate.day == today.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Helper methods for UI
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'technology':
        return Colors.blue;
      case 'business':
        return Colors.green;
      case 'sports':
        return Colors.orange;
      case 'entertainment':
        return Colors.purple;
      case 'health':
        return Colors.red;
      case 'science':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'technology':
        return Icons.computer;
      case 'business':
        return Icons.business_center;
      case 'sports':
        return Icons.sports_baseball;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.health_and_safety;
      case 'science':
        return Icons.science;
      default:
        return Icons.article;
    }
  }

  @override
  void onClose() {
    _saveFavoritesToStorage();
    super.onClose();
  }
}
