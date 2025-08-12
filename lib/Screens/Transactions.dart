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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        '${transaction.type} Details',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Transaction ID:', transaction.id.toString()),
            _buildDetailRow('User ID:', transaction.userId.toString()),
            const Divider(color: Colors.grey),

            _buildDetailRow('Amount:', '${transaction.amount} ${transaction.currency}'),
            _buildDetailRow('Type:', transaction.type),
            _buildDetailRow('Status:', transaction.status),
            const Divider(color: Colors.grey),

            _buildDetailRow('Gateway:', transaction.gateway),
            // _buildDetailRow('Gateway ID:', transaction.gatewayId),
            // _buildDetailRow('Wallet Type:', transaction.walletType),
            const Divider(color: Colors.grey),

            _buildDetailRow(
              'Date:',
              DateFormat('yyyy-MM-dd HH:mm').format(transaction.createdAt),
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

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[300],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white),
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
            'Transactions Details',
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
