import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:la_pause_clope/pages/nickname_page.dart';

import '../constants/api_config.dart';
import '../constants/app_colors.dart';
import '../constants/image_paths.dart';

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key, required this.nickname});

  final String nickname;

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage>
    with TickerProviderStateMixin {
  int _counter = 0;
  Timer? _apiTimer;

  //Replace this by your API url
  final String _clickerEndpoint = '${ApiConfig.apiDomain}/clicker/';

  IconData _iconSave = Icons.save;
  IconData _iconFetch = Icons.refresh;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Start the timer when the widget is created
    _startApiTimer();
    _fetchInitialData();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed to avoid memory leaks
    _apiTimer?.cancel();
    _animationController.dispose();
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
        if (response.statusCode == 200) {
          _counter = int.parse(response.body); // Safely access 'clicks'
        } else {
          _counter = 0; // Reset counter if API call fails
        }
      });
    } catch (e) {
      // Exception occurred during API call
      print('Error fetching initial data: $e');
      setState(() {
        _iconFetch = Icons.error;
      });
    }

    Timer(const Duration(seconds: 5), () {
      if (!context.mounted) {
        return; // If the context is not mounted, do not proceed
      }
      setState(() {
        _iconFetch = Icons.refresh;
      });
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    _animationController.forward().then((_) => _animationController.reverse());
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
    // Cancel the timer when navigating back to avoid memory leaks
    _apiTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NicknamePage()),
    );
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
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _incrementCounter,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(ImagePaths.coffee, width: 500,),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 48,
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
