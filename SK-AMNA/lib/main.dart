import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkAmnaClient());
}

class SkAmnaClient extends StatelessWidget {
  const SkAmnaClient({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const UserHomePage(),
    );
  }
}

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  String searchKey = "";
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
  }

  // --- LOGIQUE DE RECHERCHE ET AFFICHAGE ---
  Widget _buildResultats() {
    if (searchKey.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text("Entrez un produit (ex: Riz, Bijoux, Téléphone...)", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('boutiques').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("Aucune boutique enregistrée."));

        var filteredDocs = snap.data!.docs.where((d) {
          List produits = d['produits'] ?? [];
          String query = searchKey.toLowerCase().trim();
          return produits.any((p) => p.toString().toLowerCase().contains(query));
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text("Désolé, aucun magasin ne vend '$searchKey'.", 
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          );
        }

        // Tri par distance
        if (_currentPosition != null) {
          filteredDocs.sort((a, b) {
            double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a['lat'] ?? 0, a['lng'] ?? 0);
            double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b['lat'] ?? 0, b['lng'] ?? 0);
            return distA.compareTo(distB);
          });
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemBuilder: (context, i) {
            var data = filteredDocs[i].data() as Map<String, dynamic>;
            
            // --- 1. CALCUL DE LA DISTANCE (Correction de l'erreur) ---
            String distanceText = "Distance inconnue";
            if (_currentPosition != null && data['lat'] != null && data['lng'] != null) {
              double distanceInMeters = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude, 
                data['lat'], data['lng']
              );
              distanceText = "${(distanceInMeters / 1000).toStringAsFixed(1)} km de vous";
            }

            // --- 2. FILTRAGE DU PRODUIT SPÉCIFIQUE ---
            List tousLesProduits = data['produits'] ?? [];
            List produitsTrouves = tousLesProduits.where((p) => 
              p.toString().toLowerCase().contains(searchKey.toLowerCase().trim())
            ).toList();

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: const Icon(Icons.store, color: Colors.green, size: 30),
                ),
                title: Text(data['nom_boutique'] ?? "Boutique", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Affiche seulement le(s) produit(s) matché(s)
                    Text("Produit trouvé : ${produitsTrouves.join(', ')}", 
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(distanceText, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () => _showOrderOptions(data),
              ),
            );
          },
        );
      },
    );
  }

  void _trouverLivreurProche(Map<String, dynamic> boutique) async {
    showDialog(context: context, builder: (c) => const Center(child: CircularProgressIndicator()));

    var livreursSnap = await FirebaseFirestore.instance.collection('livreurs').where('gps_active', isEqualTo: true).get();
    
    if (!mounted) return;
    Navigator.pop(context);

    if (livreursSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucun livreur disponible actuellement.")));
      return;
    }

    var listeLivreurs = livreursSnap.docs.toList();
    listeLivreurs.sort((a, b) {
      double dA = Geolocator.distanceBetween(boutique['lat'], boutique['lng'], a['lat'], a['lng']);
      double dB = Geolocator.distanceBetween(boutique['lat'], boutique['lng'], b['lat'], b['lng']);
      return dA.compareTo(dB);
    });

   _showLivreurDialog(listeLivreurs.first.data(), boutique);
  }
void _showLivreurDialog(Map<String, dynamic> livreur, Map<String, dynamic> boutique) {
    // 1. Distance du livreur à la boutique (Trajet A)
    double distLivreurBoutique = Geolocator.distanceBetween(
      livreur['lat'], livreur['lng'], 
      boutique['lat'], boutique['lng']
    ) / 1000;

    // 2. Distance de la boutique au client (Trajet B)
    double distBoutiqueClient = Geolocator.distanceBetween(
      boutique['lat'], boutique['lng'], 
      _currentPosition!.latitude, _currentPosition!.longitude
    ) / 1000;

    // 3. Distance totale et calcul du prix
    double distanceTotale = distLivreurBoutique + distBoutiqueClient;
    int prixLivraison = (distanceTotale * 150).round(); // 150 FCFA par KM
    
    // Prix minimum de 500 FCFA
    if (prixLivraison < 500) prixLivraison = 500;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.motorcycle, size: 50, color: Colors.orange),
            Text("Livreur trouvé : ${livreur['prenom']}", 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Affichage détaillé des distances
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Trajet total :"),
                Text("${distanceTotale.toStringAsFixed(1)} km", 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Text("Prix estimé : $prixLivraison FCFA", 
              style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, 
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50)
              ),
              onPressed: () async {
                // Correction des liens Google Maps ($ ajouté)
                String msg = Uri.encodeComponent(
                  "🛵 *COMMANDE SK-AMNA*\n\n"
                  "Bonjour ${livreur['prenom']},\n"
                  "Je souhaite vous solliciter pour une livraison :\n\n"
                  "🏢 *Boutique* : ${boutique['nom_boutique']}\n"
                  "📍 Récupérer ici : https://www.google.com/maps/search/?api=1&query=${boutique['lat']},${boutique['lng']}\n\n"
                  "🏠 *Ma position (Client)* : https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}\n\n"
                  "📏 *Distance totale* : ${distanceTotale.toStringAsFixed(1)} km\n"
                  "💰 *Prix proposé* : $prixLivraison FCFA"
                );
                launchUrl(Uri.parse("https://wa.me/${livreur['whatsapp']}?text=$msg"), mode: LaunchMode.externalApplication);
              }, 
              child: const Text("CONFIRMER ET CONTACTER LE LIVREUR")
            )
          ],
        ),
      ),
    );
  }

  void _showOrderOptions(Map<String, dynamic> boutique) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(25, 15, 25, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text("Commander chez ${boutique['nom_boutique'] ?? boutique['nom']}", 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.chat, color: Colors.white)),
              title: const Text("Vérifier disponibilité (WhatsApp)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Demander au boutiquier via SK-AMNA"),
              onTap: () async {
               String message = Uri.encodeComponent(
  "🏪 *SK-AMNA PRO - DEMANDE DE DISPONIBILITÉ*\n\n"
  "Bonjour *${boutique['nom_boutique']}*,\n\n"
  "Un client souhaiterait savoir si vous avez ce produit en stock :\n"
  "📦 PRODUIT : *${searchKey.toUpperCase()}*\n\n"
  "Merci de nous confirmer la disponibilité et le prix actuel. 🙏\n\n"
  "📍 Voir votre boutique sur la carte : https://www.google.com/maps/search/?api=1&query=${boutique['lat']},${boutique['lng']}"
);
                String url = "https://wa.me/${boutique['whatsapp']}?text=$message";
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            ),
            const Divider(height: 30),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.motorcycle, color: Colors.white)),
              title: const Text("Demander une livraison", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Trouver le livreur le plus proche"),
              onTap: () {
                Navigator.pop(context);
                _trouverLivreurProche(boutique);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                const Icon(Icons.search, color: Colors.white70, size: 40),
                const Text("SK-AMNA", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const Text("Trouvez tout, tout de suite.", style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => searchKey = v),
                    decoration: const InputDecoration(
                      hintText: "Riz, sucre, téléphone...",
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: Colors.green),
                      suffixIcon: Icon(Icons.search, color: Colors.green),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildResultats()),
        ],
      ),
    );
  }
}