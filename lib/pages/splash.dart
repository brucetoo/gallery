// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gallery/constants.dart';
import 'package:gallery/layout/adaptive.dart';
import 'package:gallery/pages/home.dart';

const homePeekDesktop = 210.0;
const homePeekMobile = 60.0;

/// SplashPageAnimation继承与InheritedWidget代表需要共享的数据
/// （子widget中需要关心的信息 开屏动画是否结束  isFinished）
/// 访问的方式是通过 SplashPageAnimation.of(ctx).isFinished,
class SplashPageAnimation extends InheritedWidget {
  const SplashPageAnimation({
    Key key,
    @required this.isFinished,
    @required Widget child,
  })  : assert(child != null),
        super(key: key, child: child);

  final bool isFinished;

  static SplashPageAnimation of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType();
  }

  @override
  bool updateShouldNotify(SplashPageAnimation oldWidget) => true; // 无脑重新build子组件
}

class SplashPage extends StatefulWidget {
  const SplashPage({
    Key key,
    @required this.child,
  }) : super(key: key);

  final Widget child;

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  // 混入SingleTickerProviderStateMixin 为带有动画的state中提供ticker回调
  // 一个场景就是当前页的动画还在播放的时候，用户导航到另外一个页面，当前页的动画就没有必要再播放了，
  // 反之在页面切换回来的时候动画有可能还要继续播放，控制的地方就在这里
  AnimationController _controller;
  int _effect;
  final _random = Random();

  // A map of the effect index to its duration. This duration is used to
  // determine how long to display the splash animation at launch.
  //
  // If a new effect is added, this map should be updated.
  final _effectDurations = {
    1: 5,
    2: 4,
    3: 4,
    4: 5,
    5: 5,
    6: 4,
    7: 4,
    8: 4,
    9: 3,
    10: 6,
  };

  bool get _isSplashVisible {
    return _controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.forward;
  }

  @override
  void initState() {
    super.initState();

    // If the number of included effects changes, this number should be changed.
    // _effect = _random.nextInt(_effectDurations.length) + 1;
    _effect = 7;
    _controller = AnimationController(
        duration: const Duration(
          milliseconds: splashPageAnimationDurationInMilliseconds,
        ),
        vsync: this)
      ..addListener(() {  // 这里应该是模板调用方式：每次动画生成一个新的数字时，都会重新build
        setState(() {}); // 注册监听&update state
      });
    // 每个动画中都加这么一句是比较繁琐??? 可以通过AnimatedWidget来封装
    // https://book.flutterchina.club/chapter9/animation_structure.html#_9-2-1-%E5%8A%A8%E7%94%BB%E5%9F%BA%E6%9C%AC%E7%BB%93%E6%9E%84
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Animation => 抽象类 保存动画的插值和状态
  // Animatable => 动画值的映射规则
  // AnimateController => 动画控制 time vsync
  Animation<RelativeRect> _getPanelAnimation(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    // panel区域的高度(去除了额外的区域)
    final height = constraints.biggest.height -
        (isDisplayDesktop(context) ? homePeekDesktop : homePeekMobile);
    // rect的插值计算方式，只改变top
    // 通过Tween.animate(Animation)的方式改变动画执行过程中的值
    return RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 0, 0, 0),
      end: RelativeRect.fromLTRB(0, height, 0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    // 在widget树中，每一个节点都可以分发通知，通知会沿着当前节点向上传递，
    // 所有父节点都可以通过NotificationListener来监听通知
    // NotificationListener必须指定一个模板{ToggleSplashNotification}
    // 且如果指定后只会接收ToggleSplashNotification这个类型的通知
    return NotificationListener<ToggleSplashNotification>(
      // using _, __, etc. for unused callback parameters
      // 如果cb参数未用，则采用_替代,avoid name collisions
      onNotification: (_) {
        _controller.forward();
        // 返回值为true时，阻止冒泡，其父级Widget将再也收不到该通知；
        // 当返回值为false 时继续向上冒泡通知
        return true;
      },
      child: SplashPageAnimation(
        isFinished: _controller.status == AnimationStatus.dismissed,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final animation = _getPanelAnimation(context, constraints);
            // widget代表自身 下面的child，具体是指[Backdrop]
            var frontLayer = widget.child;
            print('splash is visible = $_isSplashVisible - $frontLayer');

            // 闪屏存在与否时，会有不同的子widget
            if (_isSplashVisible) {
              // 对splash屏的手势处理
              frontLayer = GestureDetector(
                // https://book.flutterchina.club/chapter8/listener.html
                // 命中的规则，点击整个范围都有效果
                // deferToChild 子组件命中
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // 高度的从最高到0（隐藏之）
                  _controller.reverse();
                },
                onVerticalDragEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dy < -200) {
                    _controller.reverse();
                  }
                },
                // 让组件本身不接受任何事件
                child: IgnorePointer(child: frontLayer),
              );
            }

            // 桌面设计中的特殊坐标处理
            if (isDisplayDesktop(context)) {
              frontLayer = Padding(
                padding: const EdgeInsets.only(top: 136),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  child: frontLayer,
                ),
              );
            }

            return Stack(
              children: [
                _SplashBackLayer(
                  isSplashCollapsed: !_isSplashVisible,
                  effect: _effect,
                  onTap: () {
                    _controller.forward();
                  },
                ),
                // 基于AnimateWidget封装的PositionedTransition
                // AnimateWidget将animation作为特定含义的参数传入进去
                // 其实Animation本身就是一个listenable
                PositionedTransition( // 只能在 Stack中使用
                  // 当SplashBackLayer往上执行动画的时候，fontLayer 同步往上执行动画
                  rect: animation,
                  child: frontLayer,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SplashBackLayer extends StatelessWidget {
  const _SplashBackLayer({
    Key key,
    @required this.isSplashCollapsed,
    this.effect,
    this.onTap, // pc上logo点击事件外抛出去
  }) : super(key: key);

  final bool isSplashCollapsed;
  final int effect;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    var effectAsset = 'splash_effects/splash_effect_$effect.gif';
    final flutterLogo = Image.asset(
      'assets/logo/flutter_logo.png',
      package: 'flutter_gallery_assets',
    );

    Widget child;
    // 处理闪屏存在和不存在在，pc和mobile的布局异同
    if (isSplashCollapsed) {
      child = isDisplayDesktop(context)
          ? Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Align(
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: onTap,
                  child: flutterLogo,
                ),
              ),
            )
          : null;
    } else {
      child = Container(
         color: Colors.purpleAccent,
         child: Stack(
            children: [
              Center(
                child: Image.asset(
                  effectAsset,
                  package: 'flutter_gallery_assets',
                ),
              ),
              Center(child: flutterLogo),
            ],
          )
      );
    }

    // 去除组件的所有子🌲的语义描述
    return ExcludeSemantics(
      child: Container(
        // This is the background color of the gifs.
        color: const Color(0xFF030303),
        padding: EdgeInsets.only(
          bottom: isDisplayDesktop(context) ? homePeekDesktop : homePeekMobile,
        ),
        child: child,
      ),
    );
  }
}
