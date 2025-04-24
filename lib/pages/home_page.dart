import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key, required this.nickname});

  final String nickname;

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage> {
  int _counter = 0;
  Timer? _apiTimer;

  //Replace this by your API url
  final String _clickerEndpoint = '${ApiConfig.apiDomain}/clicker/';

  @override
  void initState() {
    super.initState();
    // Start the timer when the widget is created
    _startApiTimer();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _apiTimer?.cancel();
    super.dispose();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _startApiTimer() {
    // Send data every minute
    _apiTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _sendDataToApi();
    });
  }

  Future<void> _sendDataToApi() async {
    try {
      final response = await http.post(
        Uri.parse(_clickerEndpoint + widget.nickname),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nickname': widget.nickname, 'clicks': _counter}),
      );

      if (response.statusCode == 200) {
        // API call successful
        print('Data sent successfully: ${response.body}');
      } else {
        // API call failed
        print(
          'Failed to send data. Status code: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      // Exception occurred during API call
      print('Error sending data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.nickname),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
