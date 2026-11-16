import 'package:flutter_test/flutter_test.dart';
import 'package:olivares_pilates/dados/validadores.dart';

void main() {
  group('validarEmail', () {
    test('aceita e-mail bem formado, com espaços nas pontas', () {
      expect(validarEmail(' ana@exemplo.com '), isNull);
      expect(validarEmail('ana.souza+pilates@estudio.com.br'), isNull);
    });

    test('recusa vazio e formatos inválidos', () {
      expect(validarEmail(null), 'Informe o e-mail.');
      expect(validarEmail('   '), 'Informe o e-mail.');
      for (final invalido in [
        'ana',
        'ana@',
        '@exemplo.com',
        'ana@exemplo',
        'a b@c.com',
      ]) {
        expect(
          validarEmail(invalido),
          'Digite um e-mail válido.',
          reason: invalido,
        );
      }
    });

    test('opcional aceita vazio e valida quando preenchido', () {
      expect(validarEmailOpcional(''), isNull);
      expect(validarEmailOpcional('ana@exemplo.com'), isNull);
      expect(validarEmailOpcional('ana@'), isNotNull);
    });
  });

  group('senha segura', () {
    test('exige 8 caracteres, maiúscula, minúscula e número', () {
      expect(senhaEhSegura('Pilates2026'), isTrue);
      expect(senhaEhSegura('Abc12345'), isTrue);
      expect(senhaEhSegura('Abc1234'), isFalse, reason: '7 caracteres');
      expect(senhaEhSegura('pilates2026'), isFalse, reason: 'sem maiúscula');
      expect(senhaEhSegura('PILATES2026'), isFalse, reason: 'sem minúscula');
      expect(senhaEhSegura('PilatesForte'), isFalse, reason: 'sem número');
    });

    test('lista mostra o que já foi cumprido', () {
      final requisitos = requisitosDaSenha('abc');
      expect(requisitos, hasLength(4));
      expect(requisitos.where((r) => r.atendido).map((r) => r.descricao), [
        'Uma letra minúscula',
      ]);
    });

    test('validador devolve mensagem para vazio e para senha fraca', () {
      expect(validarSenhaSegura(''), 'Crie uma senha.');
      expect(validarSenhaSegura('12345678'), isNotNull);
      expect(validarSenhaSegura('Pilates2026'), isNull);
    });
  });

  group('telefone', () {
    test('aceita 10 ou 11 dígitos com qualquer máscara', () {
      expect(validarTelefone('(16) 99999-0000'), isNull);
      expect(validarTelefone('1634567890'), isNull);
    });

    test('recusa vazio e tamanho errado', () {
      expect(validarTelefone(''), 'Informe o telefone.');
      expect(validarTelefone('99999-0000'), isNotNull);
      expect(validarTelefone('5516999990000'), isNotNull);
    });

    test('formata celular e fixo', () {
      expect(formatarTelefone('16999990000'), '(16) 99999-0000');
      expect(formatarTelefone('16 3456 7890'), '(16) 3456-7890');
      expect(formatarTelefone(' 123 '), '123');
    });
  });

  test('validarNome exige de 3 a 120 caracteres', () {
    expect(validarNome(''), 'Informe o nome.');
    expect(validarNome('', campo: 'seu nome'), 'Informe seu nome.');
    expect(validarNome('Al'), isNotNull);
    expect(validarNome('Ana'), isNull);
    expect(validarNome('a' * 121), isNotNull);
  });

  test('validarCapacidade aceita de 1 a 30', () {
    expect(validarCapacidade('4'), isNull);
    expect(validarCapacidade('1'), isNull);
    expect(validarCapacidade('30'), isNull);
    expect(validarCapacidade('0'), isNotNull);
    expect(validarCapacidade('31'), isNotNull);
    expect(validarCapacidade(''), isNotNull);
    expect(validarCapacidade('abc'), isNotNull);
  });
}
