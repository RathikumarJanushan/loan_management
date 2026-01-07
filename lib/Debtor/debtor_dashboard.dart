import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'debtor_status_page.dart'; // Reuse the detail page you already have

class DebtorDashboard extends StatelessWidget {
  final String icNo;
  const DebtorDashboard({super.key, required this.icNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0220),
        elevation: 0,
        title: const Text("My Loans"),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userloneregister')
            .where('icNo', isEqualTo: icNo)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text("Error loading loans",
                    style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("No loans found.",
                    style: TextStyle(color: Colors.white)));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final loanAmount = data['loanAmount'];
              final status =
                  (data['status'] ?? 'pending').toString().toUpperCase();

              Color statusColor = Colors.orangeAccent;
              if (status.contains('APPROVE')) statusColor = Colors.greenAccent;
              if (status.contains('REJECT')) statusColor = Colors.redAccent;

              return Card(
                color: const Color(0xFF120834),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                child: InkWell(
                  onTap: () {
                    // Navigate to the detail/upload page for THIS specific loan
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DebtorStatusPage(docId: doc.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: Color(0xFF7FD0D0), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Loan Application",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "RM ${loanAmount ?? '0.00'}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              if (data['loanDate'] != null)
                                Text(
                                  DateFormat('dd MMM yyyy').format(
                                      (data['loanDate'] as Timestamp).toDate()),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_ios,
                            color: Colors.white24, size: 16),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
