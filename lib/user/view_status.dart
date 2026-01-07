import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // For viewing docs
import 'package:file_picker/file_picker.dart'; // For picking missing docs
import 'package:firebase_storage/firebase_storage.dart'; // For uploading
import 'package:loan_management/user/appbar.dart';

class ViewStatusPage extends StatefulWidget {
  const ViewStatusPage({super.key});

  @override
  State<ViewStatusPage> createState() => _ViewStatusPageState();
}

class _ViewStatusPageState extends State<ViewStatusPage> {
  static const _bg = Color(0xFF0B0220);
  static const _tealBright = Color(0xFF7FD0D0);
  static const _lavender = Color(0xFFB794F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const CustomAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('userloneregister')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
                child: Text('Error', style: TextStyle(color: Colors.white)));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          final pending = <DocumentSnapshot>[];
          final approved = <DocumentSnapshot>[];
          final rejected = <DocumentSnapshot>[];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status =
                (data['status'] ?? 'pending').toString().toLowerCase();
            if (status == 'approve' || status == 'approved') {
              approved.add(doc);
            } else if (status == 'rejected' || status == 'reject') {
              rejected.add(doc);
            } else {
              pending.add(doc);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Application Status',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader =
                          const LinearGradient(colors: [_tealBright, _lavender])
                              .createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection('Pending', Colors.orangeAccent,
                    Icons.hourglass_empty, pending),
                const SizedBox(height: 30),
                _buildSection('Approved', Colors.greenAccent,
                    Icons.check_circle_outline, approved),
                const SizedBox(height: 30),
                _buildSection('Rejected', Colors.redAccent,
                    Icons.cancel_outlined, rejected),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      String title, Color color, IconData icon, List<DocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border(left: BorderSide(color: color, width: 4)),
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(title,
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (docs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('No applications.',
                style: TextStyle(
                    color: Colors.white24, fontStyle: FontStyle.italic)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (c, i) => _LoanCard(doc: docs[i]),
          ),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _LoanCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown';
    final ic = data['icNo'] ?? '-';

    DateTime? date;
    if (data['loanDate'] is Timestamp)
      date = (data['loanDate'] as Timestamp).toDate();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF120834),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        collapsedIconColor: Colors.white54,
        iconColor: const Color(0xFF7FD0D0),
        title: Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle:
            Text('IC: $ic', style: const TextStyle(color: Colors.white54)),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.black12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row('Loan Amount', '${data['loanAmount'] ?? '-'}'),
                if (date != null)
                  _row('Loan Date', DateFormat('dd MMM yyyy').format(date)),
                _row('Phone', data['phone'] ?? '-'),
                _row('Income', '${data['incomeAmount'] ?? '-'}'),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                const Text('Uploaded Documents:',
                    style: TextStyle(
                        color: Color(0xFF7FD0D0), fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Pass debtor ID to document handler
                _DocumentsHandler(debtorId: doc.id),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 13))),
          Expanded(
              child: Text(val,
                  style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
}

// ▼▼▼ NEW WIDGET FOR DOCS ▼▼▼
class _DocumentsHandler extends StatefulWidget {
  final String debtorId;
  const _DocumentsHandler({required this.debtorId});

  @override
  State<_DocumentsHandler> createState() => _DocumentsHandlerState();
}

class _DocumentsHandlerState extends State<_DocumentsHandler> {
  bool _isUploading = false;

  // 1. Function to Launch URL
  Future<void> _viewDocument(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')));
    }
  }

  // 2. Function to Upload Missing Document
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

      // Formatting filename: e.g. ID_Proof_123456.jpg
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$docType uploaded successfully'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use StreamBuilder for real-time updates (important for uploads)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(widget.debtorId)
          .collection('documat')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2));
        }

        final docs = snapshot.data?.docs ?? [];

        // Determine what is uploaded
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
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docType,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        Text(fileName,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.visibility,
                      color: Color(0xFF7FD0D0), size: 16),
                ],
              ),
            ),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...existingDocsWidgets,

            // Loading indicator during upload
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                    color: Color(0xFF7FD0D0), backgroundColor: Colors.white10),
              ),

            // Missing ID Proof Button
            if (!hasIdProof && !_isUploading)
              _buildUploadButton('Upload ID Proof', Icons.badge_outlined,
                  () => _uploadMissing('ID Proof')),

            // Missing Bank Statement Button
            if (!hasBankStmt && !_isUploading)
              _buildUploadButton(
                  'Upload Bank Statement',
                  Icons.account_balance_outlined,
                  () => _uploadMissing('Bank Statement')),

            if (docs.isEmpty && hasIdProof && hasBankStmt)
              const Text('No documents.',
                  style: TextStyle(color: Colors.white24)),
          ],
        );
      },
    );
  }

  Widget _buildUploadButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.orangeAccent,
          side: const BorderSide(color: Colors.orangeAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label),
      ),
    );
  }
}
