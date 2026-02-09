import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nucleoController = TextEditingController();
  bool _carregando = false;

  Future<void> _cadastrar() async {
    if (_nomeController.text.isEmpty || _emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha todos os campos!")));
      return;
    }

    setState(() => _carregando = true);
    try {
      // 1. Cria no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _senhaController.text.trim());

      // 2. Salva no Firestore com nível 'comum' por padrão
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
        'nome': _nomeController.text.trim(),
        'nucleo': _nucleoController.text.trim(),
        'nivel': 'comum', 
        'status': 'pendente',
        'uid': userCredential.user!.uid,
        'dataCriacao': DateTime.now(),
      });

      if (!mounted) return;
      Navigator.pop(context); // Volta para o login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cadastrado com sucesso! Aguarde ativação.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Usuário"), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.person_add, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome Completo", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _nucleoController, decoration: const InputDecoration(labelText: "Núcleo/Distrito", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _senhaController, obscureText: true, decoration: const InputDecoration(labelText: "Senha", border: OutlineInputBorder())),
            const SizedBox(height: 30),
            _carregando 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50)
                  ),
                  onPressed: _cadastrar, 
                  child: const Text("CRIAR CONTA"),
                ),
          ],
        ),
      ),
    );
  }
}