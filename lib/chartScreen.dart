import 'dart:async';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Models/SpotOrderMode.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> coinPriceList = [];
  String currentPrice = "0.00";
  String changePercent = "0.00%";
  bool isLoading = true;
  bool isCoinLoading = true;
  Timer? _timer;
  String selectedCoin = 'bitcoin';
  List<String> coinOptions = [];
  TabController? _tabController;
  String orderType = 'Market';
  TextEditingController amountController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController stopPriceController = TextEditingController();
  List<Map<String, dynamic>> orderBook = [];
  List<Map<String, dynamic>> tradeHistory = [];
  List<Map<String, dynamic>> userOrders = [];
  late WebViewController _webViewController;
  String? chartErrorMessage;
  WebSocketChannel? _orderBookChannel;
  String? cryptoWalletId;
  String? fiatWalletId;
  double fiatBalance = 0.0;
  double cryptoBalance = 0.0;
  final userId = AuthManager().userId;
  bool isAmountInCrypto = true;
  final ApiService _apiService = ApiService(); // Initialize ApiService

  final Map<String, Map<String, String>> coinSymbolMap = {
    'bitcoin': {'tradingview': 'BTCUSD', 'coinbase': 'BTC-USD'},
    'ethereum': {'tradingview': 'ETHUSD', 'coinbase': 'ETH-USD'},
    'ripple': {'tradingview': 'XRPUSD', 'coinbase': 'XRP-USD'},
    'cardano': {'tradingview': 'ADAUSD', 'coinbase': 'ADA-USD'},
    'solana': {'tradingview': 'SOLUSD', 'coinbase': 'SOL-USD'},
    'polkadot': {'tradingview': 'DOTUSD', 'coinbase': 'DOT-USD'},
    'dogecoin': {'tradingview': 'DOGEUSD', 'coinbase': 'DOGE-USD'},
    'binancecoin': {'tradingview': 'BNBUSD', 'coinbase': 'BNB-USD'},
    'chainlink': {'tradingview': 'LINKUSD', 'coinbase': 'LINK-USD'},
    'avalanche-2': {'tradingview': 'AVAXUSD', 'coinbase': 'AVAX-USD'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    fetchCoinOptions();
    fetchCoinPriceList();
    fetchWallets();
    fetchSpotOrders(); // Replace fetchOrders with fetchSpotOrders
    fetchTradeHistory();
    _initializeOrderBookWebSocket();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchCoinPriceList();
      fetchWallets();
      fetchSpotOrders(); // Update orders periodically
      fetchTradeHistory();
    });
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() {
            isLoading = true;
            chartErrorMessage = null;
          }),
          onPageFinished: (String url) => setState(() => isLoading = false),
          onWebResourceError: (error) {
            print('WebView Error: ${error.description}');
            setState(() {
              isLoading = false;
              chartErrorMessage =
                  'Failed to load chart for ${selectedCoin.toUpperCase()}. Using fallback (BTCUSD).';
              _webViewController.loadHtmlString(_getTradingViewHtml('bitcoin'));
            });
          },
        ),
      )
      ..loadHtmlString(_getTradingViewHtml(selectedCoin));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController?.dispose();
    amountController.dispose();
    priceController.dispose();
    stopPriceController.dispose();
    _orderBookChannel?.sink.close();
    super.dispose();
  }

  Future<void> fetchCoinOptions() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&per_page=10',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          coinOptions = data
              .map((coin) => coin['id'].toString())
              .where((id) => coinSymbolMap.containsKey(id))
              .toList();
          isCoinLoading = false;
          if (!coinOptions.contains(selectedCoin)) {
            selectedCoin = coinOptions.isNotEmpty ? coinOptions[0] : 'bitcoin';
          }
        });
      } else {
        throw Exception('Failed to load coins');
      }
    } catch (e) {
      setState(() {
        isCoinLoading = false;
        coinOptions = coinSymbolMap.keys.toList();
      });
      print('Error fetching coins: $e');
    }
  }

  Future<void> fetchCoinPriceList() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=20&page=1&sparkline=false',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          coinPriceList = data
              .map(
                (coin) => {
                  'id': coin['id'],
                  'name': coin['name'],
                  'symbol': coin['symbol'],
                  'price': coin['current_price'],
                  'change': coin['price_change_percentage_24h'],
                  'market_cap': coin['market_cap'],
                },
              )
              .where((coin) => coinSymbolMap.containsKey(coin['id']))
              .toList();
          if (coinPriceList.any((coin) => coin['id'] == selectedCoin)) {
            final selected = coinPriceList.firstWhere(
              (coin) => coin['id'] == selectedCoin,
            );
            currentPrice = selected['price'].toStringAsFixed(2);
            changePercent = selected['change'].toStringAsFixed(2) + '%';
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load coin prices');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching coin prices: $e');
    }
  }

  Future<void> fetchWallets() async {
    try {
      final token = await AuthManager().getAuthToken();
      final cryptoResponse = await http.get(
        Uri.parse('$ProductionBaseUrl/api/wallet/fetchCompleteCryptoDetails'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final fiatResponse = await http.get(
        Uri.parse('$ProductionBaseUrl/api/wallet/balance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (cryptoResponse.statusCode == 200 && fiatResponse.statusCode == 200) {
        final cryptoData =
            jsonDecode(cryptoResponse.body)['data'] as List<dynamic>;
        final fiatData = jsonDecode(fiatResponse.body) as List<dynamic>;

        setState(() {
          final targetCoinbase =
              coinSymbolMap[selectedCoin]?['coinbase'] ??
              selectedCoin.toUpperCase();
          final wallet = cryptoData.firstWhere(
            (w) =>
                w['coinName'] == targetCoinbase ||
                w['coinName'].split('_')[0].toUpperCase() ==
                    targetCoinbase.split('-')[0],
            orElse: () => cryptoData.isNotEmpty
                ? cryptoData[0]
                : {'balance': 0.0, '_id': null},
          );
          cryptoWalletId = wallet['_id']?.toString();
          cryptoBalance = wallet['balance']?.toDouble() ?? 0.0;

          final fiatWallet = fiatData.firstWhere(
            (w) => w['currency'] == 'USD',
            orElse: () => {'balance': 0.0, '_id': null},
          );
          fiatWalletId = fiatWallet['_id']?.toString();
          fiatBalance = fiatWallet['balance']?.toDouble() ?? 0.0;
        });
      }
    } catch (e) {
      print('Error fetching wallets: $e');
    }
  }

  Future<List<OrderData>> fetchSpotOrders() async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.get(
        Uri.parse('$ProductionBaseUrl/api/wallet/fetchSpotOrders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data
            .map((json) => OrderData.fromJson(json))
            .toList(); // Returns List<OrderData>
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to fetch spot orders: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching spot orders: $e');
    }
  }

  Future<void> fetchTradeHistory() async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.get(
        Uri.parse('$ProductionBaseUrl/api/wallet/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          tradeHistory = data
              .where(
                (tx) =>
                    tx['currency'] == coinSymbolMap[selectedCoin]?['coinbase'],
              )
              .map((tx) {
                final fiatAmount = tx['fiatAmount'] as num? ?? 0;
                final amount = tx['amount'] as num? ?? 1;
                return {
                  'time': DateTime.parse(tx['createdAt'] as String),
                  'price': fiatAmount / amount,
                  'amount': amount,
                  'type': tx['type'] as String? ?? 'Unknown',
                };
              })
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching trade history: $e');
      setState(() {
        tradeHistory = [];
      });
    }
  }

  void _initializeOrderBookWebSocket() {
    _orderBookChannel?.sink.close();
    final coinbasePair = coinSymbolMap[selectedCoin]?['coinbase'] ?? 'BTC-USD';
    _orderBookChannel = WebSocketChannel.connect(
      Uri.parse('wss://ws-feed.exchange.coinbase.com'),
    );

    _orderBookChannel!.sink.add(
      jsonEncode({
        'type': 'subscribe',
        'product_ids': [coinbasePair],
        'channels': ['level2'],
      }),
    );

    _orderBookChannel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['type'] == 'snapshot') {
          setState(() {
            orderBook = [
              ...data['bids']
                  .take(10)
                  .map(
                    (bid) => {
                      'price': double.parse(bid[0]),
                      'amount': double.parse(bid[1]),
                      'type': 'buy',
                    },
                  ),
              ...data['asks']
                  .take(10)
                  .map(
                    (ask) => {
                      'price': double.parse(ask[0]),
                      'amount': double.parse(ask[1]),
                      'type': 'sell',
                    },
                  ),
            ];
          });
        } else if (data['type'] == 'l2update') {
          setState(() {
            for (var change in data['changes']) {
              final side = change[0] == 'buy' ? 'buy' : 'sell';
              final price = double.parse(change[1]);
              final amount = double.parse(change[2]);
              orderBook.removeWhere(
                (order) => order['price'] == price && order['type'] == side,
              );
              if (amount > 0) {
                orderBook.add({'price': price, 'amount': amount, 'type': side});
              }
            }
            orderBook.sort((a, b) => b['price'].compareTo(a['price']));
            orderBook = orderBook.take(20).toList();
          });
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket closed');
      },
    );
  }

  Future<void> placeOrder(String side) async {
    try {
      final amount = double.tryParse(amountController.text) ?? 0.0;
      final price = double.tryParse(priceController.text);
      final stopPrice = double.tryParse(stopPriceController.text);

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Invalid amount',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }

      if (orderType == 'Limit' && (price == null || price <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Price is required for Limit orders',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }

      if (orderType == 'Stop-Loss' &&
          (price == null ||
              stopPrice == null ||
              price <= 0 ||
              stopPrice <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Price and stop price are required for Stop-Loss orders',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        return;
      }

      if (cryptoWalletId == null || fiatWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Wallet data not loaded. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
        await fetchWallets();
        return;
      }

      final marketPrice = double.parse(currentPrice);
      double cryptoAmount, fiatAmount;
      if (isAmountInCrypto) {
        cryptoAmount = amount;
        fiatAmount = amount * marketPrice;
      } else {
        fiatAmount = amount;
        cryptoAmount = amount / marketPrice;
      }

      final token = await AuthManager().getAuthToken();
      final response = await http.post(
        Uri.parse('$ProductionBaseUrl/api/wallet/placeOrder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cryptoWalletId': cryptoWalletId,
          'fiatWalletId': fiatWalletId,
          'coinName': coinSymbolMap[selectedCoin]?['coinbase'],
          'orderType': orderType,
          'side': side,
          'amount': cryptoAmount,
          'price': orderType == 'Market' ? marketPrice : price,
          'stopPrice': orderType == 'Stop-Loss' ? stopPrice : null,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${orderType ?? 'Market'} $side order placed successfully',
            ),
          ),
        );
        amountController.clear();
        priceController.clear();
        stopPriceController.clear();
        await fetchWallets();
        await fetchSpotOrders(); // Refresh orders after placing a new one
        await fetchTradeHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to place order: ${jsonDecode(response.body)['message']}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error placing order: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to place order')));
    }
  }

  String _getTradingViewHtml(String coinId) {
    final symbol = coinSymbolMap[coinId]?['tradingview'] ?? 'BTCUSD';
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <script src="https://s3.tradingview.com/tv.js"></script>
      </head>
      <body style="margin:0;padding:0;overflow:hidden;">
        <div id="tradingview_chart" style="width:100%;height:100vh;position:absolute;top:0;left:0;"></div>
        <script type="text/javascript">
          new TradingView.widget({
            "container_id": "tradingview_chart",
            "width": "100%",
            "height": "100%",
            "symbol": "COINBASE:$symbol",
            "interval": "60",
            "timezone": "Etc/UTC",
            "theme": "dark",
            "style": "10",
            "locale": "en",
            "toolbar_bg": "#f1f3f6",
            "enable_publishing": false,
            "allow_symbol_change": false,
            "studies": ["STD;Volume"],
            "show_popup_button": true,
            "popup_width": "1000",
            "popup_height": "650"
          });
        </script>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        backgroundColor: Colors.black,
        title: Text(
          '${selectedCoin.toUpperCase()}/USD',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          isCoinLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : DropdownButton<String>(
                  value: selectedCoin,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: Colors.black,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  underline: Container(height: 1, color: Colors.white),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCoin = newValue;
                        isLoading = true;
                        chartErrorMessage = null;
                        fetchCoinPriceList();
                        fetchWallets();
                        fetchSpotOrders(); // Refresh orders when coin changes
                        fetchTradeHistory();
                        _initializeOrderBookWebSocket();
                        _webViewController.loadHtmlString(
                          _getTradingViewHtml(newValue),
                        );
                      });
                    }
                  },
                  items: coinOptions.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$$currentPrice',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            changePercent,
                            style: TextStyle(
                              color: changePercent.contains('-')
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Fiat: \$${fiatBalance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Crypto: ${cryptoBalance.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (chartErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      chartErrorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: 'Chart'),
                    Tab(text: 'Price List'),
                    Tab(text: 'Trade'),
                    Tab(text: 'Order Book'),
                    Tab(text: 'Trade History'),
                    Tab(text: 'My Orders'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Expanded(
                        child: WebViewWidget(controller: _webViewController),
                      ),
                      ListView.builder(
                        itemCount: coinPriceList.length,
                        itemBuilder: (context, index) {
                          final coin = coinPriceList[index];
                          return ListTile(
                            onTap: () {
                              setState(() {
                                selectedCoin = coin['id'];
                                isLoading = true;
                                chartErrorMessage = null;
                                fetchCoinPriceList();
                                fetchWallets();
                                fetchSpotOrders(); // Refresh orders when coin changes
                                fetchTradeHistory();
                                _initializeOrderBookWebSocket();
                                _webViewController.loadHtmlString(
                                  _getTradingViewHtml(selectedCoin),
                                );
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.black,
                              child: Text(
                                coin['symbol'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              coin['name'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '\$${coin['price'].toStringAsFixed(2)} • ${coin['change'].toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: coin['change'] < 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                            trailing: Text(
                              '\$${NumberFormat.compact().format(coin['market_cap'])}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildToggleButton('Market'),
                                _buildToggleButton('Limit'),
                                _buildToggleButton('Stop-Loss'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: amountController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: isAmountInCrypto
                                          ? 'Amount (${coinSymbolMap[selectedCoin]!['coinbase']!.split('-')[0]})'
                                          : 'Amount (USD)',
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    isAmountInCrypto
                                        ? Icons.currency_bitcoin
                                        : Icons.attach_money,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isAmountInCrypto = !isAmountInCrypto;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value:
                                  double.tryParse(amountController.text) ?? 0.0,
                              min: 0.0,
                              max: isAmountInCrypto
                                  ? cryptoBalance
                                  : fiatBalance,
                              divisions: 100,
                              label:
                                  (double.tryParse(amountController.text) ??
                                          0.0)
                                      .toStringAsFixed(2),
                              onChanged: (value) {
                                setState(() {
                                  amountController.text = value.toStringAsFixed(
                                    2,
                                  );
                                });
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white30,
                            ),
                            const SizedBox(height: 16),
                            if (orderType != 'Market')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: priceController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Price (USD)',
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value:
                                        double.tryParse(priceController.text) ??
                                        0.0,
                                    min: 0.0,
                                    max: double.parse(currentPrice) * 2,
                                    divisions: 100,
                                    label:
                                        (double.tryParse(
                                                  priceController.text,
                                                ) ??
                                                0.0)
                                            .toStringAsFixed(2),
                                    onChanged: (value) {
                                      setState(() {
                                        priceController.text = value
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white30,
                                  ),
                                ],
                              ),
                            if (orderType == 'Stop-Loss')
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: stopPriceController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Stop Price (USD)',
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value:
                                        double.tryParse(
                                          stopPriceController.text,
                                        ) ??
                                        0.0,
                                    min: 0.0,
                                    max: double.parse(currentPrice) * 2,
                                    divisions: 100,
                                    label:
                                        (double.tryParse(
                                                  stopPriceController.text,
                                                ) ??
                                                0.0)
                                            .toStringAsFixed(2),
                                    onChanged: (value) {
                                      setState(() {
                                        stopPriceController.text = value
                                            .toStringAsFixed(2);
                                      });
                                    },
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white30,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: isSmallScreen
                                          ? screenWidth * 0.45
                                          : 150,
                                      child: ElevatedButton(
                                        onPressed: () => placeOrder('Buy'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Buy / Long',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4.0,
                                      runSpacing: 4.0,
                                      children: [
                                        _buildPercentageButton(25),
                                        _buildPercentageButton(50),
                                        _buildPercentageButton(75),
                                        _buildPercentageButton(100),
                                      ],
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    SizedBox(
                                      width: isSmallScreen
                                          ? screenWidth * 0.45
                                          : 150,
                                      child: ElevatedButton(
                                        onPressed: () => placeOrder('Sell'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: const Text(
                                          'Sell / Short',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 4.0,
                                      runSpacing: 4.0,
                                      children: [
                                        _buildPercentageButton(25),
                                        _buildPercentageButton(50),
                                        _buildPercentageButton(75),
                                        _buildPercentageButton(100),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        itemCount: orderBook.length,
                        itemBuilder: (context, index) {
                          final order = orderBook[index];
                          return ListTile(
                            title: Text(
                              '\$${order['price'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: order['type'] == 'buy'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Amount: ${order['amount'].toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: tradeHistory.length,
                        itemBuilder: (context, index) {
                          final trade = tradeHistory[index];
                          return ListTile(
                            title: Text(
                              '\$${trade['price'].toStringAsFixed(2)}',
                              style: TextStyle(
                                color: trade['type'] == 'buy'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Amount: ${trade['amount'].toStringAsFixed(2)} • ${DateFormat('HH:mm').format(trade['time'])}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: userOrders.length,
                        itemBuilder: (context, index) {
                          final order = userOrders[index];
                          return ListTile(
                            title: Text(
                              '${order['side']} ${order['orderType']} \$${order['price']?.toStringAsFixed(2) ?? 'Market'}',
                              style: TextStyle(
                                color: order['side'] == 'Buy'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              'Amount: ${order['amount'].toStringAsFixed(2)} • Status: ${order['status']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              DateFormat('HH:mm').format(order['createdAt']),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleButton(String type) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 3.5,
      child: ElevatedButton(
        onPressed: () {
          setState(() => orderType = type);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: orderType == type ? Colors.white : Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: orderType == type ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageButton(int percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: SizedBox(
        width: 40,
        child: ElevatedButton(
          onPressed: () {
            final maxAmount = isAmountInCrypto
                ? cryptoBalance
                : fiatBalance / double.parse(currentPrice);
            final newAmount = (maxAmount * percentage / 100).toStringAsFixed(2);
            setState(() {
              amountController.text = newAmount;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          ),
          child: Text(
            '$percentage%',
            style: const TextStyle(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData(this.time, this.open, this.high, this.low, this.close);
}
