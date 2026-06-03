import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Détection de la largeur de l'écran pour le responsive
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fond clair et moderne
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. MESSAGE D'ACCUEIL ---
            const Text(
              "Bonjour 👋",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 4),
            Text(
              "Voici la situation en temps réel.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // --- 2. GRILLE DES CARTES INDICATEURS (KPI) ---
            GridView.count(
              crossAxisCount: screenWidth < 600 ? 2 : (screenWidth < 1100 ? 2 : 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildKpiCard("ENFANTS SUIVIS", "1", Icons.people_alt_outlined),
                _buildKpiCard("ALERTES NON LUES", "4", Icons.notifications_none_outlined, badgeColor: Colors.blue),
                _buildKpiCard("ETA BUS", "7 min", Icons.access_time),
                _buildKpiCard("PONCTUALITÉ", "98%", Icons.trending_up),
              ],
            ),
            const SizedBox(height: 32),

            // --- 3. CONTENU PRINCIPAL (RESPONSIVE) ---
            isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildLiveTrackingTile()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildDailyActivityTile()),
                    ],
                  )
                : Column(
                    children: [
                      _buildLiveTrackingTile(),
                      const SizedBox(height: 24),
                      _buildDailyActivityTile(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CONSTRUCTEUR : CARTE KPI ---
  Widget _buildKpiCard(String title, String value, IconData icon, {Color? badgeColor}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: const Color(0xFF1A237E), size: 24),
                if (badgeColor != null)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500], letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET CONSTRUCTEUR : BLOC SUIVI EN DIRECT (CARTE) ---
  Widget _buildLiveTrackingTile() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Suivi en direct",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, 
                        height: 6, 
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "EN DIRECT", 
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Bus DK-402-AB · Ligne B — Mermoz",
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            // Intégration sécurisée et stylisée de notre carte
            Container(
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double cx = constraints.maxWidth / 2;
                  final double cy = constraints.maxHeight / 2;
                  return Stack(
                    children: [
                      HtmlElementView(
                        viewType: 'openstreetmap-html',
                        onPlatformViewCreated: (int id) {},
                      ),
                      Positioned(
                        left: cx - 22.5,
                        top: cy - 45.0,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 45),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CONSTRUCTEUR : BLOC ACTIVITÉ DU JOUR ---
  Widget _buildDailyActivityTile() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Activité du jour",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 20),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildActivityRow("Départ confirmé", "Le bus a démarré depuis l'école.", "07:15", Colors.green, isFirst: true),
                _buildActivityRow("Approche : 3 arrêts", "Préparez-vous à descendre.", "07:38", Colors.green),
                _buildActivityRow("Arrivée à l'arrêt", "Le bus est arrêté à votre point.", "07:44", Colors.green),
                _buildActivityRow("Descente confirmée", "Badge scanné. Aminata a quitté le bus.", "07:45", Colors.green, isLast: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- CONSTRUCTEUR DE LIGNE DE TIMELINE ---
  Widget _buildActivityRow(String title, String desc, String time, Color color, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Colonne de la ligne graphique de temps
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst ? Colors.transparent : Colors.grey.shade300,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(Icons.check, size: 12, color: color),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenu textuel
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E))),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
