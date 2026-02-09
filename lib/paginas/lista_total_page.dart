import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/item_estoque.dart';
import 'revisao_pedido_page.dart';
import '../servicos/carrinho_service.dart';


class ListaTotalPage extends StatefulWidget {
  final String? categoriaParaFiltrar; 
  const ListaTotalPage({super.key, this.categoriaParaFiltrar});

  @override
  State<ListaTotalPage> createState() => _ListaTotalPageState();
}

class _ListaTotalPageState extends State<ListaTotalPage> {
  String busca = "";
  final CarrinhoService _carrinhoService = CarrinhoService();

  // Função de normalização para ignorar acentos e erros
  String normalizarTexto(String? texto) {
    if (texto == null) return "";
    
    // 1. Limpeza básica: Tudo maiúsculo e sem espaços sobrando
    String t = texto.toUpperCase().trim();

    // 2. Mapeamento de variações da planilha para nomes padronizados
    if (t.contains("HIGIENIZAÇÃO") || t.contains("LIMPESA") || t.contains("COPA")) {
      return "higienizacao e limpeza";
    }
    if (t.contains("EPI") || t.contains("E.P.I.")) {
      return "epi";
    }
    if (t.contains("LABORATORIO")) {
      return "laboratorio";
    }
    if (t.contains("HOSP.") || t.contains("HOSPITALAR") || t.contains("VETERINARIO")) {
      // Note que "Medicação Veterinária" pode cair aqui, então a ordem importa
      if (t.contains("MEDICACAO")) return "medicacao veterinaria";
      return "material hospitalar";
    }
    if (t.contains("PERMANENTE")) {
      return "material permanente";
    }
    if (t.contains("EXPEDIENTE")) {
      return "expediente";
    }
    if (t.contains("PEÇA") || t.contains("REPOSIÇÃO") || t.contains("UBV")) {
      return "peca de reposicao ubv";
    }
    if (t.contains("FARDAMENTO")) {
      return "fardamento";
    }

    // 3. Se não cair em nenhuma regra, remove acentos e retorna o básico
    var comAcento = 'ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖØÙÚÛÜÑñÇç';
    var semAcento = 'AAAAAAEEEEIIIIOOOOOOUUUUNnCc';
    for (int i = 0; i < comAcento.length; i++) {
      t = t.replaceAll(comAcento[i], semAcento[i]);
    }
    return t.toLowerCase();
  }

  void _adicionarAoCarrinho(ItemEstoque item) {
    TextEditingController qtdController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Solicitar: ${item.item}'),
          content: TextField(
            controller: qtdController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Quantidade desejada'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                int qtd = int.tryParse(qtdController.text) ?? 0;
                if (qtd > 0) {
                  _carrinhoService.adicionarItem({
                    'codigo': item.codigo,
                    'nome': item.item,
                    'qtd_pedida': qtd,
                    'qtd_entregue': 0,
                  });
                  setState(() {}); // Atualiza a UI para mostrar o FAB
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
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
        title: Text(widget.categoriaParaFiltrar ?? 'Estoque Completo'),
        backgroundColor: Colors.blue,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar item...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (valor) => setState(() => busca = valor),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('produtos').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          // 1. Converte documentos para objetos ItemEstoque
          final listaItens = snapshot.data!.docs.map((doc) {
            return ItemEstoque.fromFirestore(doc.data() as Map<String, dynamic>);
          }).toList();

          // 2. FILTRAGEM INTELIGENTE
          final itensFiltrados = listaItens.where((item) {
            final nomeItem = normalizarTexto(item.item);
            final catItem = normalizarTexto(item.tipificacao);
            final termoBusca = normalizarTexto(busca);

            // REGRA: Mostrar apenas se tiver saldo maior que 0
            bool temEstoque = item.saldo > 0;

            // Filtro por Categoria
            bool atendeCategoria = true;
            if (widget.categoriaParaFiltrar != null) {
              atendeCategoria = catItem.contains(normalizarTexto(widget.categoriaParaFiltrar!));
            }

            // Filtro por termo digitado
            bool atendeBusca = nomeItem.contains(termoBusca) || 
                              item.codigo.toString().contains(termoBusca);

            return temEstoque && atendeCategoria && atendeBusca;
          }).toList();

          if (itensFiltrados.isEmpty) return const Center(child: Text('Nenhum item encontrado.'));

          return ListView.builder(
            itemCount: itensFiltrados.length,
            itemBuilder: (context, index) {
              final item = itensFiltrados[index];
              
              Color corSaldo = Colors.black87;
              String textoSaldo = 'Saldo: ${item.saldo}';
              if (item.saldo == -999) { corSaldo = Colors.red; textoSaldo = 'NEGATIVO'; }
              else if (item.saldo == -888) { corSaldo = Colors.orange; textoSaldo = 'ERRO #REF'; }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(item.unidade.isNotEmpty ? item.unidade[0] : 'U'),
                ),
                title: Text(item.item, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Cód: ${item.codigo} | ${item.tipificacao}'),
                trailing: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Saldo: ${item.saldo}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green, size: 28),
                      onPressed: () => _adicionarAoCarrinho(item),
                    ),
                  ],
                ),
              ),
              
              // BANNER DE RESTRIÇÃO (Removi o const que causava o erro)
              if (item.tipificacao.toUpperCase().contains("PERMANENTE") || 
                  item.tipificacao.toUpperCase().contains("MEDICACAO"))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.amber.shade100,
                  child: Row( // Removido 'const' daqui
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Restrição: Necessita autorização (uso/qtd diminuta).",
                          style: TextStyle( // Removido 'const' daqui
                            fontSize: 11, 
                            color: Colors.orange.shade900, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
            },
          );
        },
      ),
      floatingActionButton: _carrinhoService.totalItens == 0 ? null : FloatingActionButton.extended(
        onPressed: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RevisaoPedidoPage(itensSelecionados: _carrinhoService.itens)),
          );
          if (resultado == true) {
            setState(() {}); // Atualiza se o carrinho foi limpo
          }
        },
        label: Text('Ver Pedido (${_carrinhoService.totalItens})'),
        icon: const Icon(Icons.shopping_cart),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }
}