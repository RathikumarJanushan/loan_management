import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/appbar.dart';

class DocUploadPage extends StatefulWidget {
  final String debtorId;
  const DocUploadPage({super.key, required this.debtorId});

  @override
  State<DocUploadPage> createState() => _DocUploadPageState();
}

class _DocUploadPageState extends State<DocUploadPage> {
  // Separate variables for each document type
  PlatformFile? _idProofFile;
  PlatformFile? _bankStmtFile;

  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Palette
  static const _bg = Color(0xFF0B0220);
  static const _tealBright = Color(0xFF7FD0D0);
  static const _cardColor = Color(0xFF120834);

  // Helper to pick a single file
  Future<PlatformFile?> _pickSingleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg', 'docx'],
      );
      return result?.files.first;
    } catch (e) {
      debugPrint("Error picking file: $e");
      return null;
    }
  }

  // --- Upload Logic ---
  Future<void> _uploadAll() async {
    if (_idProofFile == null && _bankStmtFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one document.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;

    // Calculate total operations (1 or 2 files)
    int totalFiles =
        (_idProofFile != null ? 1 : 0) + (_bankStmtFile != null ? 1 : 0);
    int completed = 0;

    try {
      // Helper function to upload a specific file with renaming logic
      Future<void> uploadFile(PlatformFile file, String docTypePrefix) async {
        final ext = file.extension ?? 'jpg';

        // RENAME LOGIC: e.g., ID_Proof_17192345.pdf
        final newName =
            '${docTypePrefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        // Storage Path: debtor_docs/{debtorId}/{newName}
        final storageRef =
            storage.ref().child('debtor_docs/${widget.debtorId}/$newName');

        UploadTask task;
        if (file.bytes != null) {
          task = storageRef.putData(file.bytes!);
        } else if (file.path != null) {
          task = storageRef.putFile(File(file.path!));
        } else {
          return;
        }

        await task;
        final downloadUrl = await storageRef.getDownloadURL();

        // Save metadata to 'documat' sub-collection
        await firestore
            .collection('userloneregister')
            .doc(widget.debtorId)
            .collection('documat')
            .add({
          'docType': docTypePrefix.replaceAll('_', ' '), // e.g. "ID Proof"
          'fileName': newName,
          'originalName': file.name,
          'url': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'size': file.size,
        });

        completed++;
        setState(() {
          _uploadProgress = completed / totalFiles;
        });
      }

      // Execute uploads based on what was selected
      if (_idProofFile != null) await uploadFile(_idProofFile!, 'ID_Proof');
      if (_bankStmtFile != null)
        await uploadFile(_bankStmtFile!, 'Bank_Statement');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents uploaded successfully!'),
            backgroundColor: _tealBright,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // --- UI Widget for an Upload Box ---
  Widget _buildUploadBox({
    required String title,
    required IconData icon,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _tealBright, size: 20),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _isUploading ? null : onPick,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: file == null
                  ? Colors.white.withOpacity(0.05)
                  : _tealBright.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: file == null ? Colors.white24 : _tealBright,
                  style: BorderStyle.solid),
            ),
            child: file == null
                ? Column(
                    children: const [
                      Icon(Icons.add_circle_outline,
                          color: Colors.white54, size: 32),
                      SizedBox(height: 8),
                      Text('Tap to upload document',
                          style: TextStyle(color: Colors.white38)),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: _tealBright, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent),
                        onPressed: _isUploading ? null : onRemove,
                      )
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const CustomAppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Documents',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                                colors: [Color(0xFF7FD0D0), Color(0xFFB794F4)])
                            .createShader(const Rect.fromLTWH(0, 0, 260, 40))),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload the required documents below to finalize the registration.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 32),

                // --- 1. ID PROOF SECTION ---
                _buildUploadBox(
                  title: 'ID Proof (IC / Passport)',
                  icon: Icons.badge_outlined,
                  file: _idProofFile,
                  onPick: () async {
                    final f = await _pickSingleFile();
                    if (f != null) setState(() => _idProofFile = f);
                  },
                  onRemove: () => setState(() => _idProofFile = null),
                ),

                const SizedBox(height: 32),

                // --- 2. BANK STATEMENT SECTION ---
                _buildUploadBox(
                  title: 'Bank Statement',
                  icon: Icons.account_balance_outlined,
                  file: _bankStmtFile,
                  onPick: () async {
                    final f = await _pickSingleFile();
                    if (f != null) setState(() => _bankStmtFile = f);
                  },
                  onRemove: () => setState(() => _bankStmtFile = null),
                ),

                const SizedBox(height: 40),

                // --- Progress & Buttons ---
                if (_isUploading) ...[
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.white10,
                    color: _tealBright,
                  ),
                  const SizedBox(height: 10),
                  Center(
                      child: Text(
                          '${(_uploadProgress * 100).toInt()}% Uploaded',
                          style: const TextStyle(color: Colors.white70))),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUploading
                            ? null
                            : () => Navigator.pushNamedAndRemoveUntil(
                                context, '/home', (r) => false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (_idProofFile == null && _bankStmtFile == null) ||
                                    _isUploading
                                ? null
                                : _uploadAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tealBright,
                          foregroundColor: const Color(0xFF0B0220),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.cloud_upload),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload & Finish',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
