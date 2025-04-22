import 'package:flutter/material.dart';

import 'main.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({Key? key}) : super(key: key);

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage> {
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _navigateToHomePage(BuildContext context) {
    if (_nicknameController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(
            title: 'Flutter Demo Home Page',
            nickname: _nicknameController.text,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a nickname')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Your Nickname'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Nickname',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _navigateToHomePage(context),
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}