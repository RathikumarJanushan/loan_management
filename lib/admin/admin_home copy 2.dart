// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';

// class AdminHomePage extends StatefulWidget {
//   const AdminHomePage({super.key});

//   @override
//   State<AdminHomePage> createState() => _AdminHomePageState();
// }

// class _AdminHomePageState extends State<AdminHomePage> {
//   bool _isLoading = true;
//   List<QueryDocumentSnapshot> _loans = [];
//   Map<String, List<QueryDocumentSnapshot>> _paymentsMap = {};
//   Map<String, Map<String, double>> _monthlySummaries = {};

//   @override
//   void initState() {
//     super.initState();
//     _fetchData();
//   }

//   Future<void> _fetchData() async {
//     setState(() => _isLoading = true);

//     final loansSnapshot =
//         await FirebaseFirestore.instance.collection('userloneregister').get();
//     final loans = loansSnapshot.docs;

//     final payments = <String, List<QueryDocumentSnapshot>>{};

//     for (final loanDoc in loans) {
//       final paymentsSnapshot = await loanDoc.reference
//           .collection('payments')
//           .orderBy('dueDate')
//           .get();
//       payments[loanDoc.id] = paymentsSnapshot.docs;
//     }

//     if (mounted) {
//       setState(() {
//         _loans = loans;
//         _paymentsMap = payments;
//       });
//       _calculateMonthlySummaries();
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   void _calculateMonthlySummaries() {
//     final summaries = <String, Map<String, double>>{};
//     final userMonthlyFinalBalance = <String, Map<String, double>>{};

//     _paymentsMap.forEach((userId, payments) {
//       for (final paymentDoc in payments) {
//         final data = paymentDoc.data() as Map<String, dynamic>?;
//         if (data == null) continue;

//         final dueDate = _asDate(data['dueDate']);
//         if (dueDate == null) continue;

//         final monthKey = DateFormat('yyyy-MM').format(dueDate);

//         summaries.putIfAbsent(
//             monthKey,
//             () => {
//                   'principal': 0.0,
//                   'interest': 0.0,
//                   'pendingInterest': 0.0,
//                   'loanBalance': 0.0,
//                 });

//         summaries[monthKey]!['principal'] =
//             (summaries[monthKey]!['principal']!) +
//                 ((data['principal'] as num?) ?? 0);
//         summaries[monthKey]!['interest'] = (summaries[monthKey]!['interest']!) +
//             ((data['interest'] as num?) ?? 0);
//         summaries[monthKey]!['pendingInterest'] =
//             (summaries[monthKey]!['pendingInterest']!) +
//                 ((data['pendingInterest'] as num?) ?? 0);

//         userMonthlyFinalBalance.putIfAbsent(monthKey, () => {});
//         userMonthlyFinalBalance[monthKey]![userId] =
//             ((data['loanBalance'] as num?) ?? 0).toDouble();
//       }
//     });

//     summaries.forEach((monthKey, value) {
//       double totalMonthBalance = 0;
//       if (userMonthlyFinalBalance.containsKey(monthKey)) {
//         userMonthlyFinalBalance[monthKey]!.forEach((userId, balance) {
//           totalMonthBalance += balance;
//         });
//       }
//       summaries[monthKey]!['loanBalance'] = totalMonthBalance;
//     });

//     setState(() {
//       _monthlySummaries = summaries;
//     });
//   }

//   String _fmtDate(DateTime? d) {
//     if (d == null) return '-';
//     return DateFormat('dd/MM/yyyy').format(d);
//   }

//   DateTime? _asDate(Object? v) {
//     if (v is Timestamp) return v.toDate();
//     if (v is DateTime) return v;
//     return null;
//   }

//   Map<String, List<QueryDocumentSnapshot>> _groupPaymentsByMonth(
//       List<QueryDocumentSnapshot> payments) {
//     final Map<String, List<QueryDocumentSnapshot>> grouped = {};
//     for (final payment in payments) {
//       final data = payment.data() as Map<String, dynamic>?;
//       if (data == null) continue;

//       final dueDate = _asDate(data['dueDate']);
//       if (dueDate != null) {
//         final monthKey = DateFormat('yyyy-MM').format(dueDate);
//         grouped.putIfAbsent(monthKey, () => []).add(payment);
//       }
//     }
//     return grouped;
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (_loans.isEmpty) {
//       return const Center(
//         child: Text(
//           "No loan records found.",
//           style: TextStyle(fontSize: 18, color: Colors.grey),
//         ),
//       );
//     }

//     // FIXED: Wrap the entire body in a SingleChildScrollView to prevent overflow
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           _buildOverallSummary(),
//           // FIXED: Use ListView.builder directly with shrinkWrap and physics
//           ListView.builder(
//             // 2. Add these two properties
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _loans.length,
//             itemBuilder: (context, index) {
//               final loanDoc = _loans[index];
//               final loanData = loanDoc.data() as Map<String, dynamic>;
//               final loanPayments = _paymentsMap[loanDoc.id] ?? [];
//               final debtorName = loanData['name'] ?? 'Unknown Name';

//               final groupedPayments = _groupPaymentsByMonth(loanPayments);
//               final sortedMonths = groupedPayments.keys.toList()..sort();

//               return Card(
//                 margin:
//                     const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12)),
//                 elevation: 2,
//                 child: ExpansionTile(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   collapsedShape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   title: Text(
//                     debtorName,
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
//                   ),
//                   subtitle: Text("Doc ID: ${loanDoc.id}"),
//                   leading: CircleAvatar(
//                     backgroundColor: const Color(0xFF1E3A8A),
//                     child: Text(
//                       (index + 1).toString(),
//                       style: const TextStyle(
//                           color: Colors.white, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                   children: [
//                     if (loanPayments.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.all(16.0),
//                         child: Text("No payments recorded for this loan."),
//                       )
//                     else
//                       ...sortedMonths.map((monthKey) {
//                         final monthlyPayments = groupedPayments[monthKey]!;
//                         return _buildMonthlyReport(monthKey, monthlyPayments);
//                       }).toList(),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildOverallSummary() {
//     if (_monthlySummaries.isEmpty) return const SizedBox.shrink();

//     final sortedMonths = _monthlySummaries.keys.toList()..sort();

//     return Card(
//       margin: const EdgeInsets.all(8.0),
//       elevation: 4,
//       color: const Color(0xFF1E3A8A),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               "All Users - Monthly Totals",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const Divider(color: Colors.white54),
//             ...sortedMonths.map((monthKey) {
//               final data = _monthlySummaries[monthKey]!;
//               final displayMonth = DateFormat.yMMMM()
//                   .format(DateFormat('yyyy-MM').parse(monthKey));
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       displayMonth,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                         color: Colors.amber,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       alignment: WrapAlignment.spaceBetween,
//                       runSpacing: 12.0,
//                       children: [
//                         _buildOverallSummaryItem(
//                             "Principal", data['principal']!),
//                         _buildOverallSummaryItem("Interest", data['interest']!),
//                         _buildOverallSummaryItem(
//                             "Pending", data['pendingInterest']!),
//                         _buildOverallSummaryItem(
//                             "Balance", data['loanBalance']!),
//                       ],
//                     ),
//                   ],
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildOverallSummaryItem(String label, double value) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontSize: 12, color: Colors.white70),
//           ),
//           Text(
//             value.toStringAsFixed(2),
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMonthlyReport(
//       String monthKey, List<QueryDocumentSnapshot> payments) {
//     double totalPrincipal = 0,
//         totalInterest = 0,
//         totalPendingInterest = 0,
//         finalLoanBalance = 0;

//     for (var doc in payments) {
//       final data = doc.data() as Map<String, dynamic>;
//       totalPrincipal += (data['principal'] as num?) ?? 0;
//       totalInterest += (data['interest'] as num?) ?? 0;
//       totalPendingInterest += (data['pendingInterest'] as num?) ?? 0;
//       finalLoanBalance = ((data['loanBalance'] as num?) ?? 0).toDouble();
//     }

//     final displayMonth =
//         DateFormat.yMMMM().format(DateFormat('yyyy-MM').parse(monthKey));

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8.0),
//             child: Text(
//               'Summary for $displayMonth',
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           _buildSummaryRow(
//             totalPrincipal: totalPrincipal,
//             totalInterest: totalInterest,
//             totalPendingInterest: totalPendingInterest,
//             finalLoanBalance: finalLoanBalance,
//           ),
//           const Divider(height: 24),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: _buildPaymentsTable(payments),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSummaryRow({
//     required double totalPrincipal,
//     required double totalInterest,
//     required double totalPendingInterest,
//     required double finalLoanBalance,
//   }) {
//     return Card(
//       color: Colors.blueGrey[50],
//       elevation: 0,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Wrap(
//           alignment: WrapAlignment.spaceAround,
//           runSpacing: 12.0,
//           spacing: 8.0,
//           children: [
//             _buildSummaryItem('Total Principal', totalPrincipal),
//             _buildSummaryItem('Total Interest', totalInterest),
//             _buildSummaryItem('Total Pending', totalPendingInterest),
//             _buildSummaryItem('Loan Balance', finalLoanBalance),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryItem(String label, double value) {
//     return Column(
//       children: [
//         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
//         const SizedBox(height: 4),
//         Text(
//           value.toStringAsFixed(2),
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFF1E3A8A),
//           ),
//         ),
//       ],
//     );
//   }

//   DataTable _buildPaymentsTable(List<QueryDocumentSnapshot> payments) {
//     return DataTable(
//       columns: const [
//         DataColumn(label: Text('Due Date')),
//         DataColumn(label: Text('Payment Date')),
//         DataColumn(label: Text('Principal')),
//         DataColumn(label: Text('Interest')),
//         DataColumn(label: Text('Pending Interest')),
//         DataColumn(label: Text('Loan Balance')),
//       ],
//       rows: payments.map((paymentDoc) {
//         final data = paymentDoc.data() as Map<String, dynamic>;

//         String formatNum(dynamic value) {
//           if (value is num) return value.toStringAsFixed(2);
//           return '-';
//         }

//         return DataRow(cells: [
//           DataCell(Text(_fmtDate(_asDate(data['dueDate'])))),
//           DataCell(Text(_fmtDate(_asDate(data['paymentDate'])))),
//           DataCell(Text(formatNum(data['principal']))),
//           DataCell(Text(formatNum(data['interest']))),
//           DataCell(Text(formatNum(data['pendingInterest']))),
//           DataCell(Text(formatNum(data['loanBalance']))),
//         ]);
//       }).toList(),
//     );
//   }
// }
