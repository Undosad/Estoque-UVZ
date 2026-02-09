import 'package:flutter/material.dart';

class CarrinhoService extends ChangeNotifier {
  // Singleton para acesso global
  static final CarrinhoService _instance = CarrinhoService._internal();
  factory CarrinhoService() => _instance;
  CarrinhoService._internal();

  final List<Map<String, dynamic>> _itens = [];

  List<Map<String, dynamic>> get itens => List.unmodifiable(_itens);

  void adicionarItem(Map<String, dynamic> item) {
    // Verifica se o item já existe no carrinho pelo código
    int index = _itens.indexWhere((i) => i['codigo'] == item['codigo']);
    if (index != -1) {
      // Se já existe, soma a quantidade
      _itens[index]['qtd_pedida'] += item['qtd_pedida'];
    } else {
      // Se não existe, adiciona novo
      _itens.add(item);
    }
    notifyListeners();
  }

  void removerItem(String codigo) {
    _itens.removeWhere((item) => item['codigo'] == codigo);
    notifyListeners();
  }

  void limparCarrinho() {
    _itens.clear();
    notifyListeners();
  }

  int get totalItens => _itens.length;
}
