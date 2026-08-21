import 'language_notifier.dart';
import 'localization_data.dart';

class StringHelper {
  static String _get(String key) {
    final code = LanguageNotifier.languageCode.value;
    return LocalizationData.data[code]?[key] ?? LocalizationData.data['en']?[key] ?? key;
  }

  static String get appName => _get('appName');
  static String get version => 'v1.0.0';
  static String get success => _get('success');
  static String get error => _get('error');
  static String get ok => _get('ok');
  static String get cancel => _get('cancel');
  static String get loading => _get('loading');

  // Home Screen
  static String get downloadTitle => _get('downloadTitle');
  static String get downloadSubtitle => _get('downloadSubtitle');
  static String get pasteUrlHint => _get('pasteUrlHint');
  static String get pasteLinkBtn => _get('pasteLinkBtn');
  static String get clearTextBtn => _get('clearTextBtn');
  static String get downloadBtn => _get('downloadBtn');
  static String get downloaderBtn => _get('downloaderBtn');
  static String get platforms => _get('platforms');
  static String get mediaTools => _get('mediaTools');
  static String get seeAll => _get('seeAll');
  static String get mediaToolsSubtitle => _get('mediaToolsSubtitle');

  // Platforms
  static String get instagram => 'Instagram';
  static String get facebook => 'Facebook';
  static String get tiktok => 'TikTok';
  static String get youtube => 'YouTube';
  static String get other => _get('other');

  // Tools
  static String get removeWatermark => _get('removeWatermark');
  static String get removeWatermarkDesc => _get('removeWatermarkDesc');
  static String get addWatermark => _get('addWatermark');
  static String get addWatermarkDesc => _get('addWatermarkDesc');
  static String get trimVideo => _get('trimVideo');
  static String get trimVideoDesc => _get('trimVideoDesc');
  static String get convertFormat => _get('convertFormat');
  static String get convertFormatDesc => _get('convertFormatDesc');
  static String get compress => _get('compress');
  static String get compressDesc => _get('compressDesc');
  static String get removeAudio => _get('removeAudio');
  static String get removeAudioDesc => _get('removeAudioDesc');
  static String get muteVideo => _get('muteVideo');
  static String get muteVideoDesc => _get('muteVideoDesc');
  static String get extractMp3 => _get('extractMp3');
  static String get extractMp3Desc => _get('extractMp3Desc');

  // Trim Screen
  static String get chooseSource => _get('chooseSource');
  static String get pickSourceDesc => _get('pickSourceDesc');
  static String get uploadFromGallery => _get('uploadFromGallery');
  static String get failedToLoadVideo => _get('failedToLoadVideo');
  static String get or => _get('or');
  static String get downloading => _get('downloading');
  static String get processing => _get('processing');
  static String get loadFromUrl => _get('loadFromUrl');
  static String get generatingPreview => _get('generatingPreview');
  static String get startTimeLabel => _get('startTimeLabel');
  static String get endTimeLabel => _get('endTimeLabel');
  static String get customTimer => _get('customTimer');
  static String get slider => _get('slider');
  static String get trimmingFailed => _get('trimmingFailed');
  static String get saveTrimmedVideo => _get('saveTrimmedVideo');
  static String get trimmedSavedSuccess => _get('trimmedSavedSuccess');
  static String get pasteLinkFirst => _get('pasteLinkFirst');
  static String get invalidLink => _get('invalidLink');
  static String get couldNotReadLink => _get('couldNotReadLink');
  static String get checkLinkRetry => _get('checkLinkRetry');
  static String get copyVideoLinkFrom => _get('copyVideoLinkFrom');
  static String get galleryAccessFailed => _get('galleryAccessFailed');

  // Settings Screen
  static String get settings => _get('settings');
  static String get preferences => _get('preferences');
  static String get language => _get('language');
  static String get selectLanguage => _get('selectLanguage');
  static String get languageDefault => _get('languageName');
  static String get theme => _get('theme');
  static String get lightMode => _get('lightMode');
  static String get darkMode => _get('darkMode');
  static String get systemDefault => _get('systemDefault');
  static String get support => _get('support');
  static String get faq => _get('faq');
  static String get faqDesc => _get('faqDesc');
  static String get legal => _get('legal');
  static String get terms => _get('terms');
  static String get termsDesc => _get('termsDesc');
  static String get privacy => _get('privacy');
  static String get privacyDesc => _get('privacyDesc');
  static String get termsContent => _get('termsContent');
  static String get privacyContent => _get('privacyContent');

