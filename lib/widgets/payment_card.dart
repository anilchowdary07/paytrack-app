import 'package:flutter/material.dart';
import 'package:payment_reminder_app/models/payment_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:payment_reminder_app/utils/app_colors.dart';
import 'package:payment_reminder_app/utils/app_icons.dart';
import 'package:payment_reminder_app/services/firestore_service.dart';

class PaymentCard extends StatefulWidget {
  final Payment payment;
  final VoidCallback onDismissed;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onDismissed,
  });

  @override
  State<PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<PaymentCard> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = widget.payment.dueDate.isBefore(DateTime.now());
    final formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(widget.payment.dueDate);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Dismissible(
        key: Key(widget.payment.id),
        onDismissed: (direction) => widget.onDismissed(),
        background: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getIconBgColor(widget.payment.category),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  AppIcons.getIconData(widget.payment.category),
                  color: AppColors.getIconColor(widget.payment.category),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.payment.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.displayLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due: $formattedDate',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isOverdue
                            ? theme.colorScheme.error
                            : theme.textTheme.bodyLarge?.color?.withAlpha(178),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${widget.payment.amount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Checkbox(
                value: widget.payment.isPaid,
                onChanged: (bool? value) {
                  if (value != null) {
                    final updatedPayment = widget.payment.copyWith(
                      isPaid: value,
                    );
                    _firestoreService.updatePayment(
                      widget.payment.id,
                      updatedPayment.toFirestore(),
                    );
                  }
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
