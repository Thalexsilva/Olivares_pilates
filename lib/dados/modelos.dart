// Modelos das coleções do app no Cloud Firestore.
//
//   usuarios/{uid}  cadastro de quem usa o app (RF002)
//   alunos/{id}     alunos do usuário logado (RF003/RF004)
//   aulas/{id}      aulas do usuário logado (RF003/RF004)
//
// Todo documento de `alunos` e `aulas` leva o campo `uid` do dono. As telas
// consultam com `where('uid', isEqualTo: uid)` e o `firestore.rules` recusa
// leitura ou gravação de documento de outro usuário.
import 'package:cloud_firestore/cloud_firestore.dart';

class Colecoes {
  static const String usuarios = 'usuarios';
  static const String alunos = 'alunos';
  static const String aulas = 'aulas';
}

DateTime? _lerData(Object? valor) => valor is Timestamp ? valor.toDate() : null;

String _lerTexto(Object? valor) => valor is String ? valor : '';

class Usuario {
  final String uid;
  final String nome;
  final String telefone;
  final String email;
  final String estudio;
  final DateTime? criadoEm;

  const Usuario({
    required this.uid,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.estudio,
    this.criadoEm,
  });

  factory Usuario.fromMap(String uid, Map<String, dynamic> dados) {
    return Usuario(
      uid: uid,
      nome: _lerTexto(dados['nome']),
      telefone: _lerTexto(dados['telefone']),
      email: _lerTexto(dados['email']),
      estudio: _lerTexto(dados['estudio']),
      criadoEm: _lerData(dados['criadoEm']),
    );
  }

  /// Campos que a pessoa pode editar depois do cadastro.
  Map<String, dynamic> toPerfilMap() => {
    'uid': uid,
    'nome': nome.trim(),
    'telefone': telefone.trim(),
    'email': email.trim().toLowerCase(),
    'estudio': estudio.trim(),
  };

  Map<String, dynamic> toCreateMap() => {
    ...toPerfilMap(),
    'criadoEm': FieldValue.serverTimestamp(),
  };
}

/// Como o aluno frequenta o estúdio.
const List<String> kPlanosDeAluno = [
  'Particular',
  'Wellhub',
  'TotalPass',
  'Experimental',
];

class Aluno {
  final String id;
  final String uid;
  final String nome;
  final String telefone;
  final String email;
  final String plano;
  final String objetivo;
  final bool ativo;
  final DateTime? criadoEm;

  const Aluno({
    this.id = '',
    required this.uid,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.plano,
    required this.objetivo,
    required this.ativo,
    this.criadoEm,
  });

  factory Aluno.fromMap(String id, Map<String, dynamic> dados) {
    return Aluno(
      id: id,
      uid: _lerTexto(dados['uid']),
      nome: _lerTexto(dados['nome']),
      telefone: _lerTexto(dados['telefone']),
      email: _lerTexto(dados['email']),
      plano: _lerTexto(dados['plano']),
      objetivo: _lerTexto(dados['objetivo']),
      ativo: dados['ativo'] == true,
      criadoEm: _lerData(dados['criadoEm']),
    );
  }

  /// Campos editáveis. `uid` e `criadoEm` não mudam depois da criação.
  Map<String, dynamic> toUpdateMap() => {
    'nome': nome.trim(),
    'telefone': telefone.trim(),
    'email': email.trim().toLowerCase(),
    'plano': plano,
    'objetivo': objetivo.trim(),
    'ativo': ativo,
  };

  Map<String, dynamic> toCreateMap() => {
    'uid': uid,
    ...toUpdateMap(),
    'criadoEm': FieldValue.serverTimestamp(),
  };
}

const List<String> kModalidadesDeAula = [
  'Reformer',
  'Cadillac',
  'Chair',
  'Barrel',
  'Solo',
  'Circuito',
];

class Aula {
  final String id;
  final String uid;
  final String titulo;
  final DateTime dataHora;
  final String modalidade;
  final int capacidade;
  final String observacoes;
  final DateTime? criadoEm;

  const Aula({
    this.id = '',
    required this.uid,
    required this.titulo,
    required this.dataHora,
    required this.modalidade,
    required this.capacidade,
    required this.observacoes,
    this.criadoEm,
  });

  factory Aula.fromMap(String id, Map<String, dynamic> dados) {
    final capacidade = dados['capacidade'];
    return Aula(
      id: id,
      uid: _lerTexto(dados['uid']),
      titulo: _lerTexto(dados['titulo']),
      dataHora:
          _lerData(dados['dataHora']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      modalidade: _lerTexto(dados['modalidade']),
      capacidade: capacidade is num ? capacidade.toInt() : 0,
      observacoes: _lerTexto(dados['observacoes']),
      criadoEm: _lerData(dados['criadoEm']),
    );
  }

  Map<String, dynamic> toUpdateMap() => {
    'titulo': titulo.trim(),
    'dataHora': Timestamp.fromDate(dataHora),
    'modalidade': modalidade,
    'capacidade': capacidade,
    'observacoes': observacoes.trim(),
  };

  Map<String, dynamic> toCreateMap() => {
    'uid': uid,
    ...toUpdateMap(),
    'criadoEm': FieldValue.serverTimestamp(),
  };
}