  // FAQ
  static String get faqQ1 => _get('faqQ1');
  static String get faqA1 => _get('faqA1');
  static String get faqQ2 => _get('faqQ2');
  static String get faqA2 => _get('faqA2');
  static String get faqQ3 => _get('faqQ3');
  static String get faqA3 => _get('faqA3');
  static String get faqQ4 => _get('faqQ4');
  static String get faqA4 => _get('faqA4');
  static String get faqQ8 => _get('faqQ8');
  static String get faqA8 => _get('faqA8');
  static String get faqQ5 => _get('faqQ5');
  static String get faqA5 => _get('faqA5');
  static String get faqQ6 => _get('faqQ6');
  static String get faqA6 => _get('faqA6');
  static String get faqQ7 => _get('faqQ7');
  static String get faqA7 => _get('faqA7');

  // Format Screen
  static String get selectFormat => _get('selectFormat');
  static String get video => _get('video');
  static String get videoQuality => _get('videoQuality');
  static String get audio => _get('audio');
  static String get audioQuality => _get('audioQuality');
  static String get saved => _get('saved');
  static String get viewHistory => _get('viewHistory');
  static String get downloadStarted => _get('downloadStarted');
  static String get downloadFailed => _get('downloadFailed');
  static String get highQualityMP3 => _get('highQualityMP3');
  static String get audioOnly => _get('audioOnly');
  static String get chooseAQualityFirst => _get('chooseAQualityFirst');
  static String get yourFileHasBeenSavedToYourDevice => _get('yourFileHasBeenSavedToYourDevice');

  // History Screen
  static String get history => _get('history');
  static String get mp3 => 'MP3';
  static String get clearHistory => _get('clearHistory');
  static String get noHistory => _get('noHistory');
  static String get tagDownload => _get('tagDownload');
  static String get tagTrim => _get('tagTrim');
  static String get tagConvert => _get('tagConvert');
  static String get tagEraser => _get('tagEraser');
  static String get tagWatermarked => _get('tagWatermarked');

  // Platform Download Screen
  static String get pleasePasteAValid => _get('pleasePasteAValid');
  static String get link => _get('link');
  static String get paste => _get('paste');
  static String get your => _get('your');
  static String get linkHere => _get('linkHere');
  static String get linkBelowToStart => _get('linkBelowToStart');

  // Convert Screen
  static String get convertFormatTitle => _get('convertFormatTitle');
  static String get chooseMediaType => _get('chooseMediaType');
  static String get selectTargetFormat => _get('selectTargetFormat');
  static String get pickAudioFile => _get('pickAudioFile');
  static String get pickVideoFile => _get('pickVideoFile');
  static String get convertNow => _get('convertNow');
  static String get converting => _get('converting');
  static String get conversionSuccess => _get('conversionSuccess');
  static String get conversionFailed => _get('conversionFailed');
  static String get noFileSelected => _get('noFileSelected');
  
  // Specific New Keys
  static String get splashSubtitle => _get('splashSubtitle');
  static String get chooseMedia => _get('chooseMedia');
  static String get chooseAudio => _get('chooseAudio');
  static String get chooseVideo => _get('chooseVideo');
  static String get selectAndContinue => _get('selectAndContinue');
  static String get position => _get('position');
  static String get size => _get('size');
  static String get magicEraser => _get('magicEraser');
  static String get drawToErase => _get('drawToErase');
  static String get simplyDraw => _get('simplyDraw');
  static String get generateVideo => _get('generateVideo');
  static String get clearSelection => _get('clearSelection');
  static String get changeVideo => _get('changeVideo');
  static String get addBranding => _get('addBranding');
  static String get dragBrand => _get('dragBrand');
  static String get typeWatermark => _get('typeWatermark');
  static String get loadingMedia => _get('loadingMedia');
  static String get drawBoxFirst => _get('drawBoxFirst');
  static String get erasedSavedSuccess => _get('erasedSavedSuccess');
  static String get processingFailed => _get('processingFailed');
  static String get unsupportedFileType => _get('unsupportedFileType');
  static String get videoSavedSuccess => _get('videoSavedSuccess');
  static String get failedApplyWatermark => _get('failedApplyWatermark');
  static String get processingWait => _get('processingWait');
}
