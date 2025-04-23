import 'dart:async';

import 'package:flutter/material.dart';
import 'home_page.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage>
    with TickerProviderStateMixin {
  final _nicknameController = TextEditingController();

  late final AnimationController _titleController;
  late final Animation<Offset> _titleOffset;

  late final AnimationController _fieldController;
  late final Animation<double> _fieldFade;

  late final AnimationController _buttonController;
  late final Animation<double> _buttonScale;

  final String _fullText = 'Profitez de cette pause clope !';
  String _visibleText = '';
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();

    // Title animation (slide from top)
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    // TextField animation (fade in)
    _fieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fieldFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fieldController, curve: Curves.easeIn));

    // Button animation (scale up)
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.8,
      upperBound: 1.0,
    );
    _buttonScale = CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    );
    _startTypewriterAnimation();
    // Start animations with a slight delay between them
    _startAnimations();
  }

  void _startTypewriterAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      const duration = Duration(milliseconds: 80);
      Timer.periodic(duration, (Timer timer) {
        if (_textIndex < _fullText.length) {
          setState(() {
            _visibleText += _fullText[_textIndex];
            _textIndex++;
          });
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _titleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _fieldController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _titleController.dispose();
    _fieldController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _navigateToHomePage(BuildContext context) {
    if (_nicknameController.text.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => MyHomePage(
                title: 'Flutter Demo Home Page',
                nickname: _nicknameController.text,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a nickname')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(40.0),
          children: [
            SlideTransition(
              position: _titleOffset,
              child: Text(
                _visibleText,
                style: const TextStyle(
                  fontSize: 82,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 144),
            FadeTransition(
              opacity: _fieldFade,
              child: TextField(
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                cursorHeight: 24,
                cursorWidth: 2,
                maxLength: 20,
                maxLines: 1,
                controller: _nicknameController,
                decoration: const InputDecoration(
                  hintStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                  labelStyle: TextStyle(color: Colors.white, fontSize: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.black87, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  labelText: 'Votre nom de joueur',
                ),
              ),
            ),
            const SizedBox(height: 20),
            ScaleTransition(
              scale: _buttonScale,
              child: ElevatedButton(
                onPressed: () => _navigateToHomePage(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Commençons le jeux !',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
