import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


class ActivityHistoryScreen extends StatelessWidget {
  final List activities;

  const ActivityHistoryScreen({super.key, required this.activities});

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return "--";
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy à HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          "Historique Complet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F4C75),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: activities.isEmpty
          ? const Center(child: Text("Aucun historique disponible"))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 15),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                return _buildActivityTile(activities[index]);
              },
            ),
    );
  }

  // On réutilise ton design de tuile
  Widget _buildActivityTile(Map activity) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
          _getIconForDescription(activity['description']),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['report_title'] ?? "Action Système",
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
                const SizedBox(height: 4),
                Text(
                  _formatFullDate(activity['created_at']),
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

  Widget _getIconForDescription(String desc) {
    Color color = desc.contains('resolu') ? Colors.green : Colors.blue;
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(Icons.history, color: color, size: 18),
    );
  }

  
}
