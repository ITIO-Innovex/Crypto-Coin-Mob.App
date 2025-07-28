import 'package:coincraze/Models/Transactions.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final String userId;

  TransactionHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History')),
      body: FutureBuilder<List<Transactions>>(
        future: ApiService().getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final transactions = snapshot.data ?? [];
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return ListTile(
                title: Text('${tx.type.toUpperCase()} ${tx.amount} ${tx.currency}'),
                subtitle: Text('Status: ${tx.status} | Gateway: ${tx.gateway}'),
                trailing: Text(tx.createdAt.toString()),
              );
            },
          );
        },
      ),
    );
  }
}