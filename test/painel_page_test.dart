import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivares_pilates/dados/repositorio.dart';
import 'package:olivares_pilates/telas/painel_page.dart';
import 'package:olivares_pilates/tema/tema.dart';

/// Repositório falso: cada leitura devolve o próximo stream da fila.
class _RepositorioFalso extends Repositorio {
  _RepositorioFalso(this.streams) : super(uid: 'uid-1');

  final List<Stream<ConsultaSnapshot>> streams;
  int leituras = 0;

  Stream<ConsultaSnapshot> _proximo() => streams[leituras++];

  @override
  Stream<ConsultaSnapshot> alunosEmTempoReal() => _proximo();

  @override
  Stream<ConsultaSnapshot> aulasEmTempoReal() => _proximo();
}

Future<void> _abrir(WidgetTester tester, Widget aba) {
  return tester.pumpWidget(
    MaterialApp(
      theme: TemaOlivares.claro,
      home: Scaffold(body: aba),
    ),
  );
}

void main() {
  final semPermissao = FirebaseException(
    plugin: 'cloud_firestore',
    code: 'permission-denied',
  );
  final semConexao = FirebaseException(
    plugin: 'cloud_firestore',
    code: 'unavailable',
  );

  group('RF004 falha na leitura', () {
    testWidgets('alunos: mostra o motivo e tenta de novo ao toque', (
      tester,
    ) async {
      final segundaLeitura = StreamController<ConsultaSnapshot>();
      addTearDown(segundaLeitura.close);
      final repositorio = _RepositorioFalso([
        Stream.error(semConexao),
        segundaLeitura.stream,
      ]);
      await _abrir(tester, AlunosTab(repositorio: repositorio));
      await tester.pump();

      expect(find.text('Não foi possível carregar os alunos'), findsOneWidget);
      expect(find.textContaining('Sem conexão com o servidor'), findsOneWidget);
      expect(repositorio.leituras, 1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(repositorio.leituras, 2);
      expect(find.text('Não foi possível carregar os alunos'), findsNothing);
      expect(find.text('Carregando alunos...'), findsOneWidget);
    });

    testWidgets('aulas: mostra o motivo e tenta de novo ao toque', (
      tester,
    ) async {
      final segundaLeitura = StreamController<ConsultaSnapshot>();
      addTearDown(segundaLeitura.close);
      final repositorio = _RepositorioFalso([
        Stream.error(semPermissao),
        segundaLeitura.stream,
      ]);
      await _abrir(tester, AulasTab(repositorio: repositorio));
      await tester.pump();

      expect(find.text('Não foi possível carregar as aulas'), findsOneWidget);
      expect(find.textContaining('Sem permissão'), findsOneWidget);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(repositorio.leituras, 2);
      expect(find.text('Carregando aulas...'), findsOneWidget);
    });
  });

  testWidgets('enquanto o Firestore não responde, mostra o carregamento', (
    tester,
  ) async {
    final leitura = StreamController<ConsultaSnapshot>();
    addTearDown(leitura.close);
    await _abrir(
      tester,
      AlunosTab(repositorio: _RepositorioFalso([leitura.stream])),
    );

    expect(find.text('Carregando alunos...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
