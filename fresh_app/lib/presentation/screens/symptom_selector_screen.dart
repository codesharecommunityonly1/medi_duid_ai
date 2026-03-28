import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/animations.dart';
import '../../services/medical_diagnosis_service.dart';
import 'condition_detail_screen.dart';

class SymptomSelectorScreen extends StatefulWidget {
  const SymptomSelectorScreen({super.key});

  @override
  State<SymptomSelectorScreen> createState() => _SymptomSelectorScreenState();
}

class _SymptomSelectorScreenState extends State<SymptomSelectorScreen> {
  final Set<String> _selectedSymptoms = {};
  String _searchQuery = '';
  List<String> _filteredSymptoms = [];
  final _searchController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadSymptoms();
  }

  void _loadSymptoms() {
    final allSymptoms = MedicalDiagnosisService.instance.getAllSymptoms();
    setState(() {
      _filteredSymptoms = allSymptoms.take(100).toList();
    });
  }

  void _filterSymptoms(String query) {
    final allSymptoms = MedicalDiagnosisService.instance.getAllSymptoms();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredSymptoms = allSymptoms.take(100).toList();
      } else {
        _filteredSymptoms = allSymptoms
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .take(50)
            .toList();
      }
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  Future<void> _diagnose() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    final results = MedicalDiagnosisService.instance.diagnoseBySymptoms(_selectedSymptoms.toList());

    setState(() {
      _isAnalyzing = false;
    });

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching conditions found')),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DiagnosisResultsScreen(
          selectedSymptoms: _selectedSymptoms.toList(),
          results: results,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Smart Diagnosis'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedSymptoms.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSymptoms.clear();
                });
              },
              icon: const Icon(Icons.clear_all, color: Colors.white),
              label: Text('${_selectedSymptoms.length} Clear', style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.2))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your symptoms:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _filterSymptoms,
                  decoration: InputDecoration(
                    hintText: '🔍 Search symptoms...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterSymptoms('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_selectedSymptoms.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedSymptoms.map((s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _toggleSymptom(s),
                        backgroundColor: AppColors.success.withOpacity(0.2),
                      )).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _filteredSymptoms.isEmpty
                ? const Center(child: Text('No symptoms found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredSymptoms.length,
                    itemBuilder: (context, index) {
                      final symptom = _filteredSymptoms[index];
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                        child: ListTile(
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          title: Text(symptom),
                          onTap: () => _toggleSymptom(symptom),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _isAnalyzing
                    ? Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ThinkingDots(color: Colors.white),
                            SizedBox(width: 12),
                            Text(
                              '🧠 AI is analyzing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _selectedSymptoms.isNotEmpty ? _diagnose : null,
                        icon: const Icon(Icons.psychology),
                        label: Text(
                          _selectedSymptoms.isEmpty
                              ? 'Select symptoms to diagnose'
                              : '🔍 Diagnose (${_selectedSymptoms.length} symptoms)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiagnosisResultsScreen extends StatelessWidget {
  final List<String> selectedSymptoms;
  final List<MedicalCondition> results;

  const DiagnosisResultsScreen({
    super.key,
    required this.selectedSymptoms,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final totalConfidence = results.fold<int>(0, (sum, c) => sum + c.confidenceScore);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 AI Diagnosis Results'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      '🧠 AI Analysis Complete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your symptoms:',
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: selectedSymptoms.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Conditions', '${results.length}', Icons.medical_services),
                      _buildStat('Top Match', '${results.isNotEmpty ? results.first.confidenceScore : 0}%', Icons.trending_up),
                      _buildStat('Severity', results.isNotEmpty ? results.first.severity.toUpperCase() : '-', Icons.warning_amber),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Possible Conditions (sorted by confidence)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final condition = results[index];
                final severityColor = _getSeverityColor(condition.severity);
                final confidencePercent = condition.confidenceScore / 100.0;
                final isTopResult = index == 0;

                return AppAnimations.fadeIn(
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isTopResult
                          ? const BorderSide(color: AppColors.primary, width: 2)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ConditionDetailScreen(condition: condition),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isTopResult ? AppColors.primary : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        color: isTopResult ? Colors.white : Colors.grey.shade600,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        condition.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        condition.category,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${condition.confidenceScore}%',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _getConfidenceColor(confidencePercent),
                                      ),
                                    ),
                                    Text(
                                      'confidence',
                                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ConfidenceBar(
                              value: confidencePercent,
                              color: _getConfidenceColor(confidencePercent),
                              height: 10,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: severityColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        condition.severity == 'critical' || condition.severity == 'severe'
                                            ? Icons.warning
                                            : Icons.info_outline,
                                        size: 14,
                                        color: severityColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        condition.severity.toUpperCase(),
                                        style: TextStyle(
                                          color: severityColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (condition.confidenceScore >= 70)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'High Confidence',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Icon(Icons.chevron_right, color: Colors.grey[400]),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'severe':
        return Colors.orange;
      case 'moderate':
        return Colors.amber;
      case 'mild':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
