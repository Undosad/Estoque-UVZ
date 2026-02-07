import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import 'package:primeiro_projeto_flutter/paginas/detalhe_movimentacao_page.dart';
import 'conferencia_pedido_page.dart';

class PedidosPage extends StatelessWidget {
  const PedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requisições Pendentes'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Filtramos para mostrar apenas o que está pendente
        stream: FirebaseFirestore.instance
            .collection('requisicoes')
            .where('status', isEqualTo: 'pendente')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar.'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma requisição pendente.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final dados = docs[index].data() as Map<String, dynamic>;
              final DateTime data = (dados['data'] as Timestamp).toDate();
              final String solicitante = dados['solicitante'] ?? 'Não informado';
              final List itens = dados['itens'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.orange),
                  title: Text('Solicitante: $solicitante'),
                  subtitle: Text(
                    'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}\n${itens.length} itens solicitados',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalheMovimentacaoPage(
                          titulo: 'Solicitante: ${dados['solicitante']}',
                          subtitulo: 'Status: Pendente',
                          itens: dados['itens'] ?? dados['produtos'] ?? [],
                        ),
                      ),
                    );
                    _abrirConferencia(context, docs[index].id, dados);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _abrirConferencia(BuildContext context, String idDoc, Map<String, dynamic> dados) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConferenciaPedidoPage(docId: idDoc, dados: dados),
      ),
    );
  }
}