import 'package:get/get.dart';

class Article {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final String publishedAt;
  final Source source;
  final String? author;
  final String? content;

  // RxBool untuk favorite state
  var isFavorite = false.obs;

  Article({
    required this.title,
    this.description,
    required this.url,
    this.urlToImage,
    required this.publishedAt,
    required this.source,
    this.author,
    this.content,
  });

  // Factory constructor dari JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    // Handle source (bisa Map atau String)
    final source = json['source'] is String
        ? Source(name: json['source']?.toString() ?? 'Unknown Source')
        : Source.fromJson(json['source'] ?? {});

    // Handle publishedAt (bisa DateTime atau String)
    String publishedAt;
    if (json['publishedAt'] is DateTime) {
      publishedAt = (json['publishedAt'] as DateTime).toIso8601String();
    } else {
      publishedAt = json['publishedAt']?.toString() ?? '';
    }

    return Article(
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString(),
      url: json['url']?.toString() ?? '',
      urlToImage: json['urlToImage']?.toString(),
      publishedAt: publishedAt,
      source: source,
      author: json['author']?.toString(),
      content: json['content']?.toString(),
    );
  }

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'source': source.toJson(),
      'author': author,
      'content': content,
    };
  }

  // Copy dengan favorite status
  Article copyWith({
    String? title,
    String? description,
    String? url,
    String? urlToImage,
    String? publishedAt,
    Source? source,
    String? author,
    String? content,
    bool? isFavorite,
  }) {
    final article = Article(
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      urlToImage: urlToImage ?? this.urlToImage,
      publishedAt: publishedAt ?? this.publishedAt,
      source: source ?? this.source,
      author: author ?? this.author,
      content: content ?? this.content,
    );
    if (isFavorite != null) {
      article.isFavorite.value = isFavorite;
    }
    return article;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Article && runtimeType == other.runtimeType && url == other.url;

  @override
  int get hashCode => url.hashCode;
}

class Source {
  final String? id;
  final String name;

  Source({
    this.id,
    required this.name,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    return Source(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Unknown Source',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Source &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

// Model untuk response API
class NewsResponse {
  final String? status;
  final int totalResults;
  final List<Article> articles;

  NewsResponse({
    this.status,
    required this.totalResults,
    required this.articles,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    return NewsResponse(
      status: json['status']?.toString(),
      totalResults: json['totalResults'] as int? ?? 0,
      articles: (json['articles'] as List<dynamic>?)
              ?.map((article) => Article.fromJson(article as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'totalResults': totalResults,
      'articles': articles.map((article) => article.toJson()).toList(),
    };
  }
}