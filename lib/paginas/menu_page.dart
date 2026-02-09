import 'package:flutter/material.dart';
import 'package:primeiro_projeto_flutter/paginas/estoque_page.dart';
import 'package:primeiro_projeto_flutter/paginas/saidas_page.dart';
import 'package:primeiro_projeto_flutter/paginas/entradas_page.dart';
import 'package:primeiro_projeto_flutter/paginas/pedidos_page.dart';
import 'package:primeiro_projeto_flutter/paginas/historico_pedidos_pessoa_page.dart';




class MinhaTela extends StatelessWidget {
  const MinhaTela({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BOTÃO ESTOQUE
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EstoquePage()),
                );
              },
              child: const Text('Estoque'),
            ),
            const SizedBox(height: 20),

            // BOTÃO ENTRADAS
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EntradasPage()), // Nome da classe no arquivo entradas_page
                );
              },
              child: const Text('Entradas'),
            ),
            const SizedBox(height: 20),

            // BOTÃO SAÍDAS
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SaidasPage()), // Nome da classe no arquivo saidas_page
                );
              },
              child: const Text('Saídas'),
            ),
            const SizedBox(height: 20),

            // BOTÃO PEDIDOS (PENDENTES)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PedidosPage()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
              child: const Text('Pedidos Pendentes'),
            ),
            const SizedBox(height: 20),

            // BOTÃO HISTÓRICO POR PESSOA
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoricoPedidosPessoaPage()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              child: const Text('Pedidos por Pessoa/Núcleo'),
            ),
          ],
        ),
      ),
    );
  }
}