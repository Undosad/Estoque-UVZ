import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'detalhe_movimentacao_page.dart';

class HistoricoPedidosPessoaPage extends StatefulWidget {
  const HistoricoPedidosPessoaPage({super.key});

  @override
  State<HistoricoPedidosPessoaPage> createState() => _HistoricoPedidosPessoaPageState();
}

class _HistoricoPedidosPessoaPageState extends State<HistoricoPedidosPessoaPage> {
  String _filtroSolicitante = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos por Pessoa/Núcleo'),
        backgroundColor: Colors.blueAccent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Filtrar por solicitante...',
                prefixIcon: const Icon(Icons.person_search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (valor) => setState(() => _filtroSolicitante = valor.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requisicoes')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar pedidos.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final solicitante = (doc['solicitante'] ?? "").toString().toLowerCase();
            return solicitante.contains(_filtroSolicitante);
          }).toList();

          if (docs.isEmpty) return const Center(child: Text('Nenhum pedido encontrado.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final dados = docs[index].data() as Map<String, dynamic>;
              final DateTime data = (dados['data'] as Timestamp).toDate();
              final String solicitante = dados['solicitante'] ?? 'Não informado';
              final String status = dados['status'] ?? 'pendente';
              final List itens = dados['itens'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    status == 'finalizado' ? Icons.check_circle : Icons.pending_actions,
                    color: status == 'finalizado' ? Colors.green : Colors.orange,
                  ),
                  title: Text('Solicitante: $solicitante'),
                  subtitle: Text(
                    'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}\nStatus: ${status.toUpperCase()} | ${itens.length} itens',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalheMovimentacaoPage(
                          titulo: 'Solicitante: $solicitante',
                          subtitulo: 'Status: ${status.toUpperCase()}',
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
    );
  }
}
