import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinImageProvider {
  static final Map<String, String> _imageCache = {};
  static const String fallbackImage =
      'https://via.placeholder.com/32x32.png?text=?';

  /// Public method to get image URL for a coin
  static Future<String> getImage(String nativeAsset) async {
    if (_imageCache.containsKey(nativeAsset)) {
      return _imageCache[nativeAsset]!;
    }

    final imageUrl = await _fetchFromCoinGecko(nativeAsset);
    final url = imageUrl ?? fallbackImage;

    _imageCache[nativeAsset] = url;
    return url;
  }

  /// Extract symbol and search CoinGecko
  static Future<String?> _fetchFromCoinGecko(String nativeAsset) async {
    try {
      final symbol = _extractSymbol(nativeAsset).toLowerCase();
      final url = Uri.parse(
        'https://api.coingecko.com/api/v3/search?query=$symbol',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coins = data['coins'] as List;

        // Try exact match first
        for (final coin in coins) {
          if ((coin['symbol'] as String).toLowerCase() == symbol) {
            return coin['large'];
          }
        }

        // Otherwise fallback to first result
        if (coins.isNotEmpty) {
          return coins.first['large'];
        }
      }
    } catch (e) {
      print('CoinGecko image fetch failed for $nativeAsset: $e');
    }
    return null;
  }

  /// Extract coin symbol from nativeAsset (e.g., 'BTC_TEST' → 'BTC')
  static String _extractSymbol(String nativeAsset) {
    if (nativeAsset.contains('_')) {
      return nativeAsset.split('_').first;
    }
    return nativeAsset;
  }
}
