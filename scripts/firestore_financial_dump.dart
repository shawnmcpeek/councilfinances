import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

Future<void> main(List<String> args) async {
  // TODO: Replace with your actual org ID and year, or parse from args
  const organizationId = 'C015857'; // Example: 'C015857'
  const year = '2025';
  const isAssembly = false;

  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;

  final incomeRef = firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('finance')
      .doc('income')
      .collection(year);

  final expenseRef = firestore
      .collection('organizations')
      .doc(organizationId)
      .collection('finance')
      .doc('expenses')
      .collection(year);

  final incomeSnapshot = await incomeRef.get();
  final expenseSnapshot = await expenseRef.get();

  final incomeEntries = incomeSnapshot.docs.map((doc) => doc.data()).toList();
  final expenseEntries = expenseSnapshot.docs.map((doc) => doc.data()).toList();

  final result = {
    'organizationId': organizationId,
    'year': year,
    'income': incomeEntries,
    'expenses': expenseEntries,
  };

  print(jsonEncode(result));
} 