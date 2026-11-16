// Raiz do app: tema, idioma e a porta de acesso (login ou painel).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'tema/tema.dart';
import 'dados/auth_service.dart';
import 'dados/repositorio.dart';
import 'telas/acesso_pages.dart';
import 'telas/painel_page.dart';
import 'componentes/componentes.dart';

typedef CriadorDeRepositorio = Repositorio Function(String uid);

class OlivaresPilatesApp extends StatelessWidget {
  const OlivaresPilatesApp({
    super.key,
    required this.criarAuth,
    required this.criarRepositorio,
    this.falhaInicial,
  });

  /// Liga o app ao Firebase Authentication e ao Cloud Firestore.
  factory OlivaresPilatesApp.firebase({String? falhaInicial}) {
    return OlivaresPilatesApp(
      criarAuth: FirebaseAuthService.new,
      criarRepositorio: (uid) => Repositorio(uid: uid),
      falhaInicial: falhaInicial,
    );
  }

  final AuthGateway Function() criarAuth;
  final CriadorDeRepositorio criarRepositorio;

  /// Motivo de o Firebase não ter iniciado. Quando existe, o app só mostra
  /// o aviso.
  final String? falhaInicial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olivares Pilates',
      debugShowCheckedModeBanner: false,
      theme: TemaOlivares.claro,
      darkTheme: TemaOlivares.escuro,
      themeMode: ThemeMode.system,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: falhaInicial != null
          ? _FalhaAoIniciar(mensagem: falhaInicial!)
          : PortaDeAcesso(
              auth: criarAuth(),
              criarRepositorio: criarRepositorio,
            ),
    );
  }
}

class _FalhaAoIniciar extends StatelessWidget {
  const _FalhaAoIniciar({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cores.fundo,
      body: EstadoDeTela(
        icone: Icons.cloud_off_outlined,
        titulo: 'Não foi possível iniciar',
        mensagem: mensagem,
        erro: true,
      ),
    );
  }
}

/// Decide entre as telas de acesso e o painel conforme a sessão do
/// Firebase Authentication.
class PortaDeAcesso extends StatefulWidget {
  const PortaDeAcesso({
    super.key,
    required this.auth,
    required this.criarRepositorio,
  });

  final AuthGateway auth;
  final CriadorDeRepositorio criarRepositorio;

  @override
  State<PortaDeAcesso> createState() => _PortaDeAcessoState();
}

class _PortaDeAcessoState extends State<PortaDeAcesso> {
  late Stream<String?> _sessao = widget.auth.uidLogado;
  int _tentativa = 0;

  void _tentarDeNovo() {
    setState(() {
      _tentativa++;
      _sessao = widget.auth.uidLogado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      key: ValueKey(_tentativa),
      stream: _sessao,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: context.cores.fundo,
            body: EstadoDeTela(
              icone: Icons.lock_reset,
              titulo: 'Não foi possível conferir seu acesso',
              mensagem: mensagemDeErroDeAcesso(snapshot.error!),
              rotuloAcao: 'Tentar novamente',
              onAcao: _tentarDeNovo,
              erro: true,
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: context.cores.fundo,
            body: const Carregando(mensagem: 'Conferindo seu acesso...'),
          );
        }
        final uid = snapshot.data;
        if (uid == null) return FluxoDeAcesso(auth: widget.auth);
        return PainelPage(
          key: ValueKey(uid),
          auth: widget.auth,
          repositorio: widget.criarRepositorio(uid),
        );
      },
    );
  }
}
