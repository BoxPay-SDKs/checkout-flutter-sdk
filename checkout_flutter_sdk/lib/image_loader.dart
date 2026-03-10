import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageLoader extends StatefulWidget {
  final String image;
  final Widget errorWidget;

  const ImageLoader({
    Key? key,
    required this.image,
    required this.errorWidget,
  }) : super(key: key);

  @override
  State<ImageLoader> createState() => _ImageLoaderState();
}

class _ImageLoaderState extends State<ImageLoader> {
  bool _error = false;
  bool _load = true;
  String _extractedImage = "";
  String _svgContent = "";

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.image.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(widget.image));
      final text = response.body;

      // 1. CHECK FOR HIDDEN PNGs (Like the Visa logo)
      final base64Match = RegExp(r'xlink:href="(data:image/[^"]+)"').firstMatch(text);

      if (base64Match != null && base64Match.group(1) != null) {
        setState(() {
          _extractedImage = base64Match.group(1)!;
          _load = false;
        });
      } else {
        // 2. CHECK FOR MISSING VIEWBOX (Fixes cropping issue)
        String finalSvg = text;

        if (!finalSvg.contains('viewBox')) {
          final widthMatch = RegExp(r'width="([^"]+)"').firstMatch(text);
          final heightMatch = RegExp(r'height="([^"]+)"').firstMatch(text);

          if (widthMatch != null && heightMatch != null) {
            final w = double.tryParse(widthMatch.group(1)!) ?? 0;
            final h = double.tryParse(heightMatch.group(1)!) ?? 0;

            finalSvg = finalSvg.replaceFirst(
              '<svg ',
              '<svg viewBox="0 0 $w $h" ',
            );
          }
        }

        setState(() {
          _svgContent = finalSvg;
          _load = false;
        });
      }
    } catch (e) {
      debugPrint("SVG Load Error: $e");
      setState(() {
        _error = true;
        _load = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Loading state — shimmer
    if (_load && !_error) {
      return _ShimmerBox();
    }

    // Error state
    if (_error) {
      return FittedBox(
        fit: BoxFit.contain,
        child: widget.errorWidget,
      );
    }

    // PNG-in-SVG (like Visa)
    if (_extractedImage.isNotEmpty) {
  // Strip the data:image/png;base64, prefix and decode
  final base64Str = _extractedImage.split(',').last;
  final bytes = base64Decode(base64Str);
  
  return Image.memory(
    bytes,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => widget.errorWidget,
  );
}

    // Regular SVG
    if (_svgContent.isNotEmpty) {
      return SvgPicture.string(
        _svgContent,
        fit: BoxFit.contain,
      );
    }

    return widget.errorWidget;
  }
}

// Shimmer widget
class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}