import 'package:flutter/material.dart';
import 'package:primeiro_projeto_flutter/paginas/lista_total_page.dart';

class CategoriasPage extends StatelessWidget {
  const CategoriasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          _itemCategoria(context, 'Higienização e Limpeza', Icons.cleaning_services),
          const Divider(),
          _itemCategoria(context, 'Laboratório', Icons.biotech),
          const Divider(),
          _itemCategoria(context, 'Material Hospitalar', Icons.local_hospital),
          const Divider(),
          _itemCategoria(context, 'Medicação Veterinária', Icons.pets),
          const Divider(),
          _itemCategoria(context, 'Material Permanente', Icons.inventory_2),
          const Divider(),
          _itemCategoria(context, 'Expediente', Icons.edit_note),
          const Divider(),
          _itemCategoria(context, 'EPI', Icons.engineering),
          const Divider(),
          _itemCategoria(context, 'Peça de Reposição UBV', Icons.settings),
          const Divider(),
          _itemCategoria(context, 'Fardamento', Icons.checkroom),
        ],
      ),
    );
  }

  // Função para criar o item da lista com ícone personalizado
Widget _itemCategoria(BuildContext context, String nome, IconData icone) {
  return ListTile(
    leading: Icon(icone, color: Colors.blueGrey),
    title: Text(nome),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      // Navega para a lista total, mas avisa qual categoria filtrar
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ListaTotalPage(categoriaParaFiltrar: nome),
        ),
      );
    },
  );
}
}