import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'nickname_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.nickname});

  final String title;
  final String nickname;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  Timer? _apiTimer;

  //Replace this by your API url
  final String _apiUrl = 'http://10.120.1.233:8080/clicker/';

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
        Uri.parse(_apiUrl + widget.nickname),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nickname': widget.nickname,
          'clicks': _counter,
        }),
      );

      if (response.statusCode == 200) {
        // API call successful
        print('Data sent successfully: ${response.body}');
      } else {
        // API call failed
        print(
            'Failed to send data. Status code: ${response
                .statusCode}, Body: ${response.body}');
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
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text('${widget.title} - ${widget.nickname}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium,
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const NicknamePage(),
    );
  }
}
