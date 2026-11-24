import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const BuscadorCepApp());
}

class BuscadorCepApp extends StatelessWidget {
  const BuscadorCepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Buscador de CEP',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F7F6), // Fundo suave
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const TelaConsultaCep(),
    );
  }
}

class TelaConsultaCep extends StatefulWidget {
  const TelaConsultaCep({super.key});

  @override
  State<TelaConsultaCep> createState() => _TelaConsultaCepState();
}

class _TelaConsultaCepState extends State<TelaConsultaCep> {
  final TextEditingController _cepInput = TextEditingController();
  Map<String, dynamic>? _endereco;
  bool _carregando = false;

  @override
  void dispose() {
    _cepInput.dispose();
    super.dispose();
  }

  Future<void> _consultarEndereco() async {
    final cepLimpo = _cepInput.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cepLimpo.length != 8) {
      _mostrarAviso('Informe um CEP válido com 8 dígitos.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _carregando = true;
      _endereco = null;
    });

    try {
      final url = Uri.parse('https://viacep.com.br');
      final resposta = await http.get(url);

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (dados['erro'] == true) {
          _mostrarAviso('CEP não encontrado na base de dados.');
        } else {
          setState(() {
            _endereco = dados;
          });
        }
      } else {
        _mostrarAviso('Erro ao consultar o servidor (${resposta.statusCode}).');
      }
    } catch (e) {
      _mostrarAviso('Sem conexão com a internet.');
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

  void _limparCampos() {
    _cepInput.clear();
    setState(() {
      _endereco = null;
    });
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localizador de Endereço'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _cepInput,
              keyboardType: TextInputType.number,
              maxLength: 9,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Digite o CEP',
                hintText: 'Ex: 79400000',
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _limparCampos,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _consultarEndereco(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _carregando ? null : _consultarEndereco,
              icon: _carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_carregando ? 'Buscando...' : 'Buscar Endereço'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            if (_endereco != null) _buildCardResultado(_endereco!),
          ],
        ),
      ),
    );
  }

  Widget _buildCardResultado(Map<String, dynamic> dados) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _linhaInformacao('Logradouro', dados['logradouro']),
            const Divider(),
            _linhaInformacao('Bairro', dados['bairro']),
            const Divider(),
            _linhaInformacao('Cidade', dados['localidade']),
            const Divider(),
            _linhaInformacao('Estado (UF)', dados['uf']),
            const Divider(),
            _linhaInformacao('DDD', dados['ddd']),
          ],
        ),
      ),
    );
  }

  Widget _linhaInformacao(String titulo, dynamic valor) {
    final texto = (valor == null || valor.toString().isEmpty)
        ? 'Não informado'
        : valor.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          Flexible(
            child: Text(
              texto,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
