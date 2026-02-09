import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsuarioProvider extends ChangeNotifier {
  String? _nome;
  String? _nucleo;
  String? _nivel; // 'comum' ou 'especial'
  bool _estaLogado = false;

  String? get nome => _nome;
  String? get nucleo => _nucleo;
  String? get nivel => _nivel;
  bool get estaLogado => _estaLogado;

  Future<void> carregarUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    _nome = prefs.getString('nome');
    _nucleo = prefs.getString('nucleo');
    _nivel = prefs.getString('nivel') ?? 'comum'; // Se não tiver, é comum
    
    if (_nome != null && _nucleo != null) {
      _estaLogado = true;
      notifyListeners();
    }
  }

  Future<void> configurarUsuario(String nome, String nucleo, bool lembrar, {String nivel = 'comum'}) async {
    _nome = nome;
    _nucleo = nucleo;
    _nivel = nivel; // Recebe o nível do Firebase (comum ou especial)
    _estaLogado = true;
    notifyListeners();

    if (lembrar) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nome', nome);
      await prefs.setString('nucleo', nucleo);
      await prefs.setString('nivel', nivel); // Salva o nível no celular
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _nome = null;
    _nucleo = null;
    _nivel = null;
    _estaLogado = false;
    notifyListeners();
  }
}