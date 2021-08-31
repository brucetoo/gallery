// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:gallery/data/gallery_options.dart';

// Common constants between SlowMotionSetting and SettingsListItem.
final settingItemBorderRadius = BorderRadius.circular(10);
const settingItemHeaderMargin = EdgeInsetsDirectional.fromSTEB(32, 0, 32, 8);

class DisplayOption {
  final String title;
  final String subtitle;

  DisplayOption(this.title, {this.subtitle});
}

class SlowMotionSetting extends StatelessWidget {
  const SlowMotionSetting({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final options = GalleryOptions.of(context);

    return Semantics(
      container: true,
      child: Container(
        margin: settingItemHeaderMargin,
        child: Material(
          shape: RoundedRectangleBorder(borderRadius: settingItemBorderRadius),
          color: colorScheme.secondary,
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        GalleryLocalizations.of(context).settingsSlowMotion,
                        style: textTheme.subtitle1.apply(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Switch(
                  activeColor: colorScheme.primary,
                  value: options.timeDilation != 1.0,
                  onChanged: (isOn) => GalleryOptions.update(
                    context,
                    options.copyWith(timeDilation: isOn ? 5.0 : 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsListItem<T> extends StatefulWidget {
  const SettingsListItem({
    Key key,
    @required this.optionsMap,
    @required this.title,
    @required this.selectedOption,
    @required this.onOptionChanged,
    @required this.onTapSetting,
    @required this.isExpanded,
  }) : super(key: key);

  final LinkedHashMap<T, DisplayOption> optionsMap;
  final String title;
  final T selectedOption;
  final ValueChanged<T> onOptionChanged;
  final Function onTapSetting;
  final bool isExpanded;

  @override
  _SettingsListItemState createState() => _SettingsListItemState<T>();
}

class _SettingsListItemState<T> extends State<SettingsListItem<T>>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _childrenHeightFactor; // 子组件高度的因子
  Animation<double> _headerChevronRotation; // icon动画
  Animation<double> _headerSubtitleHeight; // subtitle动画
  Animation<EdgeInsetsGeometry> _headerMargin;
  Animation<EdgeInsetsGeometry> _headerPadding;
  Animation<EdgeInsetsGeometry> _childrenPadding;
  Animation<BorderRadius> _headerBorderRadius;

  // For ease of use. Correspond to the keys and values of `widget.optionsMap`.
  Iterable<T> _options;
  Iterable<DisplayOption> _displayOptions;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    // 注意！！！！！！
    // margin,padding的动画控制，可以使用 EdgeInsetsGeometryTween
    // minWidth/Height的变化，使用BoxConstraintsTween
    // borderRadius的变化，使用BorderRadiusTween

    // Tween.animate(controller) == controller.drive(tween) 类似

    // 子高度当前变化的因子
    _childrenHeightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
    // icon 0 => 90°变化
    _headerChevronRotation =
        Tween<double>(begin: 0, end: 0.5).animate(_controller);
    // 上下左右的位置变为 32 => 0
    _headerMargin = EdgeInsetsGeometryTween(
      begin: settingItemHeaderMargin,
      end: EdgeInsets.zero,
    ).animate(_controller);
    // Tween.animate(controller) == controller.drive(tween);
    _headerPadding = EdgeInsetsGeometryTween(
      begin: const EdgeInsetsDirectional.fromSTEB(16, 10, 0, 10),
      end: const EdgeInsetsDirectional.fromSTEB(32, 18, 32, 20),
    ).animate(_controller);
    // subtitle高度从1到0
    _headerSubtitleHeight =
        _controller.drive(Tween<double>(begin: 1.0, end: 0.0));
    _childrenPadding = EdgeInsetsGeometryTween(
      begin: const EdgeInsets.symmetric(horizontal: 32),
      end: EdgeInsets.zero,
    ).animate(_controller);
    _headerBorderRadius = BorderRadiusTween(
      begin: settingItemBorderRadius,
      end: BorderRadius.zero,
    ).animate(_controller);

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }

    // 将配置的kv分开
    _options = widget.optionsMap.keys;
    _displayOptions = widget.optionsMap.values;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleExpansion() {
    if (widget.isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse().then<void>((value) {
        if (!mounted) {
          return;
        }
      });
    }
  }

  Widget _buildHeaderWithChildren(BuildContext context, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategoryHeader(
          margin: _headerMargin.value,
          padding: _headerPadding.value,
          borderRadius: _headerBorderRadius.value,
          subtitleHeight: _headerSubtitleHeight,
          chevronRotation: _headerChevronRotation,
          title: widget.title,
          subtitle: widget.optionsMap[widget.selectedOption]?.title ?? '',
          onTap: () => widget.onTapSetting(),
        ),
        Padding(
          padding: _childrenPadding.value,
          child: ClipRect(
            child: Align(
              heightFactor: _childrenHeightFactor.value,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 构建时候的展开动画
    _handleExpansion();
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildHeaderWithChildren,
      // 可展开的列表UI(刚好它需要展开的动画，所有直接用AnimationBuilder来控制子组件的动画)
      child: Container(
        constraints: const BoxConstraints(maxHeight: 384), // 控制最大高度
        margin: const EdgeInsetsDirectional.only(start: 24, bottom: 40),
        // 左侧的边界线
        decoration: BoxDecoration(
          border: BorderDirectional(
            start: BorderSide(
              width: 2,
              color: theme.colorScheme.background,
            ),
          ),
        ),
        child: ListView.builder(
          // listview的高度是尽可能大还是包裹住所有item为准。在ScrollView下，必须为true
          shrinkWrap: true,
          itemCount: widget.isExpanded ? _options.length : 0,
          itemBuilder: (context, index) {
            final displayOption = _displayOptions.elementAt(index);
            return RadioListTile<T>(
              value: _options.elementAt(index),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayOption.title,
                    // 这些关于style的使用，基本上都必须是在Material作为基组件下才能生效
                    style: theme.textTheme.bodyText1.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  if (displayOption.subtitle != null)
                    Text(
                      displayOption.subtitle,
                      style: theme.textTheme.bodyText1.copyWith(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.8),
                      ),
                    ),
                ],
              ),
              groupValue: widget.selectedOption,
              onChanged: (newOption) => widget.onOptionChanged(newOption),
              activeColor: Theme.of(context).colorScheme.primary,
              dense: true,
            );
          },
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    Key key,
    this.margin,
    this.padding,
    this.borderRadius,
    this.subtitleHeight,
    this.chevronRotation,
    this.title,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final String title;
  final String subtitle;
  final Animation<double> subtitleHeight;
  final Animation<double> chevronRotation;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: margin,
      child: Material(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        color: colorScheme.secondary,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Padding(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: textTheme.subtitle1.apply(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizeTransition(
                        sizeFactor: subtitleHeight,
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.overline.apply(
                            color: colorScheme.primary,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 8,
                  end: 24,
                ),
                child: RotationTransition(
                  turns: chevronRotation,
                  child: const Icon(Icons.arrow_drop_down),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
