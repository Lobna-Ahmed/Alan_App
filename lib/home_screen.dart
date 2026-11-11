import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'app_colors.dart';
import 'flowing_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;
  bool _listening = false;
  double _level = 0; // 0.0 (silent) to 1.0 (loud)

  // Whoever connects the backend only needs this variable.
  String recognizedText = '';

  // Language: English by default, Arabic when switched with the EN/AR button.
  bool _arabic = false;
  String? _enLocale; // null = use the phone's default
  String? _arLocale; // null = Arabic voice input is not installed on this phone

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ok = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _stopState());
        }
      },
      onError: (error) {
        if (mounted) setState(() => _stopState());
      },
    );
    if (ok) await _loadLocales();
    if (mounted) setState(() => _available = ok);
  }

  // Ask the phone which languages it can listen to, and pick English and
  // Arabic (Egyptian Arabic first if the phone has it).
  Future<void> _loadLocales() async {
    final locales = await _speech.locales();
    final ids = locales.map((l) => l.localeId).toList();

    String? find(String language, String preferredCountry) {
      final matches =
          ids.where((id) => id.toLowerCase().startsWith(language)).toList();
      if (matches.isEmpty) return null;
      return matches.firstWhere(
        (id) => id.toUpperCase().contains(preferredCountry),
        orElse: () => matches.first,
      );
    }

    _arLocale = find('ar', 'EG');
    _enLocale = find('en', 'US');
  }

  // The EN/AR button
  Future<void> _switchLanguage() async {
    if (!_arabic && _arLocale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Arabic voice input is not installed on this phone. '
            'Add Arabic in the phone language settings.',
          ),
        ),
      );
      return;
    }
    if (_listening) await _speech.stop();
    if (!mounted) return;
    setState(() {
      _arabic = !_arabic;
      _stopState();
      recognizedText = '';
    });
  }

  void _stopState() {
    _listening = false;
    _level = 0;
  }

  Future<void> _toggleListening() async {
    if (!_available) return;

    if (_listening) {
      await _speech.stop();
      setState(() => _stopState());
      return;
    }

    setState(() {
      _listening = true;
      recognizedText = '';
    });

    await _speech.listen(
      localeId: _arabic ? _arLocale : _enLocale,
      onResult: (result) {
        setState(() => recognizedText = result.recognizedWords);
      },
      onSoundLevelChange: (db) {
        // Sound level is roughly -2 to 10, so we squeeze it into 0 to 1.
        final value = ((db + 2) / 12).clamp(0.0, 1.0).toDouble();
        setState(() => _level = value);
      },
    );
  }

  // A white circle with softly blurred rings that get more and more
  // transparent. It stays still until you start listening, then the
  // rings spread outward with your voice.
  Widget _bubble() {
    const core = 130.0;
    const ringAlpha = [130, 84, 50, 24]; // inner to outer ring, while listening

    // 0 when idle. When listening: a small "wake up" plus your voice level.
    final spread = _listening ? 0.04 + 0.12 * _level : 0.0;
    final coreGrow = _listening ? 0.04 + 0.25 * _level : 0.0;
    // Quick while following your voice, slower when settling back to rest.
    final sizeDuration = Duration(milliseconds: _listening ? 180 : 500);

    final layers = <Widget>[];

    // Biggest, most transparent ring first, so it sits at the back.
    for (var i = 4; i >= 1; i--) {
      final size = core * (1 + 0.26 * i + spread * i);
      layers.add(
        ImageFiltered(
          // Very small blur on each ring
          imageFilter: ui.ImageFilter.blur(
            sigmaX: 1.5,
            sigmaY: 1.5,
            tileMode: TileMode.decal,
          ),
          // Barely visible at rest, fades in smoothly when listening
          child: AnimatedOpacity(
            opacity: _listening ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: sizeDuration,
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(ringAlpha[i - 1]),
              ),
            ),
          ),
        ),
      );
    }

    // The solid white circle in the middle
    final coreSize = core * (1 + coreGrow);
    layers.add(
      AnimatedContainer(
        duration: sizeDuration,
        curve: Curves.easeOut,
        width: coreSize,
        height: coreSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );

    return SizedBox(
      width: 400,
      height: 400,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: layers,
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      body: FlowingBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: language switch (EN/AR) and dark mode toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _switchLanguage,
                    style: TextButton.styleFrom(
                      foregroundColor: c.textSecondary,
                    ),
                    icon: const Icon(Icons.translate_rounded, size: 20),
                    label: Text(
                      _arabic ? 'AR' : 'EN',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Dark mode toggle: moon in light mode, sun in dark mode
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeMode,
                    builder: (context, mode, _) {
                      final dark = isDarkNow(context);
                      return IconButton(
                        onPressed: () {
                          themeMode.value =
                              dark ? ThemeMode.light : ThemeMode.dark;
                        },
                        icon: Icon(
                          dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          color: c.textSecondary,
                          size: 26,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                _listening
                    ? (_arabic ? 'جارٍ الاستماع...' : 'Listening...')
                    : (_arabic
                        ? 'اضغط على الدائرة للتحدث'
                        : 'Tap the circle to talk'),
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 16,
                  shadows: c.textShadows,
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleListening,
                    child: _bubble(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Text(
                  _available
                      ? recognizedText
                      : (_arabic
                          ? 'الميكروفون غير متاح. تحقق من الأذونات.'
                          : 'Microphone not available. Check permissions.'),
                  textAlign: TextAlign.center,
                  textDirection:
                      _arabic ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 18,
                    shadows: c.textShadows,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}