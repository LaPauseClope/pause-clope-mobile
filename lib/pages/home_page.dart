import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/app_colors.dart';

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
    _fetchInitialData();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _apiTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    try {
      final response = await http.get(Uri.parse(_clickerEndpoint + widget.nickname));

      if (!context.mounted) {
        return; // If the context is not mounted, do not proceed
      }

      if (response.statusCode == 200) {
        setState(() {
          _counter = int.parse(response.body); // Initialize counter with fetched data
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to fetch initial data', style: TextStyle(color: Colors.white),),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Exception occurred during API call
      print('Error fetching initial data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch initial data', style: TextStyle(color: Colors.white),),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        body: jsonEncode({'clicks': _counter}),
      );

      if (!context.mounted) {
        return; // If the context is not mounted, do not proceed
      }

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved', style: TextStyle(color: Colors.white),),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save', style: TextStyle(color: Colors.white),),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Exception occurred during API call
      print('Error sending data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save', style: TextStyle(color: Colors.white),),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
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
