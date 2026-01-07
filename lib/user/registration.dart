import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loan_management/user/appbar.dart';
import 'summary_register_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // TODO: Replace with your actual Gemini API Key
  static const String _apiKey = 'AIzaSyBqOz61PLMxLEIgt8YIuUGYzwVx7CWNQBo';

  // controllers
  final _name = TextEditingController();
  final _ic = TextEditingController();
  final _address = TextEditingController();
  final _occupation = TextEditingController();
  final _phone = TextEditingController();
  final _loan = TextEditingController();
  final _income = TextEditingController();
  final _interest = TextEditingController();
  final _paymentPeriod = TextEditingController();
  final _nation = TextEditingController();

  // selects
  String? _gender;
  DateTime? _loanDate;
  bool _isExtracting = false; // To show loading state

  // palette
  static const _bg = Color(0xFF0B0220);
  static const _card = Color(0xFF120834);
  static const _field = Color(0xFFFFFAE6);
  static const _teal = Color(0xFF5FB2B2);
  static const _tealBright = Color(0xFF7FD0D0);
  static const _lavender = Color(0xFFB794F4);

  // --- Gemini Extraction Logic ---
  Future<void> _pickAndExtractIC() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isExtracting = true);

      // Read image bytes
      final Uint8List imageBytes = await image.readAsBytes();

      // Initialize Gemini Model
      // Note: gemini-1.5-flash is faster and cheaper for this task
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      // Prompt engineering
      final prompt = TextPart("Analyze this Malaysian IC (Identity Card). "
          "Extract the Name, IC Number, and Address. "
          "Return STRICTLY raw JSON format with keys: 'name', 'ic', 'address'. "
          "Do not include markdown code blocks (like ```json). "
          "If a field is not found, leave it empty string.");

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)])
      ];

      final response = await model.generateContent(content);

      if (response.text != null) {
        // Clean up response just in case Gemini includes markdown
        String rawJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> data = jsonDecode(rawJson);

        setState(() {
          _name.text = data['name'] ?? '';
          _ic.text = data['ic'] ?? '';
          _address.text = data['address'] ?? '';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Details extracted successfully!'),
              backgroundColor: _teal,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extracting ID: $e')),
        );
      }
    } finally {
      setState(() => _isExtracting = false);
    }
  }
  // -------------------------------

  InputDecoration _inputDec(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Icon(icon, color: Colors.black54),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: _field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _teal, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _tealBright, width: 2.5),
        ),
      );

  Widget _rowLabel(String label, {IconData? icon}) => SizedBox(
        width: 220,
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String text, IconData icon) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [_tealBright, _lavender]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black87, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

  // New Widget for the Upload Button
  Widget _uploadButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Align with label width
          const SizedBox(width: 244),
          Expanded(
            child: InkWell(
              onTap: _isExtracting ? null : _pickAndExtractIC,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: _tealBright.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isExtracting)
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _tealBright),
                      )
                    else ...[
                      const Icon(Icons.document_scanner, color: _tealBright),
                      const SizedBox(width: 10),
                      const Text(
                        "Upload IC to Auto-fill",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textRow({
    required String label,
    required TextEditingController c,
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _rowLabel(label, icon: icon),
          const SizedBox(width: 24),
          Expanded(
            child: TextFormField(
              controller: c,
              keyboardType: type,
              maxLength: maxLength,
              inputFormatters: inputFormatters,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDec('', icon: icon).copyWith(counterText: ''),
              validator: validator ??
                  (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _rowLabel('Gender', icon: Icons.person),
          const SizedBox(width: 24),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _genderTile('Male', Icons.male),
                _genderTile('Female', Icons.female),
                _genderTile('Other', Icons.transgender),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderTile(String value, IconData icon) {
    final selected = _gender == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16, color: selected ? Colors.black87 : Colors.white70),
          const SizedBox(width: 6),
          Text(value),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.black87 : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      selected: selected,
      selectedColor: _tealBright,
      backgroundColor: Colors.white10,
      shape: StadiumBorder(
          side: BorderSide(color: selected ? _tealBright : Colors.white24)),
      onSelected: (_) => setState(() => _gender = value),
    );
  }

  Widget _dateRow() {
    final text = _loanDate == null
        ? 'Select date'
        : '${_loanDate!.year}-${_loanDate!.month.toString().padLeft(2, '0')}-${_loanDate!.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _rowLabel('Loan date', icon: Icons.event),
          const SizedBox(width: 24),
          Expanded(
            child: InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year - 50),
                  lastDate: DateTime(now.year + 5),
                  initialDate: _loanDate ?? now,
                );
                if (picked != null) setState(() => _loanDate = picked);
              },
              child: InputDecorator(
                decoration: _inputDec('Select date', icon: Icons.event),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.calendar_today,
                        size: 18, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: TextStyle(
                        color:
                            _loanDate == null ? Colors.black54 : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    if (_gender == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gender is required')));
      return;
    }
    if (_loanDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Loan date is required')));
      return;
    }

    final data = RegistrationData(
      name: _name.text.trim(),
      gender: _gender!,
      icNo: _ic.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      work: _occupation.text.trim(),
      incomeAmount: _income.text.trim(),
      loanAmount: _loan.text.trim(),
      loanDate: _loanDate!,
      interestRatePct: _interest.text.trim(),
      paymentPeriod: _paymentPeriod.text.trim(),
      nation: _nation.text.trim(),
      status: 'pending',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SummaryRegisterPage(data: data)),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _ic.dispose();
    _address.dispose();
    _occupation.dispose();
    _phone.dispose();
    _loan.dispose();
    _income.dispose();
    _interest.dispose();
    _paymentPeriod.dispose();
    _nation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: const CustomAppBar(),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          margin: const EdgeInsets.all(20),
          // gradient border look
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0x3312E6FF), Color(0x33B794F4)],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
              border: Border.all(color: Colors.white10),
            ),
            child: Form(
              key: _formKey,
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
                            Icon(Icons.app_registration,
                                size: 18, color: Colors.black87),
                            SizedBox(width: 6),
                            Text(
                              'Registration',
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
                      const Icon(Icons.verified_user, color: Colors.white24),
                    ],
                  ),

                  // sections
                  _sectionTitle('Applicant details', Icons.badge),
                  const SizedBox(height: 8),

                  // --- ADDED UPLOAD BUTTON HERE ---
                  _uploadButton(),
                  // --------------------------------

                  _textRow(label: 'Name', c: _name, icon: Icons.person_outline),
                  _genderRow(),
                  _textRow(label: 'Ic No', c: _ic, icon: Icons.credit_card),
                  _textRow(
                      label: 'Address', c: _address, icon: Icons.home_outlined),
                  _textRow(
                    label: 'Phone number',
                    c: _phone,
                    type: TextInputType.number,
                    maxLength: 15,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.phone_iphone,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return RegExp(r'^\d{7,15}$').hasMatch(v)
                          ? null
                          : 'Digits only (7–15)';
                    },
                  ),
                  _textRow(
                      label: 'Work', c: _occupation, icon: Icons.work_outline),
                  _textRow(
                    label: 'Nation',
                    c: _nation,
                    icon: Icons.flag_outlined,
                  ),

                  _sectionTitle('Loan details', Icons.savings_outlined),
                  const SizedBox(height: 8),

                  _textRow(
                    label: 'Income Amount',
                    c: _income,
                    type: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.trending_up,
                  ),
                  _textRow(
                    label: 'Loan amount',
                    c: _loan,
                    type: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _dateRow(),
                  _textRow(
                    label: 'Interest Rate (%)',
                    c: _interest,
                    type: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,3}([.]\d{0,2})?$')),
                    ],
                    icon: Icons.percent,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final x = double.tryParse(v);
                      if (x == null) return 'Invalid number';
                      if (x < 0 || x > 100) return '0–100 only';
                      return null;
                    },
                  ),
                  _textRow(
                    label: 'Payment Period',
                    c: _paymentPeriod,
                    type: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.schedule,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return int.tryParse(v) == null ? 'Digits only' : null;
                    },
                  ),

                  const SizedBox(height: 20),
                  // submit bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline,
                            color: Colors.white54, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Review your details. You can see a plain summary and confirm on the next screen.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bg,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      onPressed: _submit,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('SUBMIT'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
