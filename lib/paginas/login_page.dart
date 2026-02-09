import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/usuario_provider.dart';
import 'menu_page.dart';
import 'cadastro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  bool _carregando = false;
  bool _lembrarMe = true;

  Future<void> _entrar() async {
    if (_emailController.text.isEmpty || _senhaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha e-mail e senha!")),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      // 1. Tenta o login no Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _senhaController.text.trim());

      // 2. Busca os dados extras no Firestore usando o UID do usuário
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        var dados = userDoc.data() as Map<String, dynamic>;

        // 3. Verifica se o administrador já aprovou o usuário
        if (dados['status'] == 'pendente') {
          await FirebaseAuth.instance.signOut(); // Desloga por segurança
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sua conta aguarda aprovação do administrador.")),
          );
        } else {
          // 4. Salva no Provider e vai para o Menu
          if (!mounted) return;
          await Provider.of<UsuarioProvider>(context, listen: false).configurarUsuario(
            dados['nome'] ?? 'Usuário',
            dados['nucleo'] ?? 'Geral',
            _lembrarMe,
            nivel: dados['nivel'] ?? 'comum', // Passando o nível real do banco!
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MenuPage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String erro = "Erro ao entrar";
      if (e.code == 'user-not-found') erro = "E-mail não cadastrado.";
      if (e.code == 'wrong-password') erro = "Senha incorreta.";
      if (e.code == 'invalid-email') erro = "E-mail inválido.";
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.inventory, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text("Estoque UVZ", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Senha", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _lembrarMe,
                    onChanged: (val) => setState(() => _lembrarMe = val!),
                  ),
                  const Text("Manter logado"),
                ],
              ),
              const SizedBox(height: 20),
              _carregando
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _entrar,
                        child: const Text("ACESSAR", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CadastroPage()));
                },
                child: const Text("Não tem conta? Cadastre-se agora"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}