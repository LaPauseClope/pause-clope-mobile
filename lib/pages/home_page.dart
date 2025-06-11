import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import '../constants/app_colors.dart';
import '../constants/image_paths.dart';

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

  IconData _iconSave = Icons.save;
  IconData _iconFetch = Icons.refresh;

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
      final response = await http.get(
        Uri.parse(_clickerEndpoint + widget.nickname),
      );

      if (!context.mounted) {
        return; // If the context is not mounted, do not proceed
      }

      setState(() {
        _iconFetch = response.statusCode == 200 ? Icons.check : Icons.error;
      });
    } catch (e) {
      // Exception occurred during API call
      print('Error fetching initial data: $e');
      setState(() {
        _iconFetch = Icons.error;
      });
    }

    Timer(const Duration(seconds: 5), () {
      setState(() {
        _iconFetch = Icons.refresh;
      });
    });
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
        setState(() {
          _iconSave = Icons.check;
        });
      } else {
        setState(() {
          _iconSave = Icons.error;
        });
      }
    } catch (e) {
      // Exception occurred during API call
      print('Error sending data: $e');
      setState(() {
        _iconSave = Icons.error;
      });
    }

    Timer(const Duration(seconds: 5), () {
      setState(() {
        _iconSave = Icons.save;
      });
    });
  }

  void _navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      appBar: AppBar(
        leading: BackButton(onPressed: () => _navigateBack(context)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.nickname),
        actions: [
          IconButton(
            icon: Icon(_iconSave),
            onPressed: _sendDataToApi, // Save data when the button is pressed
          ),
          IconButton(
            icon: Icon(_iconFetch),
            onPressed: () {
              _fetchInitialData(); // Refresh data when the button is pressed
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: ElevatedButton(
              onPressed: _incrementCounter,
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
                overlayColor: WidgetStatePropertyAll(Colors.transparent),
                elevation: WidgetStatePropertyAll(0.0),
                shadowColor: WidgetStatePropertyAll(Colors.transparent),
                padding: WidgetStatePropertyAll(EdgeInsets.all(0)),
                foregroundColor: WidgetStatePropertyAll(Colors.transparent),
                surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
              ),
              child: Image.asset(ImagePaths.coffee),
            ),
          ),
          Center(
            child: Text(
              'Clicks: $_counter',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
