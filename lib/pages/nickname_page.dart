import 'dart:async';

import 'package:flutter/material.dart';
import 'package:la_pause_clope/constants/image_paths.dart';

import '../constants/app_colors.dart';
import 'home_page.dart';

class NicknamePage extends StatefulWidget {
  const NicknamePage({super.key});

  @override
  State<NicknamePage> createState() => _NicknamePageState();
}

class _NicknamePageState extends State<NicknamePage>
    with TickerProviderStateMixin {
  final _nicknameController = TextEditingController();

  late final AnimationController _imageController;
  late final Animation<Offset> _imageOffset;

  late final AnimationController _titleController;
  late final Animation<Offset> _titleOffset;

  late final AnimationController _fieldController;
  late final Animation<double> _fieldFade;

  late final AnimationController _buttonController;
  late final Animation<double> _buttonScale;

  final String _fullText = 'Bienvenue dans cette pause café !';
  String _visibleText = '';
  int _textIndex = 0;

  @override
  void initState() {
    super.initState();

    // Image animation (slide from bottom)
    _imageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _imageOffset = Tween<Offset>(
      begin: const Offset(0, 0.54),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _imageController, curve: Curves.easeOut));

    // Title animation (slide from top)
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _titleOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeOut));

    // TextField animation (fade in)
    _fieldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fieldFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fieldController, curve: Curves.easeIn));

    // Button animation (fade in)
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonScale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeIn));
    _startTypewriterAnimation();
    // Start animations with a slight delay between them
    _startAnimations();
  }

  void _startTypewriterAnimation() {
    Future.delayed(const Duration(milliseconds: 200), () {
      const duration = Duration(milliseconds: 40);
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
    await Future.delayed(const Duration(milliseconds: 600));
    _fieldController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _titleController.dispose();
    _fieldController.dispose();
    _buttonController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _navigateToHomePage(BuildContext context) async {


    if (_nicknameController.text.isNotEmpty) {
      _imageController.forward();
      _titleController.reverse();
      _fieldController.reverse();
      _buttonController.reverse();
      await Future.delayed(const Duration(milliseconds: 1200), () {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ClickerPage(nickname: _nicknameController.text),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom de joueur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blue,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _imageOffset,
              child: Image.asset(ImagePaths.coffee),
            ),
          ),
          Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(40.0),
              children: [
                SlideTransition(
                  position: _titleOffset,
                  child: Text(
                    _visibleText,
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 144),
                FadeTransition(
                  opacity: _fieldFade,
                  child: TextField(
                    style: const TextStyle(color: AppColors.white),
                    cursorColor: AppColors.white,
                    cursorHeight: 24,
                    cursorWidth: 2,
                    maxLength: 20,
                    maxLines: 1,

                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      counterStyle: TextStyle(color: AppColors.white),
                      hintStyle: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(color: Colors.black87, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        borderSide: BorderSide(
                          color: AppColors.white,
                          width: 2,
                        ),
                      ),
                      labelText: 'Entrez votre nom de joueur',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _buttonScale,
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
        ],
      ),
    );
  }
}
