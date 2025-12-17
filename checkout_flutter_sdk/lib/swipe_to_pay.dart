import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import this
import 'dart:async';
import 'package:lottie/lottie.dart';

class SwipeToPaySheet extends StatefulWidget {
  final String amount;
  final String last4;
  final String? logoUrl; // 1. Add this field
  final Color merchantColor;
  final Future<void> Function() onSwipeCompleted;
  final VoidCallback onMoreOptions;

  const SwipeToPaySheet({
    Key? key,
    required this.amount,
    required this.last4,
    required this.logoUrl,
    required this.merchantColor,
    required this.onSwipeCompleted,
    required this.onMoreOptions,
  }) : super(key: key);

  @override
  _SwipeToPaySheetState createState() => _SwipeToPaySheetState();
}

class _SwipeToPaySheetState extends State<SwipeToPaySheet> {
  bool isProcessing = false;

  static const String packageName = 'boxpay_checkout_flutter_sdk';


  double _dragValue = 0.0;
  final double _knobWidth = 60.0;
  final double _containerHeight = 54.0;
  final double _padding = 4.0;

  Color _purpleColor = const Color(0xFF000000);
  final Color _mintColor = const Color(0xFFE5F8F2);
  final Color _textColor = const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    String displayAmount = widget.amount.contains("₹") ? widget.amount : "₹${widget.amount}";
    _purpleColor = widget.merchantColor;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: isProcessing 
        
        // ---------------------------------------------------------
        // CASE 1: LOADING (isProcessing = true)
        // Everything else is hidden. Only this list is shown.
        // ---------------------------------------------------------
        ? [
            SizedBox(
              // We give it a fixed height roughly equal to the content 
              // so the sheet doesn't shrink/collapse visually.
              height: 250, 
              child: Center(
                child: Lottie.asset(
                  'assets/animations/BoxPayLogo.json',
                  height: 80, 
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
            )
          ]
          
        // ---------------------------------------------------------
        // CASE 2: CONTENT (isProcessing = false)
        // Header, Card, Slider are shown here.
        // ---------------------------------------------------------
        : [
            // 1. Drag Handle
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // 2. Header (Pay Amount + More Options)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pay $displayAmount", 
                      style: TextStyle(color: _textColor, fontSize: 22, fontFamily: 'Poppins', fontWeight: FontWeight.w800, package: packageName)),
                    const SizedBox(height: 4),
                    const Text("Last Used Payment Option", 
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w500, package: packageName)),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onMoreOptions,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Text("More Options", 
                            style: TextStyle(color: _purpleColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, package: packageName)),
                          Icon(Icons.chevron_right, color: _purpleColor, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 3. Card Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _mintColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildCardIcon(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.last4,
                      style: TextStyle(color: _textColor, fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15, package: packageName),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.radio_button_checked, color: _purpleColor, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 4. Slider
            LayoutBuilder(
              builder: (context, constraints) {
                return _buildCustomSwipeSlider(constraints.maxWidth, displayAmount);
              },
            ),
          ],
      ),
    );
  }

  // 4. Updated Icon Logic to use Logo URL
  Widget _buildCardIcon() {
    // A. Priority: Use URL if available
    if (widget.logoUrl != null && widget.logoUrl!.isNotEmpty) {
      return SizedBox(
        width: 40, 
        height: 25,
        child: SvgPicture.network(
          widget.logoUrl!,
          fit: BoxFit.contain,
          // If SVG fails or is loading, show the fallback
          placeholderBuilder: (context) => Icon(Icons.credit_card, color: _purpleColor, size: 28),
        ),
      );
    }
    
    // B. Fallback: Use manual styles
    return Icon(Icons.credit_card, color: _purpleColor, size: 28);
  }

  Widget _buildCustomSwipeSlider(double maxWidth, String displayAmount) {
    // Total travel distance = Container Width - Knob Width - (Padding * 2)
    final double maxDragDistance = maxWidth - _knobWidth - (_padding * 2);

    return Container(
      height: _containerHeight,
      decoration: BoxDecoration(
        color: _purpleColor,
        borderRadius: BorderRadius.circular(16),
      ),
      // Use Stack to overlay Text and the Moving Knob
      child: Stack(
        children: [
          // 1. Centered Text
          Center(
            child: Opacity(
              // Fade text as you swipe
              opacity: (1 - (_dragValue / maxDragDistance)).clamp(0.0, 1.0), 
              child: Text(
                "Swipe to Pay $displayAmount",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Poppins',fontWeight: FontWeight.w700,package: packageName
                ),
              ),
            ),
          ),

          // 2. The Sliding Knob
          Positioned(
            left: _padding + _dragValue, // Moves based on drag state
            top: _padding,
            bottom: _padding,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  // Update drag value, constrained between 0 and max distance
                  double newValue = _dragValue + details.delta.dx;
                  _dragValue = newValue.clamp(0.0, maxDragDistance);
                });
              },
              onHorizontalDragEnd: (details) async {
                // Check if dragged far enough (e.g., > 90% of the way)
                if (_dragValue > maxDragDistance * 0.9) {
                  // Snap to end
                  setState(() {
                    _dragValue = maxDragDistance;
                  });
                  // Trigger Action
                  try {
                    // 2. Trigger Action and Wait
                    isProcessing = true;
                    await widget.onSwipeCompleted();
                  } catch (e) {
                    // 3. API FAILED: Stop loading and Reset Slider
                    if (mounted) {
                      setState(() {
                        isProcessing = false; // Stop animation
                        _dragValue = 0.0;     // Move knob back to start
                      });
                    }
                  }
                } else {
                  // Snap back to start if not completed
                  setState(() {
                    _dragValue = 0.0;
                  });
                }
              },
              child: Container(
                width: _knobWidth,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(2, 0),
                    )
                  ]
                ),
                child: Center(
                  child: Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    color: _purpleColor,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}