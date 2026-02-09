import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';

class EstoquePage extends StatefulWidget {
  const EstoquePage({super.key});

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage> {
  String _busca = "";
  final List<Map<String, dynamic>> _carrinho = [];

  void _adicionarAoCarrinho(Map<String, dynamic> produto) {
    final TextEditingController qtdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Solicitar Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(produto['item'], style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: qtdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantidade Necessária",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              if (qtdController.text.isNotEmpty) {
                setState(() {
                  _carrinho.add({
                    'produto': produto['item'],
                    'quantidade': double.tryParse(qtdController.text) ?? 0,
                    'unidade': produto['unidade'] ?? 'UN',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${produto['item']} adicionado à lista!")),
                );
              }
            },
            child: const Text("Adicionar"),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarRequisicaoCompleta(UsuarioProvider usuario) async {
    if (_carrinho.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('requisicoes').add({
        'solicitante': usuario.nome,
        'nucleo': usuario.nucleo,
        'data': FieldValue.serverTimestamp(),
        'status': 'pendente',
        'itens': List.from(_carrinho), 
      });

      // TRAVA DE SEGURANÇA: Verifica se a tela ainda existe antes de atualizar o estado
      if (!mounted) return;

      setState(() {
        _carrinho.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Requisição enviada com sucesso!")),
      );
    } catch (e) {
      // TRAVA DE SEGURANÇA para erro
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar: $e")),
      );
    }
  }

  Future<void> _editarSaldo(BuildContext context, String docId, String nomeItem, num saldoAtual, String nomeUsuario) async {
    final TextEditingController controller = TextEditingController(text: saldoAtual.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Corrigir Saldo"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Novo Saldo", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              double? novoSaldo = double.tryParse(controller.text);
              if (novoSaldo != null) {
                await FirebaseFirestore.instance.collection('produtos').doc(docId).update({'saldo_atual': novoSaldo});
                
                if (!context.mounted) return; // Trava de segurança no diálogo
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<UsuarioProvider>(context);
    final bool isControlador = usuario.nivel == 'especial';

    return DefaultTabController(
      length: isControlador ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isControlador ? "Estoque UVZ" : "Solicitar Itens"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            // Se for requisitante, a altura é menor pois não tem as abas
            preferredSize: Size.fromHeight(isControlador ? 110 : 70),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: TextField(
                    onChanged: (val) => setState(() => _busca = val.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Buscar item...",
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (isControlador) // Só mostra as abas para o Controlador
                  const TabBar(
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: "GERAL"),
                      Tab(text: "A CORRIGIR"),
                    ],
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: !isControlador && _carrinho.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _enviarRequisicaoCompleta(usuario),
                label: Text("Enviar Pedido (${_carrinho.length} itens)"),
                icon: const Icon(Icons.send),
                backgroundColor: Colors.green,
              )
            : null,
        body: isControlador 
          ? TabBarView(
              children: [
                _listaEstoque(context, false, isControlador, usuario),
                _listaEstoque(context, true, isControlador, usuario),
              ],
            )
          : _listaEstoque(context, false, isControlador, usuario),
      ),
    );
  }

  Widget _listaEstoque(BuildContext context, bool apenasNegativos, bool isControlador, UsuarioProvider usuario) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs.where((doc) {
          var p = doc.data() as Map<String, dynamic>;
          bool bateBusca = (p['item'] ?? '').toString().toLowerCase().contains(_busca);
          bool bateNegativo = apenasNegativos ? (p['saldo_atual'] ?? 0) < 0 : true;
          return bateBusca && bateNegativo;
        }).toList();

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var produto = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: ListTile(
                title: Text(produto['item'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text(produto['tipificacao'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isControlador)
                      Text(
                        "${produto['saldo_atual']} ${produto['unidade']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (produto['saldo_atual'] ?? 0) < 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    const SizedBox(width: 10),
                    if (isControlador)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarSaldo(context, doc.id, produto['item'], produto['saldo_atual'], usuario.nome!),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                        onPressed: () => _adicionarAoCarrinho(produto),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}