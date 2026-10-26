import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'POS App'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS / Cashier'**
  String get pos;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @purchases.
  ///
  /// In en, this message translates to:
  /// **'Purchases'**
  String get purchases;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @returns.
  ///
  /// In en, this message translates to:
  /// **'Returns'**
  String get returns;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @cashManagement.
  ///
  /// In en, this message translates to:
  /// **'Cash Management'**
  String get cashManagement;

  /// No description provided for @debts.
  ///
  /// In en, this message translates to:
  /// **'Debts & Receivables'**
  String get debts;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @indonesian.
  ///
  /// In en, this message translates to:
  /// **'Indonesian'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By'**
  String get createdBy;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedBy.
  ///
  /// In en, this message translates to:
  /// **'Updated By'**
  String get updatedBy;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @customerTier.
  ///
  /// In en, this message translates to:
  /// **'Customer Tier'**
  String get customerTier;

  /// No description provided for @rewardPoints.
  ///
  /// In en, this message translates to:
  /// **'Reward Points'**
  String get rewardPoints;

  /// No description provided for @permission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get permission;

  /// No description provided for @access.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get access;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get syncStatus;

  /// No description provided for @syncQueue.
  ///
  /// In en, this message translates to:
  /// **'Sync Queue'**
  String get syncQueue;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get info;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noData;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDelete;

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient stock'**
  String get insufficientStock;

  /// No description provided for @transactionSaved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transactionSaved;

  /// No description provided for @transactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed'**
  String get transactionFailed;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied. You do not have permission to access this feature.'**
  String get accessDenied;

  /// No description provided for @appDisplayName.
  ///
  /// In en, this message translates to:
  /// **'POSku'**
  String get appDisplayName;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'v0.1.0'**
  String get appVersion;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @minPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minPasswordLength;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginFailed(Object error);

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode — data stored on this device.'**
  String get offlineMode;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your store account.'**
  String get loginSubtitle;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New Transaction'**
  String get newTransaction;

  /// No description provided for @syncInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Sync interrupted'**
  String get syncInterrupted;

  /// No description provided for @offlinePending.
  ///
  /// In en, this message translates to:
  /// **'Offline · {pending} changes pending in queue'**
  String offlinePending(Object pending);

  /// No description provided for @offlineSaved.
  ///
  /// In en, this message translates to:
  /// **'Offline · all data stored locally'**
  String get offlineSaved;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing… ({count} items)'**
  String syncing(Object count);

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {message}'**
  String syncError(Object message);

  /// No description provided for @syncReady.
  ///
  /// In en, this message translates to:
  /// **'Ready · stored locally'**
  String get syncReady;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced · last {ago}'**
  String syncSynced(Object ago);

  /// No description provided for @agoJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoJustNow;

  /// No description provided for @agoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMinutes(Object n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} hours ago'**
  String agoHours(Object n);

  /// No description provided for @revenueToday.
  ///
  /// In en, this message translates to:
  /// **'Revenue Today'**
  String get revenueToday;

  /// No description provided for @subtitleInvoice.
  ///
  /// In en, this message translates to:
  /// **'completed invoices'**
  String get subtitleInvoice;

  /// No description provided for @grossProfitToday.
  ///
  /// In en, this message translates to:
  /// **'Gross Profit Today'**
  String get grossProfitToday;

  /// No description provided for @subtitleCogs.
  ///
  /// In en, this message translates to:
  /// **'after COGS'**
  String get subtitleCogs;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @lowStockCount.
  ///
  /// In en, this message translates to:
  /// **'{count} need restock'**
  String lowStockCount(Object count);

  /// No description provided for @stockSafe.
  ///
  /// In en, this message translates to:
  /// **'stock safe'**
  String get stockSafe;

  /// No description provided for @chartSales.
  ///
  /// In en, this message translates to:
  /// **'Sales Chart'**
  String get chartSales;

  /// No description provided for @chartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'last 14 days'**
  String get chartSubtitle;

  /// No description provided for @lowStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStockTitle;

  /// No description provided for @noActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get noActivity;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @allStockSafe.
  ///
  /// In en, this message translates to:
  /// **'All stock safe'**
  String get allStockSafe;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @greetingNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get greetingNight;

  /// No description provided for @greetingRole.
  ///
  /// In en, this message translates to:
  /// **'{greet} · role {role}'**
  String greetingRole(Object greet, Object role);

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'{title} will be available in the next phase.'**
  String comingSoon(Object title);

  /// No description provided for @tooltipOpenSidebar.
  ///
  /// In en, this message translates to:
  /// **'Open sidebar'**
  String get tooltipOpenSidebar;

  /// No description provided for @tooltipCollapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get tooltipCollapseSidebar;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @transactionsToday.
  ///
  /// In en, this message translates to:
  /// **'Transactions Today'**
  String get transactionsToday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
