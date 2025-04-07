import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'app_drawer.dart';
import 'package:intl/intl.dart';

class SmsEntryPage extends StatefulWidget {
  const SmsEntryPage({Key? key}) : super(key: key);

  @override
  _SmsEntryPageState createState() => _SmsEntryPageState();
}

class _SmsEntryPageState extends State<SmsEntryPage> {
  final Telephony telephony = Telephony.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<SmsMessage> _messages = [];
  late Interpreter _interpreter;
  late List<String> _tokenizerWords;

  @override
  void initState() {
    super.initState();
    _initializeSmsPermissions();
    //_loadModelAndTokenizer();
  }

  Future<void> _initializeSmsPermissions() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted == true) {
      await _fetchSmsMessages();
      _listenForIncomingMessages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SMS permission is required.")),
      );
    }
  }

  Future<void> _markAsProcessed(SmsMessage message) async {
    try {
      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;

      await firestore.collection('processed_messages').add({
        'userid': userid,
        'message_body': message.body,
        'status': 'processed',
        'timestamp': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error marking message as processed: $e");
    }
  }

  Future<void> _showSavedMessages() async {
    try {
      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;

      // Fetch messages from 'saved_messages'
      QuerySnapshot savedSnapshot = await firestore
          .collection('saved_messages')
          .where('userid', isEqualTo: userid)
          .get();

      List<String> savedMessages = savedSnapshot.docs.map((doc) {
        return '''
      Message: ${doc['message']}
      Amount: ${doc['amount']}
      Transaction Type: ${doc['transaction_type']}
      Date: ${(doc['transaction_date'] as Timestamp).toDate()}
      Extracted Date: ${(doc['extracted_date'] as Timestamp).toDate()}
      Category: ${doc['category']}
      ''';
      }).toList();

      _showMessagesDialog("Saved Messages", savedMessages);
    } catch (e) {
      debugPrint("Error fetching saved messages: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch saved messages: $e")),
      );
    }
  }





  Future<void> _showDeletedMessages() async {
    try {
      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;

      QuerySnapshot deletedSnapshot = await firestore
          .collection('deleted_messages')
          .where('userid', isEqualTo: userid)
          .get();

      List<String> deletedMessages = deletedSnapshot.docs.map((doc) {
        return '''
      Message: ${doc['message_body']}
      Status: ${doc['status']}
      Timestamp: ${(doc['timestamp'] as Timestamp).toDate()}
      ''';
      }).toList();

      if (!mounted) return;

      if (deletedMessages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No deleted messages found.")),
        );
        return;
      }

      _showMessagesDialog("Deleted Messages", deletedMessages);
    } catch (e) {
      debugPrint("Error fetching deleted messages: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch deleted messages: $e")),
      );
    }
  }





  void _showMessagesDialog(String title, List<String> messages,
      {bool isSaved = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(messages[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _deleteMessageFromFirestore(
                              messages[index], isSaved: isSaved);

                          setState(() {
                            messages.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Message deleted successfully.")),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _deleteMessageFromFirestore(String messageBody, {bool isSaved = false}) async {
    try {
      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;
      String collection = isSaved ? 'saved_messages' : 'deleted_messages';

      QuerySnapshot snapshot = await firestore
          .collection(collection)
          .where('userid', isEqualTo: userid)
          .where('message_body', isEqualTo: messageBody)
          .get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // Restore message in 'all_bank_messages'
      await firestore.collection('all_bank_messages').add({
        'userid': userid,
        'message_body': messageBody,
        'timestamp': Timestamp.now(),
        'is_deleted': false,
      });

      setState(() {
        _messages.removeWhere((msg) => msg.body == messageBody);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message restored successfully.")),
      );
    } catch (e) {
      debugPrint("Error deleting message from Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to restore message: $e")),
      );
    }
  }





  bool _isPromotionalMessage(String body) {
    // Define criteria for detecting promotional messages
    List<String> promotionalKeywords = [
      'offer',
      'discount',
      'sale',
      'win',
      'free',
      'cashback',
      'deal',
      'coupon',
      'bonanza',
      'reward',
      'promo',
      'subscription',
      'get'
    ];

    // Check if any promotional keyword exists in the message body
    for (String keyword in promotionalKeywords) {
      if (body.toLowerCase().contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  Future<void> _fetchSmsMessages() async {
    try {
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      );

      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;

      QuerySnapshot processedSnapshot = await firestore
          .collection('processed_messages')
          .where('userid', isEqualTo: userid)
          .get();

      List<String> processedBodies = processedSnapshot.docs
          .map((doc) => doc['message_body'] as String)
          .toList();

      List<SmsMessage> filteredMessages = [];

      for (var msg in messages) {
        String body = msg.body ?? '';
        bool containsAmountKeyword = body.contains(RegExp(r'\b(Rs|INR)\b', caseSensitive: false));
        bool isBankMessage = await _isBankMessageML(body) || _isBankMessage(body);
        bool isPromotionalMessage = _isPromotionalMessage(body);

        if (!processedBodies.contains(body) &&
            containsAmountKeyword &&
            isBankMessage &&
            !isPromotionalMessage) {
          filteredMessages.add(msg);

          // Save all bank-related messages to 'all_bank_messages' collection
          await firestore.collection('all_bank_messages').add({
            'userid': userid,
            'message_body': body,
            'timestamp': Timestamp.now(),
            'is_deleted': false,
          });
        }
      }

      setState(() {
        _messages = filteredMessages;
      });
    } catch (e) {
      debugPrint("Error fetching SMS messages: $e");
    }
  }





  void _listenForIncomingMessages() {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        if (mounted &&
            (await _isBankMessageML(message.body ?? '') || _isBankMessage(message.body ?? ''))) {
          setState(() {
            _messages.insert(0, message);
          });
        }
      },
    );
  }

  // Future<void> _loadModelAndTokenizer() async {
  //   try {
  //     _interpreter = await Interpreter.fromAsset('text_classification_model.tflite');
  //
  //     String tokenizerData = await DefaultAssetBundle.of(context).loadString('assets/tokenizer.json');
  //     _tokenizerWords = List<String>.from(json.decode(tokenizerData));
  //   } catch (e) {
  //     debugPrint("Error loading model/tokenizer: $e");
  //   }
  // }

  Future<bool> _isBankMessageML(String message) async {
    try {
      if (message.isEmpty) return false;

      // Tokenize the message
      List<int> tokenizedMessage = _tokenizeMessage(message);

      // Prepare input tensor for the model
      final inputTensor = [tokenizedMessage];

      // Define output tensor for model predictions
      final outputTensor = List<double>.filled(1, 0);

      // Run the inference
      _interpreter.run(inputTensor, outputTensor);

      // If the model predicts it's a bank message (threshold > 0.5)
      return outputTensor[0] > 0.5;
    } catch (e) {
      debugPrint("Error in ML classification: $e");
      return false;
    }
  }

  List<int> _tokenizeMessage(String message) {
    final tokens = message.split(' ');
    return tokens.map((word) {
      return _tokenizerWords.indexOf(word) != -1
          ? _tokenizerWords.indexOf(word)
          : 0; // Use 0 if the word is not in the vocabulary
    }).toList();
  }

  bool _isBankMessage(String message) {
    List<String> bankKeywords = [
      'credited',
      'debited',
      'withdrawal',
      'deposit',
      'sent',
      'recieved'
    ];

    for (String keyword in bankKeywords) {
      if (message.toLowerCase().contains(keyword)) return true;
    }
    return false;
  }


  Future<Map<String, String>> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Check if the user's name is available in the Firestore `users` collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String username = userDoc.exists && userDoc['username'] != null
          ? userDoc['username'] as String
          : user.displayName ?? 'Unknown User';

      String userid = user.uid;
      //String? email = user.email;

      return {'username': username, 'userid': userid };
    } else {
      throw Exception("No user is currently logged in.");
    }
  }
  Future<void> _deleteMessage(SmsMessage message) async {
    try {
      Map<String, String> currentUser = await _getCurrentUser();
      String userid = currentUser['userid']!;

      // Move to 'deleted_messages' collection
      await firestore.collection('deleted_messages').add({
        'userid': userid,
        'message_body': message.body,
        'status': 'deleted',
        'timestamp': Timestamp.now(),
      });

      // Remove from 'all_bank_messages'
      await _removeFromAllBankMessages(message.body ?? "", userid);

      // Mark the message as processed
      await _markAsProcessed(message);

      setState(() {
        _messages.remove(message);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message deleted successfully.")),
      );
    } catch (e) {
      debugPrint("Error deleting message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete message: $e")),
      );
    }
  }

  Future<void> _removeFromAllBankMessages(String messageBody, String userid) async {
    QuerySnapshot snapshot = await firestore
        .collection('all_bank_messages')
        .where('userid', isEqualTo: userid)
        .where('message_body', isEqualTo: messageBody)
        .get();

    for (QueryDocumentSnapshot doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transport',
    'General',
    'Education',
    'Medical',
    'Entertainment',
    'Bills & Utilities',
    'Groceries',
    'Rent',
    'Salary',
    'Investment',
    'Travel',
    'Subscriptions',
    'Gifts & Donations',
    'Taxes',
    'Insurance',
    'Fitness',
    'Pets',
    'Loan Repayment',
  ];




  Future<void> _storeBankMessage(SmsMessage message, String category) async {
    try {
      String messageBody = message.body ?? "";
      double? amount = _extractAmount(messageBody);
      String transactionType = _getTransactionType(messageBody);
      DateTime transactionDate = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);
      DateTime? extractedDate = _extractDate(messageBody);
      Map<String, String> currentUser = await _getCurrentUser();
      String username = currentUser['username']!;
      String userid = currentUser['userid']!;
      await firestore.collection('saved_messages').add({
        'username': username,
        'userid': userid,
        'amount': amount,
        'transaction_type': transactionType,
        'message': messageBody,
        'timestamp': Timestamp.now(),
        'transaction_date': Timestamp.fromDate(transactionDate),
        'extracted_date': extractedDate != null ? Timestamp.fromDate(extractedDate) : Timestamp.fromDate(transactionDate),
        'category': category,
      });
      DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      DateFormat timeFormat = DateFormat('HH:mm:ss');
      String formattedDate = extractedDate != null
          ? dateFormat.format(extractedDate)
          : dateFormat.format(transactionDate);
      String formattedTime = extractedDate != null
          ? timeFormat.format(extractedDate)
          : timeFormat.format(transactionDate);
      Map<String, dynamic> expenseData = {
        'username': username,
        'email': "null",
        'date': formattedDate,
        'time': formattedTime,
        'category': category,
        'amount': amount,
        'userID': userid,
        'type':"Sms"
      };
      try {
        await FirebaseFirestore.instance.collection('expenses').add(expenseData);
      } catch (e) {
        throw Exception("Failed to save expense data: $e");
      }
      DocumentReference categoryRef =
      FirebaseFirestore.instance.collection(userid).doc(category);
      DocumentSnapshot categorySnapshot = await categoryRef.get();
      await _removeFromAllBankMessages(messageBody, userid);
      await _markAsProcessed(message);
      setState(() {
        _messages.remove(message);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message saved to 'Saved Messages'.")),
      );
    } catch (e) {
      debugPrint("Error saving message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save message: $e")),
      );
    }
  }






  double? _extractAmount(String message) {
    RegExp amountRegex =
    RegExp(r'(?:Rs|INR)[.:]?\s?(\d+(?:,\d{3})*(?:\.\d{1,2})?)');
    Match? match = amountRegex.firstMatch(message);
    if (match != null) {
      String amount = match.group(1)!.replaceAll(',', '');
      return double.tryParse(amount);
    }
    return null;
  }

  String _getTransactionType(String message) {
    if (message.toLowerCase().contains('credited')) return 'Credit';
    if (message.toLowerCase().contains('debited')) return 'Debit';
    if (message.toLowerCase().contains('withdrawal')) return 'Withdrawal';
    return 'Other';
  }

  DateTime? _extractDate(String message) {
    try {
      RegExp dateRegex = RegExp(
        r'(\d{1,2}/\d{1,2}/\d{4})|(\d{1,2}\s(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s\d{4})',
        caseSensitive: false,
      );

      Match? match = dateRegex.firstMatch(message);
      if (match != null) {
        return DateTime.tryParse(match.group(0)!);
      }
    } catch (e) {
      debugPrint("Error extracting date: $e");
    }
    return null;
  }

  void _showActionDialog(SmsMessage message, int index) {
    String selectedCategory = _categories[0]; // Default category

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Message Action"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Do you want to save this bank-related message?",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _storeBankMessage(message, selectedCategory);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"),
                ),
                TextButton(
                  onPressed: () async {
                    await _deleteMessage(message);
                    Navigator.of(context).pop();
                  },
                  child: const Text("Delete"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE39C6F),
        title: const Text("Bank SMS Entry"),
        centerTitle: true,
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Fetch Expense Details via SMS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSmsMessages,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: const Color(0xFFE39C6F), // Set the text color to white
              ),
              child: const Text("Fetch SMS"),
            ),
            ElevatedButton(
              onPressed: _showSavedMessages,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: const Color(0xFFE39C6F), // Set the text color to white
              ),
              child: const Text("Show Saved Messages"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showDeletedMessages,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: const Color(0xFFE39C6F), // Set the text color to white
              ),
              child: const Text("Show Deleted Messages"),
            ),


            const SizedBox(height: 16),
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                child: Text(
                  "No bank-related messages found.",
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];

                  // Convert the SMS timestamp to a readable date
                  DateTime transactionDate = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);
                  String formattedDate =
                      "${transactionDate.day}-${transactionDate.month}-${transactionDate.year} ${transactionDate.hour}:${transactionDate.minute}";

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        message.address ?? "Unknown Sender",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.body ?? "No content"),
                          const SizedBox(height: 4),
                          Text(
                            "Transaction Date: $formattedDate",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showActionDialog(message, index);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

