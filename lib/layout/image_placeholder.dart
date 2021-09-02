// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';

/// An image that shows a [placeholder] widget while the target [image] is
/// loading, then fades in the new image when it loads.
///
/// This is similar to [FadeInImage] but the difference is that it allows you
/// to specify a widget as a [placeholder], instead of just an [ImageProvider].
/// It also lets you override the [child] argument, in case you want to wrap
/// the image with another widget, for example an [Ink.image].
class FadeInImagePlaceholder extends StatelessWidget {
  const FadeInImagePlaceholder({
    Key key,
    @required this.image,
    @required this.placeholder,
    this.child,
    this.duration = const Duration(milliseconds: 500),
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.fit,
  })  : assert(placeholder != null),
        assert(image != null),
        super(key: key);

  /// The target image that we are loading into memory.
  final ImageProvider image;

  /// Widget displayed while the target [image] is loading.
  final Widget placeholder;

  /// What widget you want to display instead of [placeholder] after [image] is
  /// loaded.
  ///
  /// Defaults to display the [image].
  final Widget child;

  /// The duration for how long the fade out of the placeholder and
  /// fade in of [child] should take.
  final Duration duration;

  /// See [Image.excludeFromSemantics].
  final bool excludeFromSemantics;

  /// See [Image.width].
  final double width;

  /// See [Image.height].
  final double height;

  /// See [Image.fit].
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      excludeFromSemantics: excludeFromSemantics,
      width: width,
      height: height,
      fit: fit,
      // fit: BoxFit.cover,
      // 因为image没有material的ripple效果，且Ink.image没有 frameBuilder这中构造函数
      // Ink.image核心还是对图片进行decoration, 所以通过 Image加载图片（加动画），然后通过
      // Ink.image显示，才有了如此周转的调用方式
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        // 同步加载出来的时候，直接显示即可```（能立即渲染）
        // on the same rendering pipeline frame
        if (wasSynchronouslyLoaded) {
          return this.child ?? child;
        } else {
          // 子元素发生变化时的动态切换，如果只是文本，需要用key: ValueKey 包裹
          return AnimatedSwitcher(
            duration: duration,
            // 存在两种子view placeholder 和 真实的图片 child, 前提是frame是否存在
            // frame = It will be null before the first image frame is ready
            // 加载后的子组件可任意定义，默认是child = image，但是优先看外部的child是否配置
            child: frame != null ? this.child ?? child : placeholder,
          );
        }
      },
    );
  }
}
