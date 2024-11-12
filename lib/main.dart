import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Added .evn variables
  await dotenv.load();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['API_KEY']!,
      authDomain: dotenv.env['AUTH_DOMAIN']!,
      projectId: dotenv.env['PROJECT_ID']!,
      storageBucket: dotenv.env['STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
      appId: dotenv.env['APP_ID']!,
      measurementId: dotenv.env['MEASUREMENT_ID']!,
    ),
  );
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return const InventoryHomePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
class LoginPage extends StatelessWidget {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final GoogleSignIn signIn = GoogleSignIn();

  LoginPage({super.key});

  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await signIn.signIn();
    if (googleUser == null) return; 
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await auth.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: signInWithGoogle,
          child: const Text('Sign in with Moogle'),
        ),
      ),
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override
  IHPState createState() => IHPState();
}

class IHPState extends State<InventoryHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('I.M.S'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
            },
          ),
        ],
      ),
      body: InventoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddDialog(context),
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> showAddDialog(BuildContext context) async {
    String name = '';
    int quantity = 0;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                onChanged: (value) => quantity = int.tryParse(value) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                addItem(name, quantity);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addItem(String name, int quantity) async {
    if (name.isNotEmpty && quantity > 0) {
      await FirebaseFirestore.instance.collection('inventory').add({
        'name': name,
        'quantity': quantity,
        'Done': false,
      });
    }
  }
}

class InventoryList extends StatefulWidget {
  const InventoryList({super.key});

  @override
  IlistState createState() => IlistState();
}

class IlistState extends State<InventoryList> {
  final CollectionReference inventory = FirebaseFirestore.instance.collection('inventory');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: inventory.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final items = snapshot.data!.docs;

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            bool Done = item['Done'] ?? false;

            return ListTile(
              title: Text(item['name']),
              subtitle: Text("Quantity: ${item['quantity']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: Done,
                    onChanged: (bool? value) {
                      setState(() {
                        inventory.doc(item.id).update({'Done': value});
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showEditDialog(context, item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => delItem(item.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> showEditDialog(BuildContext context, QueryDocumentSnapshot doc) async {
    String name = doc['name'];
    int quantity = doc['quantity'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Item Name'),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: quantity.toString()),
                onChanged: (value) => quantity = int.tryParse(value) ?? 0,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                actualizeItem(doc.id, name, quantity);
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Update 
  Future<void> actualizeItem(String id, String name, int quantity) async {
    if (name.isNotEmpty && quantity > 0) {
      await FirebaseFirestore.instance.collection('inventory').doc(id).update({
        'name': name,
        'quantity': quantity,
      });
    }
  }

  //  Delete 
  Future<void> delItem(String id) async {
    await FirebaseFirestore.instance.collection('inventory').doc(id).delete();
  }
}
