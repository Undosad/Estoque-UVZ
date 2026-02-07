import 'package:cloud_firestore/cloud_firestore.dart';

class RequisicaoModel {
  String? id; // ID gerado pelo Firebase
  DateTime data;
  String status; // 'pendente' ou 'finalizado'
  String solicitante;
  List<Map<String, dynamic>> itens;

  RequisicaoModel({
    this.id,
    required this.data,
    this.status = 'pendente',
    required this.solicitante,
    required this.itens,
  });

  // Transforma os dados para o formato que o Firebase entende
  Map<String, dynamic> toMap() {
    return {
      'data': Timestamp.fromDate(data), // Firebase usa Timestamp
      'status': status,
      'solicitante': solicitante,
      'itens': itens, // Aqui vai a lista de códigos e quantidades
    };
  }
}