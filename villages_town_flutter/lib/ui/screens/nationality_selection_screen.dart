import 'package:flutter/material.dart';
import '../../data/models/nationality.dart';
import '../../core/constants/layout_constants.dart';

class NationalitySelectionScreen extends StatefulWidget {
  final void Function(Nationality) onSelect;

  const NationalitySelectionScreen({super.key, required this.onSelect});

  @override
  State<NationalitySelectionScreen> createState() => _NationalitySelectionScreenState();
}

class _NationalitySelectionScreenState extends State<NationalitySelectionScreen> {
  Nationality? _selectedNationality;

  String _getCapitalName(Nationality nationality) {
    return switch (nationality.name) {
      'Turkish' => 'Istanbul',
      'Greek' => 'Athens',
      'Bulgarian' => 'Sofia',
      _ => 'Capital',
    };
  }

  @override
  Widget build(BuildContext context) {
    final nationalities = Nationality.getAll();
    final isCompact = LayoutConstants.isPhone(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                'Choose Your Nation',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Lead your people to victory',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              // Nation cards
              Expanded(
                child: isCompact
                    ? _buildVerticalLayout(nationalities)
                    : _buildHorizontalLayout(nationalities),
              ),
              // Start button
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedNationality != null
                        ? () => widget.onSelect(_selectedNationality!)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.grey.shade800,
                    ),
                    child: Text(
                      _selectedNationality != null ? 'Start Game' : 'Select a Nation',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout(List<Nationality> nationalities) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: nationalities.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildNationCard(nationalities[index]),
        );
      },
    );
  }

  Widget _buildHorizontalLayout(List<Nationality> nationalities) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: nationalities
              .map((n) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 250,
                      child: _buildNationCard(n),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNationCard(Nationality nationality) {
    final isSelected = _selectedNationality == nationality;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedNationality = nationality);
        LayoutConstants.selectionFeedback();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nationality.flag,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 12),
            Text(
              nationality.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Capital: ${_getCapitalName(nationality)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
