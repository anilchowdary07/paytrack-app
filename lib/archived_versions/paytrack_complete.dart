import 'package:flutter/material.dart';

void main() => runApp(PayTrackApp());

class PayTrackApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayTrack - Payment Reminder',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Payment> _payments = [
    Payment(
      'Electricity Bill',
      89.50,
      DateTime.now().add(Duration(days: 1)),
      'Utilities',
    ),
    Payment('Internet Bill', 45.00, DateTime.now(), 'Internet'),
    Payment(
      'Water Bill',
      32.75,
      DateTime.now().add(Duration(days: 7)),
      'Utilities',
    ),
    Payment(
      'Phone Bill',
      25.00,
      DateTime.now().add(Duration(days: 3)),
      'Phone',
    ),
    Payment('Rent', 850.00, DateTime.now().add(Duration(days: 28)), 'Housing'),
    Payment(
      'Insurance',
      120.00,
      DateTime.now().add(Duration(days: 15)),
      'Insurance',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PayTrack'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: () => _showAddPaymentDialog(),
              child: Icon(Icons.add),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildPayments();
      case 2:
        return _buildCalendar();
      case 3:
        return _buildProfile();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    double totalPending = _payments.fold(
      0,
      (sum, payment) => sum + payment.amount,
    );
    int overdueCount = _payments
        .where((p) => p.dueDate.isBefore(DateTime.now()))
        .length;
    int thisMonthCount = _payments.where((p) {
      final now = DateTime.now();
      return p.dueDate.month == now.month && p.dueDate.year == now.year;
    }).length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Pending',
                  '₹${totalPending.toStringAsFixed(0)}',
                  Icons.warning_rounded,
                  Colors.red.shade100,
                  Colors.red,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Overdue',
                  '$overdueCount bills',
                  Icons.schedule_rounded,
                  Colors.orange.shade100,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'This Month',
                  '$thisMonthCount payments',
                  Icons.calendar_month_rounded,
                  Colors.blue.shade100,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Total Bills',
                  '${_payments.length} bills',
                  Icons.receipt_rounded,
                  Colors.green.shade100,
                  Colors.green,
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // Recent Payments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Payments',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _payments.take(3).length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return _buildPaymentListItem(payment, false);
              },
            ),
          ),

          SizedBox(height: 32),

          // Quick Actions
          Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  'Add Payment',
                  Icons.add_circle,
                  Colors.blue,
                  () => _showAddPaymentDialog(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'View Calendar',
                  Icons.calendar_today,
                  Colors.orange,
                  () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayments() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Payments',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => _showAddPaymentDialog(),
                icon: Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: _buildPaymentListItem(payment, true),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Payment Calendar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 32),

          // Monthly View
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'This Month\'s Payments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Calendar grid would go here
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: 30,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final hasPayment = _payments.any(
                      (p) => p.dueDate.day == day,
                    );

                    return Container(
                      margin: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: hasPayment
                            ? Colors.red.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontWeight: hasPayment
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: hasPayment ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Upcoming this week
          Text(
            'This Week',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: _payments.where((p) {
                final now = DateTime.now();
                final weekFromNow = now.add(Duration(days: 7));
                return p.dueDate.isAfter(now) &&
                    p.dueDate.isBefore(weekFromNow);
              }).length,
              itemBuilder: (context, index) {
                final weekPayments = _payments.where((p) {
                  final now = DateTime.now();
                  final weekFromNow = now.add(Duration(days: 7));
                  return p.dueDate.isAfter(now) &&
                      p.dueDate.isBefore(weekFromNow);
                }).toList();

                if (weekPayments.isEmpty) {
                  return Center(child: Text('No payments this week!'));
                }

                final payment = weekPayments[index];
                return Card(child: _buildPaymentListItem(payment, false));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 40),
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          SizedBox(height: 20),
          Text(
            'John Doe',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'john.doe@example.com',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          SizedBox(height: 40),

          Card(
            child: Column(
              children: [
                _buildProfileOption(Icons.notifications, 'Notifications', true),
                Divider(height: 1),
                _buildProfileOption(Icons.security, 'Security', false),
                Divider(height: 1),
                _buildProfileOption(Icons.help, 'Help & Support', false),
                Divider(height: 1),
                _buildProfileOption(Icons.info, 'About PayTrack', false),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Statistics
          Container(
            padding: EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Your Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total Bills', '${_payments.length}'),
                    _buildStatItem(
                      'This Month',
                      '₹${_payments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
                    ),
                    _buildStatItem(
                      'Categories',
                      '${_payments.map((p) => p.category).toSet().length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: iconColor),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentListItem(Payment payment, bool showActions) {
    final now = DateTime.now();
    final isOverdue = payment.dueDate.isBefore(now);
    final isDueSoon = payment.dueDate.difference(now).inDays <= 1;

    Color statusColor = Colors.green;
    String statusText = 'UPCOMING';

    if (isOverdue) {
      statusColor = Colors.red;
      statusText = 'OVERDUE';
    } else if (isDueSoon) {
      statusColor = Colors.orange;
      statusText = 'DUE SOON';
    }

    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.1),
            child: Icon(Icons.payment, color: statusColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.name,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Due: ${payment.dueDate.day}/${payment.dueDate.month}/${payment.dueDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${payment.amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (showActions) ...[
                SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _markAsPaid(payment),
                      icon: Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deletePayment(payment),
                      icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, bool hasSwitch) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: hasSwitch
          ? Switch(value: true, onChanged: (v) {})
          : Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (title == 'About PayTrack') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('About PayTrack'),
              content: Text(
                'PayTrack v1.0.0\nYour personal payment reminder app\n\nFeatures:\n• Track payment due dates\n• Dashboard overview\n• Calendar view\n• Payment categories',
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
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  void _showAddPaymentDialog() {
    String name = '';
    double amount = 0;
    DateTime dueDate = DateTime.now().add(Duration(days: 30));
    String category = 'Bills';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Payment Name'),
                onChanged: (value) => name = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
                onChanged: (value) => amount = double.tryParse(value) ?? 0,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(labelText: 'Category'),
                onChanged: (value) => category = value,
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
              if (name.isNotEmpty && amount > 0) {
                setState(() {
                  _payments.add(Payment(name, amount, dueDate, category));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Payment added successfully!')),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(Payment payment) {
    setState(() {
      _payments.remove(payment);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${payment.name} marked as paid!')));
  }

  void _deletePayment(Payment payment) {
    setState(() {
      _payments.remove(payment);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${payment.name} deleted!')));
  }
}

class Payment {
  final String name;
  final double amount;
  final DateTime dueDate;
  final String category;

  Payment(this.name, this.amount, this.dueDate, this.category);
}
