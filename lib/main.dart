// ignore_for_file: avoid_print, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBMH_J7kG74WlZkwkhiqbhMMh8G4_VXv78",
        authDomain: "login-21cc2.firebaseapp.com",
        projectId: "login-21cc2",
        storageBucket: "login-21cc2.appspot.com",
        messagingSenderId: "42703193426",
        appId: "1:42703193426:web:76a705157144a6b8e9668b",
        measurementId: "G-HPPGENTZ8E",
      ),
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feedback App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FeedbackForm(),
    );
  }
}

class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  String selectedCompanyName = '';
  TextEditingController feedbackController = TextEditingController();
  Map<String, int> ratings = {
    'Service': 0,
    'Product': 0,
    'Experience': 0,
    'Delivery': 0,
    'Support': 0,
    'Recommendation': 0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales AI Feedback Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSearchBar(),
              const SizedBox(height: 20),
              selectedCompanyName.isNotEmpty
                  ? SelectedCompany(selectedCompanyName)
                  : CompanyList(
                      onCompanySelected: (companyName) {
                        setState(() {
                          selectedCompanyName = companyName;
                        });
                      },
                    ),
              const SizedBox(height: 20),
              buildRatingQuestions(),
              const SizedBox(height: 20),
              buildFeedbackTextField(),
              const SizedBox(height: 20),
              buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        onTap: () {
          setState(() {
            selectedCompanyName = '';
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search Company',
          icon: Icon(Icons.search),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget buildRatingQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ratings.keys.map((question) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$question: ${ratings[question]}'),
            Slider(
              value: ratings[question]!.toDouble(),
              onChanged: (value) {
                setState(() {
                  ratings[question] = value.round();
                });
              },
              min: 0,
              max: 5,
              divisions: 5,
              label: ratings[question].toString(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget buildFeedbackTextField() {
    return TextField(
      controller: feedbackController,
      decoration: const InputDecoration(
        labelText: 'Feedback',
        border: OutlineInputBorder(),
      ),
      maxLines: 5,
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton(
      onPressed: () {
        submitFeedback();
      },
      child: const Text('Submit Feedback'),
    );
  }

  void submitFeedback() async {
    if (selectedCompanyName.isNotEmpty && feedbackController.text.isNotEmpty) {
      var companyPath =
          selectedCompanyName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

      // Check if the company already has feedback
      var feedbackRef =
          FirebaseFirestore.instance.collection('feedback').doc(companyPath);

      var existingFeedback = await feedbackRef.get();

      if (existingFeedback.exists) {
        // Company already has feedback, add another record
        var feedbackId = existingFeedback.id + DateTime.now().toString();
        await feedbackRef.collection('records').doc(feedbackId).set({
          'feedback': feedbackController.text,
          'ratings': ratings,
        });
      } else {
        // Company does not have feedback, create a new document
        await feedbackRef.set({
          'companyName': selectedCompanyName,
          'records': [
            {
              'feedback': feedbackController.text,
              'ratings': ratings,
            }
          ],
        });
      }
      showFeedbackSubmittedDialog();

      // Reset state variables and controllers after submitting
      setState(() {
        selectedCompanyName = '';
        ratings = {
          'Service': 0,
          'Product': 0,
          'Experience': 0,
          'Delivery': 0,
          'Support': 0,
          'Recommendation': 0,
        };
      });
      feedbackController.clear(); // Clear the text in the feedback text field
    } else {
      showValidationErrorDialog();
    }
  }

  void showFeedbackSubmittedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Feedback Submitted'),
          content: const Text('Thank you for your feedback!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showValidationErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'Please select a company, provide feedback, and answer all rating questions.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class CompanyList extends StatelessWidget {
  final Function(String) onCompanySelected;

  const CompanyList({super.key, required this.onCompanySelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FutureBuilder<List<String>>(
        // Fetch all companies from Firestore
        future: FirebaseFirestore.instance
            .collection('users')
            .get()
            .then((snapshot) {
          return snapshot.docs
              .map((doc) => doc['companyName'].toString())
              .toList();
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            List<String> companyNames = snapshot.data ?? [];
            return ListView.builder(
              itemCount: companyNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(companyNames[index]),
                  onTap: () {
                    // Handle company selection logic here if needed
                    onCompanySelected(companyNames[index]);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class SelectedCompany extends StatelessWidget {
  final String companyName;

  const SelectedCompany(this.companyName, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Selected Company: $companyName',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
