// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/constants.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/layout/adaptive.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/home.dart';
import 'package:gallery/pages/settings.dart';
import 'package:gallery/pages/settings_icon/icon.dart' as settings_icon;

const double _settingsButtonWidth = 64;
const double _settingsButtonHeightDesktop = 56;
const double _settingsButtonHeightMobile = 40;

/// 首页 = 设置页面 + 主页面
class Backdrop extends StatefulWidget {
  const Backdrop({
    Key key,
    this.settingsPage,
    this.homePage,
  }) : super(key: key);

  final Widget settingsPage;
  final Widget homePage;

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with TickerProviderStateMixin {
  AnimationController _settingsPanelController;
  AnimationController _iconController;

  // FocusNode来捕捉监听TextField的焦点获取与失去
  FocusNode _settingsPageFocusNode;

  // 监听单个值的变化，需要配合ValueListenableBuilder组件来使用
  ValueNotifier<bool> _isSettingsOpenNotifier;
  Widget _settingsPage;
  Widget _homePage;

  @override
  void initState() {
    super.initState();
    // 设置页面的动画控制器，需要和animator绑定起来
    _settingsPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _settingsPageFocusNode = FocusNode();
    _isSettingsOpenNotifier = ValueNotifier(false);
    // 同时构建setting和home页面
    _settingsPage = widget.settingsPage ??
        SettingsPage(
          animationController: _settingsPanelController,
        );
    _homePage = widget.homePage ?? const HomePage();
  }

  @override
  void dispose() {
    // super之前dispose
    _settingsPanelController.dispose();
    _iconController.dispose();
    _settingsPageFocusNode.dispose();
    _isSettingsOpenNotifier.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    // Animate the settings panel to open or close.
    if (_isSettingsOpenNotifier.value) {
      _settingsPanelController.reverse();
      _iconController.reverse();
    } else {
      _settingsPanelController.forward();
      _iconController.forward();
    }
    // setting页面显示与否的标记切换
    _isSettingsOpenNotifier.value = !_isSettingsOpenNotifier.value;
  }

  Animation<RelativeRect> _slideDownSettingsPageAnimation(
      BoxConstraints constraints) {
    return RelativeRectTween(
      begin: RelativeRect.fromLTRB(0, -constraints.maxHeight, 0, 0),
      end: const RelativeRect.fromLTRB(0, 0, 0, 0),
    ).animate(
      CurvedAnimation(
        parent: _settingsPanelController, // 动画的控制器
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.ease,
        ),
      ),
    );
  }

