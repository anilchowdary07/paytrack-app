import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'services/notification_service.dart' as NotificationServiceLib;

void main() => runApp(PayTrackPremiumApp());

// Data Service for managing app data
class DataService {
  static const String _reminderKey = 'payment_reminders';
  static const String _expenseKey = 'spending_entries';
  static const String _limitsKey = 'spending_limits';
  static const String _userKey = 'user_data';

  // Save payment reminders
  static Future<void> saveReminders(List<PaymentReminder> reminders) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> reminderStrings = reminders
        .map((r) => json.encode({
              'id': r.id,
              'name': r.name,
              'amount': r.amount,
              'dueDate': r.dueDate.millisecondsSinceEpoch,
              'category': r.category,
              'isRecurring': r.isRecurring,
              'repeatInterval': r.repeatInterval,
              'reminderTimeHour': r.reminderTime.hour,
              'reminderTimeMinute': r.reminderTime.minute,
              'reminderDaysBefore': r.reminderDaysBefore,
              'priority': r.priority,
              'notes': r.notes,
            }))
        .toList();
    await prefs.setStringList(_reminderKey, reminderStrings);

    // Schedule notifications for all reminders
    final notificationService = NotificationServiceLib.NotificationService();
    for (PaymentReminder reminder in reminders) {
      await notificationService.scheduleNotification(
        NotificationServiceLib.PaymentReminder(
          id: reminder.id,
          name: reminder.name,
          amount: reminder.amount,
          dueDate: reminder.dueDate,
          category: reminder.category,
          reminderTime: reminder.reminderTime,
          reminderDaysBefore: reminder.reminderDaysBefore,
          priority: reminder.priority,
          notes: reminder.notes,
        ),
      );
    }
  }

  // Load payment reminders
  static Future<List<PaymentReminder>> loadReminders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? reminderStrings = prefs.getStringList(_reminderKey);

    if (reminderStrings == null) return [];

    return reminderStrings.map((s) {
      Map<String, dynamic> data = json.decode(s);
      return PaymentReminder(
        data['name'],
        data['amount'].toDouble(),
        DateTime.fromMillisecondsSinceEpoch(data['dueDate']),
        data['category'],
        isRecurring: data['isRecurring'] ?? false,
        repeatInterval: data['repeatInterval'] ?? 'none',
        id: data['id'],
        reminderTime: TimeOfDay(
          hour: data['reminderTimeHour'] ?? 9,
          minute: data['reminderTimeMinute'] ?? 0,
        ),
        reminderDaysBefore:
            List<int>.from(data['reminderDaysBefore'] ?? [1, 3]),
        priority: data['priority'] ?? 'medium',
        notes: data['notes'] ?? '',
      );
    }).toList();
  }

  // Save spending entries
  static Future<void> saveExpenses(List<SpendingEntry> expenses) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> expenseStrings = expenses
        .map((e) => json.encode({
              'name': e.name,
              'amount': e.amount,
              'date': e.date.millisecondsSinceEpoch,
              'category': e.category,
            }))
        .toList();
    await prefs.setStringList(_expenseKey, expenseStrings);
  }

  // Load spending entries
  static Future<List<SpendingEntry>> loadExpenses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? expenseStrings = prefs.getStringList(_expenseKey);

    if (expenseStrings == null) return [];

    return expenseStrings.map((s) {
      Map<String, dynamic> data = json.decode(s);
      return SpendingEntry(
        data['name'],
        data['amount'].toDouble(),
        DateTime.fromMillisecondsSinceEpoch(data['date']),
        data['category'],
      );
    }).toList();
  }

  // Save spending limits
  static Future<void> saveLimits(double dailyLimit, double monthlyLimit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_limit', dailyLimit);
    await prefs.setDouble('monthly_limit', monthlyLimit);
  }

  // Load spending limits
  static Future<Map<String, double>> loadLimits() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'daily': prefs.getDouble('daily_limit') ?? 100.0,
      'monthly': prefs.getDouble('monthly_limit') ?? 2000.0,
    };
  }

  // Get user email
  static Future<String> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail') ?? 'user@example.com';
  }

  // Save user email
  static Future<void> saveUserEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userEmail', email);
  }

  // Save payment history
  static Future<void> savePaymentHistory(List<PaymentHistory> history) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> historyStrings = history
        .map((h) => json.encode({
              'name': h.name,
              'amount': h.amount,
              'paidDate': h.paidDate.millisecondsSinceEpoch,
              'category': h.category,
              'originalReminderId': h.originalReminderId,
            }))
        .toList();
    await prefs.setStringList('payment_history', historyStrings);
  }

  // Load payment history
  static Future<List<PaymentHistory>> loadPaymentHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? historyStrings = prefs.getStringList('payment_history');

    if (historyStrings == null) return [];

    return historyStrings.map((s) {
      Map<String, dynamic> data = json.decode(s);
      return PaymentHistory(
        data['name'],
        data['amount'].toDouble(),
        DateTime.fromMillisecondsSinceEpoch(data['paidDate']),
        data['category'],
        data['originalReminderId'],
      );
    }).toList();
  }

  // Add payment to history and handle recurring reminders
  static Future<void> markPaymentAsPaid(PaymentReminder reminder) async {
    // Add to payment history
    List<PaymentHistory> history = await loadPaymentHistory();
    history.add(PaymentHistory(
      reminder.name,
      reminder.amount,
      DateTime.now(),
      reminder.category,
      reminder.id,
    ));
    await savePaymentHistory(history);

    // Handle recurring reminders
    List<PaymentReminder> reminders = await loadReminders();
    if (reminder.isRecurring && reminder.repeatInterval != 'none') {
      // Calculate next due date
      DateTime nextDueDate =
          _calculateNextDueDate(reminder.dueDate, reminder.repeatInterval);

      // Create next recurring reminder
      PaymentReminder nextReminder = reminder.copyWith(
        dueDate: nextDueDate,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Replace current reminder with next one
      int index = reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        reminders[index] = nextReminder;
      }
    } else {
      // Remove non-recurring reminder
      reminders.removeWhere((r) => r.id == reminder.id);
    }

    await saveReminders(reminders);
  }

  // Calculate next due date for recurring reminders
  static DateTime _calculateNextDueDate(DateTime currentDate, String interval) {
    switch (interval.toLowerCase()) {
      case 'weekly':
        return currentDate.add(Duration(days: 7));
      case 'monthly':
        return DateTime(
            currentDate.year, currentDate.month + 1, currentDate.day);
      case 'yearly':
        return DateTime(
            currentDate.year + 1, currentDate.month, currentDate.day);
      default:
        return currentDate.add(Duration(days: 30)); // Default to monthly
    }
  }
}

class PayTrackPremiumApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayTrack Premium',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: WelcomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Welcome Screen
class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade700, Colors.blue.shade900],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'PayTrack Premium',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your Smart Finance Companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              SizedBox(height: 50),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(Duration(milliseconds: 1500));

      // Basic validation
      if (_isLogin) {
        // Login validation
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          _showErrorSnackBar('Please fill in all fields');
          return;
        }

        // Simple email validation
        if (!_emailController.text.contains('@')) {
          _showErrorSnackBar('Please enter a valid email address');
          return;
        }

        // For demo purposes, accept any password with length >= 6
        if (_passwordController.text.length < 6) {
          _showErrorSnackBar(
              'Invalid credentials. Password must be at least 6 characters.');
          return;
        }
      } else {
        // Registration validation
        if (_nameController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty) {
          _showErrorSnackBar('Please fill in all fields');
          return;
        }

        if (_nameController.text.length < 2) {
          _showErrorSnackBar('Name must be at least 2 characters long');
          return;
        }

        if (!_emailController.text.contains('@') ||
            !_emailController.text.contains('.')) {
          _showErrorSnackBar('Please enter a valid email address');
          return;
        }

        if (_passwordController.text.length < 6) {
          _showErrorSnackBar('Password must be at least 6 characters long');
          return;
        }
      }

      // Save user data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', _emailController.text);
      if (!_isLogin && _nameController.text.isNotEmpty) {
        await prefs.setString('userName', _nameController.text);
      }

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isLogin ? 'Welcome back!' : 'Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to main screen
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => MainScreen()));
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (!_isLogin) {
      if (value == null || value.isEmpty) {
        return 'Name is required';
      }
      if (value.length < 2) {
        return 'Name must be at least 2 characters';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 60),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _isLogin
                        ? 'Sign in to continue'
                        : 'Join PayTrack Premium today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Name Field (only for registration)
                  if (!_isLogin) ...[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        validator: _validateName,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person, color: Colors.blue),
                          hintText: 'Full Name',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Email Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.email, color: Colors.blue),
                        hintText: 'Email Address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Password Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock, color: Colors.blue),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        hintText: 'Password',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Please wait...',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            )
                          : Text(
                              _isLogin ? 'Sign In' : 'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Toggle Login/Register
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign Up"
                          : "Already have an account? Sign In",
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),

                  if (_isLogin) ...[
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Password reset feature coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Main Screen with Navigation
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  PageController _pageController = PageController();
  late NotificationServiceLib.NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    _notificationService = NotificationServiceLib.NotificationService();
    await _notificationService.init();

    // Check for due notifications every minute
    _checkNotifications();
  }

  void _checkNotifications() {
    Future.delayed(Duration(minutes: 1), () {
      if (mounted) {
        _notificationService.checkAndShowDueNotifications();
        _checkNotifications(); // Recursive call for continuous checking
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          DashboardScreen(onNavigateToPage: (pageIndex) {
            setState(() => _currentIndex = pageIndex);
            _pageController.animateToPage(pageIndex,
                duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          }),
          PaymentRemindersScreen(),
          SpendingTrackingScreen(),
          PaymentHistoryScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, -5)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              _pageController.animateToPage(index,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.payment), label: 'Reminders'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.trending_up), label: 'Spending'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard Screen
class DashboardScreen extends StatefulWidget {
  final Function(int)? onNavigateToPage;

  const DashboardScreen({Key? key, this.onNavigateToPage}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double monthlySpent = 0.0;
  double monthlyLimit = 2000.0;
  double dailySpent = 0.0;
  int pendingPayments = 0;
  double upcomingPayments = 0.0;
  List<PaymentReminder> recentReminders = [];
  List<SpendingEntry> recentExpenses = [];
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Load limits
    Map<String, double> limits = await DataService.loadLimits();

    // Load reminders
    List<PaymentReminder> allReminders = await DataService.loadReminders();

    // Load expenses
    List<SpendingEntry> allExpenses = await DataService.loadExpenses();

    // Get user email
    String email = await DataService.getUserEmail();

    // Calculate statistics
    DateTime now = DateTime.now();
    DateTime monthStart = DateTime(now.year, now.month, 1);
    DateTime today = DateTime(now.year, now.month, now.day);

    // Calculate monthly spending
    double monthlyTotal = allExpenses
        .where((e) => e.date.isAfter(monthStart))
        .fold(0.0, (sum, e) => sum + e.amount);

    // Calculate daily spending
    double dailyTotal = allExpenses
        .where((e) => e.date.isAfter(today))
        .fold(0.0, (sum, e) => sum + e.amount);

    // Count pending payments
    int pendingCount = allReminders.length;

    // Calculate upcoming payments (next 7 days)
    DateTime nextWeek = now.add(Duration(days: 7));
    double upcomingTotal = allReminders
        .where((r) => r.dueDate.isBefore(nextWeek))
        .fold(0.0, (sum, r) => sum + r.amount);

    // Get recent items
    List<PaymentReminder> recentRemindersList = allReminders.take(3).toList();
    List<SpendingEntry> recentExpensesList = allExpenses
        .where((e) => e.date.isAfter(today.subtract(Duration(days: 1))))
        .take(3)
        .toList();

    setState(() {
      monthlyLimit = limits['monthly']!;
      monthlySpent = monthlyTotal;
      dailySpent = dailyTotal;
      pendingPayments = pendingCount;
      upcomingPayments = upcomingTotal;
      recentReminders = recentRemindersList;
      recentExpenses = recentExpensesList;
      userName = email.split('@')[0].toUpperCase();
    });
  }

  Future<void> _showNotifications() async {
    // Get scheduled notifications from our notification service
    final notificationService = NotificationServiceLib.NotificationService();
    List<Map<String, dynamic>> pendingNotifications =
        await notificationService.getPendingNotifications();

    // Also get urgent reminders (traditional way)
    List<PaymentReminder> reminders = await DataService.loadReminders();
    DateTime now = DateTime.now();

    List<PaymentReminder> urgentReminders = reminders.where((r) {
      int daysDiff = r.dueDate.difference(now).inDays;
      return daysDiff <= 1 && daysDiff >= 0;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications, color: Colors.blue),
            SizedBox(width: 8),
            Text('Notifications'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pendingNotifications.isNotEmpty) ...[
                Text(
                    '📅 Scheduled Notifications (${pendingNotifications.length})',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue)),
                SizedBox(height: 8),
                Container(
                  height: pendingNotifications.length > 3 ? 150 : null,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pendingNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = pendingNotifications[index];
                      final scheduledTime =
                          notification['scheduledTime'] as DateTime;
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          dense: true,
                          leading: Icon(Icons.schedule,
                              color: Colors.green, size: 20),
                          title: Text(notification['title'],
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['body'],
                                  style: TextStyle(fontSize: 12)),
                              Text(
                                  '⏰ ${scheduledTime.day}/${scheduledTime.month} at ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 12),
              ],
              Text('🚨 Urgent Payments',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              SizedBox(height: 8),
              if (urgentReminders.isEmpty)
                Text('No urgent payments due',
                    style: TextStyle(color: Colors.grey))
              else
                ...urgentReminders
                    .map((r) => Card(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.warning,
                                color: Colors.orange, size: 20),
                            title: Text(r.name, style: TextStyle(fontSize: 14)),
                            subtitle: Text(
                                'Due: ${r.dueDate.day}/${r.dueDate.month}',
                                style: TextStyle(fontSize: 12)),
                            trailing: Text('₹${r.amount.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ))
                    .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          if (pendingNotifications.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to notifications settings
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationSettingsScreen()),
                );
              },
              child: Text('Settings'),
            ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReminderScreen(),
      ),
    );
    if (result == true) {
      _loadDashboardData(); // Refresh data
    }
  }

  Future<void> _navigateToSetLimits() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => SetLimitsDialog(
        currentDailyLimit: 100.0, // We'll get this from DataService
        currentMonthlyLimit: monthlyLimit,
      ),
    );

    if (result != null) {
      await DataService.saveLimits(result['daily']!, result['monthly']!);
      _loadDashboardData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    double spentPercentage = monthlySpent / monthlyLimit;

    // Get time-based greeting
    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning!';
      } else if (hour < 17) {
        return 'Good Afternoon!';
      } else {
        return 'Good Evening!';
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getGreeting(),
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            Text('Welcome $userName',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: Icon(Icons.notifications_outlined, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Spending Card
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Monthly Spending',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16)),
                      Icon(Icons.trending_up, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('₹${monthlySpent.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('of ₹${monthlyLimit.toStringAsFixed(0)} limit',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: spentPercentage,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spentPercentage > 0.8 ? Colors.red : Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${(spentPercentage * 100).toStringAsFixed(1)}% of budget used',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pending Payments',
                    pendingPayments.toString(),
                    Icons.pending_actions,
                    Colors.orange.shade100,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: _buildSummaryCard(
                    'Upcoming',
                    '₹${upcomingPayments.toStringAsFixed(0)}',
                    Icons.schedule,
                    Colors.green.shade100,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 25),

            // Quick Actions
            Text('Quick Actions',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: _buildActionCard('Add Payment', Icons.add,
                        Colors.blue, _navigateToAddPayment)),
                SizedBox(width: 15),
                Expanded(
                    child: _buildActionCard('Set Limit', Icons.savings,
                        Colors.purple, _navigateToSetLimits)),
                SizedBox(width: 15),
                Expanded(
                    child: _buildActionCard(
                        'View Reports', Icons.bar_chart, Colors.teal, () {
                  // Navigate to Payment History page (index 3)
                  if (widget.onNavigateToPage != null) {
                    widget.onNavigateToPage!(3);
                  }
                })),
              ],
            ),
            SizedBox(height: 25),

            // Recent Activity
            Text('Recent Activity',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),
            ...recentReminders.map((reminder) {
              final daysDiff =
                  reminder.dueDate.difference(DateTime.now()).inDays;
              String subtitle;
              Color statusColor;

              if (daysDiff < 0) {
                subtitle =
                    'Overdue by ${daysDiff.abs()} day${daysDiff.abs() == 1 ? '' : 's'}';
                statusColor = Colors.red;
              } else if (daysDiff == 0) {
                subtitle = 'Due Today';
                statusColor = Colors.orange;
              } else if (daysDiff == 1) {
                subtitle = 'Due Tomorrow';
                statusColor = Colors.yellow;
              } else {
                subtitle = 'Due in $daysDiff days';
                statusColor = Colors.green;
              }

              IconData iconData;
              switch (reminder.category.toLowerCase()) {
                case 'utilities':
                  iconData = Icons.bolt;
                  break;
                case 'subscription':
                  iconData = Icons.subscriptions;
                  break;
                case 'insurance':
                  iconData = Icons.security;
                  break;
                case 'loan':
                  iconData = Icons.account_balance;
                  break;
                case 'credit card':
                  iconData = Icons.credit_card;
                  break;
                default:
                  iconData = Icons.payment;
              }

              return _buildActivityItem(
                reminder.name,
                '\$${reminder.amount.toStringAsFixed(2)}',
                subtitle,
                iconData,
                statusColor,
                priority: reminder.priority,
                onTap: () {
                  // Navigate to reminder details or edit
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddReminderScreen(reminder: reminder),
                    ),
                  ).then((result) {
                    if (result == true) _loadDashboardData();
                  });
                },
              );
            }).toList(),

            if (recentReminders.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(Icons.event_available,
                        size: 50, color: Colors.grey.shade400),
                    SizedBox(height: 10),
                    Text('No payment reminders yet',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 16)),
                    SizedBox(height: 5),
                    Text('Add your first payment reminder to get started',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                        textAlign: TextAlign.center),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddPayment,
                      icon: Icon(Icons.add),
                      label: Text('Add Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon,
      Color bgColor, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 30),
          SizedBox(height: 15),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: iconColor)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String amount, String subtitle, IconData icon, Color color,
      {String? priority, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      if (priority != null && priority == 'high')
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('HIGH',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(subtitle,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text(amount,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// Payment Reminders Screen
class PaymentRemindersScreen extends StatefulWidget {
  @override
  _PaymentRemindersScreenState createState() => _PaymentRemindersScreenState();
}

class _PaymentRemindersScreenState extends State<PaymentRemindersScreen> {
  List<PaymentReminder> reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    List<PaymentReminder> loadedReminders = await DataService.loadReminders();
    setState(() {
      reminders = loadedReminders;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Payment Reminders',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _addReminder,
            icon: Icon(Icons.add, color: Colors.blue),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final reminder = reminders[index];
          return _buildReminderCard(reminder, index);
        },
      ),
    );
  }

  Widget _buildReminderCard(PaymentReminder reminder, int index) {
    final now = DateTime.now();
    final isOverdue = reminder.dueDate.isBefore(now);
    final isDueSoon = reminder.dueDate.difference(now).inDays <= 1;

    Color statusColor = Colors.green;
    String statusText = 'UPCOMING';

    if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'OVERDUE';
    } else if (isDueSoon) {
      statusColor = Colors.orange;
      statusText = 'DUE SOON';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reminder.name,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Text(reminder.category,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14)),
                        if (reminder.isRecurring) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${reminder.repeatInterval.toUpperCase()}',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (reminder.priority != 'medium') ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(reminder.priority)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              reminder.priority.toUpperCase(),
                              style: TextStyle(
                                color: _getPriorityColor(reminder.priority),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (reminder.notes.isNotEmpty) ...[
                      SizedBox(height: 5),
                      Text(
                        reminder.notes,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text('₹${reminder.amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Due Date',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text(
                      '${reminder.dueDate.day}/${reminder.dueDate.month}/${reminder.dueDate.year}',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.notifications_active,
                          color: Colors.blue, size: 14),
                      SizedBox(width: 4),
                      Text('${reminder.reminderTime.format(context)}',
                          style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statusText,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  if (reminder.reminderDaysBefore.isNotEmpty) ...[
                    SizedBox(height: 5),
                    Text(
                      'Remind ${reminder.reminderDaysBefore.join(", ")} days before',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _markAsPaid(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Mark as Paid',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => _editReminder(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Icon(Icons.edit, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addReminder() {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        onAdd: (reminder) async {
          setState(() {
            reminders.add(reminder);
          });
          await DataService.saveReminders(reminders);
        },
      ),
    );
  }

  void _editReminder(int index) {
    showDialog(
      context: context,
      builder: (context) => AddReminderDialog(
        reminder: reminders[index],
        onAdd: (reminder) async {
          setState(() {
            reminders[index] = reminder;
          });
          await DataService.saveReminders(reminders);
        },
      ),
    );
  }

  void _markAsPaid(int index) async {
    final reminder = reminders[index];

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Paid'),
        content: Text(
            'Mark "${reminder.name}" as paid for ₹${reminder.amount.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Mark as Paid', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Use the new markPaymentAsPaid method from DataService
      await DataService.markPaymentAsPaid(reminder);

      // Reload reminders to reflect changes (including new recurring reminders)
      await _loadReminders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reminder.isRecurring
              ? 'Payment marked as paid! Next reminder scheduled.'
              : 'Payment marked as paid!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Spending Tracking Screen
class SpendingTrackingScreen extends StatefulWidget {
  @override
  _SpendingTrackingScreenState createState() => _SpendingTrackingScreenState();
}

class _SpendingTrackingScreenState extends State<SpendingTrackingScreen> {
  double dailyLimit = 100.0;
  double baseDailyLimit = 100.0; // Original daily limit
  double todaySpent = 0.0;
  double carryoverAmount = 0.0;
  List<SpendingEntry> todaySpending = [];

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    // Load limits
    Map<String, double> limits = await DataService.loadLimits();

    // Load all expenses
    List<SpendingEntry> allExpenses = await DataService.loadExpenses();

    // Get base daily limit
    double baseLimit = limits['daily']!;

    // Calculate carryover from previous days
    double carryover = await _calculateCarryover(allExpenses, baseLimit);

    // Filter today's expenses
    DateTime today = DateTime.now();
    DateTime startOfDay = DateTime(today.year, today.month, today.day);

    List<SpendingEntry> todaysExpenses = allExpenses.where((expense) {
      return expense.date.isAfter(startOfDay);
    }).toList();

    // Calculate today's total
    double totalToday =
        todaysExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    setState(() {
      baseDailyLimit = baseLimit;
      carryoverAmount = carryover;
      dailyLimit = baseLimit + carryover; // Add carryover to daily limit
      todaySpending = todaysExpenses;
      todaySpent = totalToday;
    });
  }

  Future<double> _calculateCarryover(
      List<SpendingEntry> allExpenses, double baseLimit) async {
    // Calculate carryover from last 7 days (excluding today)
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    double totalCarryover = 0.0;

    // Check last 7 days for unused budget
    for (int i = 1; i <= 7; i++) {
      DateTime dayStart = startOfToday.subtract(Duration(days: i));
      DateTime dayEnd = dayStart.add(Duration(days: 1));

      // Calculate spending for that day
      double daySpending = allExpenses.where((expense) {
        return expense.date.isAfter(dayStart) && expense.date.isBefore(dayEnd);
      }).fold(0.0, (sum, expense) => sum + expense.amount);

      // If spent less than daily limit, add to carryover
      if (daySpending < baseLimit) {
        totalCarryover += (baseLimit - daySpending);
      }
    }

    // Limit carryover to maximum of 3 days worth of daily limit
    return totalCarryover > (baseLimit * 3) ? (baseLimit * 3) : totalCarryover;
  }

  @override
  Widget build(BuildContext context) {
    double spentPercentage = todaySpent / dailyLimit;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Spending Tracking',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _setDailyLimit,
            icon: Icon(Icons.settings, color: Colors.blue),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Daily Spending Card
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.purple.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today\'s Spending',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16)),
                      Icon(Icons.today, color: Colors.white),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('₹${todaySpent.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                          'of ₹${dailyLimit.toStringAsFixed(0)} available today',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14)),
                      if (carryoverAmount > 0) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+₹${carryoverAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  if (carryoverAmount > 0) ...[
                    SizedBox(height: 5),
                    Text(
                        '(₹${baseDailyLimit.toStringAsFixed(0)} base + ₹${carryoverAmount.toStringAsFixed(0)} carryover)',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                  SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: spentPercentage,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      spentPercentage > 0.8 ? Colors.red : Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${(dailyLimit - todaySpent).toStringAsFixed(2)} remaining',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                      if (carryoverAmount > 0)
                        Icon(Icons.savings,
                            color: Colors.green.shade300, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Add Expense Button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.all(15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Add Expense',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 25),

            // Today's Expenses
            Text('Today\'s Expenses',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: todaySpending.length,
              itemBuilder: (context, index) {
                final expense = todaySpending[index];
                return _buildExpenseItem(expense, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(SpendingEntry expense, int index) {
    IconData categoryIcon;
    Color categoryColor;

    switch (expense.category) {
      case 'Food':
        categoryIcon = Icons.restaurant;
        categoryColor = Colors.orange;
        break;
      case 'Transport':
        categoryIcon = Icons.directions_bus;
        categoryColor = Colors.blue;
        break;
      case 'Shopping':
        categoryIcon = Icons.shopping_bag;
        categoryColor = Colors.green;
        break;
      default:
        categoryIcon = Icons.receipt;
        categoryColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.name,
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(expense.category,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(
                onPressed: () => _deleteExpense(index),
                icon: Icon(Icons.delete, color: Colors.red, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addExpense() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        onAdd: (expense) async {
          setState(() {
            todaySpending.add(expense);
            todaySpent += expense.amount;
          });

          // Load all expenses, add new one, and save
          List<SpendingEntry> allExpenses = await DataService.loadExpenses();
          allExpenses.add(expense);
          await DataService.saveExpenses(allExpenses);
        },
      ),
    );
  }

  void _setDailyLimit() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        double newLimit = dailyLimit;
        return AlertDialog(
          title: Text('Set Daily Limit'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Daily Limit (₹)'),
            onChanged: (value) =>
                newLimit = double.tryParse(value) ?? dailyLimit,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, newLimit),
              child: Text('Set'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() => dailyLimit = result);
      // Load current monthly limit and save both
      Map<String, double> limits = await DataService.loadLimits();
      await DataService.saveLimits(result, limits['monthly']!);
    }
  }

  void _deleteExpense(int index) async {
    SpendingEntry expenseToDelete = todaySpending[index];

    setState(() {
      todaySpent -= todaySpending[index].amount;
      todaySpending.removeAt(index);
    });

    // Load all expenses, remove the deleted one, and save
    List<SpendingEntry> allExpenses = await DataService.loadExpenses();
    allExpenses.removeWhere((expense) =>
        expense.name == expenseToDelete.name &&
        expense.amount == expenseToDelete.amount &&
        expense.date == expenseToDelete.date);
    await DataService.saveExpenses(allExpenses);
  }
}

// Analytics Screen
class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  double monthlySpent = 0.0;
  Map<String, double> categorySpending = {};
  Map<String, double> weeklyTrends = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    List<SpendingEntry> allExpenses = await DataService.loadExpenses();

    // Calculate monthly spending
    DateTime now = DateTime.now();
    DateTime monthStart = DateTime(now.year, now.month, 1);

    List<SpendingEntry> monthlyExpenses =
        allExpenses.where((e) => e.date.isAfter(monthStart)).toList();

    double totalMonthly = monthlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

    // Calculate category spending
    Map<String, double> categories = {};
    for (SpendingEntry expense in monthlyExpenses) {
      categories[expense.category] =
          (categories[expense.category] ?? 0) + expense.amount;
    }

    // Calculate weekly trends
    DateTime thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    DateTime lastWeekStart = thisWeekStart.subtract(Duration(days: 7));

    double thisWeekSpending = allExpenses
        .where((e) => e.date.isAfter(thisWeekStart))
        .fold(0.0, (sum, e) => sum + e.amount);

    double lastWeekSpending = allExpenses
        .where((e) =>
            e.date.isAfter(lastWeekStart) && e.date.isBefore(thisWeekStart))
        .fold(0.0, (sum, e) => sum + e.amount);

    setState(() {
      monthlySpent = totalMonthly;
      categorySpending = categories;
      weeklyTrends = {
        'This Week': thisWeekSpending,
        'Last Week': lastWeekSpending,
        'This Month': totalMonthly,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Analytics',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Overview
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.teal.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly Overview',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  SizedBox(height: 10),
                  Text('₹${monthlySpent.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text('Total spent this month',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Category Breakdown
            Text('Spending by Category',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            // Show dynamic category items
            ...categorySpending.entries.map((entry) {
              double percentage =
                  monthlySpent > 0 ? entry.value / monthlySpent : 0.0;
              Color color = _getCategoryColor(entry.key);
              return _buildCategoryItem(
                  entry.key, entry.value, percentage, color);
            }).toList(),

            if (categorySpending.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                child: Text('No spending data available for this month',
                    style: TextStyle(color: Colors.grey)),
              ),

            SizedBox(height: 25),

            // Spending Trends
            Text('Spending Trends',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 15),

            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildTrendItem('This Week', '₹345.50', '+12%', Colors.red),
                  Divider(),
                  _buildTrendItem('Last Week', '₹308.25', '-5%', Colors.green),
                  Divider(),
                  _buildTrendItem('This Month', '₹1,250.75', '+8%', Colors.red),
                  Divider(),
                  _buildTrendItem(
                      'Last Month', '₹1,156.40', '-15%', Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCategoryItem(
      String category, double amount, double percentage, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: TextStyle(fontWeight: FontWeight.w600)),
              Text('₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${(percentage * 100).toStringAsFixed(1)}% of total',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text('${(percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(
      String period, String amount, String change, Color changeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(period, style: TextStyle(fontWeight: FontWeight.w600)),
        Row(
          children: [
            Text(amount, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(change,
                  style: TextStyle(
                      color: changeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

// Payment History Screen
class PaymentHistoryScreen extends StatefulWidget {
  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<PaymentHistory> paymentHistory = [];
  List<SpendingEntry> expenses = [];
  List<PaymentReminder> reminders = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportsData() async {
    setState(() => isLoading = true);

    // Load all data for comprehensive reports
    List<PaymentHistory> history = await DataService.loadPaymentHistory();
    List<SpendingEntry> expenseData = await DataService.loadExpenses();
    List<PaymentReminder> reminderData = await DataService.loadReminders();

    setState(() {
      paymentHistory = history
        ..sort((a, b) => b.paidDate.compareTo(a.paidDate));
      expenses = expenseData..sort((a, b) => b.date.compareTo(a.date));
      reminders = reminderData;
      isLoading = false;
    });
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.file_copy, color: Colors.blue),
              title: Text('Export as Text'),
              subtitle: Text('Simple text format'),
              onTap: () {
                Navigator.pop(context);
                _performTextExport();
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.green),
              title: Text('Export Summary'),
              subtitle: Text('Overview and statistics'),
              onTap: () {
                Navigator.pop(context);
                _performSummaryExport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performTextExport() {
    final analytics = _generateAnalytics();
    String exportText = '''
PayTrack Export Report
Generated: ${DateTime.now().toString()}

=== SUMMARY ===
This Month Spending: ₹${analytics['thisMonthSpending'].toStringAsFixed(2)}
Last Month Spending: ₹${analytics['lastMonthSpending'].toStringAsFixed(2)}
Total Reminders: ${analytics['totalReminders']}
Completed Payments: ${analytics['completedPayments']}
Completion Rate: ${analytics['completionRate'].toStringAsFixed(1)}%

=== RECENT EXPENSES ===
${expenses.take(10).map((e) => '${e.date.day}/${e.date.month}/${e.date.year} - ${e.name} - ₹${e.amount.toStringAsFixed(2)} (${e.category})').join('\n')}

=== REMINDERS ===
${reminders.map((r) => '${r.name} - ₹${r.amount.toStringAsFixed(2)} - Due: ${r.dueDate.day}/${r.dueDate.month}/${r.dueDate.year}').join('\n')}
''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Data exported! (In a real app, this would save to file)'),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Export Preview'),
                content: SingleChildScrollView(
                  child: Text(exportText,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _performSummaryExport() {
    final analytics = _generateAnalytics();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Summary exported! Total: ₹${analytics['thisMonthSpending'].toStringAsFixed(2)} this month'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Map<String, dynamic> _generateAnalytics() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    // Monthly comparisons
    final thisMonthExpenses = expenses
        .where((e) => e.date.isAfter(thisMonth))
        .fold(0.0, (sum, e) => sum + e.amount);
    final lastMonthExpenses = expenses
        .where((e) => e.date.isAfter(lastMonth) && e.date.isBefore(thisMonth))
        .fold(0.0, (sum, e) => sum + e.amount);

    // Category breakdown
    Map<String, double> categorySpending = {};
    for (var expense in expenses.where((e) => e.date.isAfter(thisMonth))) {
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Payment completion rate
    final totalReminders = reminders.length;
    final completedPayments =
        paymentHistory.where((p) => p.paidDate.isAfter(thisMonth)).length;

    return {
      'thisMonthSpending': thisMonthExpenses,
      'lastMonthSpending': lastMonthExpenses,
      'categoryBreakdown': categorySpending,
      'totalReminders': totalReminders,
      'completedPayments': completedPayments,
      'completionRate':
          totalReminders > 0 ? (completedPayments / totalReminders) * 100 : 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Reports & Analytics',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download, color: Colors.green),
            onPressed: _exportData,
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadReportsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.analytics, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up, size: 20)),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
                _buildTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final analytics = _generateAnalytics();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Summary Card
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade600, Colors.teal.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('This Month',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16)),
                    Icon(Icons.calendar_today, color: Colors.white),
                  ],
                ),
                SizedBox(height: 15),
                Text('₹${analytics['thisMonthSpending'].toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      analytics['thisMonthSpending'] >
                              analytics['lastMonthSpending']
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: analytics['thisMonthSpending'] >
                              analytics['lastMonthSpending']
                          ? Colors.red.shade300
                          : Colors.green.shade300,
                      size: 20,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '${((analytics['thisMonthSpending'] - analytics['lastMonthSpending']) / (analytics['lastMonthSpending'] == 0 ? 1 : analytics['lastMonthSpending']) * 100).toStringAsFixed(1)}% vs last month',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                    'Payment Rate',
                    '${analytics['completionRate'].toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green),
              ),
              SizedBox(width: 15),
              Expanded(
                child: _buildStatCard(
                    'Total Reminders',
                    '${analytics['totalReminders']}',
                    Icons.notifications,
                    Colors.orange),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Category Breakdown
          Text('Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          ...analytics['categoryBreakdown']
              .entries
              .map((entry) => _buildCategoryItem(entry.key, entry.value))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return paymentHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey.shade400),
                SizedBox(height: 20),
                Text('No Payment History',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                SizedBox(height: 10),
                Text('Payments you mark as paid will appear here',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(20),
            itemCount: paymentHistory.length,
            itemBuilder: (context, index) {
              final payment = paymentHistory[index];
              return Card(
                margin: EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(payment.category),
                    child: Icon(
                      _getCategoryIcon(payment.category),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(payment.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: ${payment.category}',
                          style: TextStyle(color: Colors.grey.shade600)),
                      Text(
                          'Paid on: ${payment.paidDate.day}/${payment.paidDate.month}/${payment.paidDate.year}',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('₹${payment.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green)),
                      Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildTrendsTab() {
    final weeklyData = _generateWeeklyData();
    final monthlyTrend = _generateMonthlyTrend();
    final insights = _generateSmartInsights();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),

          // Weekly trend with real data
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Last 7 Days',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Total: ₹${weeklyData['total'].toStringAsFixed(2)}',
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 20),
                ..._buildRealWeeklyChart(weeklyData['daily']),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Monthly trend
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Text('Monthly Trend',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 15),
                ..._buildMonthlyTrendChart(monthlyTrend),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Peak spending analysis
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(Icons.trending_up, color: Colors.orange, size: 30),
                SizedBox(height: 10),
                Text('Peak Spending Analysis',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                Text(insights['peakDay'],
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange.shade700)),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Smart insights with real data
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue, size: 30),
                SizedBox(height: 10),
                Text('Smart Insights',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 10),
                ...insights['tips']
                    .map<Widget>((tip) => Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.circle, color: Colors.blue, size: 6),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(tip,
                                    style:
                                        TextStyle(color: Colors.blue.shade700)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _generateWeeklyData() {
    final now = DateTime.now();
    Map<String, double> dailyAmounts = {};
    double totalWeek = 0;

    // Generate data for last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(Duration(days: 1));

      double dayTotal = expenses
          .where((expense) =>
              expense.date.isAfter(dayStart) && expense.date.isBefore(dayEnd))
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final dayName =
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
      dailyAmounts[dayName] = dayTotal;
      totalWeek += dayTotal;
    }

    return {
      'daily': dailyAmounts,
      'total': totalWeek,
    };
  }

  List<Map<String, dynamic>> _generateMonthlyTrend() {
    final now = DateTime.now();
    List<Map<String, dynamic>> monthlyData = [];

    // Generate data for last 6 months
    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);

      double monthTotal = expenses
          .where((expense) =>
              expense.date.isAfter(monthDate) &&
              expense.date.isBefore(nextMonth))
          .fold(0.0, (sum, expense) => sum + expense.amount);

      monthlyData.add({
        'month': _getMonthName(monthDate.month),
        'amount': monthTotal,
      });
    }

    return monthlyData;
  }

  Map<String, dynamic> _generateSmartInsights() {
    if (expenses.isEmpty) {
      return {
        'peakDay':
            'No spending data available yet. Start tracking your expenses to see insights!',
        'tips': ['Add your first expense to get personalized insights'],
      };
    }

    // Find peak spending day
    Map<int, double> dayOfWeekSpending = {};
    for (var expense in expenses) {
      int dayOfWeek = expense.date.weekday;
      dayOfWeekSpending[dayOfWeek] =
          (dayOfWeekSpending[dayOfWeek] ?? 0) + expense.amount;
    }

    String peakDay = 'Monday';
    double maxSpending = 0;
    dayOfWeekSpending.forEach((day, amount) {
      if (amount > maxSpending) {
        maxSpending = amount;
        peakDay = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ][day - 1];
      }
    });

    // Generate category insights
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    String topCategory = 'Other';
    double topCategoryAmount = 0;
    categoryTotals.forEach((category, amount) {
      if (amount > topCategoryAmount) {
        topCategoryAmount = amount;
        topCategory = category;
      }
    });

    List<String> tips = [];

    if (maxSpending > 0) {
      tips.add(
          'Your highest spending day is $peakDay. Consider planning ahead for this day.');
    }

    if (topCategoryAmount > 0) {
      tips.add(
          '$topCategory is your biggest expense category (₹${topCategoryAmount.toStringAsFixed(2)} total).');
    }

    final avgDaily = expenses.isNotEmpty
        ? expenses.fold(0.0, (sum, e) => sum + e.amount) / 30
        : 0;
    if (avgDaily > 0) {
      tips.add(
          'Your average daily spending is ₹${avgDaily.toStringAsFixed(2)}.');
    }

    // Weekend vs weekday analysis
    double weekendSpending =
        (dayOfWeekSpending[6] ?? 0) + (dayOfWeekSpending[7] ?? 0);
    double weekdaySpending = dayOfWeekSpending.entries
        .where((entry) => entry.key >= 1 && entry.key <= 5)
        .fold(0.0, (sum, entry) => sum + entry.value);

    if (weekendSpending > weekdaySpending) {
      tips.add(
          'You spend more on weekends. Consider setting weekend-specific budgets.');
    } else if (weekdaySpending > weekendSpending) {
      tips.add(
          'Your weekday spending is higher. This might be work-related expenses.');
    }

    return {
      'peakDay':
          'Your peak spending day is $peakDay with ₹${maxSpending.toStringAsFixed(2)} total.',
      'tips': tips.isNotEmpty
          ? tips
          : ['Keep tracking your expenses to get personalized insights!'],
    };
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 10),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
          SizedBox(width: 15),
          Expanded(
            child:
                Text(category, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text('₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(category))),
        ],
      ),
    );
  }

  List<Widget> _buildRealWeeklyChart(Map<String, double> dailyData) {
    if (dailyData.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 50, color: Colors.grey.shade400),
              SizedBox(height: 10),
              Text('No data available for the last 7 days',
                  style: TextStyle(color: Colors.grey.shade600)),
              Text('Start tracking expenses to see trends',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ),
      ];
    }

    double maxAmount = dailyData.values.isEmpty
        ? 1.0
        : dailyData.values.reduce((a, b) => a > b ? a : b);
    if (maxAmount == 0) maxAmount = 1.0;

    List<String> orderedDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];

    return orderedDays.map((day) {
      double amount = dailyData[day] ?? 0.0;
      double heightPercentage = (amount / maxAmount);

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
                width: 30, child: Text(day, style: TextStyle(fontSize: 12))),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: heightPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: amount > 0
                            ? [Colors.blue.shade400, Colors.blue.shade600]
                            : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 60,
              child: Text('₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildMonthlyTrendChart(List<Map<String, dynamic>> monthlyData) {
    if (monthlyData.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.trending_up, size: 50, color: Colors.grey.shade400),
              SizedBox(height: 10),
              Text('No monthly data available',
                  style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ];
    }

    double maxAmount = monthlyData.isEmpty
        ? 1.0
        : monthlyData
            .map((data) => data['amount'] as double)
            .reduce((a, b) => a > b ? a : b);
    if (maxAmount == 0) maxAmount = 1.0;

    return monthlyData.map((data) {
      String month = data['month'];
      double amount = data['amount'];
      double heightPercentage = (amount / maxAmount);

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
                width: 35, child: Text(month, style: TextStyle(fontSize: 12))),
            SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: heightPercentage,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: amount > 0
                            ? [Colors.teal.shade400, Colors.teal.shade600]
                            : [Colors.grey.shade300, Colors.grey.shade300],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            SizedBox(
              width: 70,
              child: Text('₹${amount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'shopping':
        return Colors.green;
      case 'entertainment':
        return Colors.purple;
      case 'bills':
        return Colors.red;
      case 'healthcare':
        return Colors.pink;
      case 'education':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      default:
        return Icons.payment;
    }
  }
}

// Profile Screen
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userEmail = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    String email = await DataService.getUserEmail();
    setState(() {
      userEmail = email;
    });
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _editProfile() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController =
        TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                await DataService.saveUserEmail(emailController.text);
                setState(() {
                  userEmail = emailController.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated successfully!')),
                );
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About PayTrack Premium'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PayTrack Premium v1.0.0'),
            SizedBox(height: 5),
            Text('Build by Anil and Team',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            SizedBox(height: 10),
            Text(
                'A complete payment reminder and spending tracker app built with Flutter.'),
            SizedBox(height: 10),
            Text('Features:'),
            Text('• Payment Reminders'),
            Text('• Spending Tracking'),
            Text('• Budget Limits'),
            Text('• Analytics & Reports'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getAnalytics() async {
    final reminders = await DataService.loadReminders();

    // Get current month
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    // Calculate analytics
    final totalReminders = reminders.length;
    final activeReminders =
        reminders.where((r) => r.dueDate.isAfter(now)).length;
    final highPriorityReminders =
        reminders.where((r) => r.priority == 'high').length;

    // Calculate monthly payments (using reminder amounts for this month)
    final monthlyPayments = reminders
        .where((reminder) =>
            reminder.dueDate.isAfter(thisMonth) &&
            reminder.dueDate.isBefore(nextMonth))
        .fold(0.0, (sum, reminder) => sum + reminder.amount);

    // Calculate payment streak (count of reminders in last 30 days)
    final recentReminders = reminders
        .where((reminder) =>
            reminder.dueDate.isAfter(now.subtract(Duration(days: 30))))
        .length;

    return {
      'totalReminders': totalReminders,
      'activeReminders': activeReminders,
      'highPriorityReminders': highPriorityReminders,
      'monthlyPayments': monthlyPayments,
      'paymentStreak': recentReminders,
    };
  }

  Widget _buildAnalyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          child: Text(
                            userEmail.split('@')[0][0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.verified,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(userEmail.split('@')[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(userEmail,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text('Premium Member',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _editProfile,
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          // Share profile or app
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Profile shared successfully!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          padding: EdgeInsets.all(12),
                        ),
                        child: Icon(Icons.share, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Analytics Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 15),
                    child: Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Analytics',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getAnalytics(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final analytics = snapshot.data ?? {};
                      return Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAnalyticsCard(
                                    'Total Reminders',
                                    '${analytics['totalReminders'] ?? 0}',
                                    Icons.notifications,
                                    Colors.blue,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: _buildAnalyticsCard(
                                    'Active Reminders',
                                    '${analytics['activeReminders'] ?? 0}',
                                    Icons.schedule,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAnalyticsCard(
                                    'This Month Payments',
                                    '₹${analytics['monthlyPayments']?.toStringAsFixed(2) ?? '0.00'}',
                                    Icons.payment,
                                    Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: _buildAnalyticsCard(
                                    'High Priority',
                                    '${analytics['highPriorityReminders'] ?? 0}',
                                    Icons.priority_high,
                                    Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up, color: Colors.blue),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Payment Streak',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade800)),
                                        Text(
                                            '${analytics['paymentStreak'] ?? 0} consecutive on-time payments',
                                            style: TextStyle(
                                                color: Colors.blue.shade600,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // Settings Options
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildSettingItem(Icons.notifications, 'Notifications', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => NotificationSettingsScreen()),
                    );
                  }),
                  Divider(height: 1),
                  _buildSettingItem(Icons.security, 'Security', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SecuritySettingsScreen()),
                    );
                  }),
                  Divider(height: 1),
                  _buildSettingItem(Icons.help, 'Help & Support', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HelpSupportScreen()),
                    );
                  }),
                  Divider(height: 1),
                  _buildSettingItem(Icons.info, 'About', _showAbout),
                  Divider(height: 1),
                  _buildSettingItem(Icons.logout, 'Logout', _logout,
                      isLogout: true),
                ],
              ),
            ),
            SizedBox(height: 25),

            // App Info
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('PayTrack Premium',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  SizedBox(height: 5),
                  Text('Version 1.0.0',
                      style: TextStyle(color: Colors.grey.shade600)),
                  SizedBox(height: 15),
                  Text('Thank you for using PayTrack Premium!',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text('Build by Anil and Team',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.grey.shade700),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red : Colors.black,
          )),
      trailing:
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

// Data Models
// Data Models
class PaymentReminder {
  final String name;
  final double amount;
  final DateTime dueDate;
  final String category;
  final bool isRecurring;
  final String repeatInterval; // 'monthly', 'weekly', 'yearly', 'none'
  final String id;
  final TimeOfDay reminderTime; // Time to send reminder
  final List<int> reminderDaysBefore; // Days before due date to remind
  final String priority; // 'high', 'medium', 'low'
  final String notes;

  PaymentReminder(
    this.name,
    this.amount,
    this.dueDate,
    this.category, {
    this.isRecurring = false,
    this.repeatInterval = 'none',
    String? id,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
    this.reminderDaysBefore = const [1, 3], // Default: 1 and 3 days before
    this.priority = 'medium',
    this.notes = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  PaymentReminder copyWith({
    String? name,
    double? amount,
    DateTime? dueDate,
    String? category,
    bool? isRecurring,
    String? repeatInterval,
    String? id,
    TimeOfDay? reminderTime,
    List<int>? reminderDaysBefore,
    String? priority,
    String? notes,
  }) {
    return PaymentReminder(
      name ?? this.name,
      amount ?? this.amount,
      dueDate ?? this.dueDate,
      category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      id: id ?? this.id,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
    );
  }
}

class SpendingEntry {
  final String name;
  final double amount;
  final DateTime date;
  final String category;

  SpendingEntry(this.name, this.amount, this.date, this.category);
}

class PaymentHistory {
  final String name;
  final double amount;
  final DateTime paidDate;
  final String category;
  final String originalReminderId;

  PaymentHistory(this.name, this.amount, this.paidDate, this.category,
      this.originalReminderId);
}

// Dialogs
class AddReminderDialog extends StatefulWidget {
  final PaymentReminder? reminder;
  final Function(PaymentReminder) onAdd;

  AddReminderDialog({this.reminder, required this.onAdd});

  @override
  _AddReminderDialogState createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedCategory = 'Bills';
  DateTime _selectedDate = DateTime.now().add(Duration(days: 30));
  bool _isRecurring = false;
  String _repeatInterval = 'monthly';
  TimeOfDay _reminderTime = TimeOfDay(hour: 9, minute: 0);
  List<int> _reminderDaysBefore = [1, 3];
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      _nameController.text = widget.reminder!.name;
      _amountController.text = widget.reminder!.amount.toString();
      _notesController.text = widget.reminder!.notes;
      _selectedCategory = widget.reminder!.category;
      _selectedDate = widget.reminder!.dueDate;
      _isRecurring = widget.reminder!.isRecurring;
      _repeatInterval = widget.reminder!.repeatInterval;
      _reminderTime = widget.reminder!.reminderTime;
      _reminderDaysBefore = List.from(widget.reminder!.reminderDaysBefore);
      _priority = widget.reminder!.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.reminder == null
          ? 'Add Payment Reminder'
          : 'Edit Payment Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Payment Name'),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount (₹)'),
            ),
            SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: [
                'Bills',
                'Utilities',
                'Internet',
                'Phone',
                'Insurance',
                'Other'
              ]
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Text('Due Date: '),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Checkbox(
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value!),
                ),
                Text('Recurring Payment'),
              ],
            ),
            if (_isRecurring) ...[
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _repeatInterval,
                decoration: InputDecoration(labelText: 'Repeat Every'),
                items: [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                ].toList(),
                onChanged: (value) => setState(() => _repeatInterval = value!),
              ),
            ],
            SizedBox(height: 15),

            // Notification Time Section
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Notification Settings',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Reminder Time: '),
                      Expanded(
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _reminderTime,
                                helpText: 'Select notification time',
                              );
                              if (time != null) {
                                setState(() => _reminderTime = time);
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_reminderTime.format(context),
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                                Icon(Icons.access_time,
                                    color: Colors.blue, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Quick Options:',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  SizedBox(height: 5),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildTimeChip('Morning', TimeOfDay(hour: 9, minute: 0)),
                      _buildTimeChip(
                          'Afternoon', TimeOfDay(hour: 14, minute: 0)),
                      _buildTimeChip('Evening', TimeOfDay(hour: 18, minute: 0)),
                      _buildTimeChip('Night', TimeOfDay(hour: 21, minute: 0)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),

            // Priority
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: InputDecoration(labelText: 'Priority'),
              items: [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ].toList(),
              onChanged: (value) => setState(() => _priority = value!),
            ),
            SizedBox(height: 15),

            // Days Before Reminder
            Text('Remind me before:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [1, 2, 3, 5, 7].map((days) {
                return FilterChip(
                  label: Text('$days day${days > 1 ? 's' : ''}'),
                  selected: _reminderDaysBefore.contains(days),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _reminderDaysBefore.add(days);
                        _reminderDaysBefore.sort();
                      } else {
                        _reminderDaysBefore.remove(days);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 15),

            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional notes...',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _amountController.text.isNotEmpty) {
              final reminder = PaymentReminder(
                _nameController.text,
                double.parse(_amountController.text),
                _selectedDate,
                _selectedCategory,
                isRecurring: _isRecurring,
                repeatInterval: _isRecurring ? _repeatInterval : 'none',
                reminderTime: _reminderTime,
                reminderDaysBefore: _reminderDaysBefore,
                priority: _priority,
                notes: _notesController.text,
              );
              widget.onAdd(reminder);
              Navigator.pop(context);
            }
          },
          child: Text(widget.reminder == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String label, TimeOfDay time) {
    bool isSelected =
        _reminderTime.hour == time.hour && _reminderTime.minute == time.minute;

    return GestureDetector(
      onTap: () {
        setState(() {
          _reminderTime = time;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.blue.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: isSelected ? Colors.white : Colors.blue,
            ),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.blue,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddExpenseDialog extends StatefulWidget {
  final Function(SpendingEntry) onAdd;

  AddExpenseDialog({required this.onAdd});

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Expense Name'),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount (₹)'),
          ),
          SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(labelText: 'Category'),
            items: ['Food', 'Transport', 'Shopping', 'Entertainment', 'Other']
                .map((category) =>
                    DropdownMenuItem(value: category, child: Text(category)))
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _amountController.text.isNotEmpty) {
              final expense = SpendingEntry(
                _nameController.text,
                double.parse(_amountController.text),
                DateTime.now(),
                _selectedCategory,
              );
              widget.onAdd(expense);
              Navigator.pop(context);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

// Set Limits Dialog
class SetLimitsDialog extends StatefulWidget {
  final double currentDailyLimit;
  final double currentMonthlyLimit;

  SetLimitsDialog({
    required this.currentDailyLimit,
    required this.currentMonthlyLimit,
  });

  @override
  _SetLimitsDialogState createState() => _SetLimitsDialogState();
}

class _SetLimitsDialogState extends State<SetLimitsDialog> {
  late TextEditingController _dailyController;
  late TextEditingController _monthlyController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
        text: widget.currentDailyLimit.toStringAsFixed(0));
    _monthlyController = TextEditingController(
        text: widget.currentMonthlyLimit.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Spending Limits'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _dailyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Daily Limit (₹)',
              prefixIcon: Icon(Icons.today),
            ),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _monthlyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Monthly Limit (₹)',
              prefixIcon: Icon(Icons.calendar_month),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            double dailyLimit = double.tryParse(_dailyController.text) ??
                widget.currentDailyLimit;
            double monthlyLimit = double.tryParse(_monthlyController.text) ??
                widget.currentMonthlyLimit;

            Navigator.pop(context, {
              'daily': dailyLimit,
              'monthly': monthlyLimit,
            });
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

// Add Reminder Screen
class AddReminderScreen extends StatefulWidget {
  final PaymentReminder? reminder;

  const AddReminderScreen({Key? key, this.reminder}) : super(key: key);

  @override
  _AddReminderScreenState createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Bills';
  DateTime _selectedDate = DateTime.now().add(Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Payment Reminder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Payment Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                'Bills',
                'Utilities',
                'Internet',
                'Phone',
                'Insurance',
                'Other'
              ]
                  .map((category) =>
                      DropdownMenuItem(value: category, child: Text(category)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            SizedBox(height: 20),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            SizedBox(height: 30),
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameController.text.isNotEmpty &&
                      _amountController.text.isNotEmpty) {
                    // Validate that due date is not in the past
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final selectedDay = DateTime(_selectedDate.year,
                        _selectedDate.month, _selectedDate.day);

                    if (selectedDay.isBefore(today)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Cannot set reminder for past dates. Please select a future date.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Default reminder settings
                    final defaultReminderTime = TimeOfDay(hour: 9, minute: 0);
                    final defaultReminderDays = [1, 3];

                    // Validate reminder time logic
                    bool hasValidReminders = false;
                    for (int daysBefore in defaultReminderDays) {
                      DateTime notificationDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day - daysBefore,
                        defaultReminderTime.hour,
                        defaultReminderTime.minute,
                      );

                      if (notificationDate.isAfter(now)) {
                        hasValidReminders = true;
                        break;
                      }
                    }

                    if (!hasValidReminders) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'All reminder times would be in the past. Please adjust the due date.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Load existing reminders
                    List<PaymentReminder> reminders =
                        await DataService.loadReminders();

                    // Add new reminder with proper parameters
                    reminders.add(PaymentReminder(
                      _nameController.text,
                      double.parse(_amountController.text),
                      _selectedDate,
                      _selectedCategory,
                      isRecurring: false,
                      repeatInterval: 'none',
                      reminderTime: defaultReminderTime,
                      reminderDaysBefore: defaultReminderDays,
                      priority: 'medium',
                      notes: '',
                    ));

                    // Save updated reminders
                    await DataService.saveReminders(reminders);

                    // Return to previous screen
                    Navigator.pop(context, true);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Payment reminder added with notifications scheduled!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Text('Add Reminder',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Settings Screens
class NotificationSettingsScreen extends StatefulWidget {
  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _reminderNotifications = true;
  bool _paymentAlerts = true;
  bool _weeklyReports = false;
  bool _priorityNotifications = true;
  bool _overdueNotifications = true;
  bool _smartNotifications = false;
  String _notificationTime = '09:00';
  int _reminderDaysBefore = 3;
  String _notificationSound = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Basic Notifications
          Card(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Basic Notifications',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text('Payment Reminders'),
                  subtitle: Text('Get notified about upcoming payments'),
                  value: _reminderNotifications,
                  onChanged: (value) =>
                      setState(() => _reminderNotifications = value),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Payment Alerts'),
                  subtitle: Text('Alerts for overdue payments'),
                  value: _paymentAlerts,
                  onChanged: (value) => setState(() => _paymentAlerts = value),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Weekly Reports'),
                  subtitle: Text('Weekly spending summaries'),
                  value: _weeklyReports,
                  onChanged: (value) => setState(() => _weeklyReports = value),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Advanced Notifications
          Card(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.orange),
                      SizedBox(width: 10),
                      Text('Advanced Notifications',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text('Priority Notifications'),
                  subtitle: Text('Special alerts for high priority payments'),
                  value: _priorityNotifications,
                  onChanged: (value) =>
                      setState(() => _priorityNotifications = value),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Overdue Notifications'),
                  subtitle: Text('Daily reminders for overdue payments'),
                  value: _overdueNotifications,
                  onChanged: (value) =>
                      setState(() => _overdueNotifications = value),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Smart Notifications'),
                  subtitle: Text('AI-powered notification timing'),
                  value: _smartNotifications,
                  onChanged: (value) =>
                      setState(() => _smartNotifications = value),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Notification Timing
          Card(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Notification Timing',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                ListTile(
                  title: Text('Default Notification Time'),
                  subtitle: Text('Time for daily reminders'),
                  trailing: Text(_notificationTime,
                      style: TextStyle(color: Colors.blue)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: 9, minute: 0),
                    );
                    if (time != null) {
                      setState(() => _notificationTime = time.format(context));
                    }
                  },
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Advance Notice'),
                  subtitle: Text('Days before due date to remind'),
                  trailing: DropdownButton<int>(
                    value: _reminderDaysBefore,
                    items: [1, 2, 3, 5, 7, 14]
                        .map((days) => DropdownMenuItem(
                              value: days,
                              child:
                                  Text('$days ${days == 1 ? 'day' : 'days'}'),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _reminderDaysBefore = value!),
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Notification Sound'),
                  subtitle: Text('Sound for payment reminders'),
                  trailing: DropdownButton<String>(
                    value: _notificationSound,
                    items: ['Default', 'Chime', 'Bell', 'Alert', 'Silent']
                        .map((sound) => DropdownMenuItem(
                              value: sound,
                              child: Text(sound),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _notificationSound = value!),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Test Notification
          Card(
            child: ListTile(
              leading: Icon(Icons.notifications_active, color: Colors.purple),
              title: Text('Test Notification'),
              subtitle: Text('Send a test notification with current settings'),
              trailing: Icon(Icons.send),
              onTap: () async {
                final notificationService =
                    NotificationServiceLib.NotificationService();
                await notificationService.showTestNotification();

                // Also show pending notifications count
                final pendingNotifications =
                    await notificationService.getPendingNotifications();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Test notification sent! You have ${pendingNotifications.length} pending notifications.'),
                    action: SnackBarAction(
                      label: 'View Debug',
                      onPressed: () {
                        print(
                            '📱 Pending Notifications: ${pendingNotifications.length}');
                        for (var notification in pendingNotifications) {
                          print(
                              '   - ${notification['title']}: ${notification['body']} at ${notification['scheduledTime']}');
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notification settings saved!')),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Save All Settings'),
          ),
        ],
      ),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  @override
  _SecuritySettingsScreenState createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricAuth = false;
  bool _appLock = false;
  String _lockTimeout = '5 minutes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Biometric Authentication'),
                  subtitle: Text('Use fingerprint or face unlock'),
                  value: _biometricAuth,
                  onChanged: (value) => setState(() => _biometricAuth = value),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('App Lock'),
                  subtitle: Text('Require authentication to open app'),
                  value: _appLock,
                  onChanged: (value) => setState(() => _appLock = value),
                ),
                Divider(height: 1),
                ListTile(
                  title: Text('Lock Timeout'),
                  subtitle: Text('Auto-lock after inactivity'),
                  trailing:
                      Text(_lockTimeout, style: TextStyle(color: Colors.blue)),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: Text('Lock Timeout'),
                        children: [
                          '1 minute',
                          '5 minutes',
                          '15 minutes',
                          '30 minutes'
                        ]
                            .map((timeout) => SimpleDialogOption(
                                  onPressed: () {
                                    setState(() => _lockTimeout = timeout);
                                    Navigator.pop(context);
                                  },
                                  child: Text(timeout),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Security settings saved!')),
              );
            },
            child: Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.help_outline, color: Colors.blue),
                  title: Text('FAQ'),
                  subtitle: Text('Frequently asked questions'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('FAQ'),
                        content: Text(
                            'How do I set up recurring payments?\n\nWhen adding a payment reminder, check the "Recurring Payment" option and select your preferred interval.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text('Contact Support'),
                  subtitle: Text('Get help from our team'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Support email: support@paytrack.com')),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.feedback, color: Colors.blue),
                  title: Text('Send Feedback'),
                  subtitle: Text('Help us improve the app'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Send Feedback'),
                        content: TextField(
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Your feedback...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Feedback sent! Thank you.')),
                              );
                            },
                            child: Text('Send'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 64, color: Colors.blue),
                  SizedBox(height: 15),
                  Text(
                    'Need More Help?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Our support team is here to help you 24/7. Feel free to reach out for any assistance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
