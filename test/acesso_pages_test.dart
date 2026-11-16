import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivares_pilates/dados/auth_service.dart';
import 'package:olivares_pilates/telas/acesso_pages.dart';
import 'package:olivares_pilates/tema/tema.dart';

/// Autenticação falsa: guarda o que as telas pediram e responde como o
/// teste mandar.
class _AuthFalso implements AuthGateway {
  Object? erro;
  Completer<void>? espera;
  bool perfilSalvo = true;

  final List<(String, String)> logins = [];
  final List<String> recuperacoes = [];
  final List<Map<String, String>> cadastros = [];

  Future<void> _responder() async {
    if (espera != null) await espera!.future;
    if (erro != null) throw erro!;
  }

  @override
  Stream<String?> get uidLogado => const Stream.empty();

  @override
  String? get uidAtual => null;

  @override
  String? get emailAtual => null;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    logins.add((email, senha));
    await _responder();
  }

  @override
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String telefone,
    required String estudio,
    required String email,
    required String senha,
  }) async {
    cadastros.add({
      'nome': nome,
      'telefone': telefone,
      'estudio': estudio,
      'email': email,
      'senha': senha,
    });
    await _responder();
    return ResultadoCadastro(uid: 'uid-novo', perfilSalvo: perfilSalvo);
  }

  @override
  Future<void> recuperarSenha(String email) async {
    recuperacoes.add(email);
    await _responder();
  }

  @override
  Future<void> sair() async {}
}

Future<void> _abrir(WidgetTester tester, _AuthFalso auth) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaOlivares.claro,
      home: FluxoDeAcesso(auth: auth),
    ),
  );
}

Future<void> _preencherCadastro(
  WidgetTester tester, {
  String senha = 'Pilates2026',
  String? confirmacao,
}) async {
  await tester.enterText(find.byKey(const Key('cadastro-nome')), 'Ana Souza');
  await tester.enterText(
    find.byKey(const Key('cadastro-telefone')),
    '16999990000',
  );
  await tester.enterText(
    find.byKey(const Key('cadastro-estudio')),
    'Studio Ana',
  );
  await tester.enterText(
    find.byKey(const Key('cadastro-email')),
    'ana@exemplo.com',
  );
  await tester.enterText(find.byKey(const Key('cadastro-senha')), senha);
  await tester.enterText(
    find.byKey(const Key('cadastro-confirmacao')),
    confirmacao ?? senha,
  );
  await tester.pump();
}

