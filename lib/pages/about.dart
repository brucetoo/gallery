// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/gallery_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void showAboutDialog({
  @required BuildContext context,
}) {
  assert(context != null);
  showDialog<void>(
    context: context,
    builder: (context) {
      return _AboutDialog();
    },
  );
}

Future<String> getVersionNumber() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

class _AboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyTextStyle =
        textTheme.bodyText1.apply(color: colorScheme.onPrimary);

    const name = 'Flutter Gallery'; // Don't need to localize.
    const legalese = '© 2021 The Flutter team'; // Don't need to localize.
    final repoText = GalleryLocalizations.of(context).githubRepo(name);
    final seeSource =
        GalleryLocalizations.of(context).aboutDialogDescription(repoText);
    final repoLinkIndex = seeSource.indexOf(repoText);
    final repoLinkIndexEnd = repoLinkIndex + repoText.length;
    // 文本的分拆显示处理
    final seeSourceFirst = seeSource.substring(0, repoLinkIndex);
    final seeSourceSecond = seeSource.substring(repoLinkIndexEnd);

    return AlertDialog(
      backgroundColor: colorScheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          // 交叉轴(横轴) 占据布局位置 左对齐
          crossAxisAlignment: CrossAxisAlignment.start,
          // 主轴(纵轴) 以最小来决定空白占据的大小
          mainAxisSize: MainAxisSize.min,
          children: [
            // 异步获取数据 future 用snapshot承载
            FutureBuilder(
              future: getVersionNumber(),
              builder: (context, snapshot) => Text(
                snapshot.hasData ? '$name ${snapshot.data}' : name,
                style: textTheme.headline4.apply(color: colorScheme.onPrimary),
              ),
            ),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    style: bodyTextStyle,
                    text: seeSourceFirst,
                  ),
                  TextSpan(
                    // 类似于js中的merge操作，快速基于一个style创建新的style
                    style: bodyTextStyle.copyWith(
                      color: colorScheme.primary,
                    ),
                    text: repoText,
                    // TextSpan绑定点击事件
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        const url = 'https://github.com/flutter/gallery/';
                        // url_launcher
                        if (await canLaunch(url)) {
                          await launch(
                            url,
                            forceSafariVC: false,
                          );
                        }
                      },
                  ),
                  TextSpan(
                    style: bodyTextStyle,
                    text: seeSourceSecond,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              legalese,
              style: bodyTextStyle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Typography.material2018(
                    platform: Theme.of(context).platform,
                  ).black,
                  cardColor: Colors.white,
                ),
                child: const LicensePage(
                  applicationName: name,
                  applicationLegalese: legalese,
                ),
              ),
            ));
          },
          child: Text(
            MaterialLocalizations.of(context).viewLicensesButtonLabel,
          ),
        ),
        TextButton(
          onPressed: () {
            // 关闭Dialog直接pop即可
            Navigator.pop(context);
          },
          child: Text(MaterialLocalizations.of(context).closeButtonLabel),
        ),
      ],
    );
  }
}
