// Mock class annotations for mockito code generation
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([
  http.Client,
  FirebaseFirestore,
  FirebaseAuth,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  SharedPreferences,
])
void main() {}
