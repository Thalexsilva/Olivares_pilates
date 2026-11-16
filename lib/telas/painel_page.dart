// Painel: alunos e aulas do usuário logado, em tempo real
// (RF004), com inserção, edição e exclusão (RF003).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../tema/tema.dart';
import '../dados/auth_service.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import 'formularios.dart';
import '../componentes/componentes.dart';

const double _larguraMaxima = 880;

class PainelPage extends StatefulWidget {
  const PainelPage({super.key, required this.auth, required this.repositorio});

  final AuthGateway auth;
  final Repositorio repositorio;

  @override
  State<PainelPage> createState() => _PainelPageState();
}

class _PainelPageState extends State<PainelPage>
    with SingleTickerProviderStateMixin {
  late final TabController _abas = TabController(length: 2, vsync: this)
    ..addListener(_aoTrocarAba);
  late final Stream<DocumentoSnapshot> _usuario = widget.repositorio
      .usuarioEmTempoReal();
  Usuario? _usuarioAtual;

  void _aoTrocarAba() {
    if (!_abas.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _abas.dispose();
    super.dispose();
  }

  Future<void> _sair() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Seus alunos e aulas continuam guardados. Para voltar, entre com '
          'seu e-mail e senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await widget.auth.sair();
  }

  Future<void> _abrirPerfil() async {
    final messenger = ScaffoldMessenger.of(context);
    final cores = context.cores;
    final salvou = await showDialog<bool>(
      context: context,
      builder: (_) => PerfilDialog(
        repositorio: widget.repositorio,
        email: widget.auth.emailAtual ?? _usuarioAtual?.email ?? '',
        usuario: _usuarioAtual,
      ),
    );
    if (salvou == true) {
      mostrarAviso(messenger, cores, 'Cadastro salvo com sucesso.');
    }
  }

  Future<void> _novoAluno() =>
      abrirFormularioDeAluno(context, widget.repositorio);

  Future<void> _novaAula() =>
      abrirFormularioDeAula(context, widget.repositorio);

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final naAbaDeAlunos = _abas.index == 0;
    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: AppBar(
        titleSpacing: Espacos.xl,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoOlivares(size: 30),
            SizedBox(width: Espacos.lg),
            Text('Olivares Pilates'),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('painel-perfil'),
            tooltip: 'Meu cadastro',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _abrirPerfil,
          ),
          IconButton(
            key: const Key('painel-sair'),
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _sair,
          ),
          const SizedBox(width: Espacos.md),
        ],
        bottom: TabBar(
          controller: _abas,
          tabs: const [
            Tab(icon: Icon(Icons.groups_outlined), text: 'Alunos'),
            Tab(icon: Icon(Icons.event_note_outlined), text: 'Aulas'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('painel-novo'),
        onPressed: naAbaDeAlunos ? _novoAluno : _novaAula,
        icon: const Icon(Icons.add),
        label: Text(naAbaDeAlunos ? 'Novo aluno' : 'Nova aula'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _larguraMaxima),
            child: Column(
              children: [
                // Cadastro do usuário, lido de `usuarios/{uid}` em tempo real.
                StreamBuilder<DocumentoSnapshot>(
                  stream: _usuario,
                  builder: (context, snapshot) {
                    final doc = snapshot.data;
                    final dados = doc?.data();
                    _usuarioAtual = (doc != null && dados != null)
                        ? Usuario.fromMap(doc.id, dados)
                        : null;
                    return _Saudacao(
                      usuario: _usuarioAtual,
                      semCadastro: snapshot.hasData && !(doc?.exists ?? false),
                      onCompletar: _abrirPerfil,
                    );
                  },
                ),
                Expanded(
                  child: TabBarView(
                    controller: _abas,
                    children: [
                      AlunosTab(repositorio: widget.repositorio),
                      AulasTab(repositorio: widget.repositorio),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Saudacao extends StatelessWidget {
  const _Saudacao({
    required this.usuario,
    required this.semCadastro,
    required this.onCompletar,
  });

  final Usuario? usuario;
  final bool semCadastro;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    final nome = usuario?.nome.trim() ?? '';
    final estudio = usuario?.estudio.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacos.xl,
        Espacos.xl,
        Espacos.xl,
        Espacos.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nome.isEmpty ? 'Olá!' : 'Olá, ${nome.split(' ').first}!',
            style: textTheme.titleLarge?.copyWith(color: cores.texto),
          ),
          const SizedBox(height: Espacos.xs),
          Text(
            estudio.isEmpty
                ? 'Só você vê os alunos e as aulas desta conta.'
                : '$estudio. Só você vê os alunos e as aulas desta conta.',
            style: textTheme.bodyMedium?.copyWith(color: cores.secundario),
          ),
          if (semCadastro) ...[
            const SizedBox(height: Espacos.lg),
            const FaixaDeMensagem(
              tom: TomDoAviso.info,
              texto:
                  'Seu cadastro está incompleto: falta nome, telefone e '
                  'estúdio.',
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onCompletar,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Completar cadastro'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ações compartilhadas: formulário e exclusão com mensagem de confirmação
// ---------------------------------------------------------------------------

Future<void> abrirFormularioDeAluno(
  BuildContext context,
  Repositorio repositorio, {
  Aluno? aluno,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final cores = context.cores;
  final salvou = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlunoFormDialog(repositorio: repositorio, aluno: aluno),
  );
  if (salvou == true) {
    mostrarAviso(
      messenger,
      cores,
      aluno == null
          ? 'Aluno cadastrado com sucesso.'
          : 'Alterações do aluno salvas com sucesso.',
    );
  }
}

Future<void> abrirFormularioDeAula(
  BuildContext context,
  Repositorio repositorio, {
  Aula? aula,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final cores = context.cores;
  final salvou = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AulaFormDialog(repositorio: repositorio, aula: aula),
  );
  if (salvou == true) {
    mostrarAviso(
      messenger,
      cores,
      aula == null
          ? 'Aula cadastrada com sucesso.'
          : 'Alterações da aula salvas com sucesso.',
    );
  }
}

Future<void> _excluirComConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  required Future<void> Function() excluir,
  required String sucesso,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final cores = context.cores;
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: cores.erro,
            foregroundColor: cores.onStatus,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmou != true) return;
  try {
    await excluir();
    mostrarAviso(messenger, cores, sucesso);
  } catch (erro) {
    mostrarAviso(
      messenger,
      cores,
      'Não foi excluído. ${mensagemDeErroDeDados(erro)}',
      tom: TomDoAviso.erro,
    );
  }
}

enum _AcaoDoItem { editar, excluir }

class _MenuDoItem extends StatelessWidget {
  const _MenuDoItem({required this.onEditar, required this.onExcluir});

  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AcaoDoItem>(
      tooltip: 'Mais ações',
      onSelected: (acao) => switch (acao) {
        _AcaoDoItem.editar => onEditar(),
        _AcaoDoItem.excluir => onExcluir(),
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _AcaoDoItem.editar,
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _AcaoDoItem.excluir,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Excluir'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _CartaoDeItem extends StatelessWidget {
  const _CartaoDeItem({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Material(
      color: cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.medium),
        side: BorderSide(color: cores.bordaSuave),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Espacos.xl,
            Espacos.lg,
            Espacos.md,
            Espacos.lg,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacos.md,
        vertical: Espacos.xs,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Raios.small),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResumoDaLista extends StatelessWidget {
  const _ResumoDaLista(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacos.xs),
      child: Text(
        texto,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: context.cores.secundario),
      ),
    );
  }
}

const EdgeInsets _margemDaLista = EdgeInsets.fromLTRB(
  Espacos.xl,
  Espacos.md,
  Espacos.xl,
  // Espaço para o botão "Novo" não cobrir o último item.
  96,
);

// ---------------------------------------------------------------------------
// RF004: coleção `alunos` com StreamBuilder + ListView
// ---------------------------------------------------------------------------

class AlunosTab extends StatefulWidget {
  const AlunosTab({super.key, required this.repositorio});

  final Repositorio repositorio;

  @override
  State<AlunosTab> createState() => _AlunosTabState();
}

class _AlunosTabState extends State<AlunosTab>
    with AutomaticKeepAliveClientMixin {
  late Stream<ConsultaSnapshot> _alunos = widget.repositorio
      .alunosEmTempoReal();
  int _tentativa = 0;

  @override
  bool get wantKeepAlive => true;

  /// Falhou a leitura: abre o stream de novo.
  void _tentarDeNovo() {
    setState(() {
      _tentativa++;
      _alunos = widget.repositorio.alunosEmTempoReal();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repositorio = widget.repositorio;
    return StreamBuilder<ConsultaSnapshot>(
      key: ValueKey(_tentativa),
      stream: _alunos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EstadoDeTela(
            key: const Key('alunos-erro'),
            icone: Icons.cloud_off_outlined,
            titulo: 'Não foi possível carregar os alunos',
            mensagem: mensagemDeErroDeDados(snapshot.error!),
            rotuloAcao: 'Tentar novamente',
            onAcao: _tentarDeNovo,
            erro: true,
          );
        }
        if (!snapshot.hasData) {
          return const Carregando(mensagem: 'Carregando alunos...');
        }
        final alunos = alunosDoSnapshot(snapshot.data!);
        if (alunos.isEmpty) {
          return EstadoDeTela(
            key: const Key('alunos-vazio'),
            icone: Icons.groups_outlined,
            titulo: 'Nenhum aluno cadastrado',
            mensagem:
                'Cadastre o primeiro aluno. Ele aparece aqui assim que for '
                'salvo.',
            rotuloAcao: 'Cadastrar aluno',
            iconeAcao: Icons.add,
            onAcao: () => abrirFormularioDeAluno(context, repositorio),
          );
        }
        final ativos = alunos.where((aluno) => aluno.ativo).length;
        return ListView.separated(
          key: const Key('alunos-lista'),
          padding: _margemDaLista,
          itemCount: alunos.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: Espacos.lg),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ResumoDaLista(
                '${alunos.length} ${alunos.length == 1 ? 'aluno' : 'alunos'}, '
                '$ativos ${ativos == 1 ? 'ativo' : 'ativos'}',
              );
            }
            final aluno = alunos[index - 1];
            return _AlunoCard(
              aluno: aluno,
              onEditar: () =>
                  abrirFormularioDeAluno(context, repositorio, aluno: aluno),
              onExcluir: () => _excluirComConfirmacao(
                context,
                titulo: 'Excluir ${aluno.nome}?',
                mensagem: 'O cadastro do aluno é apagado e não volta.',
                excluir: () => repositorio.excluirAluno(aluno.id),
                sucesso: 'Aluno excluído.',
              ),
            );
          },
        );
      },
    );
  }
}

class _AlunoCard extends StatelessWidget {
  const _AlunoCard({
    required this.aluno,
    required this.onEditar,
    required this.onExcluir,
  });

  final Aluno aluno;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  String get _iniciais {
    final partes = aluno.nome.trim().split(RegExp(r'\s+'))
      ..removeWhere((parte) => parte.isEmpty);
    if (partes.isEmpty) return '?';
    final primeira = partes.first.characters.first;
    final ultima = partes.length > 1 ? partes.last.characters.first : '';
    return (primeira + ultima).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    final contato = [
      aluno.telefone,
      aluno.email,
    ].where((valor) => valor.isNotEmpty).join(' · ');
    return _CartaoDeItem(
      onTap: onEditar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enfeite: o leitor de tela já lê o nome completo ao lado.
          ExcludeSemantics(
            child: CircleAvatar(
              radius: 22,
              backgroundColor: cores.azulNeblina,
              child: Text(
                _iniciais,
                style: textTheme.labelLarge?.copyWith(
                  color: cores.azulPrimario,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: Espacos.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aluno.nome,
                  style: textTheme.titleMedium?.copyWith(color: cores.texto),
                ),
                const SizedBox(height: Espacos.sm),
                Wrap(
                  spacing: Espacos.md,
                  runSpacing: Espacos.xs,
                  children: [
                    _Etiqueta(texto: aluno.plano, cor: cores.azulPrimario),
                    _Etiqueta(
                      texto: aluno.ativo ? 'Ativo' : 'Inativo',
                      cor: aluno.ativo ? cores.sucesso : cores.secundario,
                    ),
                  ],
                ),
                if (contato.isNotEmpty) ...[
                  const SizedBox(height: Espacos.md),
                  Text(
                    contato,
                    style: textTheme.bodyMedium?.copyWith(
                      color: cores.secundario,
                    ),
                  ),
                ],
                if (aluno.objetivo.isNotEmpty) ...[
                  const SizedBox(height: Espacos.xs),
                  Text(
                    'Objetivo: ${aluno.objetivo}',
                    style: textTheme.bodyMedium?.copyWith(color: cores.texto),
                  ),
                ],
              ],
            ),
          ),
          _MenuDoItem(onEditar: onEditar, onExcluir: onExcluir),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RF004: coleção `aulas` com StreamBuilder + ListView
// ---------------------------------------------------------------------------

class AulasTab extends StatefulWidget {
  const AulasTab({super.key, required this.repositorio});

  final Repositorio repositorio;

  @override
  State<AulasTab> createState() => _AulasTabState();
}

class _AulasTabState extends State<AulasTab>
    with AutomaticKeepAliveClientMixin {
  late Stream<ConsultaSnapshot> _aulas = widget.repositorio.aulasEmTempoReal();
  int _tentativa = 0;

  @override
  bool get wantKeepAlive => true;

  /// Falhou a leitura: abre o stream de novo.
  void _tentarDeNovo() {
    setState(() {
      _tentativa++;
      _aulas = widget.repositorio.aulasEmTempoReal();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final repositorio = widget.repositorio;
    return StreamBuilder<ConsultaSnapshot>(
      key: ValueKey(_tentativa),
      stream: _aulas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EstadoDeTela(
            key: const Key('aulas-erro'),
            icone: Icons.cloud_off_outlined,
            titulo: 'Não foi possível carregar as aulas',
            mensagem: mensagemDeErroDeDados(snapshot.error!),
            rotuloAcao: 'Tentar novamente',
            onAcao: _tentarDeNovo,
            erro: true,
          );
        }
        if (!snapshot.hasData) {
          return const Carregando(mensagem: 'Carregando aulas...');
        }
        final agora = DateTime.now();
        final aulas = aulasDoSnapshot(snapshot.data!, agora: agora);
        if (aulas.isEmpty) {
          return EstadoDeTela(
            key: const Key('aulas-vazio'),
            icone: Icons.event_note_outlined,
            titulo: 'Nenhuma aula cadastrada',
            mensagem:
                'Cadastre a primeira aula. Ela aparece aqui assim que for '
                'salva.',
            rotuloAcao: 'Cadastrar aula',
            iconeAcao: Icons.add,
            onAcao: () => abrirFormularioDeAula(context, repositorio),
          );
        }
        final proximas = aulas
            .where((aula) => !aula.dataHora.isBefore(agora))
            .length;
        return ListView.separated(
          key: const Key('aulas-lista'),
          padding: _margemDaLista,
          itemCount: aulas.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: Espacos.lg),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _ResumoDaLista(
                '${aulas.length} ${aulas.length == 1 ? 'aula' : 'aulas'}, '
                '$proximas por vir',
              );
            }
            final aula = aulas[index - 1];
            return _AulaCard(
              aula: aula,
              passada: aula.dataHora.isBefore(agora),
              onEditar: () =>
                  abrirFormularioDeAula(context, repositorio, aula: aula),
              onExcluir: () => _excluirComConfirmacao(
                context,
                titulo: 'Excluir "${aula.titulo}"?',
                mensagem: 'A aula é apagada e não volta.',
                excluir: () => repositorio.excluirAula(aula.id),
                sucesso: 'Aula excluída.',
              ),
            );
          },
        );
      },
    );
  }
}

class _AulaCard extends StatelessWidget {
  const _AulaCard({
    required this.aula,
    required this.passada,
    required this.onEditar,
    required this.onExcluir,
  });

  final Aula aula;
  final bool passada;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    final dia = DateFormat('dd', 'pt_BR').format(aula.dataHora);
    final mes = DateFormat(
      'MMM',
      'pt_BR',
    ).format(aula.dataHora).replaceAll('.', '').toUpperCase();
    final quando = DateFormat(
      "EEEE, dd/MM/y 'às' HH:mm",
      'pt_BR',
    ).format(aula.dataHora);
    final vagas = aula.capacidade == 1 ? '1 vaga' : '${aula.capacidade} vagas';
    return _CartaoDeItem(
      onTap: onEditar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enfeite: a data completa vem escrita no cartão.
          ExcludeSemantics(
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: Espacos.md),
              decoration: BoxDecoration(
                color: cores.azulNeblina,
                borderRadius: BorderRadius.circular(Raios.small),
              ),
              child: Column(
                children: [
                  Text(
                    dia,
                    style: textTheme.titleLarge?.copyWith(
                      color: cores.azulPrimario,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    mes,
                    style: textTheme.labelSmall?.copyWith(
                      color: cores.azulPrimario,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Espacos.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  aula.titulo,
                  style: textTheme.titleMedium?.copyWith(color: cores.texto),
                ),
                const SizedBox(height: Espacos.sm),
                Wrap(
                  spacing: Espacos.md,
                  runSpacing: Espacos.xs,
                  children: [
                    _Etiqueta(texto: aula.modalidade, cor: cores.azulPrimario),
                    _Etiqueta(texto: vagas, cor: cores.info),
                    _Etiqueta(
                      texto: passada ? 'Já passou' : 'Por vir',
                      cor: passada ? cores.secundario : cores.sucesso,
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.md),
                Text(
                  quando,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cores.secundario,
                  ),
                ),
                if (aula.observacoes.isNotEmpty) ...[
                  const SizedBox(height: Espacos.xs),
                  Text(
                    aula.observacoes,
                    style: textTheme.bodyMedium?.copyWith(color: cores.texto),
                  ),
                ],
              ],
            ),
          ),
          _MenuDoItem(onEditar: onEditar, onExcluir: onExcluir),
        ],
      ),
    );
  }
}
