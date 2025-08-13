import 'dart:async';
import 'package:flutter/material.dart';

import 'smart_trio_card.dart';

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
