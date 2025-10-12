import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/appbar.dart';

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

  // palette
  static const _bg = Color(0xFF0B0220);
  static const _card = Color(0xFF120834);
  static const _teal = Color(0xFF5FB2B2);
  static const _tealBright = Color(0xFF7FD0D0);
  static const _lavender = Color(0xFFB794F4);

  Widget _line(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          '$k: $v',
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      );

  double _numParse(String s) {
    if (s.isEmpty) return 0;
    final cleaned = s.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }

  String _rm(num x) => 'RM ${x.toStringAsFixed(2)}';

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
      'paymentPeriod': periodInt, // months
      'nation': d.nation,
      'calc': {
        'totalInterest': totalInterest,
        'totalPayment': totalPayment,
        'monthlyPayment': monthlyPayment,
        'monthlyBenefit': monthlyBenefit,
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref = await FirebaseFirestore.instance
          .collection('userloneregister')
          .add(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registered. ID: ${ref.id}')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
      setState(() => _saving = false);
    }
  }

  Widget _metricTile(String title, String value, IconData icon) {
    return Container(
      width: 360,
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

  @override
  Widget build(BuildContext context) {
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
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          margin: const EdgeInsets.all(20),
          // outer gradient border
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
            child: ListView(
              children: [
                // header
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
                const SizedBox(height: 16),

                // plain lines section (as requested earlier)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Name', d.name),
                      _line('Gender', d.gender),
                      _line('Ic No', d.icNo),
                      _line('Address', d.address),
                      _line('Phone number', d.phone),
                      _line('Work', d.work),
                      _line('Income Amount', d.incomeAmount),
                      _line('Loan amount', d.loanAmount),
                      _line('Loan date', dateStr),
                      _line('Interest Rate (%)', d.interestRatePct),
                      _line('Payment Period', d.paymentPeriod),
                      _line('Nation', d.nation),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 18),

                // calculated tiles
                Wrap(
                  spacing: 0,
                  runSpacing: 0,
                  children: [
                    _metricTile(
                      'Total interest',
                      _rm(totalInterest),
                      Icons.trending_up,
                    ),
                    _metricTile(
                      'Total payment',
                      _rm(totalPayment),
                      Icons.payments_outlined,
                    ),
                    _metricTile(
                      'MONTHLY PAYMENT',
                      _rm(monthlyPayment),
                      Icons.calendar_month,
                    ),
                    _metricTile(
                      'MONTHLY BENEFIT (RM)',
                      _rm(monthlyBenefit),
                      Icons.ssid_chart_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // info bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.white54, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Confirm to save this registration. A random document ID will be created in Firestore at collection "userloneregister".',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _bg,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
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
                    label: Text(_saving ? 'Saving...' : 'Confirm & Register'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
