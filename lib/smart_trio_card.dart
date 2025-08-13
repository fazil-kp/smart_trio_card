library stacked_trio_carousel;

import 'dart:async';

import 'package:flutter/material.dart';

class SmartTrioCard extends StatefulWidget {
  const SmartTrioCard({super.key, required this.background, required this.children, required this.params, this.routeObserver, this.controller}) : assert(children.length == 3, "the children list should contain exactly 3 items.");

  final Widget background;
  final List<Widget> children;
  final RouteObserver? routeObserver;
  final SmartTrioCardParams params;
  final SmartTrioCardController? controller;

  @override
  State<SmartTrioCard> createState() => _SmartTrioCardState();
}

class _SmartTrioCardState extends State<SmartTrioCard> with TickerProviderStateMixin, RouteAware {
  late double _verticalStartingPoint;

  final List<OverlayEntry> _overlayEntries = [];

  late List<Widget> _children;

  late SmartTrioCardController _controller;

  @override
  void initState() {
    _controller = widget.controller ?? SmartTrioCardController(tickerProvider: this);

    _controller.onAnimationStart = _handleAnimationStart;
    _controller.onAnimationEnd = _handleAnimationEnd;
    _controller.onAnimationProgress = _listenToAnimationChanges;

    _children = List.from(widget.children);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      try {
        RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final size = renderBox!.size;
        final centerPoint = renderBox.size.height / 2;
        final offset = renderBox.localToGlobal(Offset.zero);

        _verticalStartingPoint = centerPoint - widget.params.cardHeight / 2;
        _controller.initializeAnimations(widget.params, offset.dx, size.width);
      } catch (_) {}

      _generateStackedCards();
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.routeObserver != null) {
      try {
        widget.routeObserver?.subscribe(this, ModalRoute.of(context)!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (widget.routeObserver != null) {
      widget.routeObserver?.unsubscribe(this);
    }

    for (var entry in _overlayEntries) {
      try {
        if (entry.mounted) {
          entry.remove();
        }
      } catch (_) {}
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    Future.delayed(widget.params.appearDuration, () {
      for (var entry in _overlayEntries) {
        if (mounted) {
          try {
            Overlay.of(context).insert(entry);
          } catch (_) {}
        }
      }
    });
  }

  @override
  void didPushNext() {
    Future.delayed(widget.params.disappearDuration, () {
      for (var entry in _overlayEntries) {
        if (entry.mounted) {
          try {
            entry.remove();
          } catch (_) {}
        }
      }
    });

    super.didPushNext();
  }

  void _rearrangeStackedCards() {
    for (var entry in _overlayEntries) {
      if (entry.mounted) {
        entry.remove();
      }
    }

    _children.insert(0, _children.removeLast());
    _generateStackedCards();
  }

  void _generateStackedCards() {
    _overlayEntries.clear();
    for (int i = 0; i < _controller.positionAnimations.length; i++) {
      _overlayEntries.add(_createOverlayEntry(_controller.positionAnimations[i], _controller.opacityAnimations[i], _controller.scaleAnimations[i], _children[i]));
      try {
        Overlay.of(context).insert(_overlayEntries[i]);
      } catch (_) {}
    }
  }

  final LayerLink layerLink = LayerLink();

  OverlayEntry _createOverlayEntry(Animation<double?> animation, Animation<double?> opacity, Animation<double?> scale, Widget child) {
    return OverlayEntry(
      builder: (ctx) => AnimatedBuilder(
        animation: animation,
        builder: (ctx, _) {
          return Positioned(
            height: widget.params.cardHeight,
            width: widget.params.cardWidth,
            child: CompositedTransformFollower(
              link: layerLink,
              showWhenUnlinked: false,
              offset: Offset(animation.value!, _verticalStartingPoint),
              child: Transform.scale(
                scale: scale.value,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onPanDown: _onPanDown,
                    onPanUpdate: _onPanUpdate,
                    onPanCancel: _onPanCancel,
                    onPanEnd: _onPanEnd,
                    child: IgnorePointer(ignoring: child != _children.last && !_controller.isAnimationCompleted, child: child),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onPanEnd(details) {
    _controller.onUserInteractionEnd();
  }

  void _onPanCancel() {
    _controller.onUserInteractionCancel();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _controller.onUserInteractionUpdate(details, widget.params.cardWidth);
  }

  void _onPanDown(_) {
    _controller.onUserInteractionStart();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: layerLink, child: widget.background);
  }

  void _handleAnimationEnd() {
    switch (_controller.swipingMethod) {
      case SwipingMethod.animationDriven:
        _rearrangeStackedCards();
        break;

      case SwipingMethod.userDriven:
        _rearrangeStackedCards();

        break;
    }
  }

  void _handleAnimationStart() {}

  void _listenToAnimationChanges(double progress) {
    switch (_controller.swipingMethod) {
      case SwipingMethod.animationDriven:
        if (progress > 0.5) {
          if (!_controller.hasPassedMid) {
            for (var entry in _overlayEntries) {
              if (entry.mounted) {
                entry.remove();
              }
            }
            try {
              Overlay.of(context).insert(_overlayEntries.first);
            } catch (_) {}
            try {
              Overlay.of(context).insert(_overlayEntries.last);
            } catch (_) {}
            try {
              Overlay.of(context).insert(_overlayEntries[1]);
            } catch (_) {}
          }
        }
        break;

      case SwipingMethod.userDriven:
        if (_controller.isSwipingforward) {
          if (progress > 0.5) {
            if (!_controller.hasPassedMid) {
              for (var entry in _overlayEntries) {
                if (entry.mounted) {
                  entry.remove();
                }
              }

              try {
                Overlay.of(context).insert(_overlayEntries.first);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries.last);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries[1]);
              } catch (_) {}
            }
          }
        } else {
          if (progress < 0.5) {
            if (!_controller.hasPassedMid) {
              for (var entry in _overlayEntries) {
                if (entry.mounted) {
                  entry.remove();
                }
              }

              try {
                Overlay.of(context).insert(_overlayEntries.first);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries[1]);
              } catch (_) {}
              try {
                Overlay.of(context).insert(_overlayEntries.last);
              } catch (_) {}
            }
          }
        }
        break;
    }
  }
}

class SmartTrioCardParams {
  final double cardHeight;

  final double cardWidth;

  final double scaleRatio;

  final double minimumOpacity;

  final double maximumOpacity;

  final EdgeInsets padding;

  final Duration disappearDuration;

  final Duration appearDuration;

  SmartTrioCardParams({required this.cardHeight, required this.cardWidth, this.padding = EdgeInsets.zero, this.scaleRatio = 0.7, this.minimumOpacity = 0.2, this.maximumOpacity = 1, this.appearDuration = const Duration(milliseconds: 275), this.disappearDuration = const Duration(milliseconds: 50)}) : assert(scaleRatio > 0 && scaleRatio < 1, "Scale ratio should be greater than 0 and smaller than 1"), assert(minimumOpacity >= 0 && minimumOpacity <= 1, "Minimum opacity value should be between 0 and 1"), assert(maximumOpacity >= 0 && maximumOpacity <= 1, "Maximum opacity value should be between 0 and 1"), assert(maximumOpacity > minimumOpacity, "Maximum opacity value should be bigger than minimum opacity value");
}

enum SwipingMethod { animationDriven, userDriven }

class SmartTrioCardController {
  late AnimationController _animationController;

  late List<Animation<double>> positionAnimations;
  late List<Animation<double>> opacityAnimations;
  late List<Animation<double>> scaleAnimations;

  Timer? _timer;

  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  final Duration animationDuration;

  final Duration autoPlayInterval;

  VoidCallback? onAnimationStart;

  VoidCallback? onAnimationEnd;

  void Function(double progress)? onAnimationProgress;

  late SwipingMethod _swipingMethod;

  SwipingMethod get swipingMethod => _swipingMethod;

  bool _isSwipingforward = false;

  bool get isSwipingforward => _isSwipingforward;

  bool _cardSwapped = false;

  bool get cardSwapped => _cardSwapped;

  bool _hasPassedMid = false;

  bool get hasPassedMid => _hasPassedMid;

  bool _autoPlay = true;

  bool get autoPlay => _autoPlay;

  get isAnimationCompleted => _animationController.status == AnimationStatus.completed;

  SmartTrioCardController({required TickerProvider tickerProvider, this.animationDuration = const Duration(seconds: 1), this.autoPlayInterval = const Duration(seconds: 3), bool autoPlay = true}) {
    _animationController = AnimationController(vsync: tickerProvider, duration: animationDuration)
      ..addStatusListener(animationStatusListener)
      ..addListener(_animationListener);

    _autoPlay = autoPlay;
    if (_autoPlay) {
      startAutoPlay();
      _swipingMethod = SwipingMethod.animationDriven;
    } else {
      _swipingMethod = SwipingMethod.userDriven;
    }
  }

  void _animationListener() {
    onAnimationProgress?.call(_animationController.value);
    switch (_swipingMethod) {
      case SwipingMethod.animationDriven:
        if (_animationController.value > 0.5 && !_hasPassedMid) {
          _hasPassedMid = true;
        }
        break;
      case SwipingMethod.userDriven:
        if (_isSwipingforward) {
          if (_animationController.value > 0.5 && !_hasPassedMid) {
            _hasPassedMid = true;
          }
        } else {
          if (_animationController.value < 0.5 && _hasPassedMid) {
            _hasPassedMid = true;
          }
        }
    }
  }

  void animationStatusListener(status) {
    if (status == AnimationStatus.forward) {
      onAnimationStart?.call();
    } else if (status == AnimationStatus.completed) {
      _hasPassedMid = false;
      if (_swipingMethod == SwipingMethod.userDriven) {
        if (_isSwipingforward && !_cardSwapped && _animationController.value == 1) {
          onAnimationEnd?.call();
          _cardSwapped = true;
          _animationController.reset();
        }
      } else {
        if (_animationController.value == 1) {
          onAnimationEnd?.call();
          _animationController.reset();
        }
      }
    }
  }

  void initializeAnimations(SmartTrioCardParams params, xStartPoint, parentWidth) {
    positionAnimations = [
      Tween(
        begin: _firstCardPosition(xPoint: xStartPoint, cardWidth: params.cardWidth, horizontalPadding: params.padding.horizontal, scaleRatio: params.scaleRatio),
        end: _secondCardPosition(cardWidth: params.cardWidth, horizontalPadding: params.padding.horizontal, scaleRatio: params.scaleRatio, width: parentWidth),
      ).animate(_animationController),
      Tween(
        begin: _secondCardPosition(cardWidth: params.cardWidth, horizontalPadding: params.padding.horizontal, scaleRatio: params.scaleRatio, width: parentWidth),
        end: _thirdCardPosition(cardWidth: params.cardWidth, width: parentWidth),
      ).animate(_animationController),
      Tween(
        begin: _thirdCardPosition(cardWidth: params.cardWidth, width: parentWidth),
        end: _firstCardPosition(xPoint: xStartPoint, cardWidth: params.cardWidth, horizontalPadding: params.padding.horizontal, scaleRatio: params.scaleRatio),
      ).animate(_animationController),
    ];

    opacityAnimations = [Tween<double>(begin: params.minimumOpacity, end: params.minimumOpacity).animate(_animationController), Tween<double>(begin: params.minimumOpacity, end: params.maximumOpacity).animate(_animationController), Tween<double>(begin: params.maximumOpacity, end: params.minimumOpacity).animate(_animationController)];

    scaleAnimations = [Tween<double>(begin: params.scaleRatio, end: params.scaleRatio).animate(_animationController), Tween<double>(begin: params.scaleRatio, end: 1).animate(_animationController), Tween<double>(begin: 1, end: params.scaleRatio).animate(_animationController)];
  }

  double _firstCardPosition({required double xPoint, required double cardWidth, required double scaleRatio, required double horizontalPadding}) {
    return xPoint - ((cardWidth - cardWidth * scaleRatio) / 2) + horizontalPadding;
  }

  double _secondCardPosition({required double width, required double cardWidth, required double scaleRatio, required double horizontalPadding}) {
    return width - (cardWidth * scaleRatio + ((cardWidth - cardWidth * scaleRatio) / 2)) - horizontalPadding;
  }

  double _thirdCardPosition({required double width, required double cardWidth}) {
    return (width / 2) - (cardWidth / 2);
  }

  void startAutoPlay() {
    _stopTimer();
    _timer = Timer.periodic(autoPlayInterval, (_) {
      next();
    });
    _autoPlay = true;
    _swipingMethod = SwipingMethod.animationDriven;
  }

  void stopAutoPlay() {
    _stopTimer();
    _autoPlay = false;
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void next() {
    if (!_animationController.isAnimating) {
      _currentIndex = (_currentIndex + 1) % 3;
      _animationController.animateTo(1);
    }
  }

  void previous() {
    if (!_animationController.isAnimating) {
      _currentIndex = (_currentIndex - 1 + 3) % 3;
      _animationController.animateTo(1);
    }
  }

  void stopAnimation() {
    _animationController.stop();
  }

  Future animateTo(double value) {
    return _animationController.animateTo(value);
  }

  void onUserInteractionStart() {
    _stopTimer();
    stopAnimation();
    _cardSwapped = false;
    _hasPassedMid = false;
  }

  void onUserInteractionUpdate(DragUpdateDetails details, double cardWidth) {
    _swipingMethod = SwipingMethod.userDriven;

    if (_isSwipingforward != details.delta.dx < 0) {
      _hasPassedMid = false;
    }
    _isSwipingforward = details.delta.dx < 0;

    if (!_cardSwapped) {
      double value = 1 - (details.globalPosition.dx / cardWidth);
      _animationController.value = value.clamp(0, 1);
    }
  }

  void onUserInteractionCancel() {
    _cardSwapped = false;
    if (_autoPlay) {
      _swipingMethod = SwipingMethod.animationDriven;
    } else {
      _swipingMethod = SwipingMethod.userDriven;
    }
  }

  void onUserInteractionEnd() {
    _cardSwapped = false;
    _swipingMethod = SwipingMethod.animationDriven;

    if (_animationController.value > 0.5 && _animationController.value != 1) {
      _animationController.animateTo(1).then((value) {
        _hasPassedMid = false;
        _isSwipingforward = false;
        if (_autoPlay) {
          _swipingMethod = SwipingMethod.animationDriven;
        } else {
          _swipingMethod = SwipingMethod.userDriven;
        }
      });
    } else if (_animationController.value < 0.5) {
      _animationController.animateTo(0).then((value) {
        _hasPassedMid = false;
      });
    }
    if (_autoPlay) {
      startAutoPlay();
    }
  }

  void dispose() {
    _animationController.dispose();
    _stopTimer();
  }
}
