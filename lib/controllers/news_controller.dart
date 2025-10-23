import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../services/news_service.dart';
import '../models/article.dart';
import '../models/news_category.dart';

class NewsController extends GetxController {
  // Observable variables
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

    // Auto-fetch news jika sudah lebih dari 30 menit atau tidak ada cached data
    if (_shouldAutoRefresh() || !_hasCachedArticles()) {
      fetchTopHeadlines();
    } else {
      _loadCachedArticles();
    }
  }

  void initializeCategories() {
    categories.value = NewsCategory.getAllCategories();
  }

  bool _shouldAutoRefresh() {
    final now = DateTime.now();
    final difference = now.difference(lastFetchTime.value);
    return difference.inMinutes > 30;
  }

  bool _hasCachedArticles() {
    return _storage.hasData(_cachedArticlesKey);
  }

  // Load favorites dari local storage
  void _loadFavoritesFromStorage() {
    try {
      final storedFavorites = _storage.read<List>(_favoritesKey);
      if (storedFavorites != null) {
        favoriteArticles.assignAll(
          storedFavorites
              .map((item) => Article.fromJson(item))
              .where((article) => article.title.isNotEmpty)
              .toList(),
        );

        // Set favorite status untuk semua favorites yang diload
        for (var favorite in favoriteArticles) {
          favorite.isFavorite.value = true;
        }
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }

  // Save favorites ke local storage
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

  // Load last fetch time
  void _loadLastFetchTime() {
    final storedTime = _storage.read<String>(_lastFetchKey);
    if (storedTime != null) {
      lastFetchTime.value = DateTime.parse(storedTime);
    }
  }

  // Save last fetch time
  void _saveLastFetchTime() {
    _storage.write(_lastFetchKey, DateTime.now().toIso8601String());
    lastFetchTime.value = DateTime.now();
  }

  // Load selected country
  void _loadSelectedCountry() {
    final storedCountry = _storage.read<String>(_selectedCountryKey);
    if (storedCountry != null) {
      currentCountry.value = storedCountry;
    }
  }

  // Save selected country
  void _saveSelectedCountry() {
    _storage.write(_selectedCountryKey, currentCountry.value);
  }

  // Load cached articles
  void _loadCachedArticles() {
    try {
      final cachedArticles = _storage.read<List>(_cachedArticlesKey);
      if (cachedArticles != null && cachedArticles.isNotEmpty) {
        final loadedArticles = cachedArticles
            .map((item) => Article.fromJson(item))
            .where((article) => article.title.isNotEmpty)
            .toList();

        articles.assignAll(loadedArticles);
        _updateTopArticles();

        print('📁 Loaded ${loadedArticles.length} cached articles');
      }
    } catch (e) {
      print('❌ Error loading cached articles: $e');
    }
  }

  // Save articles ke cache
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

  // Update top articles
  void _updateTopArticles() {
    if (articles.length > 5) {
      topArticles.assignAll(articles.sublist(0, 5));
    } else {
      topArticles.assignAll(articles);
    }
  }

  // Enhanced fetch top headlines dengan pagination
  Future<void> fetchTopHeadlines({bool loadMore = false}) async {
    if (loadMore) {
      if (!canLoadMore.value || isLoadingMore.value) return;
      isLoadingMore(true);
      currentPage.value++;
    } else {
      if (isLoading.value) return;
      isLoading(true);
      currentPage(1);
      canLoadMore(true);
    }

    try {
      if (!loadMore) {
        errorMessage('');
        hasError(false);
      }

      print(
        '🌐 Fetching headlines for country: ${currentCountry.value} (Page ${currentPage.value})',
      );

      List<Article> result = await NewsService.getTopHeadlines(
        country: currentCountry.value,
        pageSize: 30,
        page: currentPage.value,
      );

      if (result.isNotEmpty) {
        if (loadMore) {
          // Tambahkan ke existing articles
          articles.addAll(result);
          // Remove duplicates
          final seenUrls = <String>{};
          articles.retainWhere((article) => seenUrls.add(article.url!));
        } else {
          // Replace articles
          articles.assignAll(result);
        }

        _saveArticlesToCache(articles);
        _saveLastFetchTime();
        _updateTopArticles();

        // Check jika bisa load more
        canLoadMore(result.length >= 30);

        print('✅ Loaded ${result.length} articles (Total: ${articles.length})');

        if (!loadMore) {
          _showSnackbar(
            '📰 News Updated',
            'Loaded ${result.length} fresh articles',
            Colors.green.shade600,
          );
        }
      } else {
        if (loadMore) {
          canLoadMore(false);
          _showSnackbar(
            'No More Articles',
            'All articles have been loaded',
            Colors.blue.shade600,
          );
        } else {
          errorMessage('No articles available at the moment');
          hasError(true);
        }
      }
    } on NewsApiException catch (e) {
      _handleApiError(e, 'fetching headlines');
      if (loadMore) {
        currentPage.value--; // Rollback page jika error
      }
    } catch (e) {
      _handleGenericError(e, 'fetching headlines');
      if (loadMore) {
        currentPage.value--; // Rollback page jika error
      }
    } finally {
      if (loadMore) {
        isLoadingMore(false);
      } else {
        isLoading(false);
        isRefreshing(false);
      }
    }
  }

  // Load more articles
  Future<void> loadMoreArticles() async {
    await fetchTopHeadlines(loadMore: true);
  }

  // Fetch dari multiple categories
  Future<void> fetchMultipleCategories() async {
    try {
      isLoading(true);
      errorMessage('');
      hasError(false);
      currentPage(1);
      canLoadMore(false); // Disable load more untuk multiple categories

      print('🎯 Fetching from multiple categories...');

      List<Article> result = await NewsService.getMultipleCategoriesNews(
        country: currentCountry.value,
        categories: [
          'general',
          'technology',
          'business',
          'sports',
          'entertainment',
        ],
        articlesPerCategory: 15,
      );

      if (result.isNotEmpty) {
        articles.assignAll(result);
        _saveArticlesToCache(articles);
        _updateTopArticles();

        print('✅ Loaded ${result.length} articles from multiple categories');

        _showSnackbar(
          'Diverse News Loaded',
          'Fetched ${result.length} articles from various categories',
          Colors.green.shade600,
        );
      } else {
        errorMessage('No articles available from multiple categories');
        hasError(true);
      }
    } on NewsApiException catch (e) {
      _handleApiError(e, 'fetching multiple categories');
    } catch (e) {
      _handleGenericError(e, 'fetching multiple categories');
    } finally {
      isLoading(false);
    }
  }

  // Alternative news source as fallback
  Future<List<Article>> _fetchAlternativeNews() async {
    try {
      // Try different categories as fallback
      final List<String> fallbackCategories = [
        'technology',
        'sports',
        'entertainment',
        'business',
      ];

      for (String category in fallbackCategories) {
        try {
          final result = await NewsService.getNewsByCategory(
            category: category,
            country: currentCountry.value,
            pageSize: 20,
          );
          if (result.isNotEmpty) {
            print('✅ Found ${result.length} articles in $category category');
            return result;
          }
        } catch (e) {
          print('❌ Failed to fetch $category category: $e');
          continue;
        }
      }
    } catch (e) {
      print('❌ Alternative news fetch failed: $e');
    }

    return [];
  }

  // Enhanced error handling for API exceptions
  void _handleApiError(NewsApiException e, String operation) {
    String errorMsg = _parseErrorMessage(e);
    errorMessage('Failed to load news: $errorMsg');
    hasError(true);
    print('❌ API Error $operation: ${e.message}');

    // Fallback to cached data
    if (articles.isEmpty) {
      _loadCachedArticles();
      if (articles.isNotEmpty) {
        errorMessage('Showing cached news. $errorMsg');
        hasError(false);

        _showSnackbar(
          '⚠️ Using Cached Data',
          'Showing previously saved articles',
          Colors.orange.shade600,
        );
      }
    }
  }

  // Enhanced error handling for generic exceptions
  void _handleGenericError(dynamic e, String operation) {
    String errorMsg = _parseErrorMessage(e);
    errorMessage('Failed to load news: $errorMsg');
    hasError(true);
    print('❌ Error $operation: $e');

    // Fallback to cached data
    if (articles.isEmpty) {
      _loadCachedArticles();
      if (articles.isNotEmpty) {
        errorMessage('Showing cached news. $errorMsg');
        hasError(false);

        _showSnackbar(
          '⚠️ Using Cached Data',
          'Showing previously saved articles',
          Colors.orange.shade600,
        );
      }
    }
  }

  // Enhanced error message parsing
  String _parseErrorMessage(dynamic error) {
    if (error is NewsApiException) {
      return error.message;
    }

    String errorString = error.toString();

    // Remove exception prefixes and provide user-friendly messages
    errorString = errorString.replaceAll('Exception: ', '');

    if (errorString.contains('SocketException') ||
        errorString.contains('Network is unreachable') ||
        errorString.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network settings.';
    } else if (errorString.contains('Timeout') ||
        errorString.contains('timed out')) {
      return 'Connection timeout. Server is taking too long to respond.';
    } else if (errorString.contains('401') ||
        errorString.contains('Unauthorized')) {
      return 'API key invalid or expired. Please contact support.';
    } else if (errorString.contains('429')) {
      return 'Too many requests. Please wait a moment before trying again.';
    } else if (errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorString.contains('No host specified')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorString.contains('XMLHttpRequest')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'Unable to load news. Please try again.';
  }

  // Enhanced fetch news by category
  Future<void> fetchNewsByCategory(String category) async {
    try {
      isLoading(true);
      errorMessage('');
      hasError(false);
      selectedCategory(category);
      currentPage(1);
      canLoadMore(true);

      print('🌐 Fetching $category news...');

      List<Article> result = await NewsService.getNewsByCategory(
        category: category,
        country: currentCountry.value,
        pageSize: 25,
      );

      if (result.isNotEmpty) {
        articles.assignAll(result);
        print('✅ Loaded ${result.length} $category articles');
      } else {
        errorMessage(
          'No news found for $category category. Try refreshing or check back later.',
        );
        hasError(true);
      }
    } on NewsApiException catch (e) {
      _handleApiError(e, 'fetching $category news');
    } catch (e) {
      _handleGenericError(e, 'fetching $category news');
    } finally {
      isLoading(false);
    }
  }

  // Improved category search terms
  String _getCategorySearchTerm(String category) {
    final searchTerms = {
      'business': 'business OR finance OR economy OR market OR stock',
      'entertainment':
          'entertainment OR celebrity OR movie OR film OR music OR Hollywood',
      'health': 'health OR medical OR healthcare OR medicine OR wellness',
      'science': 'science OR research OR discovery OR study OR innovation',
      'sports':
          'sports OR football OR basketball OR game OR match OR tournament',
      'technology':
          'technology OR tech OR innovation OR digital OR AI OR artificial intelligence',
      'general': 'news OR current affairs OR breaking news',
    };

    return searchTerms[category] ?? 'news OR $category';
  }

  // Enhanced search dengan pagination
  Future<void> searchNews(String query, {bool loadMore = false}) async {
    if (query.trim().isEmpty && !loadMore) {
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
      searchQuery(query.trim());
      currentPage(1);
      canLoadMore(true);
    }

    try {
      List<Article> result = await NewsService.searchNews(
        searchQuery.value,
        pageSize: 30,
        page: currentPage.value,
      );

      if (result.isNotEmpty) {
        if (loadMore) {
          articles.addAll(result);
        } else {
          articles.assignAll(result);
        }
        canLoadMore(result.length >= 30);

        print('✅ Found ${result.length} results for "${searchQuery.value}"');
      } else {
        if (!loadMore) {
          errorMessage('No results found for "${searchQuery.value}"');
          hasError(true);
        } else {
          canLoadMore(false);
        }
      }
    } on NewsApiException catch (e) {
      _handleApiError(e, 'searching news');
      if (loadMore) {
        currentPage.value--;
      }
    } catch (e) {
      _handleGenericError(e, 'searching news');
      if (loadMore) {
        currentPage.value--;
      }
    } finally {
      if (loadMore) {
        isLoadingMore(false);
      } else {
        isLoading(false);
      }
    }
  }

  // Enhanced favorites management
  void addToFavorites(Article article) {
    if (!favoriteArticles.any((item) => item.url == article.url)) {
      // Create a new instance to avoid reference issues
      final favoriteArticle = Article(
        source: article.source,
        author: article.author,
        title: article.title,
        description: article.description,
        url: article.url,
        urlToImage: article.urlToImage,
        publishedAt: article.publishedAt,
        content: article.content,
      );
      favoriteArticle.isFavorite.value = true;

      favoriteArticles.add(favoriteArticle);
      _saveFavoritesToStorage();

      // Update the original article's favorite status
      article.isFavorite.value = true;

      _showSnackbar(
        '❤️ Added to Favorites',
        'Article saved to your favorites',
        Colors.green.shade600,
      );
    }
  }

  void removeFromFavorites(Article article) {
    favoriteArticles.removeWhere((item) => item.url == article.url);
    _saveFavoritesToStorage();

    // Update the article's favorite status
    article.isFavorite.value = false;

    _showSnackbar(
      '🗑️ Removed from Favorites',
      'Article removed from favorites',
      Colors.orange.shade600,
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
      // Reset favorite status for all articles
      for (var favorite in favoriteArticles) {
        favorite.isFavorite.value = false;
      }

      favoriteArticles.clear();
      _saveFavoritesToStorage();

      _showSnackbar(
        '🧹 All Favorites Cleared',
        'All articles have been removed from favorites',
        Colors.blue.shade600,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Helper method for showing snackbars
  void _showSnackbar(
    String title,
    String message,
    Color backgroundColor, {
    Duration duration = const Duration(seconds: 2),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
      icon: Icon(Icons.info, color: Colors.white),
    );
  }

  // Enhanced refresh with retry logic
  Future<void> refreshNews() async {
    isRefreshing(true);
    errorMessage('');
    hasError(false);

    try {
      // Add a small delay to show refreshing state
      await Future.delayed(const Duration(milliseconds: 500));

      if (searchQuery.value.isNotEmpty) {
        await searchNews(searchQuery.value);
      } else if (selectedCategory.value != 'general') {
        await fetchNewsByCategory(selectedCategory.value);
      } else {
        await fetchTopHeadlines();
      }
    } catch (e) {
      errorMessage('Refresh failed: ${_parseErrorMessage(e)}');
      hasError(true);
    } finally {
      isRefreshing(false);
    }
  }

  // Change country and refresh news
  Future<void> changeCountry(String countryCode) async {
    if (currentCountry.value != countryCode) {
      currentCountry.value = countryCode;
      _saveSelectedCountry();

      // Refresh news with new country
      if (searchQuery.value.isNotEmpty) {
        await searchNews(searchQuery.value);
      } else if (selectedCategory.value != 'general') {
        await fetchNewsByCategory(selectedCategory.value);
      } else {
        await fetchTopHeadlines();
      }
    }
  }

  // Get available countries from NewsService
  List<String> getAvailableCountries() {
    return NewsService.getAvailableCountries();
  }

  void clearSearch() {
    searchQuery('');
    isSearching(false);
    selectedCategory('general');
    currentPage(1);
    canLoadMore(true);
    fetchTopHeadlines();
  }

  List<Article> get displayArticles {
    return articles;
  }

  bool get hasArticles => articles.isNotEmpty;
  bool get hasFavorites => favoriteArticles.isNotEmpty;

  // Additional utility methods
  List<Article> getTrendingArticles() {
    if (articles.length < 3) return articles;
    return articles.sublist(0, 3);
  }

  List<Article> getArticlesBySource(String source) {
    return articles
        .where(
          (article) =>
              article.source?.name?.toLowerCase().contains(
                source.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  // Get articles by date (today)
  List<Article> getTodaysArticles() {
    final today = DateTime.now();
    return articles.where((article) {
      if (article.publishedAt == null) return false;
      try {
        final articleDate = DateTime.parse(article.publishedAt!);
        return articleDate.year == today.year &&
            articleDate.month == today.month &&
            articleDate.day == today.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Cleanup method
  @override
  void onClose() {
    _saveFavoritesToStorage();
    _saveLastFetchTime();
    _saveSelectedCountry();
    super.onClose();
  }
}
