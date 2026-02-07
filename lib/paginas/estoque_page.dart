import 'package:flutter/material.dart';
import 'package:primeiro_projeto_flutter/paginas/categorias_page.dart';
import 'package:primeiro_projeto_flutter/paginas/lista_total_page.dart';

class EstoquePage extends StatelessWidget {
  const EstoquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Estoque'),
        backgroundColor: Colors.blue,
      ),
      body: ListView( // ListView é melhor que Column para menus longos
        children: [
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Estoque Completo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
              MaterialPageRoute(builder: (context) => const ListaTotalPage()),
        );
    },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.orange), // Ícone especial para tipos
            title: const Text('Por Tipo'),
            subtitle: const Text('Filtrar estoque por categoria'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Setinha para a direita
          onTap: () {
            // Aqui vamos navegar para a nova página de categorias
            Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoriasPage()),
            );
          },
        ),
        ],
      ),
    );
  }
}