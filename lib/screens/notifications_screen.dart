import 'dart:convert';
import 'package:citycare_mobile/config.dart';
import 'package:citycare_mobile/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final UserModel currentUser; 

  const NotificationsScreen({super.key, required this.currentUser});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List notifications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // ✅ On récupère l'ID dynamiquement depuis le widget
      final userId = widget.currentUser.id;

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/auth/notifications/$userId'),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            notifications = jsonDecode(response.body);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Erreur fetch notifications: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(int notifId) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/auth/notifications/read/$notifId'),
      );
      if (response.statusCode == 200) {
        // On rafraîchit la liste localement pour faire disparaître le point bleu
        _fetchNotifications();
      }
    } catch (e) {
      print("Erreur marquage lecture: $e");
    }
  }

  // Fonction pour afficher le message et marquer comme lu
void _showNotificationDetails(Map notif) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Titre de la notification
            Text(
              notif['titre'] ?? "Mise à jour du signalement",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F4C75),
              ),
            ),
            const SizedBox(height: 15),

            // Carte de résumé
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FA),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.sync_alt,
                    "Nouveau Statut",
                    notif['description']
                        .toString()
                        .split(':')
                        .last
                        .trim()
                        .toUpperCase(),
                    isStatus: true,
                  ),
                  const Divider(height: 25),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    "Date de mise à jour",
                    _formatFullDate(notif['created_at']),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            const Text(
              "DÉTAILS DU MESSAGE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),

            // Le corps du message (très lisible)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notif['description'] ??
                    "Votre signalement a été mis à jour par les services municipaux.",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bouton Fermer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C75),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Fermer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (notif['is_read'] == 0) _markAsRead(notif['id']);
  }

  // Widget Helper pour les lignes d'info
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isStatus = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A73B8)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const Spacer(),
        Container(
          padding: isStatus
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
              : null,
          decoration: isStatus
              ? BoxDecoration(
                  color: value.contains('RESOLU')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isStatus
                  ? (value.contains('RESOLU') ? Colors.green : Colors.orange)
                  : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  // Petit widget helper pour les lignes de détails

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      // --- HEADER UNIFORMISÉ (COMME L'ADMIN) ---
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F4C75), // Bleu foncé identique
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return _buildNotificationItem(notif);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationItem(Map notif) {
    final bool isRead = notif['is_read'] == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: isRead ? null : Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getNotifColor(notif).withOpacity(0.1),
          child: Icon(
            _getNotifIcon(notif),
            color: _getNotifColor(notif),
            size: 20,
          ),
        ),
        title: Text(
          notif['titre'] ?? "Notification",
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            notif['description'] ?? "",
            maxLines: 1, // Limite à une seule ligne
            overflow: TextOverflow.ellipsis, // Ajoute les "..."
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatFullDate(notif['created_at']),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        onTap: () => _showNotificationDetails(notif),
      ),
    );
  }

  // --- HELPERS ---
  Color _getNotifColor(Map notif) {
    String desc = (notif['description'] ?? "").toLowerCase();
    if (desc.contains('resolu')) return Colors.green;
    return Colors.blue;
  }

  IconData _getNotifIcon(Map notif) {
    String desc = (notif['description'] ?? "").toLowerCase();
    if (desc.contains('resolu')) return Icons.check_circle_outline;
    return Icons.notifications_active_outlined;
  }

  String _formatFullDate(String? dateStr) {
    if (dateStr == null) return "--";
    DateTime date = DateTime.parse(dateStr).toLocal();
    return DateFormat('dd MMM yyyy à HH:mm').format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 70,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          const Text(
            "Aucune notification",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