  Animation<RelativeRect> _slideDownHomePageAnimation(
      BoxConstraints constraints) {
    return RelativeRectTween(
      begin: const RelativeRect.fromLTRB(0, 0, 0, 0),
      // 此处加galleryHeaderHeight会在setting底部留白，可以去掉
      // end: RelativeRect.fromLTRB(
      //   0,
      //   constraints.biggest.height - galleryHeaderHeight,
      //   0,
      //   -galleryHeaderHeight,
      end: RelativeRect.fromLTRB(
        0,
        constraints.biggest.height,
        0,
        0,
      ),
    ).animate(
      CurvedAnimation(
        parent: _settingsPanelController,
        curve: const Interval(
          0.0,
          0.4,
          curve: Curves.ease,
        ),
      ),
    );
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    final isDesktop = isDisplayDesktop(context);

    // ValueListenableBuilder 包裹在此存在的意义是当setting打开或者关闭的时候
    // 需要将焦点在 settingPage 和 homePage 之间主动切换
    // 用于监听某个值的变化后执行不同的build逻辑
    final Widget settingsPage = ValueListenableBuilder<bool>(
      valueListenable: _isSettingsOpenNotifier,
      // 第二个参数是根据泛型中的bool来决定的类型，代表是否setting页面打开
      builder: (context, isSettingsOpen, child) {
        return ExcludeSemantics(
          excluding: !isSettingsOpen,
          // 这坨监听键盘的事件的炒作，委实没看到应用的场景
          child: isSettingsOpen
              ? RawKeyboardListener(
                  includeSemantics: false,
                  focusNode: _settingsPageFocusNode,
                  onKey: (event) {
                    if (event.logicalKey == LogicalKeyboardKey.escape) {
                      _toggleSettings(); // setting value变化后 会执行rebuild
                    }
                  },
                  child: FocusScope(child: _settingsPage), // setting 显示时，聚焦焦点
                )
              : ExcludeFocus(child: _settingsPage), // setting 隐藏后移除焦点
        );
      },
    );

    final Widget homePage = ValueListenableBuilder<bool>(
      valueListenable: _isSettingsOpenNotifier,
      builder: (context, isSettingsOpen, child) {
        return ExcludeSemantics(
          excluding: isSettingsOpen,
          // 控制焦点变化的时候需要这个来配合
          child: FocusTraversalGroup(child: _homePage),
        );
      },
    );

    // 这个很厉害，是在不使用AppBar的情况下 直接改变stateBar的文本颜色
    // 如果存在AppBar可以通过brightness熟悉改变
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 根据主题的配置来确定系统栏的颜色
      value: GalleryOptions.of(context).resolvedSystemUiOverlayStyle(),
      child: Stack(
        // 在数值中 还能有条件判断的写法，厉害
        children: [
          if (!isDesktop) ...[
            // Slides the settings page up and down from the top of the
            // screen.
            PositionedTransition(
              rect: _slideDownSettingsPageAnimation(constraints),
              child: settingsPage,
            ),
            // Slides the home page up and down below the bottom of the
            // screen.
            PositionedTransition(
              rect: _slideDownHomePageAnimation(constraints),
              child: homePage,
            ),
          ],
          if (isDesktop) ...[
            Semantics(sortKey: const OrdinalSortKey(2), child: homePage),
            ValueListenableBuilder<bool>(
              valueListenable: _isSettingsOpenNotifier,
              builder: (context, isSettingsOpen, child) {
                if (isSettingsOpen) {
                  return ExcludeSemantics(
                    child: Listener(
                      onPointerDown: (_) => _toggleSettings(),
                      child: const ModalBarrier(dismissible: false),
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
            Semantics(
              sortKey: const OrdinalSortKey(3),
              child: ScaleTransition(
                alignment: Directionality.of(context) == TextDirection.ltr
                    ? Alignment.topRight
                    : Alignment.topLeft,
                scale: CurvedAnimation(
                  parent: _settingsPanelController,
                  curve: Curves.easeIn,
                  reverseCurve: Curves.easeOut,
                ),
                child: Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Material(
                    elevation: 7,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(40),
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 560,
                        maxWidth: desktopSettingsWidth,
                        minWidth: desktopSettingsWidth,
                      ),
                      child: settingsPage,
                    ),
                  ),
                ),
              ),
            ),
          ],
          _SettingsIcon(
            animationController: _iconController,
            toggleSettings: _toggleSettings,
            isSettingsOpenNotifier: _isSettingsOpenNotifier,
          ),
          _TestIcon(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 使用LayoutBuilder的原因是希望获取整个布局的宽高？
    return LayoutBuilder(
      builder: _buildStack,
    );
  }
}

class _SettingsIcon extends AnimatedWidget {
  const _SettingsIcon(
      {this.animationController,
      this.toggleSettings,
      this.isSettingsOpenNotifier})
      : super(listenable: animationController);

  final AnimationController animationController;
  final VoidCallback toggleSettings;
  final ValueNotifier<bool> isSettingsOpenNotifier;

  String _settingsSemanticLabel(bool isOpen, BuildContext context) {
    return isOpen
        ? GalleryLocalizations.of(context).settingsButtonCloseLabel
        : GalleryLocalizations.of(context).settingsButtonLabel;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    final safeAreaTopPadding = MediaQuery.of(context).padding.top;

    return Align(
      alignment: AlignmentDirectional.topEnd,
      child: Semantics(
        sortKey: const OrdinalSortKey(1),
        button: true,
        enabled: true,
        label: _settingsSemanticLabel(isSettingsOpenNotifier.value, context),
        child: SizedBox(
          width: _settingsButtonWidth,
          height: isDesktop
              ? _settingsButtonHeightDesktop
              : _settingsButtonHeightMobile + safeAreaTopPadding,
          child: Material(
            borderRadius: const BorderRadiusDirectional.only(
              bottomStart: Radius.circular(10),
            ),
            color:
                isSettingsOpenNotifier.value & !animationController.isAnimating
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.secondaryVariant,
            clipBehavior: Clip.antiAlias, // 圆边的抗锯齿
            // InkWell组件是封装了各种事件的组件，必须在Material中使用
            child: InkWell(
              onTap: () {
                toggleSettings();
                SemanticsService.announce(
                  _settingsSemanticLabel(isSettingsOpenNotifier.value, context),
                  GalleryOptions.of(context).resolvedTextDirection(),
                );
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 3, end: 18),
                child: settings_icon.SettingsIcon(animationController.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TestIcon extends StatelessWidget {
  _TestIcon({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headline5.copyWith(color: Colors.white);
    return Align(
        alignment: AlignmentDirectional.bottomCenter,
        child: SizedBox(
            width: 60,
            height: 60,
            child: Material(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: Colors.redAccent,
              child: Align(
                alignment: AlignmentDirectional.center,
                child: InkWell(
                  onTap: () {
                    // 测试_Carousel动画
                    GalleryApp.of(context).bus.fire(ClickTestEvent());
                  },
                  child: Text('CLICK',
                    textAlign: TextAlign.center,
                    style: titleStyle,
                  ),
                ),
              ),
            )));
  }
}
