import 'package:flutter/material.dart';

import 'translations.dart';

class AppI18n extends StatefulWidget {
  final Widget child;
  const AppI18n({super.key, required this.child});

  static _AppI18nState of(BuildContext context) {
    final state = context.findAncestorStateOfType<_AppI18nState>();
    if (state == null) throw Exception('AppI18n not found in context');
    return state;
  }

  @override
  State<AppI18n> createState() => _AppI18nState();
}

class _AppI18nState extends State<AppI18n> {
  AppLang _lang = AppLang.en;

  AppLang get lang => _lang;
  Dict get t => translations[_lang]!;

  void setLang(AppLang lang) {
    setState(() => _lang = lang);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
