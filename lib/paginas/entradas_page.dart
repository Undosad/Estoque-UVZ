import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ESTA LINHA É A MAIS IMPORTANTE PARA RESOLVER O ERRO:
import 'detalhe_movimentacao_page.dart'; 
import 'criar_entrada_page.dart';

class EntradasPage extends StatelessWidget {
  const EntradasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Entradas (NF)'),
        backgroundColor: Colors.blueGrey,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entradas_estoque')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar histórico.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma nota registrada.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final dados = docs[index].data() as Map<String, dynamic>;
              final DateTime data = (dados['data'] as Timestamp).toDate();
              final String fornecedor = dados['fornecedor'] ?? 'S/F';
              final String nf = dados['nota_fiscal'] ?? 'S/N';
              final List itens = dados['itens'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.inventory, color: Colors.blueGrey),
                  title: Text('Fornecedor: $fornecedor'),
                  subtitle: Text(
                    'NF: $nf | Data: ${DateFormat('dd/MM/yyyy').format(data)}\n${itens.length} itens recebidos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  // AQUI É ONDE ATIVAMOS O CLIQUE PARA VER DETALHES:
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalheMovimentacaoPage(
                          titulo: 'Fornecedor: $fornecedor',
                          subtitulo: 'Nota Fiscal: $nf',
                          itens: itens,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CriarEntradaPage()),
          );
        },
        label: const Text('Nova Entrada (NF)'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}