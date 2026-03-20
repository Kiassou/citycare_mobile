import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatefulWidget {
  final List activities;

  const ActivityHistoryScreen({super.key, required this.activities});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  List _filteredActivities = [];
  String _selectedType = 'Tous';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _filteredActivities = widget.activities;
  }

  void _applyFilters() {
    setState(() {
      _filteredActivities = widget.activities.where((activity) {
        bool matchesType = true;
        if (_selectedType == 'Signalements') {
          matchesType = activity['type'] == 'report';
        } else if (_selectedType == 'Interventions') {
          matchesType = activity['type'] == 'work';
        }

        bool matchesDate = true;
        if (_selectedDate != null) {
          DateTime activityDate = DateTime.parse(
            activity['created_at'] ?? activity['date_signalement'],
          );
          matchesDate =
              activityDate.year == _selectedDate!.year &&
              activityDate.month == _selectedDate!.month &&
              activityDate.day == _selectedDate!.day;
        }

        return matchesType && matchesDate;
      }).toList();
    });
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return "--";
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          "Historique Complet",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0F4C75),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      /// 🔥 RESPONSIVE BODY
      body: LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;

          bool isMobile = width < 700;
          bool isTablet = width >= 700 && width < 1100;

          return Column(
            children: [
              _buildFilterBarResponsive(width),

              Expanded(
                child: _filteredActivities.isEmpty
                    ? const Center(
                        child: Text(
                          "Aucune activité ne correspond à vos filtres",
                        ),
                      )
                    : Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isMobile ? double.infinity : 900,
                          ),
                          child: isMobile
                              ? ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  itemCount: _filteredActivities.length,
                                  itemBuilder: (context, index) =>
                                      _buildActivityTile(
                                        _filteredActivities[index],
                                      ),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(15),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isTablet ? 2 : 3,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                        childAspectRatio: 2.8,
                                      ),
                                  itemCount: _filteredActivities.length,
                                  itemBuilder: (context, index) =>
                                      _buildActivityTile(
                                        _filteredActivities[index],
                                      ),
                                ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔥 FILTER BAR RESPONSIVE
  Widget _buildFilterBarResponsive(double width) {
    bool isMobile = width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20,
        vertical: 10,
      ),
      color: Colors.white,
      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDropdown()),
                    const SizedBox(width: 10),
                    _buildDateButton(),
                  ],
                ),
                const SizedBox(height: 8),
                _buildResetButton(),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildDropdown()),
                const SizedBox(width: 20),
                _buildDateButton(),
                const SizedBox(width: 10),
                _buildResetButton(),
              ],
            ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedType,
        isExpanded: true,
        onChanged: (String? newValue) {
          setState(() => _selectedType = newValue!);
          _applyFilters();
        },
        items: ['Tous', 'Signalements', 'Interventions']
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDateButton() {
    return TextButton.icon(
      onPressed: () => _selectDate(context),
      icon: Icon(
        Icons.calendar_today,
        size: 16,
        color: _selectedDate != null ? Colors.blue : Colors.grey,
      ),
      label: Text(
        _selectedDate == null
            ? "Date"
            : DateFormat('dd/MM').format(_selectedDate!),
        style: TextStyle(
          fontSize: 13,
          color: _selectedDate != null ? Colors.blue : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    if (_selectedType == 'Tous' && _selectedDate == null) {
      return const SizedBox();
    }

    return IconButton(
      icon: const Icon(Icons.close, color: Colors.redAccent),
      onPressed: () {
        setState(() {
          _selectedType = 'Tous';
          _selectedDate = null;
        });
        _applyFilters();
      },
    );
  }

  /// 🔥 TILE
  Widget _buildActivityTile(Map activity) {
    bool isReport = activity['type'] == 'report';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: (isReport ? Colors.orange : Colors.green)
                .withOpacity(0.1),
            child: Icon(
              isReport ? Icons.campaign : Icons.build,
              color: isReport ? Colors.orange : Colors.green,
              size: 18,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['report_title'] ??
                      (isReport ? "Nouveau Signalement" : "Intervention"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['description'],
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatFullDate(
                    activity['created_at'] ?? activity['date_signalement'],
                  ),
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
