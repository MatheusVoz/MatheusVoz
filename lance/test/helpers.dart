import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Carrega as fontes reais para que as medidas de texto sejam fieis ao aparelho.
Future<void> carregarFontes() async {
  final familias = {
    'Bungee': ['assets/fonts/Bungee-Regular.ttf'],
    'Fredoka': [
      'assets/fonts/Fredoka-Medium.ttf',
      'assets/fonts/Fredoka-SemiBold.ttf',
      'assets/fonts/Fredoka-Bold.ttf',
    ],
  };
  for (final e in familias.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

/// Tamanhos de tela testados (dp): celular pequeno, medio e grande.
const telas = {
  'pequena': Size(360, 640),
  'media': Size(393, 851),
  'grande': Size(430, 932),
  'tablet': Size(800, 1280),
};

bool gerarCapturas = Platform.environment['CAPTURAS'] == '1';

Future<void> capturar(WidgetTester t, String nome) async {
  if (!gerarCapturas) return;
  // Espera as fotos terminarem de carregar antes de tirar a captura.
  await t.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await t.pump();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nome.png'));
}

Future<void> esperar(WidgetTester t, [int ms = 600]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tocar(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    // Item ainda nao construido em uma lista longa: rola ate ele.
    await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  }
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f, warnIfMissed: false);
  await t.pump();
}
