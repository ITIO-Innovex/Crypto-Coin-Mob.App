class CurrencyHelper {
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
    'JPY': '¥',
    'CNY': '¥',
    'KRW': '₩',
    'RUB': '₽',
    'AUD': '\$',
    'CAD': '\$',
    'CHF': 'CHF',
    'BRL': 'R\$',
    'ZAR': 'R',
    'SGD': '\$',
    'MXN': '\$',
    'AED': 'د.إ',
    'SAR': '﷼',
    'TRY': '₺',
    'THB': '฿',
    'NGN': '₦',
    'EGP': '£',
    'PKR': '₨',
    'BDT': '৳',
    'LKR': 'Rs',
    'SEK': 'kr',
    'NOK': 'kr',
    'DKK': 'kr',
    'PLN': 'zł',
    'CZK': 'Kč',
    'HUF': 'Ft',
    'ILS': '₪',
    'MYR': 'RM',
    'IDR': 'Rp',
    'PHP': '₱',
    'VND': '₫',
    'KWD': 'د.ك',
    'QAR': 'ر.ق',
    'OMR': '﷼',
    'JOD': 'د.ا',
  };

  /// Get currency symbol by code
  static String getSymbol(String code) {
    return currencySymbols[code.toUpperCase()] ?? code;
  }

  /// Get list of all currency codes
  static List<String> get currencyList => currencySymbols.keys.toList();
}



String getFlagEmoji(String currencyCode) {
  switch (currencyCode.toUpperCase()) {
    case 'USD': return '🇺🇸';
    case 'EUR': return '🇪🇺';
    case 'GBP': return '🇬🇧';
    case 'INR': return '🇮🇳';
    case 'JPY': return '🇯🇵';
    case 'CNY': return '🇨🇳';
    case 'KRW': return '🇰🇷';
    case 'RUB': return '🇷🇺';
    case 'AUD': return '🇦🇺';
    case 'CAD': return '🇨🇦';
    case 'CHF': return '🇨🇭';
    case 'BRL': return '🇧🇷';
    case 'ZAR': return '🇿🇦';
    case 'SGD': return '🇸🇬';
    case 'MXN': return '🇲🇽';
    case 'AED': return '🇦🇪';
    case 'SAR': return '🇸🇦';
    case 'TRY': return '🇹🇷';
    case 'THB': return '🇹🇭';
    case 'NGN': return '🇳🇬';
    case 'EGP': return '🇪🇬';
    case 'PKR': return '🇵🇰';
    case 'BDT': return '🇧🇩';
    case 'LKR': return '🇱🇰';
    case 'SEK': return '🇸🇪';
    case 'NOK': return '🇳🇴';
    case 'DKK': return '🇩🇰';
    case 'PLN': return '🇵🇱';
    case 'CZK': return '🇨🇿';
    case 'HUF': return '🇭🇺';
    case 'ILS': return '🇮🇱';
    case 'MYR': return '🇲🇾';
    case 'IDR': return '🇮🇩';
    case 'PHP': return '🇵🇭';
    case 'VND': return '🇻🇳';
    case 'KWD': return '🇰🇼';
    case 'QAR': return '🇶🇦';
    case 'OMR': return '🇴🇲';
    case 'JOD': return '🇯🇴';
    default: return '🏳️'; // fallback
  }
}

final Map<String, String> _currencyToCountryCode = {
  'USD': 'us',
  'EUR': 'eu',
  'GBP': 'gb',
  'INR': 'in',
  'JPY': 'jp',
  'CNY': 'cn',
  'KRW': 'kr',
  'RUB': 'ru',
  'AUD': 'au',
  'CAD': 'ca',
  'CHF': 'ch',
  'BRL': 'br',
  'ZAR': 'za',
  'SGD': 'sg',
  'MXN': 'mx',
  'AED': 'ae',
  'SAR': 'sa',
  'TRY': 'tr',
  'THB': 'th',
  'NGN': 'ng',
  'EGP': 'eg',
  'PKR': 'pk',
  'BDT': 'bd',
  'LKR': 'lk',
  'SEK': 'se',
  'NOK': 'no',
  'DKK': 'dk',
  'PLN': 'pl',
  'CZK': 'cz',
  'HUF': 'hu',
  'ILS': 'il',
  'MYR': 'my',
  'IDR': 'id',
  'PHP': 'ph',
  'VND': 'vn',
  'KWD': 'kw',
  'QAR': 'qa',
  'OMR': 'om',
  'JOD': 'jo',
};
