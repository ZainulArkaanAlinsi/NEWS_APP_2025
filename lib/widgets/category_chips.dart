import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/news_controller.dart';

// Asumsi: NewsController dan objek category (dengan name, displayName, icon) sudah terdefinisi.

class CategoryChips extends StatelessWidget {
  // Definisi Palet Warna Baru
  static const Color accentColor = Color(
    0xFF00ADB5,
  ); // Teal/Cyan modern untuk status selected
  static const Color darkTextColor = Color(0xFF333333); // Teks gelap netral
  static const Color lightBorderColor = Color(
    0xFFE0E0E0,
  ); // Border sangat tipis untuk chip tidak terpilih

  final NewsController controller = Get.find<NewsController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Tinggi sedikit disesuaikan
      height: 55,
      child: Obx(
        () => ListView.builder(
          scrollDirection: Axis.horizontal,
          // Menggunakan padding horizontal yang sama
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.categories.length,
          itemBuilder: (context, index) {
            final category = controller.categories[index];
            final isSelected =
                controller.selectedCategory.value == category.name;

            return Padding(
              padding: EdgeInsets.only(right: 12),
              child: _buildCategoryChip(category, isSelected),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(dynamic category, bool isSelected) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300), // Durasi transisi lebih halus
      curve: Curves.easeOut,

      // --- STYLE BARU: ELEVATED CHIP ---
      decoration: BoxDecoration(
        // Warna latar belakang: Accent (Teal) jika dipilih, Putih jika tidak
        color: isSelected ? accentColor : Colors.white,

        // Bentuk Pill dengan radius yang sedikit lebih besar
        borderRadius: BorderRadius.circular(28),

        // Border: Border dihilangkan saat terpilih, diganti border tipis saat tidak terpilih
        border: Border.all(
          color: isSelected ? accentColor : lightBorderColor,
          width: isSelected ? 0 : 1.5,
        ),

        // Shadow/BoxShadow: Efek 'Terangkat' yang kuat saat dipilih
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 18,
                  offset: Offset(0, 8), // Kenaikan shadow lebih tinggi
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(
                    0,
                    2,
                  ), // Shadow sangat tipis saat tidak terpilih
                ),
              ],
      ),

      child: Material(
        color: Colors.transparent, // Penting agar ripple InkWell transparan
        child: InkWell(
          onTap: () {
            controller.fetchNewsByCategory(category.name);
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            // Padding vertikal sedikit disesuaikan agar chip lebih ramping
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    category.icon,
                    size: 18, // Ukuran ikon sedikit diperbesar
                    color: isSelected
                        ? Colors.white
                        : darkTextColor.withOpacity(0.8),
                  ),
                ),
                SizedBox(width: 8),

                // Text Style
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 300),
                  style: TextStyle(
                    fontSize: 15, // Ukuran font sedikit diperbesar
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.w600, // Teks lebih tebal saat dipilih
                    color: isSelected ? Colors.white : darkTextColor,
                  ),
                  child: Text(category.displayName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
