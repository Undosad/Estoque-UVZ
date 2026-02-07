import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'firebase_options.dart'; 
// Importante: mantenha o import da sua menu_page se o VS Code pedir
import 'package:primeiro_projeto_flutter/paginas/menu_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp()); // Chamamos o MyApp que configura o estilo do app
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Estoque UVZ',
      debugShowCheckedModeBanner: false, // Tira aquela faixa vermelha de "debug"
      home: TelaInicial(),
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Início - Estoque UVZ')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Entrar no Sistema'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MinhaTela()),
            );
          },
        ),
      ),
    );
  }
}