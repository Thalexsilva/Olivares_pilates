// Telas de acesso: login, recuperação de senha (RF001) e
// cadastro (RF002).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tema.dart';
import '../dados/auth_service.dart';
import '../dados/validadores.dart';
import '../componentes/componentes.dart';

/// Alterna entre login e cadastro sem empilhar rotas: quando a sessão abre,
/// a porta de acesso troca tudo pelo painel.
class FluxoDeAcesso extends StatefulWidget {
  const FluxoDeAcesso({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<FluxoDeAcesso> createState() => _FluxoDeAcessoState();
}

class _FluxoDeAcessoState extends State<FluxoDeAcesso> {
  bool _cadastrando = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _cadastrando
          ? CadastroPage(
              key: const ValueKey('cadastro'),
              auth: widget.auth,
              onVoltarParaLogin: () => setState(() => _cadastrando = false),
            )
          : LoginPage(
              key: const ValueKey('login'),
              auth: widget.auth,
              onCriarConta: () => setState(() => _cadastrando = true),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// RF001: login com e-mail e senha
// ---------------------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.auth, required this.onCriarConta});

  final AuthGateway auth;
  final VoidCallback onCriarConta;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocultarSenha = true;
  bool _entrando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_entrando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _entrando = true;
      _erro = null;
    });
    try {
      await widget.auth.entrar(email: _email.text, senha: _senha.text);
      // Deu certo: a porta de acesso recebe a sessão e abre o painel.
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = mensagemDeErroDeAcesso(erro));
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  Future<void> _recuperarSenha() async {
    await showDialog<void>(
      context: context,
      builder: (_) => RecuperarSenhaDialog(
        auth: widget.auth,
        emailInicial: _email.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return PainelDeAcesso(
      titulo: 'Olivares Pilates',
      subtitulo: 'Entre para ver seus alunos e suas aulas.',
      child: Form(
        key: _formKey,
        // O erro de um campo some assim que a pessoa corrige o valor.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('login-email'),
                controller: _email,
                enabled: !_entrando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'voce@exemplo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validarEmail,
              ),
              espacoEntreCampos,
              TextFormField(
                key: const Key('login-senha'),
                controller: _senha,
                enabled: !_entrando,
                obscureText: _ocultarSenha,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _entrar(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      _ocultarSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
                validator: (valor) =>
                    (valor ?? '').isEmpty ? 'Informe a senha.' : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('login-esqueci'),
                  onPressed: _entrando ? null : _recuperarSenha,
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              if (_erro != null) ...[
                FaixaDeMensagem(key: const Key('login-erro'), texto: _erro!),
                espacoEntreCampos,
              ],
              BotaoPrincipal(
                key: const Key('login-entrar'),
                rotulo: 'Entrar',
                rotuloEmAndamento: 'Entrando...',
                emAndamento: _entrando,
                icone: Icons.login,
                onPressed: _entrar,
              ),
              const SizedBox(height: Espacos.xl),
              Divider(color: cores.bordaSuave, height: 1),
              const SizedBox(height: Espacos.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Ainda não tem conta?',
                      style: TextStyle(color: cores.secundario),
                    ),
                  ),
                  TextButton(
                    key: const Key('login-criar-conta'),
                    onPressed: _entrando ? null : widget.onCriarConta,
                    child: const Text('Criar conta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// RF001: recuperação de senha por e-mail
// ---------------------------------------------------------------------------

class RecuperarSenhaDialog extends StatefulWidget {
  const RecuperarSenhaDialog({
    super.key,
    required this.auth,
    this.emailInicial = '',
  });

  final AuthGateway auth;
  final String emailInicial;

  @override
  State<RecuperarSenhaDialog> createState() => _RecuperarSenhaDialogState();
}

class _RecuperarSenhaDialogState extends State<RecuperarSenhaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailInicial);
  bool _enviando = false;
  String? _erro;
  String? _enviadoPara;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _email.text.trim().toLowerCase();
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.auth.recuperarSenha(email);
      if (!mounted) return;
      setState(() => _enviadoPara = email);
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = mensagemDeErroDeAcesso(erro));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enviadoPara = _enviadoPara;
    return DialogoFormulario(
      titulo: 'Recuperar senha',
      descricao: enviadoPara == null
          ? 'Informe o e-mail da sua conta. Enviaremos um link para você '
                'criar uma senha nova.'
          : 'Pedido registrado.',
      child: enviadoPara != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FaixaDeMensagem(
                  key: const Key('recuperar-sucesso'),
                  tom: TomDoAviso.sucesso,
                  texto:
                      'Se existir uma conta com $enviadoPara, o link de '
                      'redefinição chega em alguns minutos. Confira também '
                      'a caixa de spam.',
                ),
                espacoEntreCampos,
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Voltar para o login'),
                ),
              ],
            )
          : Form(
              key: _formKey,
              // O erro de um campo some assim que a pessoa corrige o valor.
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const Key('recuperar-email'),
                    controller: _email,
                    enabled: !_enviando,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    onFieldSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: validarEmail,
                  ),
                  if (_erro != null) ...[
                    espacoEntreCampos,
                    FaixaDeMensagem(texto: _erro!),
                  ],
                  espacoEntreCampos,
                  BotaoPrincipal(
                    key: const Key('recuperar-enviar'),
                    rotulo: 'Enviar link',
                    rotuloEmAndamento: 'Enviando...',
                    emAndamento: _enviando,
                    icone: Icons.send_outlined,
                    onPressed: _enviar,
                  ),
                  const SizedBox(height: Espacos.md),
                  TextButton(
                    onPressed: _enviando
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// RF002: cadastro com e-mail, senha segura e dados adicionais
// ---------------------------------------------------------------------------

class CadastroPage extends StatefulWidget {
  const CadastroPage({
    super.key,
    required this.auth,
    required this.onVoltarParaLogin,
  });

  final AuthGateway auth;
  final VoidCallback onVoltarParaLogin;

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _estudio = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _ocultarSenha = true;
  bool _cadastrando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // A lista de requisitos da senha acompanha o que a pessoa digita.
    _senha.addListener(_atualizarRequisitos);
  }

  void _atualizarRequisitos() => setState(() {});

  @override
  void dispose() {
    _senha.removeListener(_atualizarRequisitos);
    for (final campo in [
      _nome,
      _telefone,
      _estudio,
      _email,
      _senha,
      _confirmacao,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_cadastrando) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final cores = context.cores;
    final primeiroNome = _nome.text.trim().split(' ').first;
    setState(() {
      _cadastrando = true;
      _erro = null;
    });
    try {
      final resultado = await widget.auth.cadastrar(
        nome: _nome.text,
        telefone: formatarTelefone(_telefone.text),
        estudio: _estudio.text,
        email: _email.text,
        senha: _senha.text,
      );
      // A sessão já abriu; o aviso aparece por cima do painel.
      if (resultado.perfilSalvo) {
        mostrarAviso(
          messenger,
          cores,
          'Conta criada com sucesso. Boas-vindas, $primeiroNome!',
        );
      } else {
        mostrarAviso(
          messenger,
          cores,
          'Conta criada, mas seus dados não foram salvos. Complete em '
          '"Meu cadastro".',
          tom: TomDoAviso.info,
        );
      }
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = mensagemDeErroDeAcesso(erro));
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return PainelDeAcesso(
      titulo: 'Criar conta',
      subtitulo:
          'Seus alunos e aulas ficam guardados na sua conta e só você os vê.',
      child: Form(
        key: _formKey,
        // O erro de um campo some assim que a pessoa corrige o valor.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('cadastro-nome'),
                controller: _nome,
                enabled: !_cadastrando,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (valor) => validarNome(valor, campo: 'seu nome'),
              ),
              espacoEntreCampos,
              TextFormField(
                key: const Key('cadastro-telefone'),
                controller: _telefone,
                enabled: !_cadastrando,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\s()+-]')),
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: const InputDecoration(
                  labelText: 'Telefone com DDD',
                  hintText: '(16) 99999-0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: validarTelefone,
              ),
              espacoEntreCampos,
              TextFormField(
                key: const Key('cadastro-estudio'),
                controller: _estudio,
                enabled: !_cadastrando,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome do estúdio',
                  hintText: 'Onde você dá aula',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (valor) =>
                    validarNome(valor, campo: 'o nome do estúdio'),
              ),
              espacoEntreCampos,
              TextFormField(
                key: const Key('cadastro-email'),
                controller: _email,
                enabled: !_cadastrando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  hintText: 'voce@exemplo.com',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: validarEmail,
              ),
              espacoEntreCampos,
              TextFormField(
                key: const Key('cadastro-senha'),
                controller: _senha,
                enabled: !_cadastrando,
                obscureText: _ocultarSenha,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                    icon: Icon(
                      _ocultarSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarSenha = !_ocultarSenha),
                  ),
                ),
                validator: validarSenhaSegura,
              ),
              const SizedBox(height: Espacos.md),
              _RequisitosDaSenha(senha: _senha.text),
              espacoEntreCampos,
              TextFormField(
                key: const Key('cadastro-confirmacao'),
                controller: _confirmacao,
                enabled: !_cadastrando,
                obscureText: _ocultarSenha,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _cadastrar(),
                decoration: const InputDecoration(
                  labelText: 'Repita a senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (valor) =>
                    valor != _senha.text ? 'As senhas não são iguais.' : null,
              ),
              espacoEntreCampos,
              if (_erro != null) ...[
                FaixaDeMensagem(key: const Key('cadastro-erro'), texto: _erro!),
                espacoEntreCampos,
              ],
              BotaoPrincipal(
                key: const Key('cadastro-criar'),
                rotulo: 'Criar conta',
                rotuloEmAndamento: 'Criando conta...',
                emAndamento: _cadastrando,
                icone: Icons.person_add_alt,
                onPressed: _cadastrar,
              ),
              const SizedBox(height: Espacos.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Já tem conta?',
                      style: TextStyle(color: cores.secundario),
                    ),
                  ),
                  TextButton(
                    key: const Key('cadastro-voltar'),
                    onPressed: _cadastrando ? null : widget.onVoltarParaLogin,
                    child: const Text('Entrar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequisitosDaSenha extends StatelessWidget {
  const _RequisitosDaSenha({required this.senha});

  final String senha;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final requisito in requisitosDaSenha(senha))
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.xs),
            child: Row(
              children: [
                Icon(
                  requisito.atendido
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: requisito.atendido ? cores.sucesso : cores.secundario,
                ),
                const SizedBox(width: Espacos.md),
                Text(
                  requisito.descricao,
                  style: textTheme.bodySmall?.copyWith(
                    color: requisito.atendido ? cores.texto : cores.secundario,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
