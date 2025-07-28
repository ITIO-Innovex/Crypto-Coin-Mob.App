import 'package:coincraze/BottomBar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coincraze/Models/Transactions.dart';
import 'package:coincraze/services/api_service.dart';

class DetailsTransactionScreen extends StatefulWidget {
  @override
  _DetailsTransactionScreenState createState() =>
      _DetailsTransactionScreenState();
}

class _DetailsTransactionScreenState extends State<DetailsTransactionScreen> {
  List<Transactions> transactions = [];
  bool isLoading = true;
  bool hasError = false;

  // Filters
  String? selectedType;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final result = await ApiService().getTransactions();
      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  String formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final input = DateFormat('yyyy-MM-dd').format(dateTime);
    if (input == today) {
      return 'Today, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat('EEE, MMM d • h:mm a').format(dateTime);
    }
  }

  List<Transactions> get filteredTransactions {
    return transactions.where((tx) {
      final matchesType =
          selectedType == null || tx.type.toLowerCase() == selectedType;
      final matchesStatus =
          selectedStatus == null || tx.status.toLowerCase() == selectedStatus;
      return matchesType && matchesStatus;
    }).toList();
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              _buildFilterOption("Type", ["deposit", "withdraw"]),
              SizedBox(height: 10),
              _buildFilterOption("Status", ["pending", "completed"]),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lime,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text("Apply Filters"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70)),
        Wrap(
          spacing: 8.0,
          children: options.map((value) {
            final isSelected = label == "Type"
                ? selectedType == value
                : selectedStatus == value;
            return ChoiceChip(
              label: Text(value),
              selected: isSelected,
              selectedColor: Colors.lime,
              onSelected: (_) {
                setState(() {
                  if (label == "Type") {
                    selectedType = selectedType == value ? null : value;
                  } else {
                    selectedStatus = selectedStatus == value ? null : value;
                  }
                });
              },
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
              ),
              backgroundColor: Colors.grey[800],
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showTransactionDetails(Transactions tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                "Transaction Details",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Divider(color: Colors.grey),

              _detailRow(
                "Amount",
                "${tx.amount.toStringAsFixed(2)} ${tx.currency}",
                color: tx.type == "deposit" ? Colors.green : Colors.red,
              ),
              _detailRow("Type", tx.type.toUpperCase()),
              _detailRow(
                "Status",
                tx.status.toUpperCase(),
                color: tx.status == "pending" ? Colors.orange : Colors.green,
              ),
              _detailRow("Gateway", tx.gateway),
              _detailRow("Gateway ID", tx.id),
              _detailRow("Type", tx.type),
              _detailRow(
                "Date",
                DateFormat('yMMMEd • h:mm a').format(tx.createdAt),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemoved) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        backgroundColor: Colors.lime,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: Colors.black)),
            SizedBox(width: 4),
            GestureDetector(
              onTap: onRemoved,
              child: Icon(Icons.close, size: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Headerr
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: (){
                      Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => MainScreen(),));
                    },
                    child: Icon(Icons.arrow_back, color: Colors.white,)),
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: Colors.lime),
                    onPressed: _openFilterSheet,
                  ),
                ],
              ),
            ),

            // Filter summary
            if (selectedType != null || selectedStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    if (selectedType != null)
                      _activeFilterChip('Type: ${selectedType!}', () {
                        setState(() => selectedType = null);
                      }),
                    if (selectedStatus != null)
                      _activeFilterChip('Status: ${selectedStatus!}', () {
                        setState(() => selectedStatus = null);
                      }),
                  ],
                ),
              ),

            SizedBox(height: 10),

            // Transactions List
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: RefreshIndicator(
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  onRefresh: fetchTransactions,
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: Colors.lime),
                        )
                      : hasError
                      ? Center(child: Text('Failed to load transactions.'))
                      : filteredTransactions.isEmpty
                      ? Center(child: Text("No transactions found."))
                      : ListView.builder(
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = filteredTransactions[index];
                            final isCredit = tx.type.toLowerCase() == 'deposit';

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 4,
                              ),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: isCredit ? Colors.green : Colors.red,
                                ),
                                title: Text(
                                  '${tx.gateway.toUpperCase()}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${tx.type.toUpperCase()} • ${formatDate(tx.createdAt)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isCredit ? '+' : '-'}${tx.amount.toStringAsFixed(2)} ${tx.currency}',
                                      style: TextStyle(
                                        color: isCredit
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tx.status == 'pending'
                                            ? Colors.orange
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tx.status.toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showTransactionDetails(tx),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
