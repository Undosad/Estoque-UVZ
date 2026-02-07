import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'detalhe_movimentacao_page.dart';

class SaidasPage extends StatelessWidget {
  const SaidasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Saídas'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Buscamos apenas o que já foi finalizado
        stream: FirebaseFirestore.instance
            .collection('requisicoes')
            .where('status', isEqualTo: 'finalizado')
            .orderBy('data_entrega', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Tratamento de Erro de Conexão ou Índice
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Erro ao carregar histórico: ${snapshot.error}'),
              ),
            );
          }

          // 2. Tela de Carregamento
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          // 3. Caso não existam dados
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma saída registrada.'));
          }

          // 4. A Lista propriamente dita
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final dados = docs[index].data() as Map<String, dynamic>;

                // Tratamento flexível da data
                DateTime dataExibicao = DateTime.now();
                if (dados['data_entrega'] is Timestamp) {
                  dataExibicao = (dados['data_entrega'] as Timestamp).toDate();
                } else if (dados['data'] is Timestamp) {
                  dataExibicao = (dados['data'] as Timestamp).toDate();
                }

                // Tratamento flexível da lista de itens (itens ou produtos)
                var listaBruta = dados['itens'] ?? dados['produtos'];
                List listaDeItens = (listaBruta is List) ? listaBruta : [];
                
                final String solicitante = dados['solicitante'] ?? 'Não informado';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.outbox, color: Colors.orange),
                    title: Text('Destino: $solicitante'),
                    subtitle: Text(
                      'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(dataExibicao)}\n${listaDeItens.length} itens entregues',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalheMovimentacaoPage(
                            titulo: 'Solicitante: $solicitante',
                            subtitulo: 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(dataExibicao)}',
                            itens: listaDeItens,
                          ),
                        ),
                      );
                    },
                  ),
                );
              } catch (e) {
                // Se um documento específico estiver com erro, mostra este card de aviso
                return Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    title: const Text("Erro ao ler este registro"),
                    subtitle: Text("ID: ${docs[index].id}"),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}