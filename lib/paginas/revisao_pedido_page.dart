import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicos/carrinho_service.dart';

class RevisaoPedidoPage extends StatefulWidget {
  final List<Map<String, dynamic>> itensSelecionados;

  const RevisaoPedidoPage({super.key, required this.itensSelecionados});

  @override
  State<RevisaoPedidoPage> createState() => _RevisaoPedidoPageState();
}

class _RevisaoPedidoPageState extends State<RevisaoPedidoPage> {
  final TextEditingController _solicitanteController = TextEditingController();
  bool _estaSalvando = false;

  Future<void> _finalizarRequisicao() async {
    if (_solicitanteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, informe quem está solicitando.')),
      );
      return;
    }

    setState(() => _estaSalvando = true);

    try {
      await FirebaseFirestore.instance.collection('requisicoes').add({
        'solicitante': _solicitanteController.text,
        'data': Timestamp.now(),
        'status': 'pendente',
        'itens': widget.itensSelecionados,
      });

      if (mounted) {
        CarrinhoService().limparCarrinho();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requisição enviada com sucesso!')),
        );
      }
    } catch (e) {
      setState(() => _estaSalvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Requisição'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _solicitanteController,
              decoration: const InputDecoration(
                labelText: 'Nome do Solicitante / Setor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Itens Selecionados:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.itensSelecionados.length,
                itemBuilder: (context, index) {
                  final item = widget.itensSelecionados[index];
                  return ListTile(
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text(item['nome']),
                    subtitle: Text('Quantidade pedida: ${item['qtd_pedida']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // --- SOLUÇÃO PARA O BOTÃO ---
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            height: 55, // Aumentei um pouco para facilitar o toque
            child: ElevatedButton(
              onPressed: _estaSalvando ? null : _finalizarRequisicao,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _estaSalvando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'ENVIAR REQUISIÇÃO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}