import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/item_estoque.dart';

class EntradaEstoquePage extends StatefulWidget {
  const EntradaEstoquePage({super.key});

  @override
  State<EntradaEstoquePage> createState() => _EntradaEstoquePageState();
}

class _EntradaEstoquePageState extends State<EntradaEstoquePage> {
  String busca = "";

  void _registrarEntrada(ItemEstoque item) {
    TextEditingController qtdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Entrada: ${item.item}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo atual: ${item.saldo}', style: const TextStyle(color: Colors.blue)),
              const SizedBox(height: 10),
              TextField(
                controller: qtdController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantidade que está entrando',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                int qtdNova = int.tryParse(qtdController.text) ?? 0;
                if (qtdNova > 0) {
                  // Atualiza o Firebase somando ao saldo atual
                  await FirebaseFirestore.instance
                      .collection('produtos')
                      .doc(item.codigo)
                      .update({'saldo_atual': item.saldo + qtdNova});

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Entrada de $qtdNova itens registrada!')),
                    );
                  }
                }
              },
              child: const Text('Confirmar Entrada'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de Material'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar item para entrada...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (v) => setState(() => busca = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final itens = snapshot.data!.docs
                    .map((doc) => ItemEstoque.fromFirestore(doc.data() as Map<String, dynamic>))
                    .where((i) => i.item.toLowerCase().contains(busca) || i.codigo.contains(busca))
                    .toList();

                return ListView.builder(
                  itemCount: itens.length,
                  itemBuilder: (context, index) {
                    final item = itens[index];
                    return ListTile(
                      title: Text(item.item),
                      subtitle: Text('Saldo: ${item.saldo}'),
                      trailing: const Icon(Icons.add_box, color: Colors.blueGrey, size: 30),
                      onTap: () => _registrarEntrada(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}