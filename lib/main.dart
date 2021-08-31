// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:gallery/constants.dart';
import 'package:gallery/data/gallery_options.dart';
import 'package:gallery/pages/backdrop.dart';
import 'package:gallery/pages/splash.dart';
import 'package:gallery/routes.dart';
import 'package:gallery/themes/gallery_theme_data.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:gallery/data/demos.dart' show pumpDeferredLibraries;

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  // debugPaintSizeEnabled = true;
  runApp(const GalleryApp());
}

class GalleryApp extends StatelessWidget {
  // Dart 构造函数有如下特点（https://juejin.cn/post/6844903773094019086#heading-23）
  // 1.可以定义命名构造函数
  // 2.可以在函数体运行之前初始化实例变量
  const GalleryApp({ // 构造函数的命名参数， 也可通过位置参数 fun(pa1, [pa2 = true]) 表示
    Key key,
    this.initialRoute, // final 的变量只可被赋值一次
    this.isTestMode = false, // 默认参数值
  }) : super(key: key);

  final bool isTestMode;
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return ModelBinding(
      initialModel: GalleryOptions(
        themeMode: ThemeMode.system, // 系统的主题
        textScaleFactor: systemTextScaleFactorOption, // 系统字体缩放默认的值
        customTextDirection: CustomTextDirection.localeBased, // 文本默认的方向
        locale: null, // 本地语言环境
        timeDilation: timeDilation, // 时间扩张（动画的执行控制器，方便开发调试动画过程）
        platform: defaultTargetPlatform, // 运行环境标识
        isTestMode: isTestMode, // 默认是非调试模式(debug无)
      ),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            // By default on desktop, scrollbars are applied by the
            // ScrollBehavior. This overrides that. All vertical scrollables in
            // the gallery need to be audited before enabling this feature,
            // see https://github.com/flutter/gallery/issues/523
            scrollBehavior:
                const MaterialScrollBehavior().copyWith(scrollbars: false),
            restorationScopeId: 'rootGallery',
            title: 'Flutter Gallery',
            debugShowCheckedModeBanner: false,
            themeMode: GalleryOptions.of(context).themeMode,
            theme: GalleryThemeData.lightThemeData.copyWith(
              platform: GalleryOptions.of(context).platform,
            ),
            darkTheme: GalleryThemeData.darkThemeData.copyWith(
              platform: GalleryOptions.of(context).platform,
            ),
            localizationsDelegates: const [
              ...GalleryLocalizations.localizationsDelegates,
              LocaleNamesLocalizationsDelegate()
            ],
            initialRoute: initialRoute,
            supportedLocales: GalleryLocalizations.supportedLocales,
            locale: GalleryOptions.of(context).locale,
            localeResolutionCallback: (locale, supportedLocales) {
              deviceLocale = locale;
              return locale;
            },
            // 全局路由控制的钩子，只会对命名的路由生效
            onGenerateRoute: RouteConfiguration.onGenerateRoute,
          );
        },
      ),
    );
  }
}

// 默认的路由页面
class RootPage extends StatelessWidget {
  const RootPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ApplyTextOptions( // 只是套了一个无状态的widget去处理文本的渲染方式而已
      child: SplashPage(
        child: Backdrop(),
      ),
    );
  }
}
