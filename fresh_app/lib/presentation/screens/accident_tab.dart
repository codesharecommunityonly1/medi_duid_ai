import 'package:flutter/material.dart';
import '../../../data/accident_data.dart';
import '../../../core/constants/app_strings.dart';

class AccidentTab extends StatefulWidget {
  const AccidentTab({super.key});

  @override
  State<AccidentTab> createState() => _AccidentTabState();
}

class _AccidentTabState extends State<AccidentTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    "🚗 All",
    "🚗 Transport",
    "❤️ Medical",
    "🔥 Fire",
    "⚡ Electrical",
    "🌊 Water",
    "🐍 Animal",
    "🧠 Brain",
    "🌡️ Weather",
    "💥 Explosion"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primary.withOpacity(0.1),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabAlignment: TabAlignment.start,
            tabs: _categories.map((c) => Tab(text: c)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final accidents = category == "🚗 All" 
                  ? AccidentData.accidents 
                  : AccidentData.getByCategory(category);
              return _AccidentList(accidents: accidents);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AccidentList extends StatelessWidget {
  final List<Map<String, dynamic>> accidents;

  const _AccidentList({required this.accidents});

  @override
  Widget build(BuildContext context) {
    if (accidents.isEmpty) {
      return const Center(child: Text("No accidents in this category"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: accidents.length,
      itemBuilder: (context, index) {
        final accident = accidents[index];
        return _AccidentCard(accident: accident);
      },
    );
  }
}

class _AccidentCard extends StatelessWidget {
  final Map<String, dynamic> accident;

  const _AccidentCard({required this.accident});

  Color _getSeverityColor() {
    switch (accident['severity']) {
      case 'critical':
        return AppColors.emergency;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showAccidentDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getSeverityColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    accident['icon'],
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            accident['type'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getSeverityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            accident['severity'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _getSeverityColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (accident['situations'] as List).take(2).join(", "),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccidentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccidentDetailSheet(accident: accident),
    );
  }
}

class _AccidentDetailSheet extends StatelessWidget {
  final Map<String, dynamic> accident;

  const _AccidentDetailSheet({required this.accident});

  Color _getSeverityColor() {
    switch (accident['severity']) {
      case 'critical':
        return AppColors.emergency;
      case 'high':
        return Colors.orange;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: _getSeverityColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              accident['icon'],
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                accident['type'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "SEVERITY: ${accident['severity'].toString().toUpperCase()}",
                                  style: TextStyle(
                                    color: _getSeverityColor(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      "⚠️ Situations That Can Happen",
                      accident['situations'],
                      Colors.blue,
                      Icons.warning_amber,
                    ),
                    const SizedBox(height: 16),
                    _buildEmergencySection(
                      "🚨 Do This IMMEDIATELY",
                      accident['immediate_steps'],
                      AppColors.emergency,
                      Icons.flash_on,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      "🩹 First Aid (Before Doctor Arrives)",
                      accident['first_aid'],
                      AppColors.success,
                      Icons.medical_services,
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      "🛡️ Prevention Tips",
                      accident['prevention'],
                      Colors.purple,
                      Icons.shield,
                    ),
                    const SizedBox(height: 20),
                    if (accident['emergency_numbers'] != null) ...[
                      const Text(
                        "📞 Emergency Numbers",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: (accident['emergency_numbers'] as List).map<Widget>((num) {
                          return ActionChip(
                            avatar: const Icon(Icons.phone, color: Colors.white, size: 18),
                            label: Text(num),
                            backgroundColor: AppColors.primary,
                            labelStyle: const TextStyle(color: Colors.white),
                            onPressed: () {
                              // Could launch phone dialer here
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmergencySection(String title, List items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${entry.key + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}