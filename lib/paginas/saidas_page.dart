import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'detalhe_movimentacao_page.dart';

class SaidasPage extends StatefulWidget {
  const SaidasPage({super.key});

  @override
  State<SaidasPage> createState() => _SaidasPageState();
}

class _SaidasPageState extends State<SaidasPage> {
  bool _visaoPorItem = false;
  String _filtroItem = "";
  String _filtroDestino = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Saídas'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: Icon(_visaoPorItem ? Icons.list : Icons.inventory_2),
            tooltip: _visaoPorItem ? 'Ver por Requisição' : 'Ver por Item',
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
                    hintText: 'Filtrar por destino...',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    fillColor: Colors.white,
                    filled: true,
                    isDense: true,
                  ),
                  onChanged: (valor) => setState(() => _filtroDestino = valor.toLowerCase()),
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
            .collection('requisicoes')
            .where('status', isEqualTo: 'finalizado')
            .orderBy('data_entrega', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Nenhuma saída registrada.'));

          if (_visaoPorItem) {
            return _buildVisaoPorItem(docs);
          } else {
            return _buildVisaoPorRequisicao(docs);
          }
        },
      ),
    );
  }

  Widget _buildVisaoPorRequisicao(List<QueryDocumentSnapshot> docs) {
    final filtrados = docs.where((doc) {
      final dados = doc.data() as Map<String, dynamic>;
      final solicitante = (dados['solicitante'] ?? "").toString().toLowerCase();
      final itens = (dados['itens'] ?? []) as List;
      
      bool atendeDestino = solicitante.contains(_filtroDestino);
      bool atendeItem = _filtroItem.isEmpty || itens.any((i) => (i['nome'] ?? "").toString().toLowerCase().contains(_filtroItem));
      
      return atendeDestino && atendeItem;
    }).toList();

    return ListView.builder(
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final dados = filtrados[index].data() as Map<String, dynamic>;
        final data = (dados['data_entrega'] as Timestamp).toDate();
        final solicitante = dados['solicitante'] ?? 'Não informado';
        final itens = dados['itens'] ?? [];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.outbox, color: Colors.orange),
            title: Text('Destino: $solicitante'),
            subtitle: Text(
              'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}\n${itens.length} itens entregues',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalheMovimentacaoPage(
                    titulo: 'Solicitante: $solicitante',
                    subtitulo: 'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(data)}',
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
      final solicitante = (dados['solicitante'] ?? "").toString();
      if (!solicitante.toLowerCase().contains(_filtroDestino)) continue;

      final itens = (dados['itens'] ?? []) as List;
      for (var item in itens) {
        final nome = (item['nome'] ?? "Sem nome").toString();
        if (!nome.toLowerCase().contains(_filtroItem)) continue;

        final codigo = (item['codigo'] ?? "S/C").toString();
        final qtd = (item['qtd_entregue'] ?? 0) as int;

        if (itensAgrupados.containsKey(codigo)) {
          itensAgrupados[codigo]!['total'] += qtd;
          itensAgrupados[codigo]!['saidas'].add({
            'data': (dados['data_entrega'] as Timestamp).toDate(),
            'destino': solicitante,
            'qtd': qtd
          });
        } else {
          itensAgrupados[codigo] = {
            'nome': nome,
            'total': qtd,
            'saidas': [{
              'data': (dados['data_entrega'] as Timestamp).toDate(),
              'destino': solicitante,
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
          leading: const Icon(Icons.inventory_2, color: Colors.orange),
          title: Text(item['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Total que saiu: ${item['total']}'),
          children: (item['saidas'] as List).map<Widget>((s) {
            return ListTile(
              dense: true,
              title: Text('Para: ${s['destino']}'),
              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(s['data'])),
              trailing: Text('${s['qtd']} un', style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }).toList(),
        );
      },
    );
  }
}
