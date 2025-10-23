import 'package:get/get.dart';
import '../controllers/news_controller.dart';
import '../controllers/theme_controller.dart';

class NewsBinding extends Bindings {
  @override
  void dependencies() {
    // LazyPut: Controller akan dibuat hanya ketika dibutuhkan
    Get.lazyPut<NewsController>(() => NewsController(), fenix: true);
    Get.lazyPut<ThemeController>(() => ThemeController(), fenix: true);
  }
}