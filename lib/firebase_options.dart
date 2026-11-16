// Chaves do projeto Firebase "OlivaresFatec" (id `olivaresfatec`).
//
// São identificadores públicos: vão dentro de qualquer app Firebase. Quem
// protege os dados são as regras em `firestore.rules`, não estas chaves.
//
// Para apontar o app para outro projeto, rode `flutterfire configure`, que
// regrava este arquivo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Este app está configurado para navegador e Android.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCp8K921E3stB22NH-8LEXWdws6F3Q5wek',
    appId: '1:25927648388:web:588969521f6af95c8b6ed1',
    messagingSenderId: '25927648388',
    projectId: 'olivaresfatec',
    authDomain: 'olivaresfatec.firebaseapp.com',
    storageBucket: 'olivaresfatec.firebasestorage.app',
    measurementId: 'G-6CDST1T6P5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAKxLQJj5ZXeVoYy3s_48-ATav7lyFuNTk',
    appId: '1:25927648388:android:ed5fdd46dae19c3a8b6ed1',
    messagingSenderId: '25927648388',
    projectId: 'olivaresfatec',
    storageBucket: 'olivaresfatec.firebasestorage.app',
  );
}
