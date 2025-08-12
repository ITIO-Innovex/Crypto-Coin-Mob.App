import 'dart:async';

import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/BottomBar.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:flutter/cupertino.dart';
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
  bool isOrdersLoading = false;
  bool isTradeHistoryLoading = false;
  Timer? _timer;
  String selectedCoin = 'bitcoin';
  List<String> coinOptions = []; // Will be populated from user's wallets only
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
  String? ordersErrorMessage;
  String? tradeHistoryErrorMessage;
  WebSocketChannel? _orderBookChannel;
  String? cryptoWalletId;
  String? fiatWalletId;
  double fiatBalance = 0.0;
  double cryptoBalance = 0.0;
  final String? userId = AuthManager().userId;
  bool isAmountInCrypto = true;
  final ApiService _apiService = ApiService();

  // New variables for total coins calculation
  List<CryptoWallet> allWallets = [];
  double totalCoinsValue = 0.0;
  bool isWalletsLoading = true;
  String? walletsErrorMessage;

  // For storing real crypto icons from CoinGecko
  Map<String, String> realCoinIcons = {};

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

  final Map<String, String> coinIcons = {
    'bitcoin': '₿',
    'ethereum': 'Ξ',
    'ripple': '◊',
    'cardano': '₳',
    'solana': '◎',
    'polkadot': '●',
    'dogecoin': 'Ð',
    'binancecoin': '◆',
    'chainlink': '⬡',
    'avalanche-2': '▲',
    'litecoin': 'Ł',
    'ethereum-classic': 'ΞC',
    'eos': '◉',
    'dash': '◈',
    'celestia': '✦',
    'hedera-hashgraph': 'ℏ',
    'tron': '◊',
    'tether': '₮',
  };

  final Map<String, Color> coinColors = {
    'bitcoin': Colors.orange,
    'ethereum': Colors.blue,
    'ripple': Colors.cyan,
    'cardano': Colors.purple,
    'solana': Colors.green,
    'polkadot': Colors.pink,
    'dogecoin': Colors.yellow,
    'binancecoin': Colors.amber,
    'chainlink': Colors.indigo,
    'avalanche-2': Colors.red,
    'litecoin': Colors.grey,
    'ethereum-classic': Colors.teal,
    'eos': Colors.deepPurple,
    'dash': Colors.lightBlue,
    'celestia': Colors.deepOrange,
    'hedera-hashgraph': Colors.lime,
    'tron': Colors.redAccent,
    'tether': Colors.greenAccent,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    fetchCoinPriceList();
    fetchWallets();
    _fetchWallets(); // Fetch all crypto wallets for total calculation and dropdown options
    fetchSpotOrders();
    fetchTradeHistory();
    _initializeOrderBookWebSocket();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      fetchCoinPriceList();
      fetchWallets();
      _fetchWallets(); // Update total coins and dropdown options periodically
      fetchSpotOrders();
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

  // Fetch real crypto icons from CoinGecko API
  Future<void> fetchCoinIcons(List<String> coinIds) async {
    try {
      if (coinIds.isEmpty) return;

      final coinIdsString = coinIds.join(',');
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=$coinIdsString&order=market_cap_desc&per_page=50&page=1&sparkline=false',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          realCoinIcons.clear();
          for (var coin in data) {
            realCoinIcons[coin['id']] = coin['image'];
          }
        });
        print('Fetched ${realCoinIcons.length} coin icons from CoinGecko');
      }
    } catch (e) {
      print('Error fetching coin icons: $e');
    }
  }

  // Update coin options from existing wallet data
  void updateCoinOptionsFromWallets() {
    // Map to convert wallet currency to coin IDs for the dropdown
    final Map<String, String> currencyToCoinId = {
      'BTC': 'bitcoin',
      'BTC_TEST': 'bitcoin',
      'ETH': 'ethereum',
      'ETC': 'ethereum-classic',
      'ETC_TEST': 'ethereum-classic',
      'LTC': 'litecoin',
      'LTC_TEST': 'litecoin',
      'DOGE': 'dogecoin',
      'DOGE_TEST': 'dogecoin',
      'EOS': 'eos',
      'EOS_TEST': 'eos',
      'ADA': 'cardano',
      'ADA_TEST': 'cardano',
      'DASH': 'dash',
      'DASH_TEST': 'dash',
      'CELESTIA': 'celestia',
      'CELESTIA_TEST': 'celestia',
      'HBAR': 'hedera-hashgraph',
      'HBAR_TEST': 'hedera-hashgraph',
      'TRX': 'tron',
      'TRX_TEST': 'tron',
      'SOL': 'solana',
      'USDT': 'tether',
    };

    setState(() {
      // Extract unique coin IDs from existing allWallets data
      final walletCurrencies = allWallets
          .map((wallet) => wallet.currency)
          .toSet();
      coinOptions = walletCurrencies
          .map(
            (currency) => currencyToCoinId[currency] ?? currency.toLowerCase(),
          )
          .where((coinId) => coinId.isNotEmpty) // Remove empty values
          .toSet() // Remove duplicates
          .toList();

      isCoinLoading = false;

      print('User wallet currencies: $walletCurrencies');
      print('Mapped coin options: $coinOptions');

      // If current selected coin is not in user's wallets, select the first available
      if (!coinOptions.contains(selectedCoin) && coinOptions.isNotEmpty) {
        selectedCoin = coinOptions[0];
        _webViewController.loadHtmlString(_getTradingViewHtml(selectedCoin));
      }

      // Only show message if user has no wallets
      if (coinOptions.isEmpty) {
        print('No crypto wallets found for user');
      }
    });

    // Fetch real icons for user's coins only
    if (coinOptions.isNotEmpty) {
      fetchCoinIcons(coinOptions);
    }
  }

  Future<void> fetchCoinPriceList() async {
    try {
      // Create a comma-separated list of coin IDs from user's wallets
      final coinIds = coinOptions.join(',');

      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=$coinIds&order=market_cap_desc&per_page=50&page=1&sparkline=false',
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
              .toList();

          // Update current price and change for selected coin
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
            orElse: () => {'balance': 0.0, '_id': null},
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
      } else {
        print(
          'Failed to fetch wallets: Crypto ${cryptoResponse.statusCode}, Fiat ${fiatResponse.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching wallets: $e');
    }
  }

  // New method to fetch all crypto wallets and calculate total coins
  Future<void> _fetchWallets() async {
    setState(() {
      isWalletsLoading = true;
      walletsErrorMessage = null;
      isCoinLoading = true; // Also show loading for dropdown
    });

    try {
      final wallets = await _apiService.getCryptoWalletBalances();

      setState(() {
        allWallets = wallets;
        // Calculate total coins value by summing all wallet balances
        totalCoinsValue = wallets.fold(
          0.0,
          (sum, wallet) => sum + wallet.balance,
        );
        isWalletsLoading = false;
      });

      print(
        'Fetched ${wallets.length} wallets with total value: $totalCoinsValue',
      );

      // Update coin options for dropdown from fetched wallets
      updateCoinOptionsFromWallets();
    } catch (e) {
      print('Error fetching all wallets: $e');
      setState(() {
        allWallets = [];
        totalCoinsValue = 0.0;
        isWalletsLoading = false;
        walletsErrorMessage = 'Failed to load wallet data: ${e.toString()}';
        isCoinLoading = false;
        coinOptions = []; // Clear coin options on error
      });
    }
  }

  Future<void> fetchSpotOrders() async {
    setState(() {
      isOrdersLoading = true;
      ordersErrorMessage = null;
    });
    try {
      final orders = await _apiService.fetchSpotOrders();
      print('Raw orders from API: $orders');
      setState(() {
        userOrders = orders
            .map(
              (order) => {
                'side': order.side,
                'orderType': order.orderType,
                'price': order.price,
                'amount': order.amount,
                'status': order.status,
                'createdAt': order.createdAt,
              },
            )
            .toList();
        isOrdersLoading = false;
        print('Parsed userOrders: $userOrders');
        if (userOrders.isEmpty) {
          print('No orders found for user');
        }
      });
    } catch (e) {
      print('Error fetching spot orders: $e');
      setState(() {
        userOrders = [];
        isOrdersLoading = false;
        ordersErrorMessage = 'Failed to load orders: $e';
      });
    }
  }

  Future<void> fetchTradeHistory() async {
    setState(() {
      isTradeHistoryLoading = true;
      tradeHistoryErrorMessage = null;
    });
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.get(
        Uri.parse('$ProductionBaseUrl/api/wallet/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(
        'Trade History Response: ${response.statusCode} ${response.body}',
      ); // Debug
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final coinbasePair =
            coinSymbolMap[selectedCoin]?['coinbase'] ?? 'BTC-USD';
        print('Filtering tradeHistory for coin: $coinbasePair'); // Debug
        setState(() {
          tradeHistory = data.where((tx) => tx['currency'] == coinbasePair).map(
            (tx) {
              final fiatAmount = tx['fiatAmount'] as num? ?? 0;
              final amount = tx['amount'] as num? ?? 1;
              return {
                'time': DateTime.parse(tx['createdAt'] as String),
                'price': fiatAmount / amount,
                'amount': amount,
                'type': tx['type'] as String? ?? 'Unknown',
              };
            },
          ).toList();
          isTradeHistoryLoading = false;
          print('Fetched tradeHistory: $tradeHistory'); // Debug
        });
      } else {
        throw Exception(
          'Failed to fetch trade history: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching trade history: $e');
      setState(() {
        tradeHistory = [];
        isTradeHistoryLoading = false;
        tradeHistoryErrorMessage = 'Failed to load trade history: $e';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
        return;
      }

      if (orderType == 'Limit' && (price == null || price <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price is required for Limit orders')),
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
            content: Text(
              'Price and stop price are required for Stop-Loss orders',
            ),
          ),
        );
        return;
      }

      if (cryptoWalletId == null || fiatWalletId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wallet data not loaded. Please try again.'),
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
          SnackBar(content: Text('$orderType $side order placed successfully')),
        );
        amountController.clear();
        priceController.clear();
        stopPriceController.clear();
        await fetchWallets();
        await fetchSpotOrders();
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
    // Try to get symbol from coinSymbolMap first, otherwise create a generic one
    String symbol;
    if (coinSymbolMap.containsKey(coinId)) {
      symbol = coinSymbolMap[coinId]!['tradingview']!;
    } else {
      // For coins not in the map, try to create a symbol from the coin data
      final coinData = coinPriceList.firstWhere(
        (coin) => coin['id'] == coinId,
        orElse: () => {'symbol': coinId.toUpperCase()},
      );
      final coinSymbol = coinData['symbol'].toString().toUpperCase();
      symbol = '${coinSymbol}USD';
    }
    final html =
        '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width,initial-scale=1.0">
          <script src="https://s3.tradingview.com/tv.js"></script>
        </head>
        <body style="margin:0;padding:0;overflow:hidden">
          <div id="tradingview_chart" style="width:100%;height:100vh;position:absolute;top:0;left:0"></div>
          <script>
            new TradingView.widget({
              "container_id": "tradingview_chart",
              "width": "100%",
              "height": "100%",
              "symbol": "COINBASE:$symbol",
              "interval": "1",
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
    print('Generated HTML for $coinId: $symbol'); // Debug
    return html;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;
    final isTablet = screenWidth >= 768;

    // Responsive dimensions
    final appBarHeight = isSmallScreen ? 56.0 : (isMediumScreen ? 60.0 : 64.0);
    final iconSize = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 28.0);
    final titleFontSize = isSmallScreen ? 14.0 : (isMediumScreen ? 16.0 : 18.0);
    final horizontalPadding = isSmallScreen
        ? 8.0
        : (isMediumScreen ? 12.0 : 16.0);
    final verticalPadding = isSmallScreen ? 4.0 : (isMediumScreen ? 6.0 : 8.0);
    final cardPadding = isSmallScreen ? 8.0 : (isMediumScreen ? 12.0 : 16.0);
    final borderRadius = isSmallScreen ? 8.0 : (isMediumScreen ? 10.0 : 12.0);
    final fontSize = isSmallScreen ? 12.0 : (isMediumScreen ? 14.0 : 16.0);
    final smallFontSize = isSmallScreen ? 10.0 : (isMediumScreen ? 12.0 : 14.0);
    final largeFontSize = isSmallScreen ? 18.0 : (isMediumScreen ? 22.0 : 26.0);
    final priceFontSize = isSmallScreen ? 20.0 : (isMediumScreen ? 24.0 : 28.0);

    return Scaffold(
      backgroundColor: Colors.black,
    appBar: PreferredSize(
  preferredSize: Size.fromHeight(kToolbarHeight + 40),
  child: AppBar(
    backgroundColor: Colors.black,
    leading: IconButton(
      icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
      onPressed: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => MainScreen()),
      ),
    ),
    title: Row(
      mainAxisSize: MainAxisSize.max, // ensure bounded width
      children: [
        _buildCryptoIcon(selectedCoin, size: iconSize),
        SizedBox(width: isSmallScreen ? 6 : 8),
        Expanded(
          child: Text(
            () {
              final coinData = coinPriceList.firstWhere(
                (coin) => coin['id'] == selectedCoin,
                orElse: () => {'symbol': selectedCoin.toUpperCase()},
              );
              return '${coinData['symbol'].toString().toUpperCase()}/USD';
            }(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: titleFontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    actions: [
      // Loader while fetching coin
      if (isCoinLoading)
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
          child: SizedBox(
            width: isSmallScreen ? 16 : 20,
            height: isSmallScreen ? 16 : 20,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        )
      else
        Container(
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 8,
            vertical: isSmallScreen ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: coinOptions.isNotEmpty &&
                      coinOptions.contains(selectedCoin)
                  ? selectedCoin
                  : (coinOptions.isNotEmpty ? coinOptions.first : null),
              hint: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    coinOptions.isEmpty
                        ? Icons.wallet
                        : Icons.currency_bitcoin,
                    color: Colors.white,
                    size: isSmallScreen ? 14 : 16,
                  ),
                  SizedBox(width: isSmallScreen ? 2 : 4),
                  if (!isSmallScreen || coinOptions.isEmpty)
                    Text(
                      coinOptions.isEmpty ? 'No wallets' : 'Select coin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmallScreen ? 10 : 12,
                      ),
                    ),
                ],
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: isSmallScreen ? 16 : 20,
              ),
              dropdownColor: Colors.grey[900],
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              borderRadius: BorderRadius.circular(8),
              menuMaxHeight: isSmallScreen ? 250 : 300,
              isDense: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedCoin = newValue;
                    isLoading = true;
                    chartErrorMessage = null;
                    ordersErrorMessage = null;
                    tradeHistoryErrorMessage = null;
                    fetchCoinPriceList();
                    fetchWallets();
                    _fetchWallets();
                    fetchSpotOrders();
                    fetchTradeHistory();
                    _initializeOrderBookWebSocket();
                    _webViewController.loadHtmlString(
                      _getTradingViewHtml(newValue),
                    );
                  });
                }
              },
              items: coinOptions.isNotEmpty
                  ? coinOptions.map<DropdownMenuItem<String>>((String value) {
                      final coinData = coinPriceList.firstWhere(
                        (coin) => coin['id'] == value,
                        orElse: () => {
                          'name': value.toUpperCase(),
                          'symbol': value.toUpperCase(),
                        },
                      );
                      final displayName =
                          '${coinData['symbol'].toString().toUpperCase()}';

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isSmallScreen ? 150 : 200,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCryptoIcon(
                                value,
                                size: isSmallScreen ? 16 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList()
                  : [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.wallet,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'No wallets found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        ),
      // Wallet count indicator
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 6,
          vertical: isSmallScreen ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: coinOptions.isNotEmpty
              ? Colors.green.withOpacity(0.2)
              : Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wallet,
              size: isSmallScreen ? 8 : 10,
              color: coinOptions.isNotEmpty ? Colors.green : Colors.red,
            ),
            SizedBox(width: isSmallScreen ? 1 : 2),
            Text(
              '${coinOptions.length}',
              style: TextStyle(
                color: coinOptions.isNotEmpty ? Colors.green : Colors.red,
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: isSmallScreen ? 4 : 8),
    ],
  ),
),


      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: isLoading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                key: const ValueKey('content'),
                children: [
                  Container(
                    padding: EdgeInsets.all(horizontalPadding),
                    color: Colors.black,
                    child: isSmallScreen
                        ? Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$$currentPrice',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 20 : 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        changePercent,
                                        style: TextStyle(
                                          color: changePercent.contains('-')
                                              ? Colors.red
                                              : Colors.green,
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Fiat: \$${fiatBalance.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                      Text(
                                        'Crypto: ${cryptoBalance.toStringAsFixed(6)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isSmallScreen ? 12 : 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$$currentPrice',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLargeScreen ? 28 : 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    changePercent,
                                    style: TextStyle(
                                      color: changePercent.contains('-')
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: isLargeScreen ? 18 : 16,
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
                    isScrollable:
                        true, // Make tabs scrollable to show full text
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ), // Add padding
                    tabs: const [
                      Tab(text: 'Chart'),
                      Tab(text: 'Price List'),
                      Tab(text: 'Trade'),
                      Tab(text: 'My Orders'),
                      Tab(text: 'Trade History'),
                      Tab(text: 'Order Book'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        SizedBox.expand(
                          child: WebViewWidget(controller: _webViewController),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: ListView.builder(
                            key: const ValueKey('price_list'),
                            itemCount: coinPriceList.length,
                            itemBuilder: (context, index) {
                              final coin = coinPriceList[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedCoin == coin['id']
                                      ? (coinColors[coin['id']] ?? Colors.white)
                                            .withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: selectedCoin == coin['id']
                                      ? Border.all(
                                          color:
                                              (coinColors[coin['id']] ??
                                                      Colors.white)
                                                  .withOpacity(0.3),
                                          width: 1,
                                        )
                                      : null,
                                ),
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      selectedCoin = coin['id'];
                                      isLoading = true;
                                      chartErrorMessage = null;
                                      ordersErrorMessage = null;
                                      tradeHistoryErrorMessage = null;
                                      fetchCoinPriceList();
                                      fetchWallets();
                                      fetchSpotOrders();
                                      fetchTradeHistory();
                                      _initializeOrderBookWebSocket();
                                      _webViewController.loadHtmlString(
                                        _getTradingViewHtml(selectedCoin),
                                      );
                                    });
                                  },
                                  leading: _buildCryptoIcon(
                                    coin['id'],
                                    size: 40,
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
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '\$${NumberFormat.compact().format(coin['market_cap'])}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (selectedCoin == coin['id'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (coinColors[coin['id']] ??
                                                        Colors.white)
                                                    .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Text(
                                            'Selected',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.only(
                            bottom: 20,
                          ), // Add bottom padding to prevent overflow
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildToggleButton('Market'),
                                    _buildToggleButton('Limit'),
                                    _buildToggleButton('Stop-Loss'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildOrderTypeInfo(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: amountController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: isAmountInCrypto
                                              ? 'Amount (${coinSymbolMap[selectedCoin]?['coinbase']?.split('-')[0] ?? 'BTC'})'
                                              : 'Amount (USD)',
                                          helperText: isAmountInCrypto
                                              ? 'Available: ${cryptoBalance.toStringAsFixed(6)} ${coinSymbolMap[selectedCoin]?['coinbase']?.split('-')[0] ?? 'BTC'}'
                                              : 'Available: \$${fiatBalance.toStringAsFixed(2)} USD',
                                          helperStyle: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                          suffixIcon: Tooltip(
                                            message:
                                                'Tap the icon to switch between crypto and USD amounts',
                                            child: const Icon(
                                              Icons.swap_horiz,
                                              color: Colors.white60,
                                              size: 18,
                                            ),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black26,
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.white30,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                      (double.tryParse(amountController.text) ??
                                              0.0)
                                          .clamp(
                                            0.0,
                                            (isAmountInCrypto
                                                        ? cryptoBalance
                                                        : fiatBalance) >
                                                    0.0
                                                ? (isAmountInCrypto
                                                      ? cryptoBalance
                                                      : fiatBalance)
                                                : 1.0,
                                          ),
                                  min: 0.0,
                                  max:
                                      (isAmountInCrypto
                                              ? cryptoBalance
                                              : fiatBalance) >
                                          0.0
                                      ? (isAmountInCrypto
                                            ? cryptoBalance
                                            : fiatBalance)
                                      : 1.0,
                                  divisions: 100,
                                  label:
                                      (double.tryParse(amountController.text) ??
                                              0.0)
                                          .toStringAsFixed(2),
                                  onChanged:
                                      (isAmountInCrypto
                                              ? cryptoBalance
                                              : fiatBalance) >
                                          0.0
                                      ? (value) {
                                          setState(() {
                                            amountController.text = value
                                                .toStringAsFixed(2);
                                          });
                                        }
                                      : null,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white30,
                                ),
                                const SizedBox(height: 16),
                                if (orderType != 'Market')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: priceController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Limit Price (USD)',
                                          helperText:
                                              'Order executes only at this price or better',
                                          helperStyle: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                          suffixIcon: Tooltip(
                                            message:
                                                'Current price: \$${currentPrice}\nSet lower to buy cheaper, higher to sell for more',
                                            child: const Icon(
                                              Icons.help_outline,
                                              color: Colors.white60,
                                              size: 18,
                                            ),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black26,
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.white30,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 8),
                                      Slider(
                                        value:
                                            (double.tryParse(
                                                      priceController.text,
                                                    ) ??
                                                    0.0)
                                                .clamp(
                                                  0.0,
                                                  (double.tryParse(
                                                                currentPrice,
                                                              ) ??
                                                              0.0) >
                                                          0.0
                                                      ? (double.tryParse(
                                                                  currentPrice,
                                                                ) ??
                                                                0.0) *
                                                            2
                                                      : 1.0,
                                                ),
                                        min: 0.0,
                                        max:
                                            (double.tryParse(currentPrice) ??
                                                    0.0) >
                                                0.0
                                            ? (double.tryParse(currentPrice) ??
                                                      0.0) *
                                                  2
                                            : 1.0,
                                        divisions: 100,
                                        label:
                                            (double.tryParse(
                                                      priceController.text,
                                                    ) ??
                                                    0.0)
                                                .toStringAsFixed(2),
                                        onChanged:
                                            (double.tryParse(currentPrice) ??
                                                    0.0) >
                                                0.0
                                            ? (value) {
                                                setState(() {
                                                  priceController.text = value
                                                      .toStringAsFixed(2);
                                                });
                                              }
                                            : null,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                      ),
                                    ],
                                  ),
                                if (orderType == 'Stop-Loss')
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: stopPriceController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Stop Price (USD)',
                                          helperText:
                                              'Sell automatically when price drops to this level',
                                          helperStyle: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 11,
                                          ),
                                          suffixIcon: Tooltip(
                                            message:
                                                'Current price: \$${currentPrice}\nSet below current price to limit losses\nRecommended: 5-10% below current price',
                                            child: const Icon(
                                              Icons.help_outline,
                                              color: Colors.white60,
                                              size: 18,
                                            ),
                                          ),
                                          labelStyle: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                          filled: true,
                                          fillColor: Colors.black26,
                                          border: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: Colors.white30,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 8),
                                      // Quick preset buttons for stop-loss percentages
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildStopLossPresetButton(
                                            '5%',
                                            0.95,
                                          ),
                                          _buildStopLossPresetButton(
                                            '10%',
                                            0.90,
                                          ),
                                          _buildStopLossPresetButton(
                                            '15%',
                                            0.85,
                                          ),
                                          _buildStopLossPresetButton(
                                            '20%',
                                            0.80,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Slider(
                                        value:
                                            (double.tryParse(
                                                      stopPriceController.text,
                                                    ) ??
                                                    0.0)
                                                .clamp(
                                                  0.0,
                                                  (double.tryParse(
                                                                currentPrice,
                                                              ) ??
                                                              0.0) >
                                                          0.0
                                                      ? (double.tryParse(
                                                                  currentPrice,
                                                                ) ??
                                                                0.0) *
                                                            2
                                                      : 1.0,
                                                ),
                                        min: 0.0,
                                        max:
                                            (double.tryParse(currentPrice) ??
                                                    0.0) >
                                                0.0
                                            ? (double.tryParse(currentPrice) ??
                                                      0.0) *
                                                  2
                                            : 1.0,
                                        divisions: 100,
                                        label:
                                            (double.tryParse(
                                                      stopPriceController.text,
                                                    ) ??
                                                    0.0)
                                                .toStringAsFixed(2),
                                        onChanged:
                                            (double.tryParse(currentPrice) ??
                                                    0.0) >
                                                0.0
                                            ? (value) {
                                                setState(() {
                                                  stopPriceController.text =
                                                      value.toStringAsFixed(2);
                                                });
                                              }
                                            : null,
                                        activeColor: Colors.white,
                                        inactiveColor: Colors.white30,
                                      ),
                                      const SizedBox(height: 8),
                                      // Warning message for stop-loss
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Stop-loss orders may not execute at exact price during high volatility',
                                                style: const TextStyle(
                                                  color: Colors.orange,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 16),
                                _buildSmartSuggestions(),
                                const SizedBox(height: 16),
                                _buildRiskIndicator(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  placeOrder('Buy'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  placeOrder('Sell'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
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
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isOrdersLoading
                              ? const Center(
                                  key: ValueKey('my_orders_loading'),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : ordersErrorMessage != null
                              ? Center(
                                  key: const ValueKey('my_orders_error'),
                                  child: Text(
                                    ordersErrorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : userOrders.isEmpty
                              ? const Center(
                                  key: ValueKey('my_orders_empty'),
                                  child: Text(
                                    'No orders available',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('my_orders_list'),
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
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      trailing: Text(
                                        DateFormat('HH:mm').format(
                                          order['createdAt'] as DateTime,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isTradeHistoryLoading
                              ? const Center(
                                  key: ValueKey('trade_history_loading'),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : tradeHistoryErrorMessage != null
                              ? Center(
                                  key: const ValueKey('trade_history_error'),
                                  child: Text(
                                    tradeHistoryErrorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : tradeHistory.isEmpty
                              ? const Center(
                                  key: ValueKey('trade_history_empty'),
                                  child: Text(
                                    'No trade history available',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('trade_history_list'),
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
                                        'Amount: ${trade['amount'].toStringAsFixed(2)} • ${DateFormat('HH:mm').format(trade['time'] as DateTime)}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: orderBook.isEmpty
                              ? const Center(
                                  key: ValueKey('order_book_empty'),
                                  child: Text(
                                    'No order book data available',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  key: const ValueKey('order_book_list'),
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
                                      trailing: Text(
                                        order['amount'].toStringAsFixed(2),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTradingGuide(context),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors
                  .blueGrey // Dark mode FAB color
            : Colors.white, // Light mode FAB color
        child: Icon(
          Icons.help_outline,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
        tooltip: 'Trading Guide & Help',
      ),
    );
  }

  void _showTradingGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📚 Trading Guide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGuideSection(
                          'Market Order',
                          'Executes immediately at the best available price',
                          [
                            'Pros: Instant execution, guaranteed fill',
                            'Cons: Price may vary due to market volatility',
                            'Best for: Quick trades, high liquidity coins',
                            'Use when: You want to buy/sell immediately',
                          ],
                          Colors.green,
                        ),
                        const SizedBox(height: 16),
                        _buildGuideSection(
                          'Limit Order',
                          'Only executes at your specified price or better',
                          [
                            'Pros: Price control, better entry/exit points',
                            'Cons: May not execute if price doesn\'t reach limit',
                            'Best for: Patient traders, volatile markets',
                            'Use when: You have a target price in mind',
                          ],
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildGuideSection(
                          'Stop-Loss Order',
                          'Automatically sells when price drops to protect losses',
                          [
                            'Pros: Risk management, emotional protection',
                            'Cons: May trigger during temporary dips',
                            'Best for: Risk-averse traders, volatile assets',
                            'Use when: You want to limit potential losses',
                          ],
                          Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.yellow.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb,
                                    color: Colors.yellow,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Pro Tips',
                                    style: TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '• Start with small amounts to learn\n'
                                '• Set stop-losses 5-10% below entry price\n'
                                '• Use limit orders in volatile markets\n'
                                '• Never invest more than you can afford to lose\n'
                                '• Research before trading any cryptocurrency',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartSuggestions() {
    // Get current price change to provide contextual suggestions
    final priceChange =
        double.tryParse(changePercent.replaceAll('%', '')) ?? 0.0;
    final currentPriceValue = double.tryParse(currentPrice) ?? 0.0;

    String suggestion = '';
    String tip = '';
    Color suggestionColor = Colors.blue;
    IconData suggestionIcon = Icons.lightbulb_outline;

    if (priceChange > 5) {
      suggestion = 'Price is up ${changePercent}!';
      tip =
          'Consider setting a stop-loss to protect gains, or wait for a pullback to buy more.';
      suggestionColor = Colors.green;
      suggestionIcon = Icons.trending_up;
    } else if (priceChange < -5) {
      suggestion = 'Price is down ${changePercent}';
      tip =
          'This might be a buying opportunity, but consider using limit orders for better entry.';
      suggestionColor = Colors.red;
      suggestionIcon = Icons.trending_down;
    } else if (orderType == 'Market') {
      suggestion = 'Market Order Selected';
      tip =
          'You\'ll buy/sell immediately at current price (\$${currentPrice}). Good for quick trades!';
      suggestionColor = Colors.green;
      suggestionIcon = Icons.flash_on;
    } else if (orderType == 'Limit') {
      suggestion = 'Limit Order Selected';
      tip =
          'Set your target price. Order executes only when market reaches your price or better.';
      suggestionColor = Colors.blue;
      suggestionIcon = Icons.gps_fixed;
    } else if (orderType == 'Stop-Loss') {
      suggestion = 'Stop-Loss Order Selected';
      tip =
          'Recommended: Set stop price 5-10% below current price (\$${(currentPriceValue * 0.9).toStringAsFixed(2)} - \$${(currentPriceValue * 0.95).toStringAsFixed(2)})';
      suggestionColor = Colors.red;
      suggestionIcon = Icons.security;
    }

    if (suggestion.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: suggestionColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: suggestionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(suggestionIcon, color: suggestionColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion,
                  style: TextStyle(
                    color: suggestionColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator() {
    final amountValue = double.tryParse(amountController.text) ?? 0.0;
    final maxAmount = isAmountInCrypto ? cryptoBalance : fiatBalance;
    final percentage = maxAmount > 0 ? (amountValue / maxAmount) * 100 : 0.0;

    String riskLevel = '';
    Color riskColor = Colors.green;
    IconData riskIcon = Icons.check_circle;

    if (percentage <= 25) {
      riskLevel = 'Low Risk';
      riskColor = Colors.green;
      riskIcon = Icons.check_circle;
    } else if (percentage <= 50) {
      riskLevel = 'Moderate Risk';
      riskColor = Colors.orange;
      riskIcon = Icons.warning;
    } else if (percentage <= 75) {
      riskLevel = 'High Risk';
      riskColor = Colors.red;
      riskIcon = Icons.error;
    } else {
      riskLevel = 'Very High Risk';
      riskColor = Colors.red.shade900;
      riskIcon = Icons.dangerous;
    }

    if (amountValue <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: riskColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(riskIcon, color: riskColor, size: 16),
              const SizedBox(width: 6),
              Text(
                riskLevel,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            '${percentage.toStringAsFixed(1)}% of balance',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoIcon(
    String coinId, {
    double size = 24,
    bool showBorder = true,
  }) {
    final realIconUrl = realCoinIcons[coinId];
    final fallbackIcon =
        coinIcons[coinId] ?? coinId.substring(0, 1).toUpperCase();
    final color = coinColors[coinId] ?? Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: realIconUrl != null ? Colors.white : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: showBorder
            ? Border.all(
                color: color.withOpacity(0.5),
                width: size > 20 ? 1 : 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: realIconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image.network(
                realIconUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to text icon if image fails to load
                  return Center(
                    child: Text(
                      fallbackIcon,
                      style: TextStyle(
                        color: color,
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.6,
                      height: size * 0.6,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        color: color,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            )
          : Center(
              child: Text(
                fallbackIcon,
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildGuideSection(
    String title,
    String description,
    List<String> points,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                point,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String type) {
    String tooltip = '';
    IconData? icon;
    Color? selectedColor;

    switch (type) {
      case 'Market':
        tooltip = 'Execute immediately at current market price';
        icon = Icons.flash_on;
        selectedColor = Colors.green;
        break;
      case 'Limit':
        tooltip = 'Execute only when price reaches your specified limit';
        icon = Icons.gps_fixed;
        selectedColor = Colors.blue;
        break;
      case 'Stop-Loss':
        tooltip = 'Sell automatically when price drops to protect from losses';
        icon = Icons.security;
        selectedColor = Colors.red;
        break;
    }

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3.5,
        child: ElevatedButton(
          onPressed: () => setState(() => orderType = type),
          style: ElevatedButton.styleFrom(
            backgroundColor: orderType == type ? selectedColor : Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: orderType == type
                  ? BorderSide(color: selectedColor!, width: 2)
                  : const BorderSide(color: Colors.white24, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: orderType == type ? 4 : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: orderType == type ? Colors.white : Colors.white70,
                  size: 16,
                ),
              const SizedBox(height: 2),
              Text(
                type,
                style: TextStyle(
                  color: orderType == type ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: orderType == type
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeInfo() {
    String title = '';
    String description = '';
    String example = '';
    Color cardColor = Colors.black26;
    IconData icon = Icons.info;

    switch (orderType) {
      case 'Market':
        title = 'Market Order';
        description =
            'Executes immediately at the current market price. Best for quick trades when you want to buy/sell right now.';
        example = 'Example: Buy Bitcoin at current price (\$${currentPrice})';
        cardColor = Colors.green.withOpacity(0.1);
        icon = Icons.flash_on;
        break;
      case 'Limit':
        title = 'Limit Order';
        description =
            'Only executes when the price reaches your specified limit. Good for getting a better price.';
        example =
            'Example: Buy Bitcoin only if price drops to \$${(double.parse(currentPrice) * 0.95).toStringAsFixed(2)}';
        cardColor = Colors.blue.withOpacity(0.1);
        icon = Icons.gps_fixed;
        break;
      case 'Stop-Loss':
        title = 'Stop-Loss Order';
        description =
            'Protects your investment by selling when price drops to your stop price, limiting losses.';
        example =
            'Example: Sell Bitcoin if price falls to \$${(double.parse(currentPrice) * 0.90).toStringAsFixed(2)} to limit losses';
        cardColor = Colors.red.withOpacity(0.1);
        icon = Icons.security;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              example,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopLossPresetButton(String label, double multiplier) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: ElevatedButton(
          onPressed: () {
            final currentPriceValue = double.parse(currentPrice);
            final stopPrice = (currentPriceValue * multiplier).toStringAsFixed(
              2,
            );
            setState(() {
              stopPriceController.text = stopPrice;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${(double.parse(currentPrice) * multiplier).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
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
