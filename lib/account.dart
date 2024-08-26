import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finalassign/home.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountPage extends StatelessWidget {

  Future<void> _deleteBill(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('account').doc(documentId).delete();
    } catch (e) {
      print('Error deleting bill: $e');
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String documentId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteBill(documentId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text('Account Book'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddBillPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('account').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }
              var documents = snapshot.data?.docs;
              int totalAmount = 0;
              for (var doc in documents!) {
                totalAmount += (doc.data()['price'] as int);
              }
              var formatter = NumberFormat("#,##0", "en_US");
              var formattedTotalAmount = formatter.format(totalAmount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₩$formattedTotalAmount',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 4,
                    color: Colors.black,
                  ),
                ],
              );
            },
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('account').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                var documents = snapshot.data?.docs;
                documents?.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
                documents?.reversed;
                return ListView.builder(
                  reverse: false,
                  itemCount: documents?.length,
                  itemBuilder: (context, index) {
                    var item = documents?[index].data()['item'];
                    var price = documents?[index].data()['price'];
                    var documentId = documents?[index].id;
                    var timestamp = (documents?[index].data()['timestamp'] as Timestamp).toDate();
                    var formattedTimestamp = DateFormat('yyyy-MM-dd, HH:mm').format(timestamp);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                              Text(
                                '₩$price',
                                style: const TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedTimestamp,
                                style: const TextStyle(
                                  fontSize: 12, 
                                  color: Colors.grey, 
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ModifyBillPage(
                                            itemId: documents![index].id,
                                            currentItem: item,
                                            currentPrice: price,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      if (documentId != null) {
                                        _showDeleteConfirmationDialog(context, documentId);
                                      } else {
                                        print('Document ID is null');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.grey),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddBillPage extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Add Bill'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              _addBillToFirestore(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Bill Name',
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Enter Bill Amount',
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _addBillToFirestore(context);
              },
              child: const Text('Add Bill'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBillToFirestore(BuildContext context) async {
    try {
      String itemName = _nameController.text.trim();
      int amount = int.parse(_amountController.text.trim());

      DateTime timestamp = DateTime.now();

      await FirebaseFirestore.instance.collection('account').add({
        'item': itemName,
        'price': amount,
        'timestamp': timestamp,
      });

      Navigator.pop(context);
    } catch (e) {
      print('Error adding bill: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error adding bill. Please try again.'),
        ),
      );
    }
  }
}

class ModifyBillPage extends StatefulWidget {
  final String itemId;
  final String currentItem;
  final int currentPrice;

  ModifyBillPage({
    required this.itemId,
    required this.currentItem,
    required this.currentPrice,
  });

  @override
  _ModifyBillPageState createState() => _ModifyBillPageState();
}

class _ModifyBillPageState extends State<ModifyBillPage> {
  late TextEditingController _itemController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController(text: widget.currentItem);
    _priceController = TextEditingController(text: widget.currentPrice.toString());
  }

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        title: const Text('Modify Bill'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: 'Enter Bill Name'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Enter Bill Amount'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('account').doc(widget.itemId).update({
                  'item': _itemController.text,
                  'price': int.parse(_priceController.text),
                });
                Navigator.pop(context);
              },
              child: const Text('Modify Bill'),
            ),
          ],
        ),
      ),
    );
  }
}