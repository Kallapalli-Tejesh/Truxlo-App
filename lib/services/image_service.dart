import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:image/image.dart' as img;

class ImageService {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'truxlo_images',
      stalePeriod: Duration(days: 7),
      maxNrOfCacheObjects: 200,
      repo: JsonCacheInfoRepository(databaseName: 'truxlo_image_cache'),
    ),
  );

  // Optimized image widget with caching and compression
  static Widget optimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: _cacheManager,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildErrorWidget(),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 600,
    );
  }

  // Compress and resize images before upload
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 600,
    int quality = 85,
  }) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return imageBytes;

    // Resize if necessary
    img.Image resized = image;
    if (image.width > maxWidth || image.height > maxHeight) {
      resized = img.copyResize(
        image,
        width: image.width > maxWidth ? maxWidth : null,
        height: image.height > maxHeight ? maxHeight : null,
        interpolation: img.Interpolation.linear,
      );
    }

    // Compress
    return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
  }

  // Preload critical images
  static Future preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        await _cacheManager.getSingleFile(url);
      } catch (e) {
        // Silently fail for preloading
        continue;
      }
    }
  }

  // Clear image cache when needed
  static Future clearImageCache() async {
    await _cacheManager.emptyCache();
  }

  static Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFE53935),
        ),
      ),
    );
  }

  static Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[600],
          size: 32,
        ),
      ),
    );
  }
} 