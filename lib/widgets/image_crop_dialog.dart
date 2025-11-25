import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class ImageCropDialog extends StatefulWidget {
  final File imageFile;

  const ImageCropDialog({
    super.key,
    required this.imageFile,
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _uiImage;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      setState(() {
        _uiImage = frame.image;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Crop Avatar',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            onPressed: _isLoading ? null : _cropAndSave,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _uiImage == null
              ? const Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: ClipRect(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: GestureDetector(
                                onScaleUpdate: _onScaleUpdate,
                                child: CustomPaint(
                                  painter: ImageCropPainter(
                                    image: _uiImage!,
                                    scale: _scale,
                                    offset: _offset,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _resetZoom,
                            icon: const Icon(Icons.crop_free,
                                color: Colors.white),
                            tooltip: 'Reset',
                          ),
                          IconButton(
                            onPressed: _zoomIn,
                            icon:
                                const Icon(Icons.zoom_in, color: Colors.white),
                            tooltip: 'Zoom In',
                          ),
                          IconButton(
                            onPressed: _zoomOut,
                            icon:
                                const Icon(Icons.zoom_out, color: Colors.white),
                            tooltip: 'Zoom Out',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Handle scale
      _scale = (_scale * details.scale).clamp(0.5, 3.0);

      // Handle pan (when scale is 1.0, it's just panning)
      if (details.scale == 1.0) {
        _offset += details.focalPointDelta;
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _zoomIn() {
    setState(() {
      _scale = (_scale * 1.2).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _scale = (_scale / 1.2).clamp(0.5, 3.0);
    });
  }

  Future<void> _cropAndSave() async {
    if (_uiImage == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Read original image
      final bytes = await widget.imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        // Calculate crop area
        final imageWidth = originalImage.width;
        final imageHeight = originalImage.height;
        final minDimension = min(imageWidth, imageHeight);

        // Apply scale and offset transformations
        final scaledSize = (minDimension / _scale).round();
        final offsetX = ((imageWidth - scaledSize) / 2 - _offset.dx).round();
        final offsetY = ((imageHeight - scaledSize) / 2 - _offset.dy).round();

        // Crop to square
        final croppedImage = img.copyCrop(
          originalImage,
          x: offsetX.clamp(0, imageWidth - scaledSize),
          y: offsetY.clamp(0, imageHeight - scaledSize),
          width: scaledSize,
          height: scaledSize,
        );

        // Resize to standard avatar size
        final resizedImage = img.copyResize(
          croppedImage,
          width: 400,
          height: 400,
        );

        // Save to temp file
        final tempDir = Directory.systemTemp;
        final tempFile = File(
            '${tempDir.path}/cropped_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 85));

        if (mounted) {
          Navigator.of(context).pop(); // Close loading
          Navigator.of(context).pop(tempFile); // Return cropped file
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to crop image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ImageCropPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;

  ImageCropPainter({
    required this.image,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;

    // Calculate image display size and position
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final containerSize = size;

    // Scale to fit container while maintaining aspect ratio
    final scaleToFit = min(
      containerSize.width / imageSize.width,
      containerSize.height / imageSize.height,
    );

    final scaledImageSize = Size(
      imageSize.width * scaleToFit * scale,
      imageSize.height * scaleToFit * scale,
    );

    // Center the image with offset
    final imageOffset = Offset(
      (containerSize.width - scaledImageSize.width) / 2 + offset.dx,
      (containerSize.height - scaledImageSize.height) / 2 + offset.dy,
    );

    // Draw the image
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
        imageOffset.dx,
        imageOffset.dy,
        scaledImageSize.width,
        scaledImageSize.height,
      ),
      paint,
    );

    // Draw crop grid
    _drawGrid(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    // Draw 3x3 grid
    for (int i = 1; i < 3; i++) {
      final x = size.width / 3 * i;
      final y = size.height / 3 * i;

      // Vertical lines
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      // Horizontal lines
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
