// Validações dos formulários. Funções puras: devolvem a
// mensagem de erro ou `null` quando o valor é aceito.

final RegExp _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validarEmail(String? valor) {
  final email = (valor ?? '').trim();
  if (email.isEmpty) return 'Informe o e-mail.';
  if (!_emailRegExp.hasMatch(email)) return 'Digite um e-mail válido.';
  return null;
}

String? validarEmailOpcional(String? valor) {
  if ((valor ?? '').trim().isEmpty) return null;
  return validarEmail(valor);
}

String? validarNome(String? valor, {String campo = 'o nome'}) {
  final nome = (valor ?? '').trim();
  if (nome.isEmpty) return 'Informe $campo.';
  if (nome.length < 3) return 'Use pelo menos 3 letras.';
  if (nome.length > 120) return 'Use no máximo 120 caracteres.';
  return null;
}

/// Só os dígitos do telefone, sem máscara.
String digitosDoTelefone(String? valor) =>
    (valor ?? '').replaceAll(RegExp(r'\D'), '');

String? validarTelefone(String? valor) {
  final digitos = digitosDoTelefone(valor);
  if (digitos.isEmpty) return 'Informe o telefone.';
  if (digitos.length < 10 || digitos.length > 11) {
    return 'Digite o telefone com DDD (10 ou 11 números).';
  }
  return null;
}

/// (11) 98765-4321 ou (11) 3456-7890. Valor incompleto volta como veio.
String formatarTelefone(String? valor) {
  final d = digitosDoTelefone(valor);
  if (d.length == 11) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
  }
  if (d.length == 10) {
    return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
  }
  return (valor ?? '').trim();
}

/// Um requisito da senha segura, mostrado na tela enquanto a pessoa digita.
class RequisitoDeSenha {
  final String descricao;
  final bool atendido;

  const RequisitoDeSenha(this.descricao, this.atendido);
}

List<RequisitoDeSenha> requisitosDaSenha(String senha) => [
  RequisitoDeSenha('Pelo menos 8 caracteres', senha.length >= 8),
  RequisitoDeSenha('Uma letra maiúscula', senha.contains(RegExp(r'[A-Z]'))),
  RequisitoDeSenha('Uma letra minúscula', senha.contains(RegExp(r'[a-z]'))),
  RequisitoDeSenha('Um número', senha.contains(RegExp(r'\d'))),
];

bool senhaEhSegura(String senha) =>
    requisitosDaSenha(senha).every((requisito) => requisito.atendido);

String? validarSenhaSegura(String? valor) {
  final senha = valor ?? '';
  if (senha.isEmpty) return 'Crie uma senha.';
  if (!senhaEhSegura(senha)) {
    return 'A senha ainda não cumpre todos os requisitos abaixo.';
  }
  return null;
}

String? validarCapacidade(String? valor) {
  final numero = int.tryParse((valor ?? '').trim());
  if (numero == null) return 'Informe um número.';
  if (numero < 1 || numero > 30) return 'Use um valor de 1 a 30.';
  return null;
}
