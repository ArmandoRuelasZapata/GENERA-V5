import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isNetwork;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.isNetwork = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Hero(
            tag: imageUrl,
            child: isNetwork
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    memCacheWidth: 2200,
                    maxWidthDiskCache: 2400,
                    errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50),
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 50),
                  ),
          ),
        ),
      ),
    );
  }
}
