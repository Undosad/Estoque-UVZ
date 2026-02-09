import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConferenciaPedidoPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> dados;

  const ConferenciaPedidoPage({super.key, required this.docId, required this.dados});

  @override
  State<ConferenciaPedidoPage> createState() => _ConferenciaPedidoPageState();
}

class _ConferenciaPedidoPageState extends State<ConferenciaPedidoPage> {
  bool _processando = false;

  // FUNÇÃO MÁGICA: DAR BAIXA AUTOMÁTICA
  Future<void> _confirmarEntrega() async {
    setState(() => _processando = true);

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final List itens = widget.dados['itens'] ?? [];

      // Iniciamos uma transação para garantir que tudo ocorra bem
      await firestore.runTransaction((transaction) async {
        
        for (var item in itens) {
          String nomeItem = item['produto'];
          double qtdPedida = (item['quantidade'] as num).toDouble();

          // 1. Localizar o produto na coleção 'produtos' pelo nome
          final queryProduto = await firestore
              .collection('produtos')
              .where('item', isEqualTo: nomeItem)
              .get();

          if (queryProduto.docs.isNotEmpty) {
            final docProduto = queryProduto.docs.first;
            double saldoAtual = (docProduto.data()['saldo_atual'] as num).toDouble();
            
            // 2. Calcular novo saldo e atualizar dentro da transação
            transaction.update(docProduto.reference, {
              'saldo_atual': saldoAtual - qtdPedida,
            });
          }
        }

        // 3. Mudar o status da requisição para 'entregue'
        transaction.update(firestore.collection('requisicoes').doc(widget.docId), {
          'status': 'entregue',
          'data_entrega': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      Navigator.pop(context); // Volta para a lista
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Entrega confirmada e estoque atualizado!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Erro ao processar: $e")),
      );
    } finally {
      setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List itens = widget.dados['itens'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("Conferir Pedido")),
      body: Column(
        children: [
          ListTile(
            tileColor: Colors.orange.withOpacity(0.1),
            title: Text("Solicitante: ${widget.dados['solicitante']}"),
            subtitle: Text("Núcleo: ${widget.dados['nucleo']}"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                return ListTile(
                  leading: const Icon(Icons.check_box_outline_blank),
                  title: Text(item['produto']),
                  trailing: Text("${item['quantidade']} ${item['unidade']}", 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _processando 
              ? const CircularProgressIndicator()
              : ElevatedButton.icon(
                  onPressed: _confirmarEntrega,
                  icon: const Icon(Icons.done_all),
                  label: const Text("CONFIRMAR ENTREGA E BAIXAR ESTOQUE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}