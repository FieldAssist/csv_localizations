import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// [CsvLocalizations] is used to load translations from a CSV file.
class CsvLocalizations {
  /// Map of translations per languageCode
  final Map<String, Map<String, String>> _translationsMap = {};

  /// A key of language / country code used for [_translationsMap]
  late String _langTag;

  /// [CsvLocalizations] constructor.
  CsvLocalizations._();

  /// [CsvLocalizations] instance.
  static final instance = CsvLocalizations._();

  /// configure eol before [load]
  String eol = '\n';

  /// Load the CSV file and add translations per language.
  Future<CsvLocalizations> load(
    Locale locale,
    AssetBundle bundle,
    String path, {
    String? fallbackPath,
    VoidCallback? onFallbackCall,
  }) async {
    try {
      final result = await _loadCsvLocalisations(locale, bundle, path);
      return result;
    } catch (e) {
      if (fallbackPath != null) {
        onFallbackCall?.call();
        return _loadCsvLocalisations(locale, bundle, fallbackPath);
      } else {
        rethrow;
      }
    }
  }

  Future<CsvLocalizations> _loadCsvLocalisations(
      Locale locale, AssetBundle bundle, String path) async {
    _langTag = locale.toLanguageTag();
    final csvDoc = await bundle.loadString(path);
    final rows = CsvToListConverter(eol: eol).convert(csvDoc);
    final languages = List<String>.from(rows.first);
    _translationsMap.addEntries(languages.map((e) => MapEntry(e, {})));
    for (int i = 0; i < languages.length; i++) {
      final String languageCode = languages[i];
      for (final List row in rows) {
        final String key = row.first;
        final String value = row[i];
        _translationsMap[languageCode]![key] = value;
      }
    }
    return this;
  }

  /// Return true if the [locale] is supported.
  bool isSupported(Locale locale) {
    return true;
    // TODO this does not work, because the CSV file is not loaded yet
    //return _translationsMap.containsKey(locale.toLanguageTag());
  }

  /// Get the translation for the given [key].
  String string(String key) {
    return _translationsMap[_langTag]![key]!;
  }
}

/// A [LocalizationsDelegate] that uses [CsvLocalizations] to load translations.
///
/// The CSV file must have the following format:
///   - The first row is the list of languages.
///   - The first column is the translation keys.
///   - The other columns are the translations per language.
class CsvLocalizationsDelegate extends LocalizationsDelegate<CsvLocalizations> {
  final String path;
  final AssetBundle? assetBundle;
  final String? fallbackPath;

  /// It called when fallback path is used.
  final VoidCallback? onFallbackCall;

  const CsvLocalizationsDelegate({
    required this.path,
    this.assetBundle,
    this.fallbackPath,
    this.onFallbackCall,
  });

  @override
  bool isSupported(Locale locale) =>
      CsvLocalizations.instance.isSupported(locale);

  @override
  Future<CsvLocalizations> load(Locale locale) =>
      CsvLocalizations.instance.load(
        locale,
        assetBundle ?? rootBundle,
        path,
        fallbackPath: fallbackPath,
        onFallbackCall: onFallbackCall,
      );

  @override
  bool shouldReload(CsvLocalizationsDelegate old) => false;
}
