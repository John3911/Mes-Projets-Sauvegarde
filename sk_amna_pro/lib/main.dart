import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SkAmnaPro());
}

class SkAmnaPro extends StatelessWidget {
  const SkAmnaPro({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AuthWrapper(),
    );
  }
}

// --- 1. GESTION DE L'ÉTAT (AUTH) ---
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (userSnap.hasData && userSnap.data!.exists) {
                Map<String, dynamic> data = userSnap.data!.data() as Map<String, dynamic>;
                String role = data['role'] ?? '';
                if (role == 'boutique') return const BoutiqueDashboard();
                if (role == 'livreur') return const LivreurDashboard();
              }
              
              return const HomePage(); 
            },
          );
        }
        return const HomePage();
      },
    );
  }
}

// --- 2. LA PAGE D'ACCUEIL ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedRole = 'boutique';

  Future<void> _loginAndSetRole() async {
    try {
// Remplace "TON_ID_CLIENT_WEB.apps.googleusercontent.com" par ton vrai ID
final GoogleSignIn googleService = GoogleSignIn(
  clientId: "1004687713172-75lpr4dkkb4ol9k1g3j59fl16abv29pe.apps.googleusercontent.com", // OBLIGATOIRE POUR LE WEB
);      final googleUser = await googleService.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      
      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'role': selectedRole,
        'email': userCred.user!.email,
        'lastLogin': DateTime.now(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: const Column(
              children: [
                Icon(Icons.search, color: Colors.white70, size: 40),
                Text("SK-AMNA PRO", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Text("Vous êtes ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _roleCard("BOUTIQUIER", Icons.storefront, 'boutique'),
                      _roleCard("LIVREUR", Icons.delivery_dining, 'livreur'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: _loginAndSetRole,
                    icon: const Icon(Icons.login, color: Colors.green),
                    label: Text("Se connecter en tant que ${selectedRole.toUpperCase()}"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 Widget _roleCard(String title, IconData icon, String role) {
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.green : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.green : Colors.grey),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.green : Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// --- 3. DASHBOARD BOUTIQUIER ---
class BoutiqueDashboard extends StatefulWidget {
  const BoutiqueDashboard({super.key});
  @override
  State<BoutiqueDashboard> createState() => _BoutiqueDashboardState();
}

class _BoutiqueDashboardState extends State<BoutiqueDashboard> {
  final _nomBoutique = TextEditingController();
  final _nomResponsable = TextEditingController();
  final _prenomResponsable = TextEditingController();
  final _whatsapp = TextEditingController();
  final _produits = TextEditingController();
  String _locationStatus = "Non localisée";

  void _chargerDonnees() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance.collection('boutiques').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() {
        _nomBoutique.text = doc['nom_boutique'] ?? "";
        _nomResponsable.text = doc['nom'] ?? "";
        _prenomResponsable.text = doc['prenom'] ?? "";
        _whatsapp.text = doc['whatsapp'] ?? "";
        _produits.text = (doc['produits'] as List?)?.join(', ') ?? "";
        if (doc['lat'] != null) {
          _locationStatus = "Localisée (${doc['lat'].toStringAsFixed(2)}, ${doc['lng'].toStringAsFixed(2)})";
        }
      });
    }
  }

  void _enregistrer() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      Position pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      
      await FirebaseFirestore.instance.collection('boutiques').doc(uid).set({
        'nom_boutique': _nomBoutique.text,
        'nom': _nomResponsable.text,
        'prenom': _prenomResponsable.text,
        'whatsapp': _whatsapp.text,
        'produits': _produits.text.split(',').map((e) => e.trim()).toList(),
        'lat': pos.latitude,
        'lng': pos.longitude,
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      setState(() => _locationStatus = "Localisée (${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)})");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Boutique enregistrée !")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  @override
  void initState() { super.initState(); _chargerDonnees(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Boutique"), 
        backgroundColor: Colors.green, 
        foregroundColor: Colors.white,
        actions: [
          // BOUTON DÉCONNECTER
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _nomBoutique, decoration: const InputDecoration(labelText: "Nom Boutique")),
          TextField(controller: _prenomResponsable, decoration: const InputDecoration(labelText: "Prénom")),
          TextField(controller: _nomResponsable, decoration: const InputDecoration(labelText: "Nom")),
          TextField(controller: _whatsapp, decoration: const InputDecoration(labelText: "WhatsApp")),
          TextField(controller: _produits, decoration: const InputDecoration(labelText: "Produits (riz, savon...)")),
          const SizedBox(height: 20),
          Text(_locationStatus, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _enregistrer, child: const Text("ENREGISTRER LA BOUTIQUE")),
        ],
      ),
    );
  }
}

// --- 4. DASHBOARD LIVREUR (CORRIGÉ AVEC CHARGEMENT) ---
class LivreurDashboard extends StatefulWidget {
  const LivreurDashboard({super.key});
  @override
  State<LivreurDashboard> createState() => _LivreurDashboardState();
}

class _LivreurDashboardState extends State<LivreurDashboard> {
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _whatsapp = TextEditingController();
  bool _gpsActive = false;

  // --- AJOUT DE CETTE FONCTION POUR RÉCUPÉRER LES INFOS ---
  void _chargerInfosLivreur() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    var doc = await FirebaseFirestore.instance.collection('livreurs').doc(uid).get();
    
    if (doc.exists && mounted) {
      setState(() {
        _nom.text = doc['nom'] ?? "";
        _prenom.text = doc['prenom'] ?? "";
        _whatsapp.text = doc['whatsapp'] ?? "";
        _gpsActive = doc['gps_active'] ?? false;
      });
    }
  }

  // --- NE PAS OUBLIER D'APPELER LE CHARGEMENT ICI ---
  @override
  void initState() {
    super.initState();
    _chargerInfosLivreur();
  }

  void _sauver() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> data = {
      'nom': _nom.text, 
      'prenom': _prenom.text, 
      'whatsapp': _whatsapp.text, 
      'gps_active': _gpsActive,
    };
    
    if (_gpsActive) {
      try {
        Position pos = await Geolocator.getCurrentPosition();
        data['lat'] = pos.latitude;
        data['lng'] = pos.longitude;
      } catch (e) {
        debugPrint("Erreur GPS : $e");
      }
    }

    await FirebaseFirestore.instance.collection('livreurs').doc(uid).set(data, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Infos livreur mises à jour !")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Livreur"), 
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _prenom, decoration: const InputDecoration(labelText: "Prénom")),
          TextField(controller: _nom, decoration: const InputDecoration(labelText: "Nom")),
          TextField(controller: _whatsapp, decoration: const InputDecoration(labelText: "WhatsApp (ex: 221...)")),
          const SizedBox(height: 10),
          SwitchListTile(
            title: const Text("GPS Live (Actif pour les clients)"),
            subtitle: const Text("Désactivez pour ne plus être visible"),
            value: _gpsActive,
            onChanged: (val) { 
              setState(() => _gpsActive = val); 
              _sauver(); // Sauvegarde automatique quand on change le switch
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15)
            ),
            onPressed: _sauver, 
            child: const Text("ENREGISTRER MES MODIFICATIONS")
          ),
        ],
      ),
    );
  }
}