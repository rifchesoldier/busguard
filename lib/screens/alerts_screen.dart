import 'package:flutter/material.dart';

// Structure de données simple pour représenter une alerte
class BusAlert {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  BusAlert({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Liste locale des alertes (vide par défaut pour gérer l'état initial)
  List<BusAlert> alerts = [];

  // Fonction pour générer les alertes de démonstration comme sur ta capture
  void generateDemoAlerts() {
    setState(() {
      alerts = [
        BusAlert(
          title: "Départ confirmé",
          description: "Le bus DK-402 a démarré depuis l'école.",
          time: "03/06/2026 15:11:39",
          icon: Icons.directions_bus,
          iconColor: const Color(0xFF1A237E),
        ),
        BusAlert(
          title: "Approche : 3 arrêts",
          description: "Le bus approche, préparez-vous.",
          time: "03/06/2026 15:11:39",
          icon: Icons.location_on,
          iconColor: Colors.orange,
        ),
        BusAlert(
          title: "Arrivée à l'arrêt",
          description: "Le bus est à votre point. Aminata descend.",
          time: "03/06/2026 15:11:39",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        ),
        BusAlert(
          title: "Retard 12 min",
          description: "Embouteillage à Colobane.",
          time: "03/06/2026 15:11:39",
          icon: Icons.warning,
          iconColor: Colors.red,
        ),
      ];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Alertes de démo créées"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Fonction pour tout marquer comme lu
  void markAllAsRead() {
    setState(() {
      for (var alert in alerts) {
        alert.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcul du nombre d'alertes non lues
    int unreadCount = alerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Fond clair neutre
      appBar: AppBar(
        title: const Text("Centre d'alertes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Barre de contrôle supérieure (Statut + Boutons) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$unreadCount non lue(s) sur ${alerts.length}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: generateDemoAlerts,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Démo"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A237E),
                        side: const BorderSide(color: Color(0xFF1A237E)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (alerts.isNotEmpty)
                      ElevatedButton(
                        onPressed: markAllAsRead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text("Tout marquer lu"),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Corps principal (Liste ou Vue Vide) ---
            Expanded(
              child: alerts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildAlertCard(alert);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget affiché quand il n'y a aucune alerte
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "Aucune alerte pour le moment.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: generateDemoAlerts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Générer des alertes démo"),
          ),
        ],
      ),
    );
  }

  // Template réutilisable pour chaque carte d'alerte
  Widget _buildAlertCard(BusAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: alert.isRead ? 0 : 2,
      color: alert.isRead ? Colors.grey[100] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.isRead ? Colors.transparent : const Color(0xFF1A237E).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: alert.iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(alert.icon, color: alert.iconColor, size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              alert.title,
              style: TextStyle(
                fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 16,
                color: const Color(0xFF1A237E),
              ),
            ),
            // Petit point bleu indicateur de non lu
            if (!alert.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              alert.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 6),
            Text(
              alert.time,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
