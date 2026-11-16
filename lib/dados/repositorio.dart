// Leitura e gravação no Cloud Firestore (RF003 e RF004).
//
// Tudo aqui é do usuário logado: as consultas filtram por `uid` e toda
// inserção grava o `uid` do dono no documento.
import 'package:cloud_firestore/cloud_firestore.dart';

import 'modelos.dart';

typedef ConsultaSnapshot = QuerySnapshot<Map<String, dynamic>>;
typedef DocumentoSnapshot = DocumentSnapshot<Map<String, dynamic>>;

class Repositorio {
  Repositorio({required this.uid, FirebaseFirestore? firestore})
    : _firestoreInjetado = firestore;

  /// Usuário logado, dono de tudo que este repositório lê e grava.
  final String uid;
  final FirebaseFirestore? _firestoreInjetado;

  FirebaseFirestore get _firestore =>
      _firestoreInjetado ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _alunos =>
      _firestore.collection(Colecoes.alunos);

  CollectionReference<Map<String, dynamic>> get _aulas =>
      _firestore.collection(Colecoes.aulas);

  DocumentReference<Map<String, dynamic>> get _usuario =>
      _firestore.collection(Colecoes.usuarios).doc(uid);

  // ---- Recuperação em tempo real (RF004) ----

  /// Alunos do usuário logado. Cada alteração no Firestore chega no stream.
  Stream<ConsultaSnapshot> alunosEmTempoReal() =>
      _alunos.where('uid', isEqualTo: uid).snapshots();

  /// Aulas do usuário logado. Cada alteração no Firestore chega no stream.
  Stream<ConsultaSnapshot> aulasEmTempoReal() =>
      _aulas.where('uid', isEqualTo: uid).snapshots();

  Stream<DocumentoSnapshot> usuarioEmTempoReal() => _usuario.snapshots();

  // ---- Inserção e edição (RF003) ----

  Future<void> inserirAluno(Aluno aluno) =>
      _alunos.add(_comDono(aluno.toCreateMap()));

  Future<void> atualizarAluno(Aluno aluno) =>
      _alunos.doc(aluno.id).update(aluno.toUpdateMap());

  Future<void> excluirAluno(String id) => _alunos.doc(id).delete();

  Future<void> inserirAula(Aula aula) =>
      _aulas.add(_comDono(aula.toCreateMap()));

  Future<void> atualizarAula(Aula aula) =>
      _aulas.doc(aula.id).update(aula.toUpdateMap());

  Future<void> excluirAula(String id) => _aulas.doc(id).delete();

  /// Grava o cadastro em `usuarios/{uid}`. Cria o documento se o cadastro
  /// inicial não chegou a gravar.
  Future<void> salvarPerfil(Usuario usuario, {required bool jaExiste}) {
    if (jaExiste) return _usuario.update(usuario.toPerfilMap());
    return _usuario.set(usuario.toCreateMap());
  }

  /// O dono do documento é sempre quem está logado, nunca o que veio da tela.
  Map<String, dynamic> _comDono(Map<String, dynamic> dados) => {
    ...dados,
    'uid': uid,
  };
}

/// Alunos do snapshot em ordem alfabética.
List<Aluno> alunosDoSnapshot(ConsultaSnapshot snapshot) {
  final alunos = [
    for (final doc in snapshot.docs) Aluno.fromMap(doc.id, doc.data()),
  ];
  alunos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  return alunos;
}

/// Aulas do snapshot: as próximas primeiro (mais cedo em cima), depois as
/// que já passaram (mais recente em cima).
List<Aula> aulasDoSnapshot(ConsultaSnapshot snapshot, {DateTime? agora}) {
  final aulas = [
    for (final doc in snapshot.docs) Aula.fromMap(doc.id, doc.data()),
  ];
  return ordenarAulas(aulas, agora: agora ?? DateTime.now());
}

List<Aula> ordenarAulas(List<Aula> aulas, {required DateTime agora}) {
  final proximas = aulas.where((a) => !a.dataHora.isBefore(agora)).toList()
    ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  final passadas = aulas.where((a) => a.dataHora.isBefore(agora)).toList()
    ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  return [...proximas, ...passadas];
}
