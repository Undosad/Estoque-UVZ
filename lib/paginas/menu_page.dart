import 'package:flutter/material.dart';
import 'package:primeiro_projeto_flutter/paginas/estoque_page.dart';
import 'package:primeiro_projeto_flutter/paginas/saidas_page.dart';
import 'package:primeiro_projeto_flutter/paginas/entradas_page.dart';
import 'package:primeiro_projeto_flutter/paginas/pedidos_page.dart';
import 'package:primeiro_projeto_flutter/paginas/historico_pedidos_pessoa_page.dart';
import 'package:primeiro_projeto_flutter/paginas/meus_pedidos_page.dart'; // <--- IMPORTANTE IMPORTAR
import 'package:provider/provider.dart';
import '../providers/usuario_provider.dart';
import 'login_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  String exibirNivel(String? nivel) {
    if (nivel == 'especial') {
      return 'Controlador de Estoque';
    }
    return 'Requisitante';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = Provider.of<UsuarioProvider>(context);
    final bool isControlador = usuario.nivel == 'especial';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Olá, ${usuario.nome ?? 'Usuário'}", style: const TextStyle(fontSize: 16)),
            Text(
              "Núcleo: ${usuario.nucleo ?? 'Não definido'} (${exibirNivel(usuario.nivel)})",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            tooltip: "Sair",
            onPressed: () async {
              await Provider.of<UsuarioProvider>(context, listen: false).logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // 1. ESTOQUE / SOLICITAÇÃO (Todos vêem)
              _botaoMenu(context, isControlador ? 'Gerenciar Estoque' : 'Solicitar Materiais', const EstoquePage(), Colors.blue),

              // 2. SE FOR REQUISITANTE (Núcleo)
              if (!isControlador) ...[
                _botaoMenu(context, 'Meus Pedidos / Status', const MeusPedidosPage(), Colors.green),
              ],

              // 3. SE FOR CONTROLADOR (Especial)
              if (isControlador) ...[
                _botaoMenu(context, 'Entradas', const EntradasPage(), Colors.blue),
                _botaoMenu(context, 'Saídas', const SaidasPage(), Colors.blue),
                _botaoMenu(context, 'Pedidos Pendentes (Gestão)', const PedidosPage(), Colors.orangeAccent),
                _botaoMenu(context, 'Relatório por Pessoa/Núcleo', const HistoricoPedidosPessoaPage(), Colors.blueAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoMenu(BuildContext context, String texto, Widget pagina, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => pagina)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 55), // Botão ocupa a largura disponível
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
        ),
        child: Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }
}