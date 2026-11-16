// Peças de interface compartilhadas pelas telas.
import 'package:flutter/material.dart';

import '../tema/tema.dart';

enum TomDoAviso { erro, sucesso, info }

/// Aviso rápido no rodapé: confirma ou nega uma ação (login, cadastro,
/// inserção, exclusão).
void mostrarAviso(
  ScaffoldMessengerState messenger,
  Cores cores,
  String texto, {
  TomDoAviso tom = TomDoAviso.sucesso,
}) {
  final (fundo, icone) = switch (tom) {
    TomDoAviso.erro => (cores.erro, Icons.error_outline),
    TomDoAviso.sucesso => (cores.sucesso, Icons.check_circle_outline),
    TomDoAviso.info => (cores.info, Icons.info_outline),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: fundo,
        duration: Duration(seconds: tom == TomDoAviso.erro ? 6 : 4),
        content: Row(
          children: [
            Icon(icone, color: cores.onStatus),
            const SizedBox(width: Espacos.lg),
            Expanded(
              child: Text(texto, style: TextStyle(color: cores.onStatus)),
            ),
          ],
        ),
      ),
    );
}

/// Faixa de mensagem dentro do formulário (erro de login, de cadastro, etc.).
class FaixaDeMensagem extends StatelessWidget {
  const FaixaDeMensagem({
    super.key,
    required this.texto,
    this.tom = TomDoAviso.erro,
  });

  final String texto;
  final TomDoAviso tom;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final (cor, icone) = switch (tom) {
      TomDoAviso.erro => (cores.erro, Icons.error_outline),
      TomDoAviso.sucesso => (cores.sucesso, Icons.check_circle_outline),
      TomDoAviso.info => (cores.info, Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Espacos.lg),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(Raios.medium),
          border: Border.all(color: cor.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: cor, size: 20),
            const SizedBox(width: Espacos.md),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cores.texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de tela cheia: carregando, vazio ou erro com nova tentativa.
class EstadoDeTela extends StatelessWidget {
  const EstadoDeTela({
    super.key,
    required this.icone,
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.iconeAcao,
    this.onAcao,
    this.erro = false,
  });

  final IconData icone;
  final String titulo;
  final String mensagem;
  final String? rotuloAcao;
  final IconData? iconeAcao;
  final VoidCallback? onAcao;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    final cor = erro ? cores.erro : cores.azulPrimario;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Espacos.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, color: cor, size: 34),
              ),
              const SizedBox(height: Espacos.xl),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(color: cores.texto),
              ),
              const SizedBox(height: Espacos.md),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: cores.secundario),
              ),
              if (rotuloAcao != null && onAcao != null) ...[
                const SizedBox(height: Espacos.xxl),
                FilledButton.icon(
                  onPressed: onAcao,
                  icon: Icon(iconeAcao ?? Icons.refresh),
                  label: Text(rotuloAcao!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Carregando extends StatelessWidget {
  const Carregando({super.key, required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: Espacos.xl),
          Text(
            mensagem,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.cores.secundario),
          ),
        ],
      ),
    );
  }
}

/// Moldura das telas de acesso: marca em cima, formulário em um painel.
class PainelDeAcesso extends StatelessWidget {
  const PainelDeAcesso({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: cores.fundo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Espacos.xl,
              vertical: Espacos.xxl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: LogoOlivares(size: 84)),
                  const SizedBox(height: Espacos.lg),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: cores.texto,
                    ),
                  ),
                  const SizedBox(height: Espacos.sm),
                  Text(
                    subtitulo,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cores.secundario,
                    ),
                  ),
                  const SizedBox(height: Espacos.xxl),
                  Container(
                    padding: const EdgeInsets.all(Espacos.xxl),
                    decoration: BoxDecoration(
                      color: cores.superficie,
                      borderRadius: BorderRadius.circular(Raios.large),
                      border: Border.all(color: cores.bordaSuave),
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão principal com indicador de progresso enquanto a ação roda.
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    required this.rotuloEmAndamento,
    required this.emAndamento,
    required this.onPressed,
    this.icone,
  });

  final String rotulo;
  final String rotuloEmAndamento;
  final bool emAndamento;
  final VoidCallback onPressed;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: emAndamento ? null : onPressed,
        child: emAndamento
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: cores.secundario,
                    ),
                  ),
                  const SizedBox(width: Espacos.lg),
                  Text(rotuloEmAndamento),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icone != null) ...[
                    Icon(icone, size: 20),
                    const SizedBox(width: Espacos.md),
                  ],
                  Text(rotulo),
                ],
              ),
      ),
    );
  }
}

/// Caixa de diálogo dos formulários: largura limitada e rolagem própria.
class DialogoFormulario extends StatelessWidget {
  const DialogoFormulario({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.child,
  });

  final String titulo;
  final String descricao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: cores.superficie,
      insetPadding: const EdgeInsets.all(Espacos.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espacos.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                titulo,
                style: textTheme.titleLarge?.copyWith(color: cores.texto),
              ),
              const SizedBox(height: Espacos.sm),
              Text(
                descricao,
                style: textTheme.bodyMedium?.copyWith(color: cores.secundario),
              ),
              const SizedBox(height: Espacos.xxl),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

const SizedBox espacoEntreCampos = SizedBox(height: Espacos.xl);

/// Marca do Olivares. A arte é clara; no tema claro ela é escurecida para
/// ter contraste com o fundo.
class LogoOlivares extends StatelessWidget {
  const LogoOlivares({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/imagens/logo_olivares.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Logo do Olivares',
    );
    if (Theme.of(context).brightness == Brightness.dark) return logo;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        0.62, 0, 0, 0, 0, //
        0, 0.62, 0, 0, 0, //
        0, 0, 0.62, 0, 0, //
        0, 0, 0, 1, 0, //
      ]),
      child: logo,
    );
  }
}
