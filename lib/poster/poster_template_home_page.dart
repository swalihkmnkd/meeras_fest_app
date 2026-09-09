import 'package:flutter/material.dart';
import 'package:meeras_fest_app/poster/poster_template_editor_page.dart';
import 'package:meeras_fest_app/poster/poster_template_provider.dart';
import 'package:provider/provider.dart';

class PosterTemplatesHomePage extends StatelessWidget {
  const PosterTemplatesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PosterTemplateProvider()..fetchAll(),
      child: const PosterTemplateEditorPage(),
    );
  }
}