import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gallery/deferred_widget.dart';
import 'package:gallery/main.dart';
import 'package:gallery/pages/demo.dart';
import 'package:gallery/pages/home.dart';
import 'package:gallery/studies/crane/app.dart' deferred as crane;
import 'package:gallery/studies/crane/routes.dart' as crane_routes;
import 'package:gallery/studies/fortnightly/app.dart' deferred as fortnightly;
import 'package:gallery/studies/fortnightly/routes.dart' as fortnightly_routes;
import 'package:gallery/studies/rally/app.dart' deferred as rally;
import 'package:gallery/studies/rally/routes.dart' as rally_routes;
import 'package:gallery/studies/reply/app.dart' as reply;
import 'package:gallery/studies/reply/routes.dart' as reply_routes;
import 'package:gallery/studies/shrine/app.dart' deferred as shrine;
import 'package:gallery/studies/shrine/routes.dart' as shrine_routes;
import 'package:gallery/studies/starter/app.dart' as starter_app;
import 'package:gallery/studies/starter/routes.dart' as starter_app_routes;

typedef PathWidgetBuilder = Widget Function(BuildContext, String);

class Path {
  const Path(this.pattern, this.builder);

  /// A RegEx string for route matching.
  final String pattern;

  /// The builder for the associated pattern route. The first argument is the
  /// [BuildContext] and the second argument a RegEx match if that is included
  /// in the pattern.
  ///
  /// ```dart
  /// Path(
  ///   'r'^/demo/([\w-]+)$',
  ///   (context, matches) => Page(argument: match),
  /// )
  /// ```
  final PathWidgetBuilder builder;
}

// 路由配置表
class RouteConfiguration {
  /// List of [Path] to for route matching. When a named route is pushed with
  /// [Navigator.pushNamed], the route name is matched with the [Path.pattern]
  /// in the list below. As soon as there is a match, the associated builder
  /// will be returned. This means that the paths higher up in the list will
  /// take priority.
  static List<Path> paths = [
    Path(
      r'^' + DemoPage.baseRoute + r'/([\w-]+)$',
      (context, match) => DemoPage(slug: match),
    ),
    Path(
      r'^' + rally_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(rally.loadLibrary,
            () => rally.RallyApp()), // ignore: prefer_const_constructors
      ),
    ),
    Path(
      r'^' + shrine_routes.homeRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(shrine.loadLibrary,
            () => shrine.ShrineApp()), // ignore: prefer_const_constructors
      ),
    ),
    Path(
      r'^' + crane_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(crane.loadLibrary,
            () => crane.CraneApp(), // ignore: prefer_const_constructors
            placeholder: const DeferredLoadingPlaceholder(name: 'Crane')),
      ),
    ),
    Path(
      r'^' + fortnightly_routes.defaultRoute,
      (context, match) => StudyWrapper(
        study: DeferredWidget(
            fortnightly.loadLibrary,
            // ignore: prefer_const_constructors
            () => fortnightly.FortnightlyApp()),
      ),
    ),
    Path(
        r'^' + reply_routes.homeRoute,
        // ignore: prefer_const_constructors
        (context, match) =>
            const StudyWrapper(study: reply.ReplyApp(), hasBottomNavBar: true)),
    Path(
      r'^' + starter_app_routes.defaultRoute,
      (context, match) => const StudyWrapper(
        study: starter_app.StarterApp(),
      ),
    ),
    Path(  // 默认的根页面
      r'^/', // 这里有个关键的信息 r 前缀的字符串是为了反正 / | 这样的字符会被进行转译
      // 所有r的目的是为了保证 "原始字符串"
      (context, match) => const RootPage(),
    ),
  ];

  /// The route generator callback used when the app is navigated to a named
  /// route. Set it on the [MaterialApp.onGenerateRoute] or
  /// [WidgetsApp.onGenerateRoute] to make use of the [paths] for route
  /// matching.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // 路由匹配，页面跳转
    for (final path in paths) {
      final regExpPattern = RegExp(path.pattern);
      //  'r'^/demo/([\w-]+)$',
      if (regExpPattern.hasMatch(settings.name)) {
        final firstMatch = regExpPattern.firstMatch(settings.name);
        final match = (firstMatch.groupCount == 1) ? firstMatch.group(1) : null;
        // 这个判断就很厉害了，利用了js中无int的概念，0 和 0.00 不等，但是dart环境是相等的
        if (kIsWeb) { // 如果是web的话去掉转场动画
          return NoAnimationMaterialPageRoute<void>(
            builder: (context) => path.builder(context, match),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (context) => path.builder(context, match),
          settings: settings,
        );
      }
    }

    // If no match was found, we let [WidgetsApp.onUnknownRoute] handle it.
    return null;
  }
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
  }) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 直接返回child, 就屏蔽了转场动画，厉害```
    return child;
  }
}

class NoAnimation<T> extends MaterialPageRoute<T> {
  NoAnimation({ @required WidgetBuilder builder,
    RouteSettings settings,}) : super(builder: builder, settings: settings);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
