import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../controllers/news_controller.dart';

// MENGUBAH ke GetView<NewsController>
class DetailPage extends GetView<NewsController> {
  final Article article;
  // 'controller' (NewsController) sudah tersedia secara otomatis di GetView
  // final NewsController controller = Get.find<NewsController>(); <--- Hapus baris ini

  // Warna-warna dengan design system yang lebih konsisten
  static const Color primaryColor = Color(0xFFE53935);
  static const Color accentColor = Color(0xFF1E88E5);

  DetailPage({Key? key, required this.article}) : super(key: key);

  BuildContext get context => Get.context!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: _buildContent(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  /// Sliver AppBar dengan GetX reactive favorite state
  Widget _buildSliverAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.zero,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image dengan Hero Animation
            Hero(
              tag: 'news_image_${article.url}',
              child:
                  article.urlToImage != null && article.urlToImage!.isNotEmpty
                  ? Image.network(
                      article.urlToImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(context);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildImageShimmer(context);
                      },
                    )
                  : _buildImagePlaceholder(context),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),

            // Source Badge
            Positioned(
              bottom: 24,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  article.source.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Favorite Button dengan GetX reactive state
      actions: [
        _buildCircularActionButton(
          context,
          icon: Obx(
            () => Icon(
              // Menggunakan properti 'controller' otomatis
              controller.isFavorite(article)
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: controller.isFavorite(article)
                  ? primaryColor
                  : Colors.white,
            ),
          ),
          // Menggunakan properti 'controller' otomatis
          onPressed: () => controller.toggleFavorite(article),
        ),
      ],
    );
  }

  /// Circular Action Button
  Widget _buildCircularActionButton(
    BuildContext context, {
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(icon: icon, onPressed: onPressed, color: Colors.white),
    );
  }

  /// Image Placeholder
  Widget _buildImagePlaceholder(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 70,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[500],
            ),
            const SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer Effect untuk Loading Image
  Widget _buildImageShimmer(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Center(child: CircularProgressIndicator(color: primaryColor)),
    );
  }

  /// Main Content
  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(context),
        const SizedBox(height: 20),
        _buildMetaInfo(context),
        const SizedBox(height: 30),
        _buildDescription(context),
        const SizedBox(height: 30),
        if (article.content != null && article.content!.isNotEmpty)
          _buildFullContent(context),

        if ((article.content != null && article.content!.isNotEmpty) ||
            (article.description != null && article.description!.isNotEmpty))
          Divider(
            height: 40,
            thickness: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),

        _buildRelatedNewsSection(context),
        const SizedBox(height: 100),
      ],
    );
  }

  /// Article Title
  Widget _buildTitle(BuildContext context) {
    return Text(
      article.title,
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Meta Information
  Widget _buildMetaInfo(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _buildMetaRow(
            context,
            icon: Icons.access_time_filled_rounded,
            text: _formatDetailDate(article.publishedAt),
          ),
          if (article.author != null &&
              article.author!.isNotEmpty &&
              article.author != 'Unknown Author')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _buildMetaRow(
                context,
                icon: Icons.person_rounded,
                text: 'By ${article.author}',
              ),
            ),
        ],
      ),
    );
  }

  /// Meta Row
  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Description/Section
  Widget _buildDescription(BuildContext context) {
    if (article.description == null || article.description!.isEmpty) {
      return const SizedBox();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDarkMode
                ? accentColor.withOpacity(0.1)
                : accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border(left: BorderSide(color: accentColor, width: 4)),
          ),
          child: Text(
            article.description!,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  /// Full Content Section
  Widget _buildFullContent(BuildContext context) {
    if (article.content == null || article.content!.isEmpty) {
      return const SizedBox();
    }

    // Clean content - remove [+XXXX chars] at the end
    String cleanContent = article.content!;
    final plusIndex = cleanContent.indexOf('[+');
    if (plusIndex != -1) {
      cleanContent = cleanContent.substring(0, plusIndex).trim();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Full Article',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          cleanContent,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Related News Section dengan GetX reactive data
  Widget _buildRelatedNewsSection(BuildContext context) {
    return Obx(() {
      // Menggunakan properti 'controller' otomatis
      if (controller.articles.length <= 1) return const SizedBox();

      final relatedNews = controller.articles
          .where((item) => item.url != article.url)
          .take(3)
          .toList();

      if (relatedNews.isEmpty) return const SizedBox();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More from ${article.source}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          ...relatedNews.map(
            (relatedArticle) => _buildRelatedNewsItem(context, relatedArticle),
          ),
        ],
      );
    });
  }

  /// Related News Item dengan GetX navigation
  Widget _buildRelatedNewsItem(BuildContext context, Article relatedArticle) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Navigasi dengan Get.to()
          onTap: () => Get.to(
            () => DetailPage(article: relatedArticle),
            transition: Transition.cupertino,
            duration: const Duration(milliseconds: 400),
          ),
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        relatedArticle.urlToImage != null &&
                            relatedArticle.urlToImage!.isNotEmpty
                        ? Image.network(
                            relatedArticle.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.article_outlined,
                                color: isDarkMode
                                    ? Colors.grey[600]
                                    : Colors.grey[500],
                                size: 30,
                              );
                            },
                          )
                        : Icon(
                            Icons.article_outlined,
                            color: isDarkMode
                                ? Colors.grey[600]
                                : Colors.grey[500],
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 15),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relatedArticle.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${relatedArticle.source} • ${_timeAgo(relatedArticle.publishedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom Bar
  Widget _buildBottomBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchURL(article.url),
                icon: const Icon(Icons.public_rounded, size: 20),
                label: const Text('Read Full Article'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(width: 15),
            // Share Button
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _shareArticle(),
                  borderRadius: BorderRadius.circular(15),
                  child: Icon(
                    Icons.share_rounded,
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Utility Functions ---

  /// Format tanggal yang lebih informatif
  String _formatDetailDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();

      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      final day = date.day;
      String suffix;

      if (day % 10 == 1 && day % 100 != 11) {
        suffix = 'st';
      } else if (day % 10 == 2 && day % 100 != 12) {
        suffix = 'nd';
      } else if (day % 10 == 3 && day % 100 != 13) {
        suffix = 'rd';
      } else {
        suffix = 'th';
      }

      return '${months[date.month - 1]} $day$suffix, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Recent';
    }
  }

  /// Fungsi untuk menghitung waktu relatif
  String _timeAgo(String dateString) {
    try {
      final now = DateTime.now();
      final date = DateTime.parse(dateString);
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recent';
    }
  }

  /// Launch URL dengan error handling
  void _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackbar('Error', 'Cannot open this link');
      }
    } catch (e) {
      _showSnackbar('Error', 'Failed to open the link');
    }
  }

  /// Share Article Function
  void _shareArticle() async {
    try {
      await Share.share(
        '${article.title}\n\nRead more: ${article.url}',
        subject: 'Check out this news article from ${article.source}',
      );
    } catch (e) {
      _showSnackbar('Share', 'Failed to share article');
    }
  }

  /// Show Snackbar dengan GetX
  void _showSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(context).cardColor,
      colorText: Theme.of(context).colorScheme.onSurface,
      borderRadius: 15,
      margin: const EdgeInsets.all(16),
      icon: Icon(Icons.info_outline, color: primaryColor),
      snackStyle: SnackStyle.FLOATING,
      duration: const Duration(seconds: 3),
    );
  }
}
