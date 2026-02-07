import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/item_estoque.dart';

class CriarEntradaPage extends StatefulWidget {
  const CriarEntradaPage({super.key});

  @override
  State<CriarEntradaPage> createState() => _CriarEntradaPageState();
}

class _CriarEntradaPageState extends State<CriarEntradaPage> {
  final TextEditingController _fornecedorController = TextEditingController();
  final TextEditingController _notaController = TextEditingController();
  List<Map<String, dynamic>> itensEntrada = [];

  void _buscarEAdicionarItem() {
    String buscaItem = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Selecionar Item da Nota',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(
                    decoration: const InputDecoration(
                        labelText: 'Pesquisar produto...',
                        prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setModalState(() => buscaItem = v.toLowerCase()),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                        final produtos = snapshot.data!.docs
                            .where((doc) => doc['item']
                                .toString()
                                .toLowerCase()
                                .contains(buscaItem))
                            .toList();

                        return ListView.builder(
                          itemCount: produtos.length,
                          itemBuilder: (context, index) {
                            final p = produtos[index];
                            return ListTile(
                              title: Text(p['item']),
                              subtitle: Text('Cód: ${p['codigo']}'),
                              onTap: () => _definirQuantidade(p['codigo'], p['item']),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _definirQuantidade(String codigo, String nome) {
    TextEditingController qController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quantidade de $nome'),
        content: TextField(
          controller: qController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Qtd na Nota Fiscal'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              int qtd = int.tryParse(qController.text) ?? 0;
              if (qtd > 0) {
                setState(() {
                  itensEntrada.add({
                    'codigo': codigo,
                    'nome': nome,
                    'quantidade': qtd,
                  });
                });
                Navigator.pop(context); // Fecha o Dialog
                Navigator.pop(context); // Fecha o BottomSheet
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarEntrada() async {
    if (itensEntrada.isEmpty || _fornecedorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o fornecedor e adicione itens!')),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    DocumentReference entradaRef = FirebaseFirestore.instance.collection('entradas_estoque').doc();
    batch.set(entradaRef, {
      'fornecedor': _fornecedorController.text,
      'nota_fiscal': _notaController.text,
      'data': Timestamp.now(),
      'itens': itensEntrada,
    });

    for (var item in itensEntrada) {
      DocumentReference prodRef = FirebaseFirestore.instance.collection('produtos').doc(item['codigo']);
      batch.update(prodRef, {
        'saldo_atual': FieldValue.increment(item['quantidade'])
      });
    }

    await batch.commit();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Entrada de Material'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _fornecedorController,
                decoration: const InputDecoration(labelText: 'Fornecedor / Origem')),
            TextField(
                controller: _notaController,
                decoration: const InputDecoration(labelText: 'Nº da Nota ou Cupom')),
            const Divider(height: 30),
            const Text("Itens da Nota:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: itensEntrada.length,
                itemBuilder: (context, index) {
                  final item = itensEntrada[index];
                  return ListTile(
                    title: Text(item['nome']),
                    trailing: Text('Qtd: ${item['quantidade']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.blue)),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _buscarEAdicionarItem,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Item da Nota'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _finalizarEntrada,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('CONFIRMAR RECEBIMENTO',
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}