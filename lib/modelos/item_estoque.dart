
class ItemEstoque {
  final String codigo;
  final String item;
  final String tipificacao;
  final String unidade;
  final int saldo;

  ItemEstoque({
    required this.codigo,
    required this.item,
    required this.tipificacao,
    required this.unidade,
    required this.saldo,
  });

  // Converte o mapa do Firebase para o nosso modelo
  factory ItemEstoque.fromFirestore(Map<String, dynamic> data) {
    return ItemEstoque(
      codigo: data['codigo']?.toString() ?? '',
      item: data['item'] ?? '',
      tipificacao: data['tipificacao'] ?? '',
      unidade: data['unidade'] ?? '',
      saldo: data['saldo_atual'] ?? 0,
    );
  }
}