void main() {
  group('RF001 login', () {
    testWidgets('campos vazios mostram o que falta e não chamam o Firebase', (
      tester,
    ) async {
      final auth = _AuthFalso();
      await _abrir(tester, auth);

      await tester.tap(find.byKey(const Key('login-entrar')));
      await tester.pump();

      expect(find.text('Informe o e-mail.'), findsOneWidget);
      expect(find.text('Informe a senha.'), findsOneWidget);
      expect(auth.logins, isEmpty);
    });

    testWidgets('mostra o progresso e depois o erro de credencial', (
      tester,
    ) async {
      final auth = _AuthFalso()
        ..espera = Completer<void>()
        ..erro = FirebaseAuthException(code: 'invalid-credential');
      await _abrir(tester, auth);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'ana@exemplo.com',
      );
      await tester.enterText(find.byKey(const Key('login-senha')), 'errada');
      await tester.tap(find.byKey(const Key('login-entrar')));
      await tester.pump();

      expect(find.text('Entrando...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(auth.logins, [('ana@exemplo.com', 'errada')]);

      auth.espera!.complete();
      await tester.pumpAndSettle();

      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.text('Entrando...'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('sem internet explica o motivo', (tester) async {
      final auth = _AuthFalso()
        ..erro = FirebaseAuthException(code: 'network-request-failed');
      await _abrir(tester, auth);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'ana@exemplo.com',
      );
      await tester.enterText(find.byKey(const Key('login-senha')), 'Senha123');
      await tester.tap(find.byKey(const Key('login-entrar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem conexão com a internet'), findsOneWidget);
    });
  });

  group('RF001 recuperação de senha', () {
    testWidgets('envia o link para o e-mail digitado e confirma', (
      tester,
    ) async {
      final auth = _AuthFalso();
      await _abrir(tester, auth);

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'Ana@Exemplo.com',
      );
      await tester.tap(find.byKey(const Key('login-esqueci')));
      await tester.pumpAndSettle();

      expect(find.text('Recuperar senha'), findsOneWidget);
      await tester.tap(find.byKey(const Key('recuperar-enviar')));
      await tester.pumpAndSettle();

      expect(auth.recuperacoes, ['ana@exemplo.com']);
      expect(find.byKey(const Key('recuperar-sucesso')), findsOneWidget);
      expect(find.textContaining('ana@exemplo.com'), findsOneWidget);
    });

    testWidgets('e-mail inválido não envia; falha aparece no diálogo', (
      tester,
    ) async {
      final auth = _AuthFalso()
        ..erro = FirebaseAuthException(code: 'too-many-requests');
      await _abrir(tester, auth);

      await tester.tap(find.byKey(const Key('login-esqueci')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('recuperar-enviar')));
      await tester.pump();
      expect(auth.recuperacoes, isEmpty);

      await tester.enterText(
        find.byKey(const Key('recuperar-email')),
        'ana@exemplo.com',
      );
      await tester.tap(find.byKey(const Key('recuperar-enviar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Muitas tentativas'), findsOneWidget);
      expect(find.byKey(const Key('recuperar-sucesso')), findsNothing);
    });
  });

  group('RF002 cadastro', () {
    Future<void> abrirCadastro(WidgetTester tester, _AuthFalso auth) async {
      await _abrir(tester, auth);
      await tester.tap(find.byKey(const Key('login-criar-conta')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cadastro-criar')), findsOneWidget);
    }

    testWidgets('senha fraca é recusada antes de chamar o Firebase', (
      tester,
    ) async {
      final auth = _AuthFalso();
      await abrirCadastro(tester, auth);
      await _preencherCadastro(tester, senha: 'pilates');

      await tester.tap(find.byKey(const Key('cadastro-criar')));
      await tester.pump();

      expect(
        find.text('A senha ainda não cumpre todos os requisitos abaixo.'),
        findsOneWidget,
      );
      expect(auth.cadastros, isEmpty);
    });

    testWidgets('senhas diferentes são recusadas', (tester) async {
      final auth = _AuthFalso();
      await abrirCadastro(tester, auth);
      await _preencherCadastro(tester, confirmacao: 'Pilates2027');

      await tester.tap(find.byKey(const Key('cadastro-criar')));
      await tester.pump();

      expect(find.text('As senhas não são iguais.'), findsOneWidget);
      expect(auth.cadastros, isEmpty);
    });

    testWidgets('envia nome, telefone, estúdio, e-mail e senha e confirma', (
      tester,
    ) async {
      final auth = _AuthFalso()..espera = Completer<void>();
      await abrirCadastro(tester, auth);
      await _preencherCadastro(tester);

      await tester.tap(find.byKey(const Key('cadastro-criar')));
      await tester.pump();
      expect(find.text('Criando conta...'), findsOneWidget);

      auth.espera!.complete();
      await tester.pumpAndSettle();

      expect(auth.cadastros, [
        {
          'nome': 'Ana Souza',
          'telefone': '(16) 99999-0000',
          'estudio': 'Studio Ana',
          'email': 'ana@exemplo.com',
          'senha': 'Pilates2026',
        },
      ]);
      expect(
        find.text('Conta criada com sucesso. Boas-vindas, Ana!'),
        findsOneWidget,
      );
    });

    testWidgets('e-mail já usado mostra o erro e mantém o formulário', (
      tester,
    ) async {
      final auth = _AuthFalso()
        ..erro = FirebaseAuthException(code: 'email-already-in-use');
      await abrirCadastro(tester, auth);
      await _preencherCadastro(tester);

      await tester.tap(find.byKey(const Key('cadastro-criar')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Já existe uma conta com este e-mail'),
        findsOneWidget,
      );
      expect(find.text('Ana Souza'), findsOneWidget);
    });

    testWidgets('conta criada sem os dados salvos avisa para completar', (
      tester,
    ) async {
      final auth = _AuthFalso()..perfilSalvo = false;
      await abrirCadastro(tester, auth);
      await _preencherCadastro(tester);

      await tester.tap(find.byKey(const Key('cadastro-criar')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('seus dados não foram salvos'),
        findsOneWidget,
      );
    });

    testWidgets('a lista de requisitos acompanha a senha digitada', (
      tester,
    ) async {
      await abrirCadastro(tester, _AuthFalso());
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.enterText(
        find.byKey(const Key('cadastro-senha')),
        'Pilates2026',
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
    });
  });
}
