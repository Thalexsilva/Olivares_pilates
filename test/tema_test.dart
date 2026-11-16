import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olivares_pilates/tema/tema.dart';

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final escuro = la > lb ? lb : la;
  return (claro + 0.05) / (escuro + 0.05);
}

void main() {
  for (final (nome, cores) in [
    ('claro', Cores.claro),
    ('escuro', Cores.escuro),
  ]) {
    group('tema $nome', () {
      final pares = <(String, Color, Color, double)>[
        ('texto/fundo', cores.texto, cores.fundo, 4.5),
        ('texto/superficie', cores.texto, cores.superficie, 4.5),
        ('secundario/fundo', cores.secundario, cores.fundo, 4.5),
        ('secundario/superficie', cores.secundario, cores.superficie, 4.5),
        ('onPrimaria/primaria', cores.onPrimaria, cores.primaria, 4.5),
        ('azulPrimario/superficie', cores.azulPrimario, cores.superficie, 4.5),
        (
          'azulPrimario/azulNeblina',
          cores.azulPrimario,
          cores.azulNeblina,
          4.5,
        ),
        ('sucesso/superficie', cores.sucesso, cores.superficie, 4.5),
        ('erro/superficie', cores.erro, cores.superficie, 4.5),
        ('info/superficie', cores.info, cores.superficie, 4.5),
        ('onStatus/sucesso', cores.onStatus, cores.sucesso, 4.5),
        ('onStatus/erro', cores.onStatus, cores.erro, 4.5),
        ('onStatus/info', cores.onStatus, cores.info, 4.5),
        ('contorno/superficie', cores.contorno, cores.superficie, 3.0),
      ];
      for (final (par, tinta, fundo, minimo) in pares) {
        test('$par tem contraste de pelo menos $minimo', () {
          final contraste = _contraste(tinta, fundo);
          expect(
            contraste,
            greaterThanOrEqualTo(minimo),
            reason: '$par dá ${contraste.toStringAsFixed(2)}:1',
          );
        });
      }
    });
  }

  test('os temas registram as cores certas', () {
    expect(TemaOlivares.claro.extension<Cores>(), same(Cores.claro));
    expect(TemaOlivares.escuro.extension<Cores>(), same(Cores.escuro));
  });
}
