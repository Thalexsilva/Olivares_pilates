// Autenticação com Firebase Authentication (RF001 e RF002).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'modelos.dart';

/// Resultado do cadastro: a conta sempre existe quando este objeto volta.
class ResultadoCadastro {
  final String uid;

  /// `false` quando a conta foi criada no Authentication mas o documento em
  /// `usuarios` não pôde ser gravado. A pessoa completa em "Meu cadastro".
  final bool perfilSalvo;

  const ResultadoCadastro({required this.uid, required this.perfilSalvo});
}

/// Contrato usado pelas telas. Os testes de widget trocam por um falso.
abstract class AuthGateway {
  /// `null` quando ninguém está logado. Emite a cada login e logout.
  Stream<String?> get uidLogado;

  String? get uidAtual;

  String? get emailAtual;

  Future<void> entrar({required String email, required String senha});

  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String telefone,
    required String estudio,
    required String email,
    required String senha,
  });

  Future<void> recuperarSenha(String email);

  Future<void> sair();
}

class FirebaseAuthService implements AuthGateway {
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<String?> get uidLogado =>
      _auth.authStateChanges().map((user) => user?.uid);

  @override
  String? get uidAtual => _auth.currentUser?.uid;

  @override
  String? get emailAtual => _auth.currentUser?.email;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: senha,
    );
  }

  @override
  Future<ResultadoCadastro> cadastrar({
    required String nome,
    required String telefone,
    required String estudio,
    required String email,
    required String senha,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: senha,
    );
    final user = credencial.user!;
    final usuario = Usuario(
      uid: user.uid,
      nome: nome,
      telefone: telefone,
      email: email,
      estudio: estudio,
    );

    var perfilSalvo = true;
    try {
      // Dados adicionais do cadastro ficam na coleção `usuarios`, em um
      // documento com o mesmo id do usuário no Authentication.
      await _firestore
          .collection(Colecoes.usuarios)
          .doc(user.uid)
          .set(usuario.toCreateMap());
    } on FirebaseException {
      perfilSalvo = false;
    }
    try {
      await user.updateDisplayName(nome.trim());
    } on FirebaseAuthException {
      // O nome de exibição é só conveniência; o cadastro vale sem ele.
    }
    return ResultadoCadastro(uid: user.uid, perfilSalvo: perfilSalvo);
  }

  @override
  Future<void> recuperarSenha(String email) async {
    await _auth.setLanguageCode('pt-BR');
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (erro) {
      // A tela responde igual exista ou não a conta, para não revelar quais
      // e-mails estão cadastrados.
      if (erro.code != 'user-not-found') rethrow;
    }
  }

  @override
  Future<void> sair() => _auth.signOut();
}

/// Mensagem em português para qualquer falha de login, cadastro ou
/// recuperação de senha.
String mensagemDeErroDeAcesso(Object erro) {
  if (erro is FirebaseAuthException) {
    switch (erro.code) {
      case 'invalid-email':
        return 'O e-mail informado não é válido.';
      case 'user-disabled':
        return 'Esta conta foi desativada. Fale com o suporte.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Já existe uma conta com este e-mail. Entre ou recupere a senha.';
      case 'weak-password':
        return 'A senha é fraca demais. Use pelo menos 8 caracteres, com '
            'letras maiúsculas, minúsculas e números.';
      case 'operation-not-allowed':
        return 'O acesso por e-mail e senha não está habilitado no Firebase.';
      case 'too-many-requests':
        return 'Muitas tentativas seguidas. Aguarde alguns minutos e tente de novo.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Confira a rede e tente de novo.';
    }
  }
  return 'Não foi possível concluir agora. Tente de novo em instantes.';
}

/// Mensagem em português para falha de leitura ou gravação no Firestore.
String mensagemDeErroDeDados(Object erro) {
  if (erro is FirebaseException) {
    switch (erro.code) {
      case 'permission-denied':
        return 'Sem permissão para acessar estes dados. Saia e entre de novo.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'Sem conexão com o servidor. Confira a internet e tente de novo.';
      case 'unauthenticated':
        return 'Sua sessão expirou. Entre de novo.';
    }
  }
  return 'Não foi possível concluir agora. Tente de novo em instantes.';
}
