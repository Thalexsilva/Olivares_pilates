// Formulários: aluno, aula (RF003) e cadastro do usuário.
//
// Cada formulário grava no Cloud Firestore e fecha devolvendo `true` quando
// deu certo. Se a gravação falha, o formulário continua aberto com o motivo
// e a pessoa pode tentar de novo sem redigitar.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../tema/tema.dart';
import '../dados/auth_service.dart';
import '../dados/modelos.dart';
import '../dados/repositorio.dart';
import '../dados/validadores.dart';
import '../componentes/componentes.dart';

/// Tempo máximo de espera pela confirmação do servidor.
const Duration _prazoDeGravacao = Duration(seconds: 20);

String _mensagemDeFalha(Object erro) {
  if (erro is TimeoutException) {
    return 'O servidor demorou para responder. Confira a internet e salve de '
        'novo se o item não aparecer na lista.';
  }
  return mensagemDeErroDeDados(erro);
}

class _AcoesDoFormulario extends StatelessWidget {
  const _AcoesDoFormulario({
    required this.salvando,
    required this.rotulo,
    required this.onSalvar,
  });

  final bool salvando;
  final String rotulo;
  final VoidCallback onSalvar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BotaoPrincipal(
          key: const Key('formulario-salvar'),
          rotulo: rotulo,
          rotuloEmAndamento: 'Salvando...',
          emAndamento: salvando,
          icone: Icons.check,
          onPressed: onSalvar,
        ),
        const SizedBox(height: Espacos.md),
        TextButton(
          onPressed: salvando ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Coleção `alunos`
// ---------------------------------------------------------------------------

class AlunoFormDialog extends StatefulWidget {
  const AlunoFormDialog({super.key, required this.repositorio, this.aluno});

  final Repositorio repositorio;

  /// `null` para inserir; preenchido para editar.
  final Aluno? aluno;

  @override
  State<AlunoFormDialog> createState() => _AlunoFormDialogState();
}

class _AlunoFormDialogState extends State<AlunoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.aluno?.nome);
  late final _telefone = TextEditingController(text: widget.aluno?.telefone);
  late final _email = TextEditingController(text: widget.aluno?.email);
  late final _objetivo = TextEditingController(text: widget.aluno?.objetivo);
  late String _plano = kPlanosDeAluno.contains(widget.aluno?.plano)
      ? widget.aluno!.plano
      : kPlanosDeAluno.first;
  late bool _ativo = widget.aluno?.ativo ?? true;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.aluno != null;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final aluno = Aluno(
      id: widget.aluno?.id ?? '',
      uid: widget.repositorio.uid,
      nome: _nome.text,
      telefone: formatarTelefone(_telefone.text),
      email: _email.text,
      plano: _plano,
      objetivo: _objetivo.text,
      ativo: _ativo,
    );
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final gravacao = _editando
          ? widget.repositorio.atualizarAluno(aluno)
          : widget.repositorio.inserirAluno(aluno);
      await gravacao.timeout(_prazoDeGravacao);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Os dados não foram salvos. ${_mensagemDeFalha(erro)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario(
      titulo: _editando ? 'Editar aluno' : 'Novo aluno',
      descricao: 'O aluno fica na sua conta e aparece na lista na mesma hora.',
      child: Form(
        key: _formKey,
        // O erro de um campo some assim que a pessoa corrige o valor.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('aluno-nome'),
              controller: _nome,
              enabled: !_salvando,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nome do aluno'),
              validator: validarNome,
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('aluno-telefone'),
              controller: _telefone,
              enabled: !_salvando,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                labelText: 'Telefone com DDD',
                hintText: '(16) 99999-0000',
              ),
              validator: validarTelefone,
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('aluno-email'),
              controller: _email,
              enabled: !_salvando,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'E-mail (opcional)'),
              validator: validarEmailOpcional,
            ),
            espacoEntreCampos,
            DropdownButtonFormField<String>(
              key: const Key('aluno-plano'),
              initialValue: _plano,
              decoration: const InputDecoration(labelText: 'Plano'),
              items: [
                for (final plano in kPlanosDeAluno)
                  DropdownMenuItem(value: plano, child: Text(plano)),
              ],
              onChanged: _salvando
                  ? null
                  : (valor) => setState(() => _plano = valor ?? _plano),
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('aluno-objetivo'),
              controller: _objetivo,
              enabled: !_salvando,
              maxLines: 2,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Objetivo no Pilates',
                hintText: 'Ex.: aliviar dor lombar, ganhar mobilidade',
              ),
              validator: (valor) => (valor ?? '').trim().isEmpty
                  ? 'Informe o objetivo do aluno.'
                  : null,
            ),
            SwitchListTile(
              key: const Key('aluno-ativo'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Aluno ativo'),
              subtitle: const Text('Desligue quando o aluno parar as aulas.'),
              value: _ativo,
              onChanged: _salvando
                  ? null
                  : (valor) => setState(() => _ativo = valor),
            ),
            if (_erro != null) ...[
              const SizedBox(height: Espacos.md),
              FaixaDeMensagem(key: const Key('formulario-erro'), texto: _erro!),
            ],
            espacoEntreCampos,
            _AcoesDoFormulario(
              salvando: _salvando,
              rotulo: _editando ? 'Salvar alterações' : 'Cadastrar aluno',
              onSalvar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coleção `aulas`
// ---------------------------------------------------------------------------

class AulaFormDialog extends StatefulWidget {
  const AulaFormDialog({super.key, required this.repositorio, this.aula});

  final Repositorio repositorio;

  /// `null` para inserir; preenchido para editar.
  final Aula? aula;

  @override
  State<AulaFormDialog> createState() => _AulaFormDialogState();
}

class _AulaFormDialogState extends State<AulaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _titulo = TextEditingController(text: widget.aula?.titulo);
  late final _capacidade = TextEditingController(
    text: (widget.aula?.capacidade ?? 4).toString(),
  );
  late final _observacoes = TextEditingController(
    text: widget.aula?.observacoes,
  );
  late String _modalidade = kModalidadesDeAula.contains(widget.aula?.modalidade)
      ? widget.aula!.modalidade
      : kModalidadesDeAula.first;
  late DateTime _dataHora = widget.aula?.dataHora ?? _proximaHoraCheia();
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.aula != null;

  /// Sugestão de horário: a próxima hora cheia ou, fora do horário de
  /// aula (6h às 21h), a manhã seguinte às 8h.
  static DateTime _proximaHoraCheia() {
    final agora = DateTime.now();
    final proxima = DateTime(
      agora.year,
      agora.month,
      agora.day,
      agora.hour + 1,
    );
    if (proxima.hour >= 6 && proxima.hour <= 21) return proxima;
    final dia = proxima.hour > 21
        ? proxima.add(const Duration(days: 1))
        : proxima;
    return DateTime(dia.year, dia.month, dia.day, 8);
  }

  @override
  void dispose() {
    _titulo.dispose();
    _capacidade.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataHora,
      firstDate: DateTime(hoje.year - 1),
      lastDate: DateTime(hoje.year + 2, 12, 31),
      helpText: 'Dia da aula',
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _dataHora = DateTime(
        escolhida.year,
        escolhida.month,
        escolhida.day,
        _dataHora.hour,
        _dataHora.minute,
      );
    });
  }

  Future<void> _escolherHora() async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataHora),
      helpText: 'Horário da aula',
    );
    if (escolhida == null || !mounted) return;
    setState(() {
      _dataHora = DateTime(
        _dataHora.year,
        _dataHora.month,
        _dataHora.day,
        escolhida.hour,
        escolhida.minute,
      );
    });
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final aula = Aula(
      id: widget.aula?.id ?? '',
      uid: widget.repositorio.uid,
      titulo: _titulo.text,
      dataHora: _dataHora,
      modalidade: _modalidade,
      capacidade: int.parse(_capacidade.text.trim()),
      observacoes: _observacoes.text,
    );
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final gravacao = _editando
          ? widget.repositorio.atualizarAula(aula)
          : widget.repositorio.inserirAula(aula);
      await gravacao.timeout(_prazoDeGravacao);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Os dados não foram salvos. ${_mensagemDeFalha(erro)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dia = DateFormat('EEE, dd/MM/y', 'pt_BR').format(_dataHora);
    final hora = DateFormat.Hm('pt_BR').format(_dataHora);
    return DialogoFormulario(
      titulo: _editando ? 'Editar aula' : 'Nova aula',
      descricao: 'A aula fica na sua conta e aparece na lista na mesma hora.',
      child: Form(
        key: _formKey,
        // O erro de um campo some assim que a pessoa corrige o valor.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('aula-titulo'),
              controller: _titulo,
              enabled: !_salvando,
              autofocus: !_editando,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nome da aula',
                hintText: 'Ex.: Turma da manhã',
              ),
              validator: (valor) => validarNome(valor, campo: 'o nome da aula'),
            ),
            espacoEntreCampos,
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _CampoDeEscolha(
                    key: const Key('aula-data'),
                    rotulo: 'Dia',
                    valor: dia,
                    icone: Icons.calendar_today_outlined,
                    onTap: _salvando ? null : _escolherData,
                  ),
                ),
                const SizedBox(width: Espacos.lg),
                Expanded(
                  flex: 2,
                  child: _CampoDeEscolha(
                    key: const Key('aula-hora'),
                    rotulo: 'Horário',
                    valor: hora,
                    icone: Icons.schedule,
                    onTap: _salvando ? null : _escolherHora,
                  ),
                ),
              ],
            ),
            espacoEntreCampos,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    key: const Key('aula-modalidade'),
                    initialValue: _modalidade,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Modalidade'),
                    items: [
                      for (final modalidade in kModalidadesDeAula)
                        DropdownMenuItem(
                          value: modalidade,
                          child: Text(modalidade),
                        ),
                    ],
                    onChanged: _salvando
                        ? null
                        : (valor) => setState(
                            () => _modalidade = valor ?? _modalidade,
                          ),
                  ),
                ),
                const SizedBox(width: Espacos.lg),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const Key('aula-capacidade'),
                    controller: _capacidade,
                    enabled: !_salvando,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(labelText: 'Vagas'),
                    validator: validarCapacidade,
                  ),
                ),
              ],
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('aula-observacoes'),
              controller: _observacoes,
              enabled: !_salvando,
              maxLines: 2,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Ex.: foco em mobilidade de quadril',
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: Espacos.md),
              FaixaDeMensagem(key: const Key('formulario-erro'), texto: _erro!),
            ],
            espacoEntreCampos,
            _AcoesDoFormulario(
              salvando: _salvando,
              rotulo: _editando ? 'Salvar alterações' : 'Cadastrar aula',
              onSalvar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo que abre um seletor (data ou hora) ao toque.
class _CampoDeEscolha extends StatelessWidget {
  const _CampoDeEscolha({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.onTap,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$rotulo: $valor. Toque para alterar.',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Raios.medium),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: rotulo,
            suffixIcon: Icon(icone, size: 20),
          ),
          child: Text(valor, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coleção `usuarios`: edição do próprio cadastro
// ---------------------------------------------------------------------------

class PerfilDialog extends StatefulWidget {
  const PerfilDialog({
    super.key,
    required this.repositorio,
    required this.email,
    this.usuario,
  });

  final Repositorio repositorio;
  final String email;

  /// `null` quando o documento em `usuarios` ainda não existe.
  final Usuario? usuario;

  @override
  State<PerfilDialog> createState() => _PerfilDialogState();
}

class _PerfilDialogState extends State<PerfilDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario?.nome);
  late final _telefone = TextEditingController(text: widget.usuario?.telefone);
  late final _estudio = TextEditingController(text: widget.usuario?.estudio);
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _estudio.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final usuario = Usuario(
      uid: widget.repositorio.uid,
      nome: _nome.text,
      telefone: formatarTelefone(_telefone.text),
      email: widget.email,
      estudio: _estudio.text,
    );
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.repositorio
          .salvarPerfil(usuario, jaExiste: widget.usuario != null)
          .timeout(_prazoDeGravacao);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = 'Os dados não foram salvos. ${_mensagemDeFalha(erro)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogoFormulario(
      titulo: 'Meu cadastro',
      descricao: 'Conta: ${widget.email}',
      child: Form(
        key: _formKey,
        // O erro de um campo some assim que a pessoa corrige o valor.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('perfil-nome'),
              controller: _nome,
              enabled: !_salvando,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome completo'),
              validator: (valor) => validarNome(valor, campo: 'seu nome'),
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('perfil-telefone'),
              controller: _telefone,
              enabled: !_salvando,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(labelText: 'Telefone com DDD'),
              validator: validarTelefone,
            ),
            espacoEntreCampos,
            TextFormField(
              key: const Key('perfil-estudio'),
              controller: _estudio,
              enabled: !_salvando,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome do estúdio'),
              validator: (valor) =>
                  validarNome(valor, campo: 'o nome do estúdio'),
            ),
            if (_erro != null) ...[
              const SizedBox(height: Espacos.md),
              FaixaDeMensagem(key: const Key('formulario-erro'), texto: _erro!),
            ],
            espacoEntreCampos,
            _AcoesDoFormulario(
              salvando: _salvando,
              rotulo: 'Salvar cadastro',
              onSalvar: _salvar,
            ),
          ],
        ),
      ),
    );
  }
}
