import 'package:citycare_mobile/models/user_model.dart';
import 'package:flutter/material.dart';


class UserReportsScreen extends StatelessWidget {
  final List<dynamic> allReports;
  final int userId;

  const UserReportsScreen({
    super.key,
    required this.allReports,
    required this.userId, required UserModel user,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrage local
    final myReports = allReports.where((r) => r['user_id'] == userId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("Mes Signalements"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F4C75),
        elevation: 0,
      ),
      body: myReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 10),
                  const Text("Aucun signalement envoyé pour le moment."),
                ],
              ),
            )
          : ListView.builder(
              itemCount: myReports.length,
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                final report = myReports[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report['titre'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              report['description'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const Chip(
                        label: Text(
                          "En cours",
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
