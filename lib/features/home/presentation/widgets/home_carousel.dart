import 'dart:async';
import 'package:flutter/material.dart';

class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  int _effectivePage = 0;

  Timer? _autoSlideTimer;
  Timer? _inactivityTimer;

  static const int _largePageOffset = 10000;
  final Duration _autoSlideDuration = const Duration(seconds: 5);
  final Duration _inactivityTimeout = const Duration(seconds: 8);
  final Duration _animationDuration = const Duration(milliseconds: 500);
  final Curve _animationCurve = Curves.easeInOutCubic;

  final List<String> carouselImages = [
    'https://i.pinimg.com/736x/9b/b9/0a/9bb90a1ca47962be2e98d3d7cf20aae5.jpg',
    'https://i.pinimg.com/736x/50/5d/d6/505dd6a4b337879b2da117c5d0b02f0a.jpg',
    'https://i.pinimg.com/736x/8c/bb/21/8cbb212a7d55ca5c8be65044108c059e.jpg',
  ];

  @override
  void initState() {
    super.initState();
    if (carouselImages.isNotEmpty) {
      _effectivePage = carouselImages.length * _largePageOffset;
      _currentPage = 0;

      _pageController = PageController(initialPage: _effectivePage);
      _startAutoSlide();
    } else {
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _inactivityTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    if (carouselImages.length <= 1) return;

    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(_autoSlideDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _effectivePage + 1,
          duration: _animationDuration,
          curve: _animationCurve,
        );
      }
    });
  }

  void _stopAutoSlideAndSetupInactivityTimer() {
    _autoSlideTimer?.cancel();
    _inactivityTimer?.cancel();

    if (carouselImages.length <= 1) return;

    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (mounted) {
        _startAutoSlide();
      }
    });
  }

  void _navigateToPage(int direction) {
    if (carouselImages.isEmpty || !_pageController.hasClients) return;

    _stopAutoSlideAndSetupInactivityTimer();
    _pageController.animateToPage(
      _effectivePage + direction,
      duration: _animationDuration,
      curve: _animationCurve,
    );
  }

  Color _getPrimaryColor(BuildContext context) {
    try {
      return (context as dynamic).theme.primaryColor;
    } catch (e) {
      return Theme.of(context).primaryColor;
    }
  }

  Color _getSecondaryColor(BuildContext context) {
    try {
      return (context as dynamic).colors.secondary;
    } catch (e) {
      return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carouselImages.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text("Tidak ada gambar untuk ditampilkan.")),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,

                itemCount: null,
                onPageChanged: (index) {
                  if (!mounted) return;
                  setState(() {
                    _effectivePage = index;
                    _currentPage = index % carouselImages.length;
                  });

                  _stopAutoSlideAndSetupInactivityTimer();
                },
                itemBuilder: (context, index) {
                  final actualIndex = index % carouselImages.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(carouselImages[actualIndex]),
                        fit: BoxFit.cover,

                        onError: (exception, stackTrace) {},
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  );
                },
              ),

              if (carouselImages.length > 1)
                Positioned(
                  left: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => _navigateToPage(-1),
                      tooltip: 'Sebelumnya',
                    ),
                  ),
                ),

              if (carouselImages.length > 1)
                Positioned(
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => _navigateToPage(1),
                      tooltip: 'Berikutnya',
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (carouselImages.length > 1) const SizedBox(height: 16),
        if (carouselImages.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              carouselImages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    _currentPage == index ? 4 : 4,
                  ),

                  color:
                      _currentPage == index
                          ? _getPrimaryColor(context)
                          : _getSecondaryColor(context).withOpacity(0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
