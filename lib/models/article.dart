import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Article {
  final String title;
  final String? description;
  final String url;
  final String? urlToImage;
  final String publishedAt;
  final String source;
  final String? author;
  final String? content;

  // Tambahkan RxBool untuk favorite state
  var isFavorite = false.obs;

  Article({
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.source,
    required this.author,
    required this.content,
  });

  // Factory constructor untuk membuat Article dari JSON
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title']?.toString() ?? 'No Title',
      description: json['description']?.toString(),
      url: json['url']?.toString() ?? '',
      urlToImage: json['urlToImage']?.toString(),
      publishedAt: json['publishedAt']?.toString() ?? '',
      source: json['source'] is String
          ? json['source']
          : (json['source'] != null
                ? (json['source']['name']?.toString() ?? 'Unknown Source')
                : 'Unknown Source'),
      author: json['author']?.toString(),
      content: json['content']?.toString(),
    );
  }

  // Method untuk convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'source': source,
      'author': author,
      'content': content,
      'isFavorite': isFavorite.value,
    };
  }

  // Method untuk copy dengan favorite status yang berbeda
  Article copyWith({bool? isFavorite}) {
    final article = Article(
      title: title,
      description: description,
      url: url,
      urlToImage: urlToImage,
      publishedAt: publishedAt,
      source: source,
      author: author,
      content: content,
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
