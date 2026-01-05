import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// 1. Import PDF and Printing packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AllDebtorsPage extends StatefulWidget {
  const AllDebtorsPage({super.key});

  @override
  State<AllDebtorsPage> createState() => _AllDebtorsPageState();
}

class _AllDebtorsPageState extends State<AllDebtorsPage> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _loans = [];
  Map<String, List<QueryDocumentSnapshot>> _paymentsMap = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final loansSnapshot =
        await FirebaseFirestore.instance.collection('userloneregister').get();
    final loans = loansSnapshot.docs;
    final payments = <String, List<QueryDocumentSnapshot>>{};
    for (final loanDoc in loans) {
      final paymentsSnapshot = await loanDoc.reference
          .collection('payments')
          .orderBy('dueDate')
          .get();
      payments[loanDoc.id] = paymentsSnapshot.docs;
    }
    if (mounted) {
      setState(() {
        _loans = loans;
        _paymentsMap = payments;
        _isLoading = false;
      });
    }
  }

  // Helper to group payments by month
  Map<String, List<QueryDocumentSnapshot>> _groupPaymentsByMonth(
      List<QueryDocumentSnapshot> payments) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    for (final payment in payments) {
      final data = payment.data() as Map<String, dynamic>?;
      if (data == null) continue;
      final dueDate = _asDate(data['dueDate']);
      if (dueDate != null) {
        final monthKey = DateFormat('yyyy-MM').format(dueDate);
        grouped.putIfAbsent(monthKey, () => []).add(payment);
      }
    }
    return grouped;
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return DateFormat('dd/MM/yyyy').format(d);
  }

  DateTime? _asDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // 2. Wrap the body in a Scaffold to add the Print button
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: !_isLoading && _loans.isNotEmpty
          ? FloatingActionButton(
              onPressed: _printReport,
              backgroundColor: const Color(0xFF1E3A8A),
              tooltip: 'Print Report',
              child: const Icon(Icons.print, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loans.isEmpty) {
      return const Center(
        child: Text(
          "No loan records found.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loanDoc = _loans[index];
        final loanData = loanDoc.data() as Map<String, dynamic>;
        final loanPayments = _paymentsMap[loanDoc.id] ?? [];
        final debtorName = loanData['name'] ?? 'Unknown Name';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: ExpansionTile(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            collapsedShape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              debtorName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
            subtitle: Text("Doc ID: ${loanDoc.id}"),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E3A8A),
              child: Text(
                (index + 1).toString(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            children: [
              if (loanPayments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No payments recorded for this loan."),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildPaymentsTable(loanPayments),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  DataTable _buildPaymentsTable(List<QueryDocumentSnapshot> payments) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Due Date')),
        DataColumn(label: Text('Payment Date')),
        DataColumn(label: Text('Principal')),
        DataColumn(label: Text('Interest')),
        DataColumn(label: Text('Pending Interest')),
        DataColumn(label: Text('Loan Balance')),
      ],
      rows: payments.map((paymentDoc) {
        final data = paymentDoc.data() as Map<String, dynamic>;
        String formatNum(dynamic value) {
          if (value is num) return value.toStringAsFixed(2);
          return '-';
        }

        return DataRow(cells: [
          DataCell(Text(_fmtDate(_asDate(data['dueDate'])))),
          DataCell(Text(_fmtDate(_asDate(data['paymentDate'])))),
          DataCell(Text(formatNum(data['principal']))),
          DataCell(Text(formatNum(data['interest']))),
          DataCell(Text(formatNum(data['pendingInterest']))),
          DataCell(Text(formatNum(data['loanBalance']))),
        ]);
      }).toList(),
    );
  }

  // #######################################################################
  // ## NEW PDF GENERATION AND PRINTING LOGIC
  // #######################################################################

  Future<void> _printReport() async {
    final doc = await _generateDebtorsPdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc,
    );
  }

  Future<Uint8List> _generateDebtorsPdf() async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('All Debtors Report',
                    style: pw.TextStyle(font: font, fontSize: 24)),
                pw.Text(DateFormat.yMMMd().format(DateTime.now()),
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          List<pw.Widget> content = [];

          for (final loanDoc in _loans) {
            final loanData = loanDoc.data() as Map<String, dynamic>;
            final debtorName = loanData['name'] ?? 'Unknown Name';
            final loanPayments = _paymentsMap[loanDoc.id] ?? [];
            final groupedPayments = _groupPaymentsByMonth(loanPayments);
            final sortedMonths = groupedPayments.keys.toList()..sort();

            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20, bottom: 5),
                child: pw.Text(
                  debtorName,
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey800),
                ),
              ),
            );

            if (sortedMonths.isEmpty) {
              content.add(pw.Text('No payments recorded.',
                  style: pw.TextStyle(
                      font: font, fontStyle: pw.FontStyle.italic)));
            } else {
              for (final monthKey in sortedMonths) {
                final monthPayments = groupedPayments[monthKey]!;
                final displayMonth = DateFormat.yMMMM()
                    .format(DateFormat('yyyy-MM').parse(monthKey));

                content.add(pw.Text(displayMonth,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)));
                content.add(pw.SizedBox(height: 5));
                content.add(
                  pw.Table.fromTextArray(
                    headers: [
                      'Due Date',
                      'Principal',
                      'Interest',
                      'Pending',
                      'Balance'
                    ],
                    headerStyle: pw.TextStyle(
                        font: font, fontWeight: pw.FontWeight.bold),
                    cellStyle: pw.TextStyle(font: font),
                    cellAlignment: pw.Alignment.centerRight,
                    cellAlignments: {0: pw.Alignment.centerLeft},
                    data: monthPayments.map((paymentDoc) {
                      final data = paymentDoc.data() as Map<String, dynamic>;
                      return [
                        _fmtDate(_asDate(data['dueDate'])),
                        currencyFormat.format(data['principal'] ?? 0),
                        currencyFormat.format(data['interest'] ?? 0),
                        currencyFormat.format(data['pendingInterest'] ?? 0),
                        currencyFormat.format(data['loanBalance'] ?? 0),
                      ];
                    }).toList(),
                  ),
                );
                content.add(pw.SizedBox(height: 15));
              }
            }
            content.add(pw.Divider(height: 20));
          }
          return content;
        },
      ),
    );
    return doc.save();
  }
}
