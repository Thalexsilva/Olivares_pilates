// Ponto de entrada do Olivares Pilates.
//
// Rodar no navegador:  flutter run -d chrome
// Rodar no Android:    flutter run
// Gerar para Hosting:  flutter build web --release
//
// Para testar sem tocar no projeto Firebase, suba os emuladores
// (`firebase emulators:start --only auth,firestore`) e rode com
// `--dart-define=EMULADOR_HOST=127.0.0.1` (no emulador Android, `10.0.2.2`).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Host dos emuladores do Firebase. Vazio (padrão) usa o projeto real.
const String _emuladorHost = String.fromEnvironment('EMULADOR_HOST');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? falhaInicial;
  try {
    await Firebase.initializeApp(options: _opcoesDoFirebase());
    if (_emuladorHost.isNotEmpty) {
      await FirebaseAuth.instance.useAuthEmulator(_emuladorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(_emuladorHost, 8080);
    }
    Intl.defaultLocale = 'pt_BR';
    await initializeDateFormatting('pt_BR');
  } on UnsupportedError catch (erro) {
    // Plataforma sem chaves em `lib/firebase_options.dart`.
    falhaInicial = erro.message;
  } catch (_) {
    falhaInicial =
        'O app não conseguiu se conectar ao Firebase. Confira a internet e '
        'abra de novo.';
  }

  runApp(OlivaresPilatesApp.firebase(falhaInicial: falhaInicial));
}

/// Com emulador, o app usa um projeto de demonstração (prefixo `demo-`), que
/// nunca alcança o projeto real. Sem emulador, cada plataforma usa as chaves
/// dela.
FirebaseOptions _opcoesDoFirebase() => _emuladorHost.isNotEmpty
    ? DefaultFirebaseOptions.web.copyWith(projectId: 'demo-olivares-pilates')
    : DefaultFirebaseOptions.currentPlatform;
