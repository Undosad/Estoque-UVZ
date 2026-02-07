const admin = require('firebase-admin');
const fs = require('fs');
const csv = require('csv-parser');
const iconv = require('iconv-lite');

const serviceAccount = require("./chave-firebase.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

function tratarSaldo(valor) {
  if (!valor) return 0;
  const texto = String(valor).trim().toUpperCase();
  if (texto.includes('#REF')) return -888;
  const num = parseInt(texto);
  if (isNaN(num)) return 0;
  return num < 0 ? -999 : num;
}

console.log("⏳ Iniciando importação por posição...");
console.log("⏳ Iniciando importação com correção de acentos...");

fs.createReadStream('estoque.csv')
  .pipe(iconv.decodeStream('win1252')) 
  .pipe(csv({ separator: ';', headers: false })) 
  .on('data', async (row) => {
    const colunas = Object.values(row);
    
    const codigo = colunas[0];
    const item = colunas[1]; // Aqui o acento já deve estar corrigido
    const tipificacao = colunas[2];
    const unidade = colunas[3];
    const saldo = colunas[4];

    if (codigo === 'codigo' || !codigo) return;

    try {
      await db.collection('produtos').doc(String(codigo)).set({
        codigo: String(codigo),
        item: item ? item.trim() : "Sem nome",
        tipificacao: tipificacao || "",
        unidade: unidade || "",
        saldo_atual: tratarSaldo(saldo)
      });
      console.log(`✅ Corrigido: ${item}`);
    } catch (e) {
      console.error(`❌ Erro no código ${codigo}:`, e.message);
    }
  })
  .on('end', () => {
    console.log('🚀 Importação finalizada com acentos corrigidos!');
  });