import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class CoinSwapScreen extends StatefulWidget {
  @override
  _CoinSwapScreenState createState() => _CoinSwapScreenState();
}

class _CoinSwapScreenState extends State<CoinSwapScreen> {
  final String apiKey = '5d2be4f43cbc59ec3f34bb54e848ce812de371b15153d8a23232f49d6bbb4eba'; // Replace with your actual API key
  final TextEditingController _amountController = TextEditingController();

  List<Map<String, dynamic>> coins = [];
  String? fromCoin = 'btc';
  String? toCoin = 'eth';
  String? result;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCoins();
  }

  Future<void> fetchCoins() async {
    final url = Uri.parse('https://api.changenow.io/v1/currencies?active=true');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          coins = data
              .map<Map<String, dynamic>>((coin) => {
                    'ticker': coin['ticker'].toString().toLowerCase(),
                    'image': coin['image'] ?? '',
                  })
              .toList();
        });
      } else {
        print("❌ Failed to load coins: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<bool> isPairActive(String from, String to) async {
    final pair = "${from}_${to}";
    final url = Uri.parse('https://api.changenow.io/v1/min-amount/$pair?api_key=$apiKey');

    final res = await http.get(url);
    if (res.statusCode == 200) return true;

    final data = json.decode(res.body);
    return data['error'] != 'pair_is_inactive';
  }

  Future<void> getExchangeAmount() async {
    final amount = _amountController.text.trim();

    if (fromCoin == null || toCoin == null) {
      _showMessage("Please select both coins");
      return;
    }

    if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) {
      _showMessage("Please enter a valid amount");
      return;
    }

    setState(() {
      isLoading = true;
      result = null;
    });

    final from = fromCoin!;
    final to = toCoin!;
    final pair = "${from}_${to}";

    bool active = await isPairActive(from, to);
    if (!active) {
      _showMessage("⚠️ Pair is currently inactive.");
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('https://api.changenow.io/v1/exchange-amount/$amount/$pair?api_key=$apiKey');

    try {
      final res = await http.get(url);
      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        setState(() {
          result = "🔁 Estimated: ${body['estimatedAmount']} ${to.toUpperCase()}";
        });
      } else {
        _showMessage("❌ ${body['error'] ?? 'Error from API'}");
      }
    } catch (e) {
      _showMessage("❌ Network Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildDropdown(String? value, ValueChanged<String?> onChanged) {
    return Expanded(
      child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        icon: Icon(Icons.keyboard_arrow_down),
        onChanged: onChanged,
        items: coins.map<DropdownMenuItem<String>>((coin) {
          return DropdownMenuItem(
            value: coin['ticker'],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(coin['image']),
                  radius: 12,
                  backgroundColor: Colors.transparent,
                ),
                SizedBox(width: 8),
                Text(coin['ticker'].toUpperCase()),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('💱 Crypto Swap')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (coins.isNotEmpty)
              Row(
                children: [
                  _buildDropdown(fromCoin, (val) => setState(() => fromCoin = val)),
                  SizedBox(width: 10),
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 10),
                  _buildDropdown(toCoin, (val) => setState(() => toCoin = val)),
                ],
              ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount in ${fromCoin?.toUpperCase()}',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: isLoading ? CircularProgressIndicator(strokeWidth: 2, color: Colors.white) : Icon(Icons.calculate),
              label: Text('Get Estimate'),
              onPressed: isLoading ? null : getExchangeAmount,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
            ),
            SizedBox(height: 20),
            if (result != null)
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    result!,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}