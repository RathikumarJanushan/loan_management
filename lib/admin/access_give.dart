import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AccessGivePage extends StatefulWidget {
  const AccessGivePage({super.key});

  @override
  State<AccessGivePage> createState() => _AccessGivePageState();
}

class _AccessGivePageState extends State<AccessGivePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color:
          const Color(0xFFF8FAFC), // Light grey background for the whole page
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Access Approval",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Review applications and manage access.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 20),

          // --- TABS ---
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB), // Bright Blue
              unselectedLabelColor: const Color(0xFF94A3B8), // Grey
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: const Color(0xFF2563EB),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "Pending"),
                Tab(text: "Approved"),
                Tab(text: "Rejected"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- CONTENT ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatusList('pending'),
                _buildStatusList('approved'),
                _buildStatusList('rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusList(String filterStatus) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userloneregister')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading data"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        final filteredDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? 'pending').toString().toLowerCase();

          if (filterStatus == 'approved') return status.contains('approve');
          if (filterStatus == 'rejected') return status.contains('reject');
          return status == 'pending';
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "No $filterStatus applications found",
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: filteredDocs.length,
          separatorBuilder: (c, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _ApplicationCard(
              doc: filteredDocs[index],
              currentStatus: filterStatus,
            );
          },
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final String currentStatus;

  const _ApplicationCard({
    required this.doc,
    required this.currentStatus,
  });

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(doc.id)
          .update({
        'status': newStatus,
        'actionTakenAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Application marked as $newStatus"),
            backgroundColor:
                newStatus == 'approved' ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fmtMoney(dynamic val) {
    if (val is num) return 'RM ${val.toStringAsFixed(2)}';
    return 'RM 0.00';
  }

  Color _getStatusColor() {
    if (currentStatus == 'approved') return Colors.green;
    if (currentStatus == 'rejected') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final ic = data['icNo'] ?? '-';
    final loanAmount = data['loanAmount'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          childrenPadding: EdgeInsets.zero,
          shape: Border.all(color: Colors.transparent),

          // Header content
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentStatus.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.credit_card, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  ic,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.monetization_on_outlined,
                    size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  loanAmount is num ? _fmtMoney(loanAmount) : '$loanAmount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),

          // Expanded Content
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color:
                    Color(0xFFF1F5F9), // Light blue-grey background for clarity
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.folder_shared_outlined,
                          size: 18, color: Color(0xFF64748B)),
                      SizedBox(width: 8),
                      Text(
                        "Attached Documents",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // DOCUMENTS LIST
                  _DocumentList(debtorId: doc.id),

                  const SizedBox(height: 24),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      if (currentStatus != 'rejected')
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(context, 'rejected'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.red.shade200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Reject Application"),
                          ),
                        ),
                      if (currentStatus != 'rejected' &&
                          currentStatus != 'approved')
                        const SizedBox(width: 12),
                      if (currentStatus != 'approved')
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(context, 'approved'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981), // Green
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text("Approve Application"),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget to fetch and display clickable documents
class _DocumentList extends StatelessWidget {
  final String debtorId;
  const _DocumentList({required this.debtorId});

  Future<void> _openDoc(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open document")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(debtorId)
          .collection('documat')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2));
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "No documents attached yet.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = data['docType'] ?? data['fileName'] ?? 'Doc';
            final url = data['url'];

            return Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              child: InkWell(
                onTap: () {
                  if (url != null) _openDoc(context, url);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.description_outlined,
                          size: 16, color: Color(0xFF2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new,
                          size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
