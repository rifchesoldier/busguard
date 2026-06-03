import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte en direct", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xfff2efe9), // Couleur de fond d'une carte standard
        child: Stack(
          children: [
            // Affichage de la carte OpenStreetMap via un composant Web natif ultra-stable
            HtmlElementView(
              viewType: 'openstreetmap-html',
              onPlatformViewCreated: (int viewId) {},
            ),
            // Notre marqueur rouge positionné au centre de Dakar
            Center(
              child: Transform.translate(
                offset: const Offset(0, -20), // Ajustement pour que la pointe de l'icône soit sur le repère
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
