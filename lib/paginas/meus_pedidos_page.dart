import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';

class MeusPedidosPage extends StatelessWidget {
  const MeusPedidosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<UsuarioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Solicitações"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Removi o .where() daqui para evitar o erro de índice
        stream: FirebaseFirestore.instance
            .collection('requisicoes')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- FILTRAGEM MANUAL NO CÓDIGO ---
          // Pegamos todos os pedidos do banco e filtramos apenas os do usuário logado
          final docs = snapshot.data!.docs.where((doc) {
            final dados = doc.data() as Map<String, dynamic>;
            return dados['solicitante'] == usuario.nome; 
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text("Você ainda não realizou nenhum pedido."),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final dados = docs[index].data() as Map<String, dynamic>;
              final DateTime data = (dados['data'] as Timestamp?)?.toDate() ?? DateTime.now();
              final String status = dados['status'] ?? 'pendente';
              final List itens = dados['itens'] ?? [];

              Color corStatus = Colors.orange;
              if (status == 'entregue') corStatus = Colors.green;
              if (status == 'cancelado') corStatus = Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: Icon(Icons.shopping_basket, color: corStatus),
                  title: Text("Pedido de ${DateFormat('dd/MM/yyyy HH:mm').format(data)}"),
                  subtitle: Text("Status: ${status.toUpperCase()}"),
                  children: [
                    const Divider(),
                    ...itens.map((item) {
                      return ListTile(
                        dense: true,
                        title: Text(item['produto'] ?? 'Item desconhecido'),
                        trailing: Text(
                          "${item['quantidade']} ${item['unidade']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}