import 'package:coincraze/LoginScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:coincraze/Models/Transactions.dart'; // Correct Transactions import
import 'package:coincraze/services/api_service.dart'; // Adjust path to your ApiService

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transactions> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  final ApiService apiService = ApiService(); // Instantiate ApiService

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final fetchedTransactions = await apiService.getTransactions();
      setState(() {
        transactions = fetchedTransactions;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().contains('Session expired')
            ? 'Session expired. Please login again.'
            : 'Error fetching transactions: $e';
        isLoading = false;
      });
      if (e.toString().contains('Session expired')) {
        // Redirect to login screen
        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => LoginScreen(),));
      }
    }
  }

  void showTransactionDetails(BuildContext context, Transactions transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 36, 34, 43),
        title: Text(
          '${transaction.type} Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ID: ${transaction.id}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'User ID: ${transaction.userId}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Amount: ${transaction.amount} ${transaction.currency}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Type: ${transaction.type}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Status: ${transaction.status}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Gateway: ${transaction.gateway}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Gateway ID: ${transaction.gateway}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Wallet Type: ${transaction.walletType}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              Text(
                'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 36, 34, 43).withOpacity(0.6),
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: GoogleFonts.poppins(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
              ? Center(
                  child: Column(
                    children: [
                      Text(
                        errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: fetchTransactions,
                        child: Text('Retry', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: transactions.isEmpty
                      ? Center(
                          child: Text(
                            'No transactions available',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                        // scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return Card(
                              color: Colors.white.withOpacity(0.1),
                              child: ListTile(
                                leading: Icon(
                                  transaction.type.toLowerCase() == 'deposit'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color:
                                      transaction.type.toLowerCase() ==
                                          'deposit'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(
                                  '${transaction.type} ${transaction.amount} ${transaction.currency}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  '${DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt)} • ${transaction.status}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: Text(
                                  transaction.gateway,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                                onTap: () => showTransactionDetails(
                                  context,
                                  transaction,
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ],
      ),
    );
  }
}
