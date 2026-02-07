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
  // Mapa para controlar as quantidades que o estoquista vai digitar
  Map<String, TextEditingController> controllers = {};
  bool _processando = false;

  @override
  void initState() {
    super.initState();
    // Inicializa um controlador de texto para cada item do pedido
    for (var item in widget.dados['itens']) {
      controllers[item['codigo']] = TextEditingController(text: item['qtd_pedida'].toString());
    }
  }

  Future<void> _confirmarEntrega() async {
    setState(() => _processando = true);
    final batch = FirebaseFirestore.instance.batch(); // Usa Batch para atualizar tudo de uma vez

    try {
      for (var item in widget.dados['itens']) {
        String codigo = item['codigo'];
        int entregue = int.tryParse(controllers[codigo]!.text) ?? 0;

        // 1. Referência do produto no estoque para subtrair o saldo
        DocumentReference produtoRef = FirebaseFirestore.instance.collection('produtos').doc(codigo);
        
        // Buscamos o saldo atual para subtrair
        DocumentSnapshot produtoSnapshot = await produtoRef.get();
        if (produtoSnapshot.exists) {
          int saldoAtual = produtoSnapshot['saldo_atual'] ?? 0;
          batch.update(produtoRef, {'saldo_atual': saldoAtual - entregue});
        }

        // Atualiza a quantidade entregue no registro da requisição
        item['qtd_entregue'] = entregue;
      }

      // 2. Atualiza a requisição para 'finalizado' e salva as quantidades entregues
      DocumentReference reqRef = FirebaseFirestore.instance.collection('requisicoes').doc(widget.docId);
      batch.update(reqRef, {
        'status': 'finalizado',
        'itens': widget.dados['itens'],
        'data_entrega': Timestamp.now(),
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estoque atualizado e pedido finalizado!')),
        );
      }
    } catch (e) {
      setState(() => _processando = false);
      print("Erro ao dar baixa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List itens = widget.dados['itens'];

    return Scaffold(
      appBar: AppBar(title: const Text('Conferir Entrega'), backgroundColor: Colors.green),
      body: Column(
        children: [
          ListTile(
            tileColor: Colors.grey.shade200,
            title: Text('Solicitante: ${widget.dados['solicitante']}'),
            subtitle: const Text('Confirme as quantidades abaixo antes de finalizar.'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index];
                return ListTile(
                  title: Text(item['nome']),
                  subtitle: Text('Pediram: ${item['qtd_pedida']}'),
                  trailing: SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controllers[item['codigo']],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Entregue'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _processando ? null : _confirmarEntrega,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _processando 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('FINALIZAR E DAR BAIXA NO ESTOQUE', style: TextStyle(color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}