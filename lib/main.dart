import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(),
    );
  }
}


class InventoryHomePage extends StatefulWidget {
  const InventoryHomePage({super.key});

  @override //Inventory  Homepage State
  InvHPState createState() => InvHPState();
}

class InvHPState extends State<InventoryHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Management System')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('inventory').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.docs.map((doc) => ListTile(
              title: Text(doc['name']),
              subtitle: Text("Quantity: ${doc['quantity']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showEditDialog(context, doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => delItem(doc.id),
                  ),
                ],
              ),
            )).toList(),
          );
        },
      ),
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
          title: const Text('Add  Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Item Name'),
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
      });
    }
  }

  //  Editing 
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
