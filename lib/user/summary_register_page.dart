import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/appbar.dart';
import 'doc_upload.dart'; // Import the new upload page

// ... [Keep RegistrationData class unchanged] ...
class RegistrationData {
  final String name;
  final String gender;
  final String icNo;
  final String address;
  final String phone;
  final String work;
  final String incomeAmount;
  final String loanAmount;
  final DateTime loanDate;
  final String interestRatePct;
  final String paymentPeriod;
  final String nation;
  final String status;

  RegistrationData({
    required this.name,
    required this.gender,
    required this.icNo,
    required this.address,
    required this.phone,
    required this.work,
    required this.incomeAmount,
    required this.loanAmount,
    required this.loanDate,
    required this.interestRatePct,
    required this.paymentPeriod,
    required this.nation,
    this.status = 'pending',
  });
}

class SummaryRegisterPage extends StatefulWidget {
  final RegistrationData data;
  const SummaryRegisterPage({super.key, required this.data});

  @override
  State<SummaryRegisterPage> createState() => _SummaryRegisterPageState();
}

class _SummaryRegisterPageState extends State<SummaryRegisterPage> {
  bool _saving = false;

  // Palette
  static const _bg = Color(0xFF0B0220);
  static const _card = Color(0xFF120834);
  static const _teal = Color(0xFF5FB2B2);
  static const _tealBright = Color(0xFF7FD0D0);
  static const _lavender = Color(0xFFB794F4);

  // ... [Keep _line, _numParse, _rm, _metricTile helpers unchanged] ...
  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text('$k:',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      );

  double _numParse(String s) {
    if (s.isEmpty) return 0;
    final cleaned = s.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _rm(num x) => 'RM ${x.toStringAsFixed(2)}';

  Widget _metricTile(String title, String value, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 14, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_tealBright, _lavender]),
            ),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12, height: 1.1)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ▼▼▼ UPDATED SAVE LOGIC ▼▼▼
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final d = widget.data;
    final loan = _numParse(d.loanAmount);
    final ratePct = _numParse(d.interestRatePct);
    final periodNum = _numParse(d.paymentPeriod);
    final periodInt = periodNum.isFinite ? periodNum.round() : 0;
    final totalInterest = loan * (ratePct / 100.0) * periodInt;
    final totalPayment = loan + totalInterest;
    final monthlyPayment = periodInt > 0 ? totalPayment / periodInt : 0;
    final monthlyBenefit = periodInt > 0 ? totalInterest / periodInt : 0;

    final payload = {
      'name': d.name,
      'gender': d.gender,
      'icNo': d.icNo,
      'address': d.address,
      'phone': d.phone,
      'work': d.work,
      'incomeAmount': _numParse(d.incomeAmount),
      'loanAmount': loan,
      'loanDate': Timestamp.fromDate(d.loanDate),
      'interestRatePct': ratePct,
      'paymentPeriod': periodInt,
      'nation': d.nation,
      'status': d.status,
      'calc': {
        'totalInterest': totalInterest,
        'totalPayment': totalPayment,
        'monthlyPayment': monthlyPayment,
        'monthlyBenefit': monthlyBenefit,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      // 1. Save to Firestore
      final ref = await FirebaseFirestore.instance
          .collection('userloneregister')
          .add(payload);

      if (!mounted) return;

      // 2. Show Success Dialog with Options
      await showDialog(
        context: context,
        barrierDismissible: false, // User must choose an option
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A113B),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1))),
            title: const Text('Registration Successful',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text(
              'The debtor has been registered.\nDo you want to upload supporting documents (ID, Bank Statements, etc.) now?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Not Now: Go Home
                  Navigator.of(dialogContext).pop(); // Close dialog
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home', (route) => false); // Go home
                },
                child: const Text('Not Now',
                    style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tealBright,
                  foregroundColor: const Color(0xFF0B0220),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Now'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  // Navigate to DocUploadPage with the new ID
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocUploadPage(debtorId: ref.id),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... [Keep build method identical to previous version] ...
    // Just ensure the _save function call is correct in the button
    final d = widget.data;
    final dateStr =
        '${d.loanDate.year}-${d.loanDate.month.toString().padLeft(2, '0')}-${d.loanDate.day.toString().padLeft(2, '0')}';
    final loan = _numParse(d.loanAmount);
    final ratePct = _numParse(d.interestRatePct);
    final period = _numParse(d.paymentPeriod);
    final p = period.round();
    final totalInterest = loan * (ratePct / 100.0) * p;
    final totalPayment = loan + totalInterest;
    final monthlyPayment = p > 0 ? totalPayment / p : 0;
    final monthlyBenefit = p > 0 ? totalInterest / p : 0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: const CustomAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0x3312E6FF), Color(0x33B794F4)],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                              colors: [_tealBright, _lavender]),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.receipt_long,
                                size: 18, color: Colors.black87),
                            SizedBox(width: 6),
                            Text(
                              'Summary • Registration',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.verified, color: Colors.white24),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Data List
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _line('Name', d.name),
                        _line('Gender', d.gender),
                        _line('IC No', d.icNo),
                        _line('Address', d.address),
                        _line('Phone Number', d.phone),
                        _line('Work', d.work),
                        _line('Income Amount', d.incomeAmount),
                        _line('Loan Amount', d.loanAmount),
                        _line('Loan Date', dateStr),
                        _line('Interest Rate (%)', d.interestRatePct),
                        _line('Payment Period', d.paymentPeriod),
                        _line('Nation', d.nation),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 160,
                                child: Text('Status:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: Colors.amber.withOpacity(0.5)),
                                ),
                                child: Text(d.status.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 18),
                  // Metrics
                  Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: [
                      _metricTile('Total Interest', _rm(totalInterest),
                          Icons.trending_up),
                      _metricTile('Total Payment', _rm(totalPayment),
                          Icons.payments_outlined),
                      _metricTile('MONTHLY PAYMENT', _rm(monthlyPayment),
                          Icons.calendar_month),
                      _metricTile('MONTHLY BENEFIT (RM)', _rm(monthlyBenefit),
                          Icons.ssid_chart_outlined),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bg,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _saving ? 'Saving...' : 'Confirm & Register',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
