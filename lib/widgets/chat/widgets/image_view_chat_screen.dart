import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewChatScreen extends StatefulWidget {
  const ImageViewChatScreen({super.key, required this.imageUrl});
  final String imageUrl;

  @override
  State<ImageViewChatScreen> createState() => _ImageViewChatScreenState();
}

class _ImageViewChatScreenState extends State<ImageViewChatScreen> {
  bool _chromeVisible = true;

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleChrome,
              child: PhotoView(
                imageProvider: NetworkImage(widget.imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.0,
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorBuilder: (context, error, stack) => const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white54, size: 64),
                ),
              ),
            ),
          ),
          if (_chromeVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out_map, color: Colors.white),
                      tooltip: 'Hide controls',
                      onPressed: _toggleChrome,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
