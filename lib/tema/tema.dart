// Tema do Olivares Pilates: cores da marca Olivares no claro e no escuro.
//
// As telas leem as cores por `context.cores`, nunca por valores fixos, para
// que os dois temas tenham contraste correto.
import 'package:flutter/material.dart';

class Espacos {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
}

class Raios {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 18;
}

@immutable
class Cores extends ThemeExtension<Cores> {
  const Cores({
    required this.primaria,
    required this.onPrimaria,
    required this.azulPrimario,
    required this.azulNeblina,
    required this.texto,
    required this.secundario,
    required this.fundo,
    required this.superficie,
    required this.bordaSuave,
    required this.contorno,
    required this.sucesso,
    required this.erro,
    required this.info,
    required this.onStatus,
  });

  /// Fundo de botão principal e de item selecionado.
  final Color primaria;

  /// Texto e ícone sobre [primaria].
  final Color onPrimaria;

  /// Acento da marca: ícone de destaque, link, texto de etiqueta.
  final Color azulPrimario;

  /// Superfície de acento (avatar, bloco de data).
  final Color azulNeblina;

  final Color texto;
  final Color secundario;
  final Color fundo;

  /// Fundo de cartões, painéis e caixas de diálogo.
  final Color superficie;

  final Color bordaSuave;

  /// Borda de campo de formulário.
  final Color contorno;

  final Color sucesso;
  final Color erro;
  final Color info;

  /// Texto e ícone sobre [sucesso], [erro] e [info].
  final Color onStatus;

  static const Cores claro = Cores(
    primaria: Color(0xFF001F3F),
    onPrimaria: Color(0xFFFFFFFF),
    azulPrimario: Color(0xFF001F3F),
    azulNeblina: Color(0xFFE7EEF7),
    texto: Color(0xFF191C1D),
    secundario: Color(0xFF43474E),
    fundo: Color(0xFFF8F9FA),
    superficie: Color(0xFFFFFFFF),
    bordaSuave: Color(0xFFE1E3E4),
    contorno: Color(0xFF74777F),
    sucesso: Color(0xFF15803D),
    erro: Color(0xFFBA1A1A),
    info: Color(0xFF145A8D),
    onStatus: Color(0xFFFFFFFF),
  );

  static const Cores escuro = Cores(
    primaria: Color(0xFFAFC8F0),
    onPrimaria: Color(0xFF000613),
    azulPrimario: Color(0xFFAFC8F0),
    azulNeblina: Color(0xFF0E243F),
    texto: Color(0xFFF0F1F2),
    secundario: Color(0xFFC0C7CC),
    fundo: Color(0xFF000613),
    superficie: Color(0xFF18283E),
    bordaSuave: Color(0xFF2A3A54),
    contorno: Color(0xFF64789A),
    sucesso: Color(0xFF47D16C),
    erro: Color(0xFFFF6B6B),
    info: Color(0xFF7BC3FF),
    onStatus: Color(0xFF000613),
  );

  @override
  Cores copyWith() => this;

  @override
  Cores lerp(Cores? other, double t) => other == null || t < 0.5 ? this : other;
}

extension CoresDoContexto on BuildContext {
  /// Cores do tema atual (claro ou escuro).
  Cores get cores => Theme.of(this).extension<Cores>() ?? Cores.claro;
}

class TemaOlivares {
  static const String _fonteDeTitulo = 'Epilogue';
  static const String _fonteDeTexto = 'Manrope';

  static ThemeData get claro => _montar(Cores.claro, Brightness.light);

  static ThemeData get escuro => _montar(Cores.escuro, Brightness.dark);

  static ThemeData _montar(Cores cores, Brightness brilho) {
    final esquema =
        ColorScheme.fromSeed(
          seedColor: Cores.claro.primaria,
          brightness: brilho,
        ).copyWith(
          primary: cores.primaria,
          onPrimary: cores.onPrimaria,
          surface: cores.superficie,
          onSurface: cores.texto,
          onSurfaceVariant: cores.secundario,
          error: cores.erro,
          onError: cores.onStatus,
          outline: cores.contorno,
          outlineVariant: cores.bordaSuave,
        );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      fontFamily: _fonteDeTexto,
    );

    TextStyle titulo(double tamanho) => TextStyle(
      fontFamily: _fonteDeTitulo,
      fontSize: tamanho,
      fontWeight: FontWeight.w700,
      height: 1.2,
      color: cores.texto,
    );
    final padrao = base.textTheme.apply(
      fontFamily: _fonteDeTexto,
      bodyColor: cores.texto,
      displayColor: cores.texto,
    );
    final textos = padrao.copyWith(
      headlineSmall: titulo(24),
      titleLarge: titulo(20),
      titleMedium: padrao.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      bodyLarge: padrao.bodyLarge?.copyWith(fontSize: 15, height: 1.4),
      bodyMedium: padrao.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: padrao.bodySmall?.copyWith(fontSize: 12.5, height: 1.4),
      labelLarge: padrao.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: padrao.labelSmall?.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    OutlineInputBorder borda(Color cor, [double largura = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Raios.medium),
          borderSide: BorderSide(color: cor, width: largura),
        );
    final formaDoBotao = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Raios.medium),
    );
    const textoDoBotao = TextStyle(
      fontFamily: _fonteDeTexto,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );

    return base.copyWith(
      scaffoldBackgroundColor: cores.fundo,
      textTheme: textos,
      extensions: [cores],
      appBarTheme: AppBarTheme(
        backgroundColor: cores.superficie,
        foregroundColor: cores.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: titulo(19),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cores.azulPrimario,
        unselectedLabelColor: cores.secundario,
        indicatorColor: cores.azulPrimario,
        dividerColor: cores.bordaSuave,
        labelStyle: textoDoBotao.copyWith(fontSize: 14),
        unselectedLabelStyle: textoDoBotao.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cores.superficie,
        // Sem véu cinza no foco e ao passar o mouse: o foco é a borda azul.
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Espacos.xl,
          vertical: Espacos.xl,
        ),
        border: borda(cores.contorno),
        enabledBorder: borda(cores.contorno),
        disabledBorder: borda(cores.bordaSuave),
        focusedBorder: borda(cores.azulPrimario, 2),
        errorBorder: borda(cores.erro),
        focusedErrorBorder: borda(cores.erro, 2),
        labelStyle: TextStyle(color: cores.secundario),
        floatingLabelStyle: TextStyle(color: cores.azulPrimario),
        hintStyle: TextStyle(color: cores.secundario.withValues(alpha: 0.75)),
        errorStyle: TextStyle(color: cores.erro, fontSize: 12.5),
        errorMaxLines: 2,
        prefixIconColor: cores.secundario,
        suffixIconColor: cores.secundario,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cores.primaria,
          foregroundColor: cores.onPrimaria,
          minimumSize: const Size(64, 48),
          shape: formaDoBotao,
          textStyle: textoDoBotao,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cores.azulPrimario,
          minimumSize: const Size(48, 44),
          shape: formaDoBotao,
          textStyle: textoDoBotao.copyWith(fontSize: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cores.primaria,
        foregroundColor: cores.onPrimaria,
        extendedTextStyle: textoDoBotao,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cores.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raios.large),
        ),
        titleTextStyle: titulo(20),
        contentTextStyle: textos.bodyMedium?.copyWith(color: cores.secundario),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cores.superficie,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Raios.medium),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cores.azulPrimario,
      ),
      dividerTheme: DividerThemeData(color: cores.bordaSuave),
    );
  }
}
