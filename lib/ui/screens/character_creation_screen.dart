import 'package:flutter/material.dart';
import '../../data/models/nationality.dart';
import '../components/countryball_avatar.dart';

class CharacterCreationScreen extends StatefulWidget {
  final Nationality nationality;
  final void Function(String name) onNext;

  const CharacterCreationScreen({
    super.key,
    required this.nationality,
    required this.onNext,
  });

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onNext(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11141C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Countryball avatar
              CountryballAvatar(
                size: 120,
                nationality: widget.nationality,
                borderColor: widget.nationality.color,
                borderWidth: 3,
                showGlow: true,
                glowColor: widget.nationality.color,
              ),

              const SizedBox(height: 16),

              // Nationality label
              Text(
                widget.nationality.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),

              const SizedBox(height: 32),

              // Name input
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                maxLength: 20,
                textAlign: TextAlign.center,
                cursorColor: Colors.amber,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your name...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                  counterStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 10,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),

              const Spacer(flex: 3),

              // Next button
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _controller.text.trim().isNotEmpty
                    ? ElevatedButton(
                        key: const ValueKey('next'),
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: widget.nationality.color,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                          elevation: 8,
                          shadowColor:
                              widget.nationality.color.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 50),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
