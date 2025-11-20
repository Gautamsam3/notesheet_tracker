import 'dart:async';
import 'package:flutter/material.dart';

class EventCarouselWidget extends StatefulWidget {
  final String title;
  final List<Map<String, String>> events;
  final AxisDirection scrollDirection;

  const EventCarouselWidget({
    super.key,
    required this.title,
    required this.events,
    this.scrollDirection = AxisDirection.left,
  });

  @override
  State<EventCarouselWidget> createState() => _EventCarouselWidgetState();
}

class _EventCarouselWidgetState extends State<EventCarouselWidget> {
  late final PageController _pageController;
  late final Timer _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);

    // Set up auto scroll every 3 seconds
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_pageController.hasClients && widget.events.isNotEmpty) {
        int nextPage = (_currentPage + 1) % widget.events.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _currentPage = nextPage;
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool reverseScroll = widget.scrollDirection == AxisDirection.right;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.horizontal,
            reverse: reverseScroll,
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return _buildEventCard(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, String> event) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text("📅 ${event['date']}"),
              const SizedBox(height: 4),
              Text("📍 ${event['venue']}"),
            ],
          ),
        ),
      ),
    );
  }
}
