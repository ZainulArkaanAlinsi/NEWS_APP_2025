import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/article.dart';
// Jika Anda ingin menggunakan model Source terpisah, Anda harus membuatnya.
// Untuk saat ini, kita ikuti model Article yang source-nya adalah String.

class NewsService {
  // Multiple API keys untuk redundancy
  static const List<String> apiKeys = [
    '9027512d045b4a9bb80ad29b71595f88', // Your current key
  ];

  static const String baseUrl = 'https://newsapi.org/v2';
  static int _currentApiKeyIndex = 0;

  // Enhanced CORS proxies
  static const List<String> corsProxies = [
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
    // 'https://cors-anywhere.herokuapp.com/', // Catatan: Proxy ini sering memerlukan server demo atau tidak stabil
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
    // Rotasi proxy jika CORS gagal
    final proxyUrl = corsProxies[_currentProxyIndex];
    return '$proxyUrl${Uri.encodeComponent(url)}';
  }

  static void _rotateProxy() {
    _currentProxyIndex = (_currentProxyIndex + 1) % corsProxies.length;
    print('🔄 Rotating to proxy: ${corsProxies[_currentProxyIndex]}');
  }

  // Enhanced request dengan multiple fallbacks
  static Future<http.Response> _makeRequest(
    String url, {
    int maxRetries = 3, // Meningkatkan retries sedikit
  }) async {
    String currentUrl = url;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          // Ganti API key di URL yang baru jika sudah dirotasi
          currentUrl = url.replaceAllMapped(
            RegExp(r'apiKey=[^&]+'),
            (match) => 'apiKey=$_currentApiKey',
          );
          // Jika web, pastikan proxy juga diupdate
          if (kIsWeb) {
            currentUrl = _getCurrentProxyUrl(currentUrl);
          }
        }

        print(
          '🌐 Attempt ${attempt + 1}: ${currentUrl.substring(0, currentUrl.length > 100 ? 100 : currentUrl.length)}...',
        );

        final response = await http
            .get(Uri.parse(currentUrl))
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw NewsApiException(message: 'Request timeout'),
            );

        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode == 401 || response.statusCode == 429) {
          // Rotate API key untuk error authorization/rate limit
          _rotateApiKey();
          if (attempt < maxRetries - 1) {
            // Lanjut ke iterasi berikutnya dengan key yang baru
            continue;
          }
        } else {
          // Throw non-retriable HTTP error immediately
          throw NewsApiException(
            message: 'HTTP ${response.statusCode}',
            code: response.statusCode,
          );
        }
      } on NewsApiException {
        // Jika NewsApiException, rethrow agar bisa ditangkap di luar
        rethrow;
      } catch (e) {
        print('❌ Attempt ${attempt + 1} failed: $e');

        if (kIsWeb && attempt < maxRetries - 1) {
          // Rotate proxy hanya jika di web dan retrying
          _rotateProxy();
          await Future.delayed(Duration(seconds: 1 + attempt));
          continue;
        } else if (!kIsWeb && attempt < maxRetries - 1) {
          // Simple delay for non-web retries
          await Future.delayed(Duration(seconds: 1 + attempt));
          continue;
        }

        // Wrap error lainnya menjadi NewsApiException
        throw NewsApiException(message: 'Network/Unknown Error: $e');
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

      // Logika auto-load page 2 dihapus karena ditangani oleh controller: loadMoreArticles()
      // Ini mencegah duplikasi dan loop rekursif yang tidak perlu.

      return filteredArticles;
    } catch (e) {
      print('❌ Error in getTopHeadlines: $e');
      // Fallback to mock data jika semua gagal (hanya untuk page 1)
      if (page == 1) {
        return await _getComprehensiveMockNews();
      }
      throw e; // Lemparkan error untuk subsequent pages
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

      // Logika auto-load page 2 dihapus

      return filteredArticles;
    } catch (e) {
      print('❌ Search failed: $e');
      // Fallback to filtered mock data (hanya untuk page 1)
      if (page == 1) {
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
      throw e;
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

      // Remove duplicates berdasarkan url
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

    // Catatan: Model Article Anda menggunakan 'String' untuk 'source'
    final List<Article> mockArticles = [
      Article(
        source: 'Tech News',
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
        source: 'AI Daily',
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
        source: 'Business Daily',
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
        source: 'Finance Today',
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
      Article(
        source: 'Sports Network',
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
        source: 'Health News',
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
        source: 'Entertainment Weekly',
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
    ];

    // Shuffle untuk variasi
    mockArticles.shuffle();

    print('🎭 Generated ${mockArticles.length} comprehensive mock articles');

    return mockArticles;
  }

  // Helper methods
  static List<Article> _removeDuplicates(List<Article> articles) {
    // Menggunakan URL untuk menghilangkan duplikat (lebih akurat daripada title)
    final seenUrls = <String>{};
    return articles
        .where((article) => article.url.isNotEmpty && seenUrls.add(article.url))
        .toList();
  }

  static dynamic _validateResponse(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data['status'] == 'error') {
          // Tambahkan penanganan kode error spesifik News API
          String errorCode = data['code'] as String? ?? 'UNKNOWN_ERROR';
          String message = data['message'] as String? ?? 'API Error';

          int? httpCode;
          if (errorCode == 'apiKeyInvalid' || errorCode == 'apiKeyDisabled')
            httpCode = 401;
          else if (errorCode == 'rateLimited')
            httpCode = 429;

          throw NewsApiException(message: message, code: httpCode);
        }

        return data;
      } catch (e) {
        if (e is NewsApiException) rethrow;
        throw NewsApiException(message: 'Invalid JSON response');
      }
    } else {
      throw NewsApiException(
        message: 'HTTP ${response.statusCode}',
        code: response.statusCode,
      );
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
        article.url.isNotEmpty; // url di Article model sudah required
  }

  // Method lainnya tetap sama dengan improvement
  static Future<List<Article>> getNewsByCategory(
    String category, {
    String country = 'us',
    int pageSize = 25,
    // Parameter duplikat `required String category` dihapus di sini
  }) async {
    // Karena parameter pertama adalah `category`, maka yang di bawah ini adalah yang benar
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

  // Fungsi 'Source' yang salah dan tidak valid dihapus.
}

class NewsApiException implements Exception {
  final String message;
  final int? code;

  const NewsApiException({required this.message, this.code});

  @override
  String toString() => 'NewsAPI: $message';
}
