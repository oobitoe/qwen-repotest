// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'POS App';

  @override
  String get home => 'Home';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get pos => 'POS / Cashier';

  @override
  String get sales => 'Sales';

  @override
  String get purchases => 'Purchases';

  @override
  String get products => 'Products';

  @override
  String get categories => 'Categories';

  @override
  String get inventory => 'Inventory';

  @override
  String get suppliers => 'Suppliers';

  @override
  String get customers => 'Customers';

  @override
  String get returns => 'Returns';

  @override
  String get expenses => 'Expenses';

  @override
  String get income => 'Income';

  @override
  String get cashManagement => 'Cash Management';

  @override
  String get debts => 'Debts & Receivables';

  @override
  String get reports => 'Reports';

  @override
  String get users => 'Users';

  @override
  String get settings => 'Settings';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get language => 'Language';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get english => 'English';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Amount';

  @override
  String get total => 'Total';

  @override
  String get status => 'Status';

  @override
  String get createdBy => 'Created By';

  @override
  String get createdAt => 'Created At';

  @override
  String get updatedBy => 'Updated By';

  @override
  String get updatedAt => 'Updated At';

  @override
  String get customerTier => 'Customer Tier';

  @override
  String get rewardPoints => 'Reward Points';

  @override
  String get permission => 'Permission';

  @override
  String get access => 'Access';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get syncStatus => 'Sync Status';

  @override
  String get syncQueue => 'Sync Queue';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get loading => 'Loading';

  @override
  String get noData => 'No Data';

  @override
  String get confirmDelete => 'Are you sure you want to delete this item?';

  @override
  String get insufficientStock => 'Insufficient stock';

  @override
  String get transactionSaved => 'Transaction saved';

  @override
  String get transactionFailed => 'Transaction failed';

  @override
  String get accessDenied =>
      'Access denied. You do not have permission to access this feature.';

  @override
  String get appDisplayName => 'POSku';

  @override
  String get appVersion => 'v0.1.0';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get minPasswordLength => 'Minimum 6 characters';

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get offlineMode => 'Offline mode — data stored on this device.';

  @override
  String get loginSubtitle => 'Sign in with your store account.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get newTransaction => 'New Transaction';

  @override
  String get syncInterrupted => 'Sync interrupted';

  @override
  String offlinePending(Object pending) {
    return 'Offline · $pending changes pending in queue';
  }

  @override
  String get offlineSaved => 'Offline · all data stored locally';

  @override
  String syncing(Object count) {
    return 'Syncing… ($count items)';
  }

  @override
  String syncError(Object message) {
    return 'Sync error: $message';
  }

  @override
  String get syncReady => 'Ready · stored locally';

  @override
  String syncSynced(Object ago) {
    return 'Synced · last $ago';
  }

  @override
  String get agoJustNow => 'just now';

  @override
  String agoMinutes(Object n) {
    return '$n min ago';
  }

  @override
  String agoHours(Object n) {
    return '$n hours ago';
  }

  @override
  String get revenueToday => 'Revenue Today';

  @override
  String get subtitleInvoice => 'completed invoices';

  @override
  String get grossProfitToday => 'Gross Profit Today';

  @override
  String get subtitleCogs => 'after COGS';

  @override
  String get activeProducts => 'Active Products';

  @override
  String lowStockCount(Object count) {
    return '$count need restock';
  }

  @override
  String get stockSafe => 'stock safe';

  @override
  String get chartSales => 'Sales Chart';

  @override
  String get chartSubtitle => 'last 14 days';

  @override
  String get lowStockTitle => 'Low Stock';

  @override
  String get noActivity => 'No activity yet.';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get allStockSafe => 'All stock safe';

  @override
  String get retry => 'Try again';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get greetingNight => 'Good night';

  @override
  String greetingRole(Object greet, Object role) {
    return '$greet · role $role';
  }

  @override
  String comingSoon(Object title) {
    return '$title will be available in the next phase.';
  }

  @override
  String get tooltipOpenSidebar => 'Open sidebar';

  @override
  String get tooltipCollapseSidebar => 'Collapse sidebar';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get transactionsToday => 'Transactions Today';
}
