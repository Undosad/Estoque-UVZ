import 'package:flutter/material.dart';

class DetalheMovimentacaoPage extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List itens;

  const DetalheMovimentacaoPage({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes'), backgroundColor: Colors.blueGrey),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.blueGrey.withOpacity(0.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text(subtitulo),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: itens.length,
              itemBuilder: (context, index) {
                final item = itens[index] as Map<String, dynamic>;
                
                // Lógica robusta para mostrar quantidades
                String infoQtd = "";
                if (item.containsKey('quantidade')) {
                  infoQtd = "Qtd: ${item['quantidade']}";
                } else {
                  int p = item['qtd_pedida'] ?? 0;
                  int e = item['qtd_entregue'] ?? 0;
                  infoQtd = "Ped: $p | Ent: $e";
                }

                return ListTile(
                  title: Text(item['nome'] ?? 'Sem nome'),
                  subtitle: Text('Código: ${item['codigo'] ?? 'N/A'}'),
                  trailing: Text(infoQtd, style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}