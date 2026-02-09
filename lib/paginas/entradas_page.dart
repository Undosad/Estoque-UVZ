import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'detalhe_movimentacao_page.dart'; 
import 'criar_entrada_page.dart';

class EntradasPage extends StatefulWidget {
  const EntradasPage({super.key});

  @override
  State<EntradasPage> createState() => _EntradasPageState();
}

class _EntradasPageState extends State<EntradasPage> {
  bool _visaoPorItem = false;
  String _filtroItem = "";
  String _filtroFornecedor = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Entradas (NF)'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(_visaoPorItem ? Icons.list : Icons.inventory_2),
            tooltip: _visaoPorItem ? 'Ver por Nota' : 'Ver por Item',
            onPressed: () => setState(() => _visaoPorItem = !_visaoPorItem),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Filtrar por fornecedor/NF...',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.white,
                    filled: true,
                    isDense: true,
                  ),
                  onChanged: (valor) => setState(() => _filtroFornecedor = valor.toLowerCase()),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Filtrar por item...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.white,
                    filled: true,
                    isDense: true,
                  ),
                  onChanged: (valor) => setState(() => _filtroItem = valor.toLowerCase()),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('entradas_estoque')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar histórico.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhuma nota registrada.'));

          if (_visaoPorItem) {
            return _buildVisaoPorItem(docs);
          } else {
            return _buildVisaoPorNota(docs);
          }
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

  Widget _buildVisaoPorNota(List<QueryDocumentSnapshot> docs) {
    final filtrados = docs.where((doc) {
      final dados = doc.data() as Map<String, dynamic>;
      final fornecedor = (dados['fornecedor'] ?? "").toString().toLowerCase();
      final nf = (dados['nota_fiscal'] ?? "").toString().toLowerCase();
      final itens = (dados['itens'] ?? []) as List;
      
      bool atendeFornecedor = fornecedor.contains(_filtroFornecedor) || nf.contains(_filtroFornecedor);
      bool atendeItem = _filtroItem.isEmpty || itens.any((i) => (i['nome'] ?? "").toString().toLowerCase().contains(_filtroItem));
      
      return atendeFornecedor && atendeItem;
    }).toList();

    return ListView.builder(
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final dados = filtrados[index].data() as Map<String, dynamic>;
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
  }

  Widget _buildVisaoPorItem(List<QueryDocumentSnapshot> docs) {
    Map<String, Map<String, dynamic>> itensAgrupados = {};

    for (var doc in docs) {
      final dados = doc.data() as Map<String, dynamic>;
      final fornecedor = (dados['fornecedor'] ?? "").toString();
      final nf = (dados['nota_fiscal'] ?? "").toString();
      if (!fornecedor.toLowerCase().contains(_filtroFornecedor) && !nf.toLowerCase().contains(_filtroFornecedor)) continue;

      final itens = (dados['itens'] ?? []) as List;
      for (var item in itens) {
        final nome = (item['nome'] ?? "Sem nome").toString();
        if (!nome.toLowerCase().contains(_filtroItem)) continue;

        final codigo = (item['codigo'] ?? "S/C").toString();
        final qtd = (item['quantidade'] ?? 0) as int;

        if (itensAgrupados.containsKey(codigo)) {
          itensAgrupados[codigo]!['total'] += qtd;
          itensAgrupados[codigo]!['entradas'].add({
            'data': (dados['data'] as Timestamp).toDate(),
            'fornecedor': fornecedor,
            'nf': nf,
            'qtd': qtd
          });
        } else {
          itensAgrupados[codigo] = {
            'nome': nome,
            'total': qtd,
            'entradas': [{
              'data': (dados['data'] as Timestamp).toDate(),
              'fornecedor': fornecedor,
              'nf': nf,
              'qtd': qtd
            }]
          };
        }
      }
    }

    final listaItens = itensAgrupados.values.toList();
    listaItens.sort((a, b) => a['nome'].compareTo(b['nome']));

    return ListView.builder(
      itemCount: listaItens.length,
      itemBuilder: (context, index) {
        final item = listaItens[index];
        return ExpansionTile(
          leading: const Icon(Icons.add_box, color: Colors.blueGrey),
          title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Total que entrou: ${item['total']}'),
          children: (item['entradas'] as List).map<Widget>((e) {
            return ListTile(
              dense: true,
              title: Text('Fornecedor: ${e['fornecedor']} (NF: ${e['nf']})'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(e['data'])),
              trailing: Text('${e['qtd']} un', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
        );
      },
    );
  }
}
