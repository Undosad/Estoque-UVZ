import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'paginas/login_page.dart';
import 'package:primeiro_projeto_flutter/providers/usuario_provider.dart';
import 'package:primeiro_projeto_flutter/paginas/menu_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Aqui acontece a mágica: o app tenta carregar o usuário
    return FutureBuilder(
      future: Provider.of<UsuarioProvider>(context, listen: false).carregarUsuarioSalvo(),
      builder: (context, snapshot) {
        // Enquanto ele procura no "post-it" do celular, mostra um carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        final usuario = Provider.of<UsuarioProvider>(context);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Estoque UVZ',
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          // Se estiver logado, vai pro Menu. Se não, vai pro Login.
          home: usuario.estaLogado ? MenuPage() : LoginPage(),
        );
      },
    );
  }
}