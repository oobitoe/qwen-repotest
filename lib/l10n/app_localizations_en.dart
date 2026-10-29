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
  String get name => 'Name';

  @override
  String get stock => 'Stock';

  @override
  String get stockMovements => 'Stock Movements';

  @override
  String get adjustStock => 'Adjust Stock';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

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
  String get appDisplayName => 'PrimePOS';

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
  String get onlineMode => 'Online — data stored in cloud.';

  @override
  String get offlineSubtitle =>
      'Sign in with your store account or use offline mode.';

  @override
  String get registerAccount => 'Register Account';

  @override
  String get registerSubtitle => 'Create a new account for your store.';

  @override
  String get fullName => 'Full Name';

  @override
  String get role => 'Role';

  @override
  String get backToLogin => 'Back to login';

  @override
  String registrationFailed(Object error) {
    return 'Registration failed: $error';
  }

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

  @override
  String get subtotal => 'Subtotal';

  @override
  String get diskon => 'Discount';

  @override
  String get pajak => 'Tax';

  @override
  String get keranjang => 'Cart';

  @override
  String get keranjangKosong => 'Cart Empty';

  @override
  String get pembayaran => 'Payment';

  @override
  String get metodePembayaran => 'Payment Method';

  @override
  String get checkout => 'Checkout';

  @override
  String get batal => 'Cancel';

  @override
  String get cashRegister => 'Cash Register';

  @override
  String get openSession => 'Open Session';

  @override
  String get activeSession => 'Active Session';

  @override
  String get openedBy => 'Opened by';

  @override
  String get openingBalance => 'Opening Balance';

  @override
  String get closeSession => 'Close Session';

  @override
  String get actualBalance => 'Actual Balance';

  @override
  String get close => 'Close';

  @override
  String get register => 'Register';

  @override
  String get open => 'Open';

  @override
  String get accounts => 'Accounts';

  @override
  String get cashSessions => 'Cash Sessions';

  @override
  String get accountType => 'Account Type';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeEWallet => 'E-Wallet';

  @override
  String get accountBalance => 'Account Balance';

  @override
  String get expenseDeleted => 'Expense deleted';

  @override
  String get incomeDeleted => 'Income deleted';

  @override
  String get descriptionRequired => 'Description required';

  @override
  String get amountRequired => 'Amount required';

  @override
  String get amountInvalid => 'Invalid amount';

  @override
  String get nameRequired => 'Name required';

  @override
  String get noCategory => 'No Category';

  @override
  String get selectRegister => 'Select register';

  @override
  String get balanceRequired => 'Balance required';

  @override
  String get balanceInvalid => 'Invalid balance';

  @override
  String get paymentMethodCash => 'Cash';

  @override
  String get paymentMethodTransfer => 'Transfer';

  @override
  String get paymentMethodQris => 'QRIS';

  @override
  String get paymentMethodCard => 'Card';

  @override
  String get paymentMethodOther => 'Other';

  @override
  String get themePreset => 'Theme Preset';

  @override
  String get themePresetSubtitle => 'Choose your preferred color theme';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeModeSubtitle => 'Select light, dark, or system default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageSubtitle => 'Select application language';

  @override
  String languageChanged(Object language) {
    return 'Language changed to $language';
  }

  @override
  String get sync => 'Sync';

  @override
  String get syncSubtitle => 'Manage data synchronization';

  @override
  String get manualSync => 'Manual Sync';

  @override
  String get manualSyncDesc => 'Trigger synchronization with server now';

  @override
  String get syncQueueDesc => 'View pending sync operations';

  @override
  String get about => 'About';

  @override
  String get aboutSubtitle => 'Application information';

  @override
  String version(Object version) {
    return 'Version $version';
  }

  @override
  String get aboutDescription =>
      'Modern offline-first POS system built with Flutter, Drift, Riverpod, and Supabase.';

  @override
  String get techStack => 'Tech Stack';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get apply => 'Apply';

  @override
  String get exportCSV => 'Export CSV';

  @override
  String get exportPDF => 'Export PDF';

  @override
  String get financial => 'Financial';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get transactions => 'Transactions';

  @override
  String get grossProfit => 'Gross Profit';

  @override
  String get salesChart => 'Sales Chart';

  @override
  String get detail => 'Detail';

  @override
  String get period => 'Period';

  @override
  String get revenue => 'Revenue';

  @override
  String get avgTransaction => 'Avg Transaction';

  @override
  String get topProducts => 'Top Products';

  @override
  String get product => 'Product';

  @override
  String get category => 'Category';

  @override
  String get qtySold => 'Qty Sold';

  @override
  String get profit => 'Profit';

  @override
  String get totalStockValue => 'Total Stock Value';

  @override
  String get lowStockItems => 'Low Stock Items';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get stockDetail => 'Stock Detail';

  @override
  String get minStock => 'Min Stock';

  @override
  String get stockValue => 'Stock Value';

  @override
  String get profitLoss => 'Profit & Loss';

  @override
  String get cashFlow => 'Cash Flow';

  @override
  String get oopsSomethingWrong => 'Oops! Something went wrong';

  @override
  String noResultsFound(Object query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get tryDifferentSearch => 'Try different keywords or filters';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get connectionError => 'Unable to connect to server';

  @override
  String get retryConnection => 'Retry connection';

  @override
  String get goOnline => 'Go online';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get resourceNotFound => 'The requested resource was not found';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String serverErrorCode(Object code) {
    return 'Server error (code: $code)';
  }

  @override
  String get auditLog => 'Audit Log';

  @override
  String get user => 'User';

  @override
  String get action => 'Action';

  @override
  String get entityType => 'Entity Type';

  @override
  String get entityId => 'Entity ID';

  @override
  String get timestamp => 'Timestamp';

  @override
  String get oldValue => 'Old Value';

  @override
  String get newValue => 'New Value';

  @override
  String get changes => 'Changes';

  @override
  String get viewDetail => 'View Detail';

  @override
  String get viewChanges => 'View Changes';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get selectDate => 'Select Date';

  @override
  String get noAuditLogs => 'No audit logs found';

  @override
  String get auditLogTitle => 'Audit Log';

  @override
  String get auditLogSubtitle => 'Track all system activities';

  @override
  String get previousPage => 'Previous Page';

  @override
  String get nextPage => 'Next Page';
}
