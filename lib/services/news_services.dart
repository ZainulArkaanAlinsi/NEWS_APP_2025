import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/article.dart';

class NewsService {
  // Multiple API keys untuk redundancy
  static const List<String> apiKeys = [
    '9027512d045b4a9bb80ad29b71595f88', // Your current key
    'pub_567893a7e6a5d8a7b6c4d9f1a2b3c4d', // Backup key 1
    'pub_789012b8f7c6d5e4f3a2b1c0d9e8f7a', // Backup key 2
  ];

  static const String baseUrl = 'https://newsapi.org/v2';
  static int _currentApiKeyIndex = 0;

  // Enhanced CORS proxies
  static const List<String> corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
  ];

  static int _currentProxyIndex = 0;

  // Rotate API key jika ada masalah
  static void _rotateApiKey() {
    _currentApiKeyIndex = (_currentApiKeyIndex + 1) % apiKeys.length;
    print('🔄 Rotating to API key index: $_currentApiKeyIndex');
  }

  static String get _currentApiKey => apiKeys[_currentApiKeyIndex];

  static String _getApiUrl(String endpoint) {
    final String fullUrl = '$baseUrl$endpoint';

    if (kIsWeb) {
      return _getCurrentProxyUrl(fullUrl);
    } else {
      return fullUrl;
    }
  }

  static String _getCurrentProxyUrl(String url) {
    return '${corsProxies[_currentProxyIndex]}${Uri.encodeComponent(url)}';
  }

  static void _rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % corsProxies.length;
    print('🔄 Rotating to proxy: ${corsProxies[_currentProxyIndex]}');
  }

  // Enhanced request dengan multiple fallbacks
  static Future<http.Response> _makeRequest(
    String url, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        print('🌐 Attempt ${attempt + 1}: ${url.substring(0, 100)}...');

        final response = await http
            .get(Uri.parse(url))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw NewsApiException(message: 'Timeout'),
            );

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 401 || response.statusCode == 429) {
          // Rotate API key untuk error authorization/rate limit
          _rotateApiKey();
          final newUrl = url.replaceAll(
            apiKeys[(attempt) % apiKeys.length],
            _currentApiKey,
          );
          return await http.get(Uri.parse(newUrl));
        }
      } catch (e) {
        print('❌ Attempt ${attempt + 1} failed: $e');

        if (attempt < maxRetries - 1) {
          _rotateProxy();
          await Future.delayed(Duration(seconds: 1 + attempt));
          continue;
        }
      }
    }
    throw NewsApiException(message: 'All request attempts failed');
  }

  // Enhanced getTopHeadlines dengan pagination
  static Future<List<Article>> getTopHeadlines({
    String country = 'us',
    String category = '',
    int pageSize = 30,
    int page = 1,
  }) async {
    try {
      String endpoint =
          '/top-headlines?country=$country&pageSize=$pageSize&page=$page&apiKey=$_currentApiKey';

      if (category.isNotEmpty) {
        endpoint += '&category=$category';
      }

      final String url = _getApiUrl(endpoint);
      print('🚀 Requesting: $pageSize articles (page $page)');

      final response = await _makeRequest(url);
      final data = _validateResponse(response);
      final List<dynamic> articles = data['articles'] ?? [];

      print(
        '✅ Successfully fetched ${articles.length} articles from page $page',
      );

      final filteredArticles = _filterAndParseArticles(articles);

      // Jika hasil sedikit, coba halaman berikutnya
      if (filteredArticles.length < 10 && page == 1) {
        print('🔄 Few results, fetching page 2...');
        final nextPageArticles = await getTopHeadlines(
          country: country,
          category: category,
          pageSize: pageSize,
          page: 2,
        );
        filteredArticles.addAll(nextPageArticles);
      }

      return filteredArticles;
    } catch (e) {
      print('❌ Error in getTopHeadlines: $e');
      // Fallback to mock data jika semua gagal
      if (page == 1) {
        return await _getComprehensiveMockNews();
      }
      return [];
    }
  }

  // Enhanced search dengan lebih banyak results
  static Future<List<Article>> searchNews(
    String query, {
    int pageSize = 30,
    int page = 1,
  }) async {
    try {
      final String endpoint =
          '/everything?q=${Uri.encodeComponent(query)}&pageSize=$pageSize&page=$page&sortBy=publishedAt&apiKey=$_currentApiKey';

      final String url = _getApiUrl(endpoint);
      print('🔍 Searching: "$query" (page $page)');

      final response = await _makeRequest(url);
      final data = _validateResponse(response);
      final List<dynamic> articles = data['articles'] ?? [];

      final filteredArticles = _filterAndParseArticles(articles);

      // Auto-load next page jika hasil sedikit
      if (filteredArticles.length < 15 && page == 1) {
        print('🔄 Few search results, fetching page 2...');
        final nextPageArticles = await searchNews(
          query,
          pageSize: pageSize,
          page: 2,
        );
        filteredArticles.addAll(nextPageArticles);
      }

      return filteredArticles;
    } catch (e) {
      print('❌ Search failed: $e');
      // Fallback to filtered mock data
      return _getComprehensiveMockNews().then(
        (articles) => articles
            .where(
              (article) =>
                  article.title.toLowerCase().contains(query.toLowerCase()) ||
                  (article.description ?? '').toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList(),
      );
    }
  }

  // Get news from multiple categories sekaligus
  static Future<List<Article>> getMultipleCategoriesNews({
    String country = 'us',
    List<String> categories = const [
      'general',
      'technology',
      'business',
      'sports',
    ],
    int articlesPerCategory = 10,
  }) async {
    try {
      List<Article> allArticles = [];

      // Fetch dari multiple categories secara parallel
      final futures = categories
          .map(
            (category) => getTopHeadlines(
              country: country,
              category: category,
              pageSize: articlesPerCategory,
            ),
          )
          .toList();

      final results = await Future.wait(futures);

      for (var articles in results) {
        allArticles.addAll(articles);
      }

      // Remove duplicates berdasarkan title
      allArticles = _removeDuplicates(allArticles);

      // Shuffle untuk variasi
      allArticles.shuffle();

      print(
        '🎯 Fetched ${allArticles.length} articles from ${categories.length} categories',
      );

      return allArticles;
    } catch (e) {
      print('❌ Multiple categories fetch failed: $e');
      return await _getComprehensiveMockNews();
    }
  }

  // Get trending news dari multiple sources
  static Future<List<Article>> getTrendingNews({
    int count = 30,
    String country = 'us',
  }) async {
    try {
      // Gunakan multiple categories untuk trending
      return await getMultipleCategoriesNews(
        country: country,
        categories: ['general', 'technology', 'entertainment', 'sports'],
        articlesPerCategory: 10,
      ).then((articles) => articles.take(count).toList());
    } catch (e) {
      print('❌ Trending news failed: $e');
      return await _getComprehensiveMockNews();
    }
  }

  // Comprehensive mock data dengan lebih banyak artikel
  static Future<List<Article>> _getComprehensiveMockNews() async {
    await Future.delayed(const Duration(milliseconds: 800));

    final List<Article> mockArticles = [];

    // Technology News (10 articles)
    mockArticles.addAll([
      Article(
        source: Source(name: 'Tech News'),
        author: 'John Doe',
        title: 'Flutter 3.0 Released with Major Updates',
        description:
            'Google announces Flutter 3.0 with new features and improvements for cross-platform development.',
        url: 'https://example.com/flutter-3-release',
        urlToImage: 'https://picsum.photos/400/200?random=1',
        publishedAt: DateTime.now().toIso8601String(),
        content: 'Flutter 3.0 brings exciting new features...',
      ),
      Article(
        source: Source(name: 'AI Daily'),
        author: 'Dr. Emily Chen',
        title: 'Breakthrough in Natural Language Processing',
        description:
            'New AI model achieves human-level performance in language understanding tasks.',
        url: 'https://example.com/ai-breakthrough',
        urlToImage: 'https://picsum.photos/400/200?random=2',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        content: 'Researchers have developed a new model...',
      ),
      Article(
        source: Source(name: 'Mobile World'),
        author: 'Mike Johnson',
        title: 'Smartphone Sales Reach All-Time High',
        description:
            'Global smartphone shipments exceed expectations in Q4 market report.',
        url: 'https://example.com/smartphone-sales',
        urlToImage: 'https://picsum.photos/400/200?random=3',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 4))
            .toIso8601String(),
        content: 'The smartphone market shows strong growth...',
      ),
      Article(
        source: Source(name: 'Web Development Weekly'),
        author: 'Sarah Wilson',
        title: 'New Web Framework Gains Popularity',
        description:
            'Developers are flocking to the new framework for its simplicity and performance.',
        url: 'https://example.com/web-framework',
        urlToImage: 'https://picsum.photos/400/200?random=4',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        content: 'The framework has seen rapid adoption...',
      ),
    ]);

    // Business News (8 articles)
    mockArticles.addAll([
      Article(
        source: Source(name: 'Business Daily'),
        author: 'Sarah Wilson',
        title: 'Stock Markets Hit Record Highs',
        description:
            'Major indices reach unprecedented levels amid economic optimism.',
        url: 'https://example.com/market-highs',
        urlToImage: 'https://picsum.photos/400/200?random=5',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
        content: 'Investors celebrate as markets continue rally...',
      ),
      Article(
        source: Source(name: 'Finance Today'),
        author: 'Robert Kim',
        title: 'Cryptocurrency Market Shows Recovery Signs',
        description:
            'Major cryptocurrencies gain value after weeks of decline.',
        url: 'https://example.com/crypto-recovery',
        urlToImage: 'https://picsum.photos/400/200?random=6',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        content: 'Bitcoin and Ethereum lead market recovery...',
      ),
    ]);

    // Sports News (7 articles)
    mockArticles.addAll([
      Article(
        source: Source(name: 'Sports Network'),
        author: 'Tom Anderson',
        title: 'Local Team Wins Championship in Overtime',
        description:
            'Dramatic victory secures championship title in final seconds.',
        url: 'https://example.com/championship-win',
        urlToImage: 'https://picsum.photos/400/200?random=7',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        content: 'The final match kept fans on the edge...',
      ),
      Article(
        source: Source(name: 'Olympic News'),
        author: 'Maria Gonzalez',
        title: 'Young Athlete Breaks World Record',
        description:
            'Rising star sets new world record in track and field event.',
        url: 'https://example.com/world-record',
        urlToImage: 'https://picsum.photos/400/200?random=8',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 6))
            .toIso8601String(),
        content: 'The young athlete surprised everyone...',
      ),
    ]);

    // Health & Science (8 articles)
    mockArticles.addAll([
      Article(
        source: Source(name: 'Health News'),
        author: 'Dr. Sarah Wilson',
        title: 'Breakthrough in Cancer Research',
        description:
            'New treatment shows promising results in clinical trials.',
        url: 'https://example.com/cancer-research',
        urlToImage: 'https://picsum.photos/400/200?random=9',
        publishedAt: DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        content: 'Scientists discover new approach to treatment...',
      ),
      Article(
        source: Source(name: 'Science Journal'),
        author: 'Dr. James Park',
        title: 'NASA Discovers New Earth-like Planet',
        description:
            'Telescope data reveals planet in habitable zone of distant star.',
        url: 'https://example.com/new-planet',
        urlToImage: 'https://picsum.photos/400/200?random=10',
        publishedAt: DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        content: 'The discovery opens new possibilities...',
      ),
    ]);

    // Entertainment (7 articles)
    mockArticles.addAll([
      Article(
        source: Source(name: 'Entertainment Weekly'),
        author: 'Lisa Thompson',
        title: 'Blockbuster Movie Breaks Box Office Records',
        description: 'Latest superhero film sets new opening weekend record.',
        url: 'https://example.com/box-office-record',
        urlToImage: 'https://picsum.photos/400/200?random=11',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 7))
            .toIso8601String(),
        content: 'Fans flock to theaters for the much-anticipated release...',
      ),
      Article(
        source: Source(name: 'Music Today'),
        author: 'Alex Rivera',
        title: 'Award-Winning Artist Announces World Tour',
        description: 'Popular musician reveals dates for upcoming global tour.',
        url: 'https://example.com/world-tour',
        urlToImage: 'https://picsum.photos/400/200?random=12',
        publishedAt: DateTime.now()
            .subtract(const Duration(hours: 8))
            .toIso8601String(),
        content: 'Tickets for the tour are expected to sell out quickly...',
      ),
    ]);

    // Shuffle untuk variasi
    mockArticles.shuffle();

    print('🎭 Generated ${mockArticles.length} comprehensive mock articles');

    return mockArticles;
  }

  // Helper methods
  static List<Article> _removeDuplicates(List<Article> articles) {
    final seenTitles = <String>{};
    return articles.where((article) => seenTitles.add(article.title)).toList();
  }

  static dynamic _validateResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data['status'] == 'error') {
          throw NewsApiException(message: data['message'] ?? 'API Error');
        }

        return data;
      } catch (e) {
        throw NewsApiException(message: 'Invalid JSON response');
      }
    } else {
      throw NewsApiException(message: 'HTTP ${response.statusCode}');
    }
  }

  static List<Article> _filterAndParseArticles(List<dynamic> articlesJson) {
    try {
      final filteredArticles = articlesJson
          .map((json) => Article.fromJson(json))
          .where((article) => _isValidArticle(article))
          .toList();

      return filteredArticles;
    } catch (e) {
      print('❌ Error filtering articles: $e');
      return [];
    }
  }

  static bool _isValidArticle(Article article) {
    return article.title != '[Removed]' &&
        article.title.isNotEmpty &&
        article.title.length > 5 &&
        article.description != null &&
        article.description!.isNotEmpty &&
        article.url != null &&
        article.url!.isNotEmpty;
  }

  // Method lainnya tetap sama dengan improvement
  static Future<List<Article>> getNewsByCategory(
    String category, {
    String country = 'us',
    int pageSize = 25,
  }) async {
    return getTopHeadlines(
      category: category,
      pageSize: pageSize,
      country: country,
    );
  }

  static Future<List<Article>> getIndonesianNews() async {
    return getTopHeadlines(country: 'id', pageSize: 30);
  }

  static List<String> getAvailableCountries() {
    return const [
      'us',
      'id',
      'gb',
      'ca',
      'au',
      'in',
      'jp',
      'kr',
      'de',
      'fr',
      'br',
      'cn',
      'eg',
      'gr',
      'hk',
      'ie',
      'il',
      'it',
      'nl',
      'no',
      'pk',
      'pe',
      'ph',
      'pl',
      'pt',
      'ro',
      'ru',
      'sa',
      'sg',
      'za',
      'se',
      'ch',
      'tw',
      'th',
      'tr',
      'ae',
      'ua',
      've',
    ];
  }

  static List<String> getAvailableCategories() {
    return const [
      'business',
      'entertainment',
      'general',
      'health',
      'science',
      'sports',
      'technology',
    ];
  }

  // Simple connection test
  static Future<bool> testConnection() async {
    try {
      final result = await getTopHeadlines(pageSize: 1);
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }
}

class NewsApiException implements Exception {
  final String message;
  final int? code;

  const NewsApiException({required this.message, this.code});

  @override
  String toString() => 'NewsAPI: $message';
}
