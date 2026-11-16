# Olivares Pilates

Aplicativo Flutter para a instrutora de Pilates cadastrar e acompanhar os
alunos e as aulas do estúdio. Cada pessoa cria a própria conta e só ela vê os
dados que cadastrou.

Projeto Prático de Programação para Dispositivos Móveis (Flutter, Parte 2).

- Roda no navegador e no Android, com o mesmo código.
- Usa Firebase Authentication e Cloud Firestore (projeto `olivaresfatec`).
- Endereço no Firebase Hosting: https://olivaresfatec.web.app

## Onde está cada requisito

| Requisito | O que o app faz | Onde está no código |
| --- | --- | --- |
| RF001 Autenticação | Login com e-mail e senha, com progresso e mensagens de erro | `lib/telas/acesso_pages.dart` (`LoginPage`), `lib/dados/auth_service.dart` (`entrar`) |
| RF001 Recuperação de senha | "Esqueci minha senha" envia o link de redefinição por e-mail | `RecuperarSenhaDialog` em `lib/telas/acesso_pages.dart`, `recuperarSenha` em `lib/dados/auth_service.dart` |
| RF002 Registro | Cadastro com e-mail e senha segura (8 caracteres, maiúscula, minúscula e número) | `CadastroPage` em `lib/telas/acesso_pages.dart`, `cadastrar` em `lib/dados/auth_service.dart` |
| RF002 Dados adicionais | Nome, telefone e estúdio gravados na coleção `usuarios` | `cadastrar` em `lib/dados/auth_service.dart`, `Usuario` em `lib/dados/modelos.dart` |
| RF003 Inserção | Formulários de aluno e de aula gravam no Firestore e avisam se deu certo ou não | `lib/telas/formularios.dart`, `inserirAluno` e `inserirAula` em `lib/dados/repositorio.dart` |
| RF003 Dados por usuário | Todo documento leva o `uid` do dono; consultas e regras filtram por ele | `lib/dados/repositorio.dart`, `firestore.rules` |
| RF004 Recuperação em tempo real | `StreamBuilder` + `ListView` nas coleções `alunos` e `aulas` | `AlunosTab` e `AulasTab` em `lib/telas/painel_page.dart` |
| RF004 Falha na leitura | Tela de erro com o motivo e botão "Tentar novamente" | `_tentarDeNovo` em `lib/telas/painel_page.dart` |

## Coleções do Firestore

| Coleção | Campos |
| --- | --- |
| `usuarios/{uid}` | `uid` (string), `nome` (string), `telefone` (string), `email` (string), `estudio` (string), `criadoEm` (timestamp) |
| `alunos/{id}` | `uid` (string), `nome` (string), `telefone` (string), `email` (string), `plano` (string), `objetivo` (string), `ativo` (boolean), `criadoEm` (timestamp) |
| `aulas/{id}` | `uid` (string), `titulo` (string), `dataHora` (timestamp), `modalidade` (string), `capacidade` (number), `observacoes` (string), `criadoEm` (timestamp) |

As regras em `firestore.rules` conferem dono, campos obrigatórios, tipos e
faixas de valor. Uma conta não lê, não lista, não edita e não exclui documento
de outra.

## Estrutura

```
lib/
  main.dart              inicia o Firebase e o app
  app.dart               tema, idioma e porta de acesso (login ou painel)
  firebase_options.dart  chaves do projeto Firebase
  dados/                 modelos, validações, autenticação e Firestore
  telas/                 login, cadastro, painel e formulários
  componentes/           peças de interface reutilizadas
  tema/                  cores e tipografia, claro e escuro
test/                    testes de unidade e de tela
testes_regras/           testes das regras do Firestore no emulador
firestore.rules          regras de segurança
firebase.json            Hosting, regras e emuladores
```

## Como rodar

Requisitos: Flutter 3.44 (canal stable).

```bash
flutter pub get
flutter run -d chrome        # navegador
flutter run                  # Android (aparelho ou emulador)
```

### Sem tocar no projeto Firebase (emuladores)

Requisitos: Node 22 e Java 21.

```bash
npx firebase-tools emulators:start --only auth,firestore
flutter run -d chrome --dart-define=EMULADOR_HOST=127.0.0.1
```

No emulador Android use `--dart-define=EMULADOR_HOST=10.0.2.2`.

## Testes

```bash
flutter analyze
flutter test                         # validações, modelos, tema e telas
cd testes_regras && npm ci && npm test   # regras do Firestore no emulador
```

## Publicar no Firebase Hosting

```bash
npx firebase-tools login
flutter build web --release
npx firebase-tools deploy --only firestore:rules,hosting
```

O endereço publicado é https://olivaresfatec.web.app.

## Configuração do Firebase

O projeto `olivaresfatec` precisa de:

1. Authentication com o método **E-mail/senha** ativo.
2. Cloud Firestore criado, com as regras de `firestore.rules` publicadas.
3. App Web registrado (as chaves estão em `lib/firebase_options.dart`).
4. Para rodar no Android: app Android registrado com o pacote
   `br.com.olivares.olivares_pilates` e as chaves dele em
   `DefaultFirebaseOptions.android`. O comando `flutterfire configure` faz os
   dois passos.
