import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivares_pilates/dados/modelos.dart';
import 'package:olivares_pilates/dados/repositorio.dart';

void main() {
  group('Usuario', () {
    const usuario = Usuario(
      uid: 'uid-1',
      nome: '  Ana Souza ',
      telefone: '(16) 99999-0000',
      email: ' Ana@Exemplo.com ',
      estudio: 'Studio Ana',
    );

    test('criação grava os dados adicionais do cadastro, limpos', () {
      final mapa = usuario.toCreateMap();
      expect(mapa.keys, {
        'uid',
        'nome',
        'telefone',
        'email',
        'estudio',
        'criadoEm',
      });
      expect(mapa['nome'], 'Ana Souza');
      expect(mapa['email'], 'ana@exemplo.com');
      expect(mapa['criadoEm'], isA<FieldValue>());
    });

    test('edição não mexe na data de criação', () {
      expect(usuario.toPerfilMap().containsKey('criadoEm'), isFalse);
    });

    test('lê documento com campo faltando sem quebrar', () {
      final lido = Usuario.fromMap('uid-1', {'nome': 'Ana'});
      expect(lido.nome, 'Ana');
      expect(lido.telefone, '');
      expect(lido.criadoEm, isNull);
    });
  });

  group('Aluno', () {
    const aluno = Aluno(
      uid: 'uid-1',
      nome: ' Carla Dias ',
      telefone: '(16) 98888-0000',
      email: 'CARLA@exemplo.com',
      plano: 'Particular',
      objetivo: ' Aliviar dor lombar ',
      ativo: true,
    );

    test('documento tem mais de cinco campos, com os tipos certos', () {
      final mapa = aluno.toCreateMap();
      expect(mapa.keys, {
        'uid',
        'nome',
        'telefone',
        'email',
        'plano',
        'objetivo',
        'ativo',
        'criadoEm',
      });
      expect(mapa['uid'], 'uid-1');
      expect(mapa['nome'], 'Carla Dias');
      expect(mapa['email'], 'carla@exemplo.com');
      expect(mapa['objetivo'], 'Aliviar dor lombar');
      expect(mapa['ativo'], isA<bool>());
      expect(mapa['criadoEm'], isA<FieldValue>());
    });

    test('edição não troca o dono nem a data de criação', () {
      final mapa = aluno.toUpdateMap();
      expect(mapa.containsKey('uid'), isFalse);
      expect(mapa.containsKey('criadoEm'), isFalse);
    });

    test('ida e volta pelo Firestore preserva os dados', () {
      final criadoEm = DateTime(2026, 11, 15, 10);
      final lido = Aluno.fromMap('doc-1', {
        ...aluno.toUpdateMap(),
        'uid': 'uid-1',
        'criadoEm': Timestamp.fromDate(criadoEm),
      });
      expect(lido.id, 'doc-1');
      expect(lido.uid, 'uid-1');
      expect(lido.nome, 'Carla Dias');
      expect(lido.plano, 'Particular');
      expect(lido.ativo, isTrue);
      expect(lido.criadoEm, criadoEm);
    });
  });

  group('Aula', () {
    final aula = Aula(
      uid: 'uid-1',
      titulo: ' Turma da manhã ',
      dataHora: DateTime(2026, 12, 1, 9),
      modalidade: 'Reformer',
      capacidade: 4,
      observacoes: '',
    );

    test('documento tem mais de cinco campos, com os tipos certos', () {
      final mapa = aula.toCreateMap();
      expect(mapa.keys, {
        'uid',
        'titulo',
        'dataHora',
        'modalidade',
        'capacidade',
        'observacoes',
        'criadoEm',
      });
      expect(mapa['titulo'], 'Turma da manhã');
      expect(mapa['dataHora'], isA<Timestamp>());
      expect(mapa['capacidade'], isA<int>());
    });

    test('ida e volta pelo Firestore preserva data e vagas', () {
      final lida = Aula.fromMap('doc-2', {
        ...aula.toUpdateMap(),
        'uid': 'uid-1',
      });
      expect(lida.dataHora, DateTime(2026, 12, 1, 9));
      expect(lida.capacidade, 4);
      expect(lida.modalidade, 'Reformer');
    });
  });

  test('ordenarAulas: próximas em ordem crescente, depois as passadas', () {
    final agora = DateTime(2026, 11, 15, 12);
    Aula aulaEm(String titulo, DateTime quando) => Aula(
      uid: 'uid-1',
      titulo: titulo,
      dataHora: quando,
      modalidade: 'Solo',
      capacidade: 4,
      observacoes: '',
    );
    final ordenadas = ordenarAulas([
      aulaEm('ontem', DateTime(2026, 11, 14, 9)),
      aulaEm('semana que vem', DateTime(2026, 11, 22, 9)),
      aulaEm('semana passada', DateTime(2026, 11, 8, 9)),
      aulaEm('amanhã', DateTime(2026, 11, 16, 9)),
    ], agora: agora);
    expect(ordenadas.map((aula) => aula.titulo), [
      'amanhã',
      'semana que vem',
      'ontem',
      'semana passada',
    ]);
  });
}
