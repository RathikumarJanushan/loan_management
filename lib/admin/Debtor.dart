import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/appbar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class adminDebtorPage extends StatefulWidget {
  const adminDebtorPage({super.key});
  @override
  State<adminDebtorPage> createState() => _adminDebtorPageState();
}

class _adminDebtorPageState extends State<adminDebtorPage> {
  final _name = TextEditingController();
  final _ic = TextEditingController();
  bool _loading = false;
  DocumentSnapshot<Map<String, dynamic>>? _doc;
  List<DocumentSnapshot<Map<String, dynamic>>> _payments = [];

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: const Color(0xFFFFFAE6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB5C7D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7FD0D0), width: 2),
        ),
      );

  Future<void> _search() async {
    final ic = _ic.text.trim();
    if (ic.isEmpty) return;
    setState(() {
      _loading = true;
      _doc = null;
      _payments = [];
    });
    final qs = await FirebaseFirestore.instance
        .collection('userloneregister')
        .where('icNo', isEqualTo: ic)
        .limit(1)
        .get();

    if (qs.docs.isNotEmpty) {
      _doc = qs.docs.first;
      if (_name.text.trim().isEmpty) {
        _name.text = _doc!.data()?['name'] ?? '';
      }
      await _fetchPayments();
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _fetchPayments() async {
    if (_doc == null) return;
    final paymentsQs = await FirebaseFirestore.instance
        .collection('userloneregister')
        .doc(_doc!.id)
        .collection('payments')
        .orderBy('dueDate')
        .get();
    if (mounted) {
      setState(() {
        _payments = paymentsQs.docs;
      });
    }
  }

  Future<void> _showAddPaymentDialog(DateTime dueDate, int paidRowIndex) async {
    final amountController = TextEditingController();
    DateTime? selectedDate;
    if (!mounted) return;

    InputDecoration dialogInputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7FD0D0), width: 2),
        ));

    await showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  backgroundColor: const Color(0xFF1A113B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.white.withOpacity(0.2))),
                  title: const Text('Add Payment',
                      style: TextStyle(color: Colors.white)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: amountController,
                        style: const TextStyle(color: Colors.white),
                        decoration: dialogInputDec('Amount Paid'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true)),
                    const SizedBox(height: 16),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white24),
                            color: Colors.white.withOpacity(0.1)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  selectedDate == null
                                      ? 'Select Date Paid'
                                      : _fmtDate(selectedDate!),
                                  style: const TextStyle(color: Colors.white)),
                              IconButton(
                                  icon: const Icon(Icons.calendar_today,
                                      color: Colors.white70),
                                  onPressed: () async {
                                    final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2101));
                                    if (pickedDate != null) {
                                      setDialogState(
                                          () => selectedDate = pickedDate);
                                    }
                                  })
                            ]))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white70))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7FD0D0),
                            foregroundColor: const Color(0xFF0B0220)),
                        onPressed: () async {
                          final userInputAmount =
                              double.tryParse(amountController.text);
                          if (userInputAmount == null ||
                              userInputAmount <= 0 ||
                              selectedDate == null) return;

                          final loanData = _doc?.data();
                          final calcData = loanData?['calc'];
                          if (loanData == null || calcData == null) return;

                          final firestore = FirebaseFirestore.instance;
                          final paymentsRef = firestore
                              .collection('userloneregister')
                              .doc(_doc!.id)
                              .collection('payments');

                          final numExistingPayments = _payments.length;
                          bool isSkipPayment =
                              paidRowIndex > numExistingPayments;

                          if (isSkipPayment) {
                            final batch = firestore.batch();
                            double totalSkippedPaymentAmount = 0;

                            final lastPaymentData = _payments.last.data();
                            double runningLoanBalance =
                                ((lastPaymentData?['loanBalance'] as num?) ?? 0)
                                    .toDouble();
                            double runningLargeLoanBalance =
                                ((lastPaymentData?['largeLoanBalance']
                                            as num?) ??
                                        0)
                                    .toDouble();

                            final monthlyPayment =
                                (calcData['monthlyPayment'] as num?) ?? 0;
                            final monthlyBenefit =
                                (calcData['monthlyBenefit'] as num?) ?? 0;
                            final loanDate = _asDate(loanData['loanDate'])!;

                            for (int i = numExistingPayments;
                                i < paidRowIndex;
                                i++) {
                              final autoFilledDueDate = DateTime(loanDate.year,
                                  loanDate.month + (i + 1), loanDate.day);
                              final interest = monthlyBenefit;
                              final principal = monthlyPayment - monthlyBenefit;

                              runningLoanBalance -= principal.toDouble();
                              runningLargeLoanBalance -=
                                  monthlyPayment.toDouble();
                              totalSkippedPaymentAmount +=
                                  monthlyPayment.toDouble();

                              final autoFilledPayment = {
                                'amountPaid': monthlyPayment,
                                'paymentDate':
                                    Timestamp.fromDate(selectedDate!),
                                'dueDate':
                                    Timestamp.fromDate(autoFilledDueDate),
                                'interest': interest,
                                'principal': principal,
                                'loanBalance': runningLoanBalance,
                                'largeLoanBalance': runningLargeLoanBalance,
                                'pendingInterest': runningLargeLoanBalance -
                                    runningLoanBalance,
                                'isAutoFilled': true,
                              };
                              batch.set(paymentsRef.doc(), autoFilledPayment);
                            }

                            final adjustedAmountPaid =
                                userInputAmount - totalSkippedPaymentAmount;
                            final finalInterest = monthlyBenefit;
                            final finalPrincipal =
                                adjustedAmountPaid - finalInterest;
                            final finalLoanBalance =
                                runningLoanBalance - finalPrincipal;
                            final finalLargeLoanBalance =
                                runningLargeLoanBalance - adjustedAmountPaid;

                            final userPaidPayment = {
                              'amountPaid': adjustedAmountPaid,
                              'paymentDate': Timestamp.fromDate(selectedDate!),
                              'dueDate': Timestamp.fromDate(dueDate),
                              'interest': finalInterest,
                              'principal': finalPrincipal,
                              'loanBalance': finalLoanBalance,
                              'largeLoanBalance': finalLargeLoanBalance,
                              'pendingInterest':
                                  finalLargeLoanBalance - finalLoanBalance,
                            };
                            batch.set(paymentsRef.doc(), userPaidPayment);
                            await batch.commit();
                          } else {
                            Map<String, dynamic> newPaymentData = {
                              'amountPaid': userInputAmount,
                              'paymentDate': Timestamp.fromDate(selectedDate!),
                              'dueDate': Timestamp.fromDate(dueDate),
                            };

                            final monthlyBenefit =
                                (calcData['monthlyBenefit'] as num?) ?? 0;
                            final interest = monthlyBenefit;
                            final principal = userInputAmount - monthlyBenefit;

                            if (_payments.isEmpty) {
                              final totalPayment =
                                  (calcData['totalPayment'] as num?) ?? 0;
                              final loanAmount =
                                  (loanData['loanAmount'] as num?) ?? 0;
                              final loanBalance =
                                  loanAmount.toDouble() - principal;
                              final largeLoanBalance =
                                  totalPayment.toDouble() - userInputAmount;

                              newPaymentData['loanBalance'] = loanBalance;
                              newPaymentData['largeLoanBalance'] =
                                  largeLoanBalance;
                              newPaymentData['pendingInterest'] =
                                  largeLoanBalance - loanBalance;
                            } else {
                              final lastPaymentData = _payments.last.data();
                              final prevLoanBalance =
                                  (lastPaymentData?['loanBalance'] as num?) ??
                                      0;
                              final prevLargeLoanBalance =
                                  (lastPaymentData?['largeLoanBalance']
                                          as num?) ??
                                      0;
                              final loanBalance =
                                  prevLoanBalance.toDouble() - principal;
                              final largeLoanBalance =
                                  prevLargeLoanBalance.toDouble() -
                                      userInputAmount;

                              newPaymentData['loanBalance'] = loanBalance;
                              newPaymentData['largeLoanBalance'] =
                                  largeLoanBalance;
                              newPaymentData['pendingInterest'] =
                                  largeLoanBalance - loanBalance;
                            }
                            newPaymentData['interest'] = interest;
                            newPaymentData['principal'] = principal;
                            await paymentsRef.add(newPaymentData);
                          }

                          if (mounted) {
                            Navigator.of(context).pop();
                            _fetchPayments();
                          }
                        },
                        child: const Text('Add Payment'))
                  ],
                )));
  }

  String _fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  DateTime? _asDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Widget _kv(String k, Object? v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 180,
            child: Text(k,
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w700))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(
                v is Timestamp
                    ? _fmtDate(v.toDate())
                    : (v is DateTime ? _fmtDate(v) : '${v ?? '-'}'),
                style: const TextStyle(color: Colors.white)))
      ]));

  DataTable _scheduleTable({
    required DateTime loanDate,
    required int months,
    required List<DocumentSnapshot<Map<String, dynamic>>> payments,
  }) {
    final rows = List.generate(months, (i) {
      final due =
          DateTime(loanDate.year, loanDate.month + (i + 1), loanDate.day);
      DocumentSnapshot? paymentForThisRow;
      for (final p in payments) {
        final pDueDate = _asDate(p.data()?['dueDate']);
        if (pDueDate != null &&
            pDueDate.year == due.year &&
            pDueDate.month == due.month &&
            pDueDate.day == due.day) {
          paymentForThisRow = p;
          break;
        }
      }
      final paymentData = paymentForThisRow?.data() as Map<String, dynamic>?;
      final pendingInterestValue = paymentData?['pendingInterest'];
      final pendingInterestText = pendingInterestValue is num
          ? pendingInterestValue.toStringAsFixed(2)
          : '-';
      return DataRow(cells: [
        DataCell(
            Text(_fmtDate(due), style: const TextStyle(color: Colors.white))),
        DataCell(Text(
            paymentData?['paymentDate'] == null
                ? '-'
                : _fmtDate(_asDate(paymentData!['paymentDate'])!),
            style: const TextStyle(color: Colors.white))),
        DataCell(Text('${paymentData?['amountPaid'] ?? '-'}',
            style: const TextStyle(color: Colors.white))),
        DataCell(Text('${paymentData?['interest'] ?? '-'}',
            style: const TextStyle(color: Colors.white))),
        DataCell(Text('${paymentData?['principal'] ?? '-'}',
            style: const TextStyle(color: Colors.white))),
        DataCell(Text('${paymentData?['loanBalance'] ?? '-'}',
            style: const TextStyle(color: Colors.white))),
        DataCell(Text('${paymentData?['largeLoanBalance'] ?? '-'}',
            style: const TextStyle(color: Colors.white))),
        DataCell(Text(pendingInterestText,
            style: const TextStyle(color: Colors.white))),
        DataCell(
          paymentForThisRow != null
              ? Center(
                  child: Text('PAID',
                      style: TextStyle(
                          color: (paymentData?['isAutoFilled'] == true)
                              ? Colors.amber.shade600
                              : Colors.greenAccent.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)))
              : OutlinedButton.icon(
                  onPressed: () => _showAddPaymentDialog(due, i),
                  icon: const Icon(Icons.add_card, size: 16),
                  label: const Text('Pay'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38))),
        ),
        DataCell(
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white70),
            onPressed: () {
              if (_doc?.data() != null) {
                // This now calls the fully implemented function below
                _printInstallmentReport(
                  loanData: _doc!.data()!,
                  paymentData: paymentData,
                  dueDate: due,
                  installmentNumber: i + 1,
                );
              }
            },
          ),
        ),
      ]);
    });
    return DataTable(
        headingRowColor:
            MaterialStateProperty.all(Colors.white.withOpacity(0.06)),
        columns: const [
          DataColumn(
              label: Text('Due date', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Date of Payment',
                  style: TextStyle(color: Colors.white))),
          DataColumn(
              label:
                  Text('Amount paid', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Interest', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Principal', style: TextStyle(color: Colors.white))),
          DataColumn(
              label:
                  Text('LOAN BALANCE', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('LARGE LOAN BALANCE',
                  style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Pending Interest',
                  style: TextStyle(color: Colors.white))),
          DataColumn(
              label:
                  Text('Make Payment', style: TextStyle(color: Colors.white))),
          DataColumn(
              label:
                  Text('Print receipt', style: TextStyle(color: Colors.white))),
        ],
        rows: rows,
        columnSpacing: 28,
        dividerThickness: 0.6,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48);
  }

  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(const Color(0xff50e4d4), 'Interest Paid'),
        const SizedBox(width: 24),
        _legendItem(const Color(0xff27b6d9), 'Principal Paid'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPaymentsChart() {
    if (_payments.isEmpty) return const SizedBox.shrink();
    const interestColor = Color(0xff50e4d4);
    const principalColor = Color(0xff27b6d9);
    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < _payments.length; i++) {
      final paymentData = _payments[i].data();
      if (paymentData == null) continue;
      final interest = (paymentData['interest'] as num?)?.toDouble() ?? 0.0;
      final principal = (paymentData['principal'] as num?)?.toDouble() ?? 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: interest,
              color: interestColor,
              width: 15,
              borderRadius: BorderRadius.zero,
            ),
            BarChartRodData(
              toY: principal,
              color: principalColor,
              width: 15,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }
    Widget bottomTitles(double value, TitleMeta meta) {
      final style =
          TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10);
      String text = '';
      if (value.toInt() < _payments.length) {
        final dueDate = _asDate(_payments[value.toInt()].data()?['dueDate']);
        if (dueDate != null) {
          text = DateFormat('MMMyy').format(dueDate);
        }
      }
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(text, style: style),
      );
    }

    Widget leftTitles(double value, TitleMeta meta) {
      final style =
          TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10);
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(value.toInt().toString(), style: style),
      );
    }

    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitles,
                    reservedSize: 28)),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: leftTitles,
                    reservedSize: 40)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (BarChartGroupData group) {
                return Colors.blueGrey;
              },
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String type = rodIndex == 0 ? 'Interest' : 'Principal';
                return BarTooltipItem(
                  '$type\n',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: rod.toY.toStringAsFixed(2),
                      style: TextStyle(
                        color: rod.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ############## PDF REPORTING LOGIC ##############

  // ### 1. Prints a report for a SINGLE installment ###
  Future<void> _printInstallmentReport({
    required Map<String, dynamic> loanData,
    required Map<String, dynamic>? paymentData,
    required DateTime dueDate,
    required int installmentNumber,
  }) async {
    final doc = pw.Document();
    final calcData = loanData['calc'] as Map<String, dynamic>? ?? {};

    String formatValue(dynamic value) {
      if (value is num) return value.toStringAsFixed(2);
      return value?.toString() ?? 'N/A';
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Payment Installment Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Header(level: 2, text: 'Debtor and Loan Details'),
              pw.Table.fromTextArray(
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                data: <List<String>>[
                  <String>['Name', formatValue(loanData['name'])],
                  <String>['IC No.', formatValue(loanData['icNo'])],
                  <String>['Loan Amount', formatValue(loanData['loanAmount'])],
                  <String>[
                    'Total Payment',
                    formatValue(calcData['totalPayment'])
                  ],
                  <String>[
                    'Monthly Payment',
                    formatValue(calcData['monthlyPayment'])
                  ],
                ],
              ),
              pw.Divider(height: 20),
              pw.Header(
                level: 2,
                text: 'Installment #$installmentNumber Details',
              ),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                data: <List<String>>[
                  <String>['Field', 'Value'],
                  <String>['Due Date', _fmtDate(dueDate)],
                  <String>['Status', paymentData != null ? 'Paid' : 'Pending'],
                  <String>[
                    'Date of Payment',
                    paymentData?['paymentDate'] != null
                        ? _fmtDate(_asDate(paymentData!['paymentDate'])!)
                        : 'N/A'
                  ],
                  <String>[
                    'Amount Paid',
                    formatValue(paymentData?['amountPaid'])
                  ],
                  <String>['Interest', formatValue(paymentData?['interest'])],
                  <String>['Principal', formatValue(paymentData?['principal'])],
                  <String>[
                    'Loan Balance',
                    formatValue(paymentData?['loanBalance'])
                  ],
                  <String>[
                    'Large Loan Balance',
                    formatValue(paymentData?['largeLoanBalance'])
                  ],
                  <String>[
                    'Pending Interest',
                    formatValue(paymentData?['pendingInterest'])
                  ],
                ],
              ),
              pw.Spacer(),
              pw.Footer(
                title:
                    pw.Text('Report generated on ${_fmtDate(DateTime.now())}'),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  // ### 2. Prints a report for the ENTIRE loan ###
  Future<void> _printFullReport() async {
    if (_doc == null) return;
    final doc = await _generateFullReportPdf();
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save());
  }

  Future<pw.Document> _generateFullReportPdf() async {
    final doc = pw.Document();
    final loanData = _doc!.data()!;
    final calcData = loanData['calc'] as Map<String, dynamic>? ?? {};

    double totalAmountPaid = 0;
    double totalPrincipalPaid = 0;
    double totalInterestPaid = 0;
    double remainingBalance =
        (loanData['loanAmount'] as num?)?.toDouble() ?? 0.0;

    for (final paymentDoc in _payments) {
      final data = paymentDoc.data();
      if (data == null) continue;
      totalAmountPaid += (data['amountPaid'] as num?) ?? 0;
      totalPrincipalPaid += (data['principal'] as num?) ?? 0;
      totalInterestPaid += (data['interest'] as num?) ?? 0;
      remainingBalance = (data['loanBalance'] as num?)?.toDouble() ?? 0;
    }

    String formatValue(dynamic value) {
      if (value is num) return value.toStringAsFixed(2);
      return value?.toString() ?? 'N/A';
    }

    final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Full Loan Payment Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(_fmtDate(DateTime.now())),
            ],
          ),
        ),
        build: (context) => [
          pw.Header(level: 1, text: 'Debtor and Loan Details'),
          pw.Table.fromTextArray(
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: headerStyle,
            data: <List<String>>[
              <String>['Name:', formatValue(loanData['name'])],
              <String>['IC No.:', formatValue(loanData['icNo'])],
              <String>['Loan Amount:', formatValue(loanData['loanAmount'])],
              <String>[
                'Monthly Payment:',
                formatValue(calcData['monthlyPayment'])
              ],
            ],
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
          ),
          pw.Divider(height: 20),
          pw.Header(level: 1, text: 'Payment History'),
          pw.Table.fromTextArray(
            headerStyle: headerStyle,
            cellAlignment: pw.Alignment.centerRight,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft
            },
            headers: [
              'Due Date',
              'Payment Date',
              'Amount Paid',
              'Principal',
              'Interest',
              'Pending',
              'Balance'
            ],
            data: _payments.map((paymentDoc) {
              final data = paymentDoc.data()!;
              return [
                _fmtDate(_asDate(data['dueDate'])!),
                _fmtDate(_asDate(data['paymentDate'])!),
                formatValue(data['amountPaid']),
                formatValue(data['principal']),
                formatValue(data['interest']),
                formatValue(data['pendingInterest']),
                formatValue(data['loanBalance']),
              ];
            }).toList(),
          ),
          pw.Divider(height: 20),
          pw.Header(level: 1, text: 'Loan Summary'),
          pw.Table.fromTextArray(
            border: null,
            cellAlignment: pw.Alignment.centerLeft,
            headerStyle: headerStyle,
            data: <List<String>>[
              <String>['Total Amount Paid:', formatValue(totalAmountPaid)],
              <String>[
                'Total Principal Paid:',
                formatValue(totalPrincipalPaid)
              ],
              <String>['Total Interest Paid:', formatValue(totalInterestPaid)],
              <String>[
                'Remaining Loan Balance:',
                formatValue(remainingBalance)
              ],
            ],
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
            },
          ),
        ],
      ),
    );
    return doc;
  }
  // ############## END OF PDF LOGIC ##############

  @override
  Widget build(BuildContext context) {
    final data = _doc?.data();
    final paymentPeriod = (data?['paymentPeriod'] is int)
        ? (data!['paymentPeriod'] as int)
        : (data?['paymentPeriod'] is num
            ? (data!['paymentPeriod'] as num).round()
            : 0);
    final loanDate = _asDate(data?['loanDate']);

    num? totalMinPayment;
    final calcData = data?['calc'];
    if (calcData is Map) {
      final monthlyPayment = calcData['monthlyPayment'];
      final monthlyBenefit = calcData['monthlyBenefit'];
      if (monthlyPayment is num && monthlyBenefit is num) {
        totalMinPayment = monthlyPayment + monthlyBenefit;
      }
    }

    return Scaffold(
        backgroundColor: const Color(0xFF0B0220),
        body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Debtor',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                                colors: [Color(0xFF7FD0D0), Color(0xFFB794F4)])
                            .createShader(const Rect.fromLTWH(0, 0, 260, 40)))),
              const SizedBox(height: 20),
              Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                        width: 320,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Name',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextField(
                                  controller: _name,
                                  decoration: _dec(''),
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black)
                            ])),
                    SizedBox(
                        width: 260,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('IC',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              TextField(
                                  controller: _ic,
                                  decoration: _dec(''),
                                  style: const TextStyle(color: Colors.black),
                                  cursorColor: Colors.black,
                                  onSubmitted: (_) => _search())
                            ])),
                    ElevatedButton.icon(
                        onPressed: _loading ? null : _search,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.search),
                        label: const Text('Search'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))))
                  ]),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator()))
              else if (_doc == null)
                const Text('No record loaded.',
                    style: TextStyle(color: Colors.white60))
              else if (data != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Print Full Report'),
                    onPressed: _printFullReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FD0D0),
                      foregroundColor: const Color(0xFF0B0220),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF120834),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _kv('Name', data['name']),
                          _kv('IC No', data['icNo']),
                          _kv('Gender', data['gender']),
                          _kv('Address', data['address']),
                          _kv('Phone', data['phone']),
                          _kv('Work', data['work']),
                          _kv('Income Amount', data['incomeAmount']),
                          _kv('Loan Amount', data['loanAmount']),
                          _kv('Loan Date', data['loanDate']),
                          _kv('Interest Rate (%)', data['interestRatePct']),
                          _kv('Payment Period (months)', data['paymentPeriod']),
                          _kv('Nation', data['nation']),
                          const Divider(color: Colors.white12, height: 24),
                          const Text('Calculated',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _kv('Total Interest', data['calc']?['totalInterest']),
                          _kv('Total Payment', data['calc']?['totalPayment']),
                          _kv('Monthly Payment',
                              data['calc']?['monthlyPayment']),
                          _kv('Monthly Benefit',
                              data['calc']?['monthlyBenefit']),
                          _kv('Total Minimum Payment for Month',
                              totalMinPayment),
                          const SizedBox(height: 8),
                          _kv('Created At', data['createdAt']),
                          _kv('Doc ID', _doc!.id)
                        ])),
                const SizedBox(height: 24),
                if (_payments.isNotEmpty) ...[
                  _buildChartLegend(),
                  const SizedBox(height: 16),
                  _buildPaymentsChart(),
                  const SizedBox(height: 24),
                ],
                Row(children: [
                  const Text('Payments Schedule',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 12),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24)),
                      child: Text(
                          'Payment Period (months): ${paymentPeriod.clamp(0, 100000)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)))
                ]),
                const SizedBox(height: 10),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF120834),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12)),
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: loanDate == null || paymentPeriod <= 0
                            ? const Text(
                                'No schedule. Missing Loan Date or Payment Period.',
                                style: TextStyle(color: Colors.white60))
                            : _scheduleTable(
                                loanDate: loanDate,
                                months: paymentPeriod,
                                payments: _payments)))
              ]
            ])));
  }
}
