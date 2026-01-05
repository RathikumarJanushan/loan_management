import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Enum to define the report type
enum ReportType { monthly, yearly }

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  Map<String, List<QueryDocumentSnapshot>> _paymentsMap = {};
  Map<String, Map<String, double>> _monthlySummaries = {};
  Map<String, Map<String, double>> _yearlySummaries = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final loansSnapshot = await FirebaseFirestore.instance
        .collection('userloneregister')
        .get();
    final loans = loansSnapshot.docs;
    if (loans.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final payments = <String, List<QueryDocumentSnapshot>>{};
    for (final loanDoc in loans) {
      final paymentsSnapshot = await loanDoc.reference
          .collection('payments')
          .orderBy('dueDate')
          .get();
      payments[loanDoc.id] = paymentsSnapshot.docs;
    }
    if (mounted) {
      _paymentsMap = payments;
      _calculateMonthlySummaries();
      _calculateYearlySummaries();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateMonthlySummaries() {
    final summaries = <String, Map<String, double>>{};
    final userMonthlyFinalBalance = <String, Map<String, double>>{};
    _paymentsMap.forEach((userId, payments) {
      for (final paymentDoc in payments) {
        final data = paymentDoc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final dueDate = _asDate(data['dueDate']);
        if (dueDate == null) continue;
        final monthKey = DateFormat('yyyy-MM').format(dueDate);
        summaries.putIfAbsent(
          monthKey,
          () => {
            'principal': 0.0,
            'interest': 0.0,
            'pendingInterest': 0.0,
            'loanBalance': 0.0,
          },
        );
        summaries[monthKey]!['principal'] =
            (summaries[monthKey]!['principal']!) +
            ((data['principal'] as num?) ?? 0);
        summaries[monthKey]!['interest'] =
            (summaries[monthKey]!['interest']!) +
            ((data['interest'] as num?) ?? 0);
        summaries[monthKey]!['pendingInterest'] =
            (summaries[monthKey]!['pendingInterest']!) +
            ((data['pendingInterest'] as num?) ?? 0);
        userMonthlyFinalBalance.putIfAbsent(monthKey, () => {});
        userMonthlyFinalBalance[monthKey]![userId] =
            ((data['loanBalance'] as num?) ?? 0).toDouble();
      }
    });
    summaries.forEach((monthKey, value) {
      double totalMonthBalance = 0;
      if (userMonthlyFinalBalance.containsKey(monthKey)) {
        userMonthlyFinalBalance[monthKey]!.forEach((userId, balance) {
          totalMonthBalance += balance;
        });
      }
      summaries[monthKey]!['loanBalance'] = totalMonthBalance;
    });
    setState(() {
      _monthlySummaries = summaries;
    });
  }

  void _calculateYearlySummaries() {
    final summaries = <String, Map<String, double>>{};
    if (_monthlySummaries.isEmpty) return;
    final sortedMonths = _monthlySummaries.keys.toList()..sort();
    for (var monthKey in sortedMonths) {
      final year = monthKey.substring(0, 4);
      final monthData = _monthlySummaries[monthKey]!;
      summaries.putIfAbsent(
        year,
        () => {
          'principal': 0.0,
          'interest': 0.0,
          'pendingInterest': 0.0,
          'loanBalance': 0.0,
        },
      );
      summaries[year]!['principal'] =
          (summaries[year]!['principal']!) + monthData['principal']!;
      summaries[year]!['interest'] =
          (summaries[year]!['interest']!) + monthData['interest']!;
      summaries[year]!['pendingInterest'] =
          (summaries[year]!['pendingInterest']!) +
          monthData['pendingInterest']!;
      summaries[year]!['loanBalance'] = monthData['loanBalance']!;
    }
    setState(() {
      _yearlySummaries = summaries;
    });
  }

  DateTime? _asDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // We use a Scaffold here mainly to get access to the FloatingActionButton
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit background color
      body: _buildBody(),
      floatingActionButton: _monthlySummaries.isNotEmpty
          ? PopupMenuButton<ReportType>(
              onSelected: (ReportType type) => _printReport(type),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ReportType>>[
                    const PopupMenuItem<ReportType>(
                      value: ReportType.monthly,
                      child: Text('Print Monthly Report'),
                    ),
                    const PopupMenuItem<ReportType>(
                      value: ReportType.yearly,
                      child: Text('Print Yearly Report'),
                    ),
                  ],
              child: const FloatingActionButton(
                onPressed: null, // onPressed is handled by PopupMenuButton
                backgroundColor: Color(0xFF1E3A8A),
                tooltip: 'Print Report',
                child: Icon(Icons.print, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_monthlySummaries.isEmpty) {
      return const Center(
        child: Text(
          "No loan records found to generate a summary.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New KPI cards section
          _buildKpiSection(),
          const SizedBox(height: 16),
          // Existing summary/chart container
          _buildOverallSummaryContainer(),
        ],
      ),
    );
  }

  // NEW WIDGET: Builds the KPI cards for the most recent month
  Widget _buildKpiSection() {
    final sortedMonths = _monthlySummaries.keys.toList()..sort();
    final latestMonthData = _monthlySummaries[sortedMonths.last]!;
    final latestMonthName = DateFormat(
      'MMMM yyyy',
    ).format(DateFormat('yyyy-MM').parse(sortedMonths.last));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Summary for $latestMonthName",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(221, 0, 0, 0),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: [
            _buildKpiCard(
              title: 'Principal Collected',
              value: latestMonthData['principal']!,
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
            _buildKpiCard(
              title: 'Interest Earned',
              value: latestMonthData['interest']!,
              icon: Icons.trending_up,
              color: Colors.blue,
            ),
            _buildKpiCard(
              title: 'Pending Interest',
              value: latestMonthData['pendingInterest']!,
              icon: Icons.hourglass_bottom,
              color: Colors.orange,
            ),
            _buildKpiCard(
              title: 'Total Balance',
              value: latestMonthData['loanBalance']!,
              icon: Icons.pie_chart,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  // NEW WIDGET: A single, reusable KPI card
  Widget _buildKpiCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '',
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 200, // Fixed width for consistent look
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: const Color.fromARGB(255, 226, 4, 4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(value),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(221, 249, 247, 247),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummaryContainer() {
    return DefaultTabController(
      length: 2,
      child: Card(
        elevation: 2,
        color: const Color(0xFF1E3A8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              indicatorColor: Colors.amber,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.list_alt), text: "Monthly Report"),
                Tab(icon: Icon(Icons.bar_chart), text: "Charts"),
              ],
            ),
            SizedBox(
              height: 450,
              child: TabBarView(
                children: [_buildSummaryTextView(), _buildChartsView()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTextView() {
    final sortedMonths = _monthlySummaries.keys.toList()..sort();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "All Users - Monthly Totals",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.white54),
          ...sortedMonths.map((monthKey) {
            final data = _monthlySummaries[monthKey]!;
            final displayMonth = DateFormat.yMMMM().format(
              DateFormat('yyyy-MM').parse(monthKey),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayMonth,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 12.0,
                    children: [
                      _buildOverallSummaryItem("Principal", data['principal']!),
                      _buildOverallSummaryItem("Interest", data['interest']!),
                      _buildOverallSummaryItem(
                        "Pending",
                        data['pendingInterest']!,
                      ),
                      _buildOverallSummaryItem("Balance", data['loanBalance']!),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildChartsView() {
    final sortedMonths = _monthlySummaries.keys.toList()..sort();
    final List<Color> chartColors1 = [
      Colors.cyan.shade300,
      Colors.cyan.shade600,
    ];
    final List<Color> chartColors2 = [
      Colors.teal.shade300,
      Colors.teal.shade600,
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Principal & Interest Paid",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildLegend([
            {'color': chartColors1[0], 'text': 'Interest Paid'},
            {'color': chartColors1[1], 'text': 'Principal Paid'},
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: _buildBarChart(sortedMonths, [
              'interest',
              'principal',
            ], chartColors1),
          ),
          const Divider(color: Colors.white54, height: 32),
          const Text(
            "Pending Interest & Loan Balance",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildLegend([
            {'color': chartColors2[0], 'text': 'Pending Interest'},
            {'color': chartColors2[1], 'text': 'Loan Balance'},
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: _buildBarChart(sortedMonths, [
              'pendingInterest',
              'loanBalance',
            ], chartColors2),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    List<String> sortedMonths,
    List<String> dataKeys,
    List<Color> colors,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final monthKey = sortedMonths[value.toInt()];
                final date = DateFormat('yyyy-MM').parse(monthKey);
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    DateFormat.MMM().format(date),
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                );
              },
              reservedSize: 16,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedMonths.length, (index) {
          final monthKey = sortedMonths[index];
          final data = _monthlySummaries[monthKey]!;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data[dataKeys[0]]!,
                color: colors[0],
                width: 12,
                borderRadius: BorderRadius.zero,
              ),
              BarChartRodData(
                toY: data[dataKeys[1]]!,
                color: colors[1],
                width: 12,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegend(List<Map<String, dynamic>> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Container(width: 10, height: 10, color: item['color']),
              const SizedBox(width: 4),
              Text(
                item['text'],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverallSummaryItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReport(ReportType type) async {
    final doc = await _generatePdf(type);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc);
  }

  Future<Uint8List> _generatePdf(ReportType type) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final String title = type == ReportType.monthly
        ? "Monthly Loan Summary"
        : "Yearly Loan Summary";
    final Map<String, Map<String, double>> data = type == ReportType.monthly
        ? _monthlySummaries
        : _yearlySummaries;
    final List<String> sortedKeys = data.keys.toList()..sort();
    final String dateColumnHeader = type == ReportType.monthly
        ? "Month"
        : "Year";
    final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  title,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                'Generated on: ${DateFormat.yMMMd().format(DateTime.now())}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  dateColumnHeader,
                  'Principal',
                  'Interest',
                  'Pending Interest',
                  'Ending Balance',
                ],
                headerStyle: pw.TextStyle(
                  font: font,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey,
                ),
                cellStyle: pw.TextStyle(font: font),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {0: pw.Alignment.centerLeft},
                data: List<List<String>>.generate(sortedKeys.length, (index) {
                  final key = sortedKeys[index];
                  final rowData = data[key]!;
                  String displayKey = key;
                  if (type == ReportType.monthly) {
                    displayKey = DateFormat.yMMMM().format(
                      DateFormat('yyyy-MM').parse(key),
                    );
                  }
                  return [
                    displayKey,
                    currencyFormat.format(rowData['principal']),
                    currencyFormat.format(rowData['interest']),
                    currencyFormat.format(rowData['pendingInterest']),
                    currencyFormat.format(rowData['loanBalance']),
                  ];
                }),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
