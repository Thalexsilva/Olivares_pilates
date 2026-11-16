// Testes das regras do Firestore, rodados no emulador:
//   npm install
//   npm test
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from 'firebase/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

describe('firestore.rules: usuarios, alunos e aulas por usuário', () => {
  let testEnv: RulesTestEnvironment;

  const ana = () =>
    testEnv.authenticatedContext('ana-uid', { email: 'ana@exemplo.com' }).firestore();
  const bia = () =>
    testEnv.authenticatedContext('bia-uid', { email: 'bia@exemplo.com' }).firestore();

  const usuario = (uidDono: string, email: string) => ({
    uid: uidDono,
    nome: 'Ana Souza',
    telefone: '(16) 99999-0000',
    email,
    estudio: 'Studio Ana',
    criadoEm: serverTimestamp(),
  });

  const aluno = (uidDono: string) => ({
    uid: uidDono,
    nome: 'Carla Dias',
    telefone: '(16) 98888-0000',
    email: '',
    plano: 'Particular',
    objetivo: 'Aliviar dor lombar',
    ativo: true,
    criadoEm: serverTimestamp(),
  });

  const aula = (uidDono: string) => ({
    uid: uidDono,
    titulo: 'Turma da manhã',
    dataHora: Timestamp.fromDate(new Date('2026-12-01T12:00:00Z')),
    modalidade: 'Reformer',
    capacidade: 4,
    observacoes: '',
    criadoEm: serverTimestamp(),
  });

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-olivares-pilates',
      firestore: {
        rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const criadoEm = Timestamp.fromDate(new Date('2026-11-01T00:00:00Z'));
      await setDoc(doc(db, 'usuarios/bia-uid'), {
        ...usuario('bia-uid', 'bia@exemplo.com'),
        criadoEm,
      });
      await setDoc(doc(db, 'alunos/aluno-da-bia'), { ...aluno('bia-uid'), criadoEm });
      await setDoc(doc(db, 'alunos/aluno-da-ana'), { ...aluno('ana-uid'), criadoEm });
      await setDoc(doc(db, 'aulas/aula-da-bia'), { ...aula('bia-uid'), criadoEm });
      await setDoc(doc(db, 'aulas/aula-da-ana'), { ...aula('ana-uid'), criadoEm });
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  it('cadastro: a pessoa cria, lê e edita só o próprio documento em usuarios', async () => {
    const db = ana();
    await assertSucceeds(
      setDoc(doc(db, 'usuarios/ana-uid'), usuario('ana-uid', 'ana@exemplo.com')),
    );
    await assertSucceeds(getDoc(doc(db, 'usuarios/ana-uid')));
    await assertSucceeds(
      updateDoc(doc(db, 'usuarios/ana-uid'), { nome: 'Ana Souza Lima' }),
    );

    await assertFails(getDoc(doc(db, 'usuarios/bia-uid')));
    await assertFails(updateDoc(doc(db, 'usuarios/bia-uid'), { nome: 'Invasora' }));
    await assertFails(getDocs(query(collection(db, 'usuarios'))));
    await assertFails(deleteDoc(doc(db, 'usuarios/ana-uid')));
  });

  it('cadastro: recusa uid ou e-mail de outra pessoa, campo extra e campo faltando', async () => {
    const db = ana();
    await assertFails(
      setDoc(doc(db, 'usuarios/ana-uid'), usuario('bia-uid', 'ana@exemplo.com')),
    );
    await assertFails(
      setDoc(doc(db, 'usuarios/ana-uid'), usuario('ana-uid', 'bia@exemplo.com')),
    );
    await assertFails(
      setDoc(doc(db, 'usuarios/ana-uid'), {
        ...usuario('ana-uid', 'ana@exemplo.com'),
        admin: true,
      }),
    );
    const { telefone: _semTelefone, ...incompleto } = usuario('ana-uid', 'ana@exemplo.com');
    await assertFails(setDoc(doc(db, 'usuarios/ana-uid'), incompleto));
    await assertFails(
      setDoc(doc(db, 'usuarios/ana-uid'), {
        ...usuario('ana-uid', 'ana@exemplo.com'),
        criadoEm: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')),
      }),
    );
  });

  it('sem login ninguém lê nem grava', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'usuarios/bia-uid')));
    await assertFails(getDoc(doc(db, 'alunos/aluno-da-bia')));
    await assertFails(setDoc(doc(db, 'alunos/novo'), aluno('ana-uid')));
    await assertFails(setDoc(doc(db, 'aulas/nova'), aula('ana-uid')));
  });

  for (const [colecao, dados, proprio, alheio, alteracao] of [
    ['alunos', aluno, 'aluno-da-ana', 'aluno-da-bia', { ativo: false }],
    ['aulas', aula, 'aula-da-ana', 'aula-da-bia', { capacidade: 6 }],
  ] as const) {
    it(`${colecao}: insere, lista, edita e exclui só o que é da própria conta`, async () => {
      const db = ana();
      await assertSucceeds(setDoc(doc(db, `${colecao}/novo`), dados('ana-uid')));
      const meus = await assertSucceeds(
        getDocs(query(collection(db, colecao), where('uid', '==', 'ana-uid'))),
      );
      expect(meus.docs.map((item) => item.id).sort()).toEqual([proprio, 'novo'].sort());
      await assertSucceeds(updateDoc(doc(db, `${colecao}/${proprio}`), alteracao));
      await assertSucceeds(deleteDoc(doc(db, `${colecao}/${proprio}`)));
    });

    it(`${colecao}: não lê, lista, edita nem exclui o que é de outra conta`, async () => {
      const db = ana();
      await assertFails(getDoc(doc(db, `${colecao}/${alheio}`)));
      await assertFails(getDocs(query(collection(db, colecao))));
      await assertFails(
        getDocs(query(collection(db, colecao), where('uid', '==', 'bia-uid'))),
      );
      await assertFails(updateDoc(doc(db, `${colecao}/${alheio}`), alteracao));
      await assertFails(deleteDoc(doc(db, `${colecao}/${alheio}`)));
    });

    it(`${colecao}: recusa inserir em nome de outra conta e trocar o dono`, async () => {
      const db = ana();
      await assertFails(setDoc(doc(db, `${colecao}/novo`), dados('bia-uid')));
      await assertFails(updateDoc(doc(db, `${colecao}/${proprio}`), { uid: 'bia-uid' }));
      await assertFails(
        updateDoc(doc(db, `${colecao}/${proprio}`), {
          criadoEm: Timestamp.fromDate(new Date('2020-01-01T00:00:00Z')),
        }),
      );
      await assertFails(
        setDoc(doc(db, `${colecao}/novo`), { ...dados('ana-uid'), extra: 'x' }),
      );
    });
  }

  it('alunos: recusa tipo errado e valor fora da lista', async () => {
    const db = ana();
    await assertFails(setDoc(doc(db, 'alunos/novo'), { ...aluno('ana-uid'), ativo: 'sim' }));
    await assertFails(setDoc(doc(db, 'alunos/novo'), { ...aluno('ana-uid'), plano: 'Outro' }));
    await assertFails(setDoc(doc(db, 'alunos/novo'), { ...aluno('ana-uid'), nome: 'Al' }));
    await assertFails(setDoc(doc(db, 'alunos/novo'), { ...aluno('ana-uid'), objetivo: '' }));
  });

  it('aulas: recusa tipo errado e valor fora da faixa', async () => {
    const db = ana();
    await assertFails(setDoc(doc(db, 'aulas/nova'), { ...aula('ana-uid'), capacidade: 0 }));
    await assertFails(setDoc(doc(db, 'aulas/nova'), { ...aula('ana-uid'), capacidade: 31 }));
    await assertFails(setDoc(doc(db, 'aulas/nova'), { ...aula('ana-uid'), capacidade: 2.5 }));
    await assertFails(
      setDoc(doc(db, 'aulas/nova'), { ...aula('ana-uid'), dataHora: '2026-12-01' }),
    );
    await assertFails(
      setDoc(doc(db, 'aulas/nova'), { ...aula('ana-uid'), modalidade: 'Yoga' }),
    );
  });

  it('qualquer outra coleção é negada, mesmo com login', async () => {
    const db = ana();
    await assertFails(getDoc(doc(db, 'outra/qualquer')));
    await assertFails(setDoc(doc(db, 'outra/qualquer'), { uid: 'ana-uid' }));
  });
});
