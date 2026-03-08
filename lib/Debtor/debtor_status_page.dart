import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DebtorStatusPage extends StatefulWidget {
  final String docId;
  const DebtorStatusPage({super.key, required this.docId});

  @override
  State<DebtorStatusPage> createState() => _DebtorStatusPageState();
}

class _DebtorStatusPageState extends State<DebtorStatusPage> {
  static const _bg = Color(0xFF0B0220);
  static const _cardColor = Color(0xFF120834);

  // To store payments for the table
  List<DocumentSnapshot<Map<String, dynamic>>> _payments = [];
  bool _isLoadingPayments = true;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  // Fetch payments sub-collection for the table
  Future<void> _fetchPayments() async {
    try {
      final qs = await FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(widget.docId)
          .collection('payments')
          .orderBy('dueDate')
          .get();

      if (mounted) {
        setState(() {
          _payments = qs.docs;
          _isLoadingPayments = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching payments: $e");
      if (mounted) setState(() => _isLoadingPayments = false);
    }
  }

  // Helper: Format Date
  String _fmtDate(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // Helper: Parse Date
  DateTime? _asDate(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0220),
        elevation: 0,
        title: const Text("My Application"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userloneregister')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
                child: Text('Application not found.',
                    style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Normalize status
          final status = (data['status'] ?? 'pending').toString().toLowerCase();
          final isApproved = status.contains('approve');

          Color statusColor;
          IconData statusIcon;
          String statusText;

          if (isApproved) {
            statusColor = Colors.greenAccent;
            statusIcon = Icons.check_circle;
            statusText = "APPROVED";
          } else if (status.contains('reject')) {
            statusColor = Colors.redAccent;
            statusIcon = Icons.cancel;
            statusText = "REJECTED";
          } else {
            statusColor = Colors.orangeAccent;
            statusIcon = Icons.hourglass_top;
            statusText = "PENDING";
          }

          // Data for Table
          final loanDate = _asDate(data['loanDate']);
          final paymentPeriod = (data['paymentPeriod'] is int)
              ? (data['paymentPeriod'] as int)
              : (data['paymentPeriod'] is num
                  ? (data['paymentPeriod'] as num).round()
                  : 0);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 48),
                      const SizedBox(height: 10),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Application Details
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Details",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const Divider(color: Colors.white12, height: 24),
                      _row('Applicant Name', data['name'] ?? '-'),
                      _row('IC Number', data['icNo'] ?? '-'),
                      _row('Loan Amount', '${data['loanAmount'] ?? '-'}'),
                      if (data['loanDate'] != null)
                        _row(
                            'Application Date',
                            DateFormat('dd MMM yyyy').format(
                                (data['loanDate'] as Timestamp).toDate())),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Documents
                const Text("Documents",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: _DocumentsHandler(debtorId: widget.docId),
                ),

                const SizedBox(height: 30),

                // 4. Payment Schedule Table (ONLY IF APPROVED)
                if (isApproved) ...[
                  const Text("Payment Schedule",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: (loanDate == null || paymentPeriod <= 0)
                          ? const Text('Schedule unavailable.',
                              style: TextStyle(color: Colors.white60))
                          : _scheduleTable(
                              loanDate: loanDate,
                              months: paymentPeriod,
                              payments: _payments),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Table Logic (View Only) ---
  DataTable _scheduleTable({
    required DateTime loanDate,
    required int months,
    required List<DocumentSnapshot<Map<String, dynamic>>> payments,
  }) {
//[Image of Amortization Table]

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

        // Status Column (Replacing Make Payment)
        DataCell(
          paymentForThisRow != null
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('PAID',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)))
              : const Text('PENDING',
                  style: TextStyle(color: Colors.orangeAccent, fontSize: 10)),
        ),
      ]);
    });

    return DataTable(
        headingRowColor:
            MaterialStateProperty.all(Colors.white.withOpacity(0.06)),
        columns: const [
          DataColumn(
              label: Text('Due Date', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Date Paid', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Amount', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Interest', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Principal', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Balance', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Large Bal', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Pend. Int', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Status', style: TextStyle(color: Colors.white))),
        ],
        rows: rows,
        columnSpacing: 20,
        dividerThickness: 0.6,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 48);
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- Reused Document Handler ---
class _DocumentsHandler extends StatefulWidget {
  final String debtorId;
  const _DocumentsHandler({required this.debtorId});

  @override
  State<_DocumentsHandler> createState() => _DocumentsHandlerState();
}

class _DocumentsHandlerState extends State<_DocumentsHandler> {
  bool _isUploading = false;

  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')));
    }
  }

  Future<void> _uploadMissing(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isUploading = true);
      final file = result.files.first;
      final ext = file.extension ?? 'jpg';
      final safeType = docType.replaceAll(' ', '_');
      final newName =
          '${safeType}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('debtor_docs/${widget.debtorId}/$newName');

      if (file.bytes != null) {
        await storageRef.putData(file.bytes!);
      } else if (file.path != null) {
        await storageRef.putFile(File(file.path!));
      } else {
        throw 'No file data';
      }

      final url = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(widget.debtorId)
          .collection('documat')
          .add({
        'docType': docType,
        'fileName': newName,
        'url': url,
        'uploadedAt': FieldValue.serverTimestamp(),
        'size': file.size,
      });

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$docType uploaded successfully'),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(widget.debtorId)
          .collection('documat')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        bool hasIdProof = false;
        bool hasBankStmt = false;

        final existingDocsWidgets = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final docType = data['docType'] ?? 'Document';
          final fileName = data['fileName'] ?? 'Unknown';
          final url = data['url'];

          if (docType == 'ID Proof') hasIdProof = true;
          if (docType == 'Bank Statement') hasBankStmt = true;

          return InkWell(
            onTap: () => _viewDocument(url),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.white70),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docType,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text(fileName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.visibility, color: Color(0xFF7FD0D0)),
                ],
              ),
            ),
          );
        }).toList();

        return Column(
          children: [
            ...existingDocsWidgets,
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(color: Color(0xFF7FD0D0)),
              ),
            if (!hasIdProof && !_isUploading)
              _buildUploadButton('Upload ID Proof', Icons.badge_outlined,
                  () => _uploadMissing('ID Proof')),
            if (!hasBankStmt && !_isUploading)
              _buildUploadButton(
                  'Upload Bank Statement',
                  Icons.account_balance_outlined,
                  () => _uploadMissing('Bank Statement')),
          ],
        );
      },
    );
  }

  Widget _buildUploadButton(String label, IconData icon, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7FD0D0),
          side: const BorderSide(color: Color(0xFF7FD0D0)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
