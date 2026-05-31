import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/register_api.dart';
import '../brand_colors.dart';
import '../env/app_env.dart';
import '../router/app_router.dart';
import 'register_api_provider.dart';
import 'register_documents_provider.dart';
import 'register_location_autocomplete.dart';
import 'register_location_provider.dart';

enum _DocPickSource { camera, gallery, document }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _travelMilesController = TextEditingController();
  final _gphcController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _qualificationDateController = TextEditingController();
  final _proRef1NameController = TextEditingController();
  final _proRef1PhoneController = TextEditingController();
  final _proRef1DetailsController = TextEditingController();
  final _proRef2NameController = TextEditingController();
  final _proRef2PhoneController = TextEditingController();
  final _proRef2DetailsController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String _yourRole = 'Pharmacist';
  String? _gender;
  bool? _independentPrescriber;
  bool _agreedPharmacistTc = false;
  bool _agreedPrivacyPolicy = false;

  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _pharmacistTcUrl =
      'https://www.capitallocums.co.uk/pharmacisttandcs';
  static const _privacyPolicyUrl =
      'https://www.capitallocums.co.uk/privacy-policy';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(registerLocationProvider.notifier).clear();
    });
  }

  static const _radius = 8.0;
  static const _pageBg = Color(0xFFF8F9FA);
  static const _border = Color(0xFFE0E0E0);
  static const _labelColor = Color(0xFF424242);

  static const _yourRoleOptions = ['Pharmacist', 'Technician', 'Dispenser'];

  static List<({int index, String label, bool isRequired})> _documentEntries(
    bool isPharmacist,
  ) {
    return [
      (index: RegisterDocSlot.passport, label: 'Passport', isRequired: true),
      (
        index: RegisterDocSlot.visaWorkPermit,
        label: 'Visa/Work permit (if required)',
        isRequired: false,
      ),
      (
        index: RegisterDocSlot.nationalInsurance,
        label: 'National insurance',
        isRequired: true,
      ),
      (
        index: RegisterDocSlot.qualificationCert,
        label: 'Qualification certificates',
        isRequired: true,
      ),
      if (isPharmacist)
        (
          index: RegisterDocSlot.dbsCheck,
          label: 'DBS Check',
          isRequired: true,
        ),
    ];
  }

  static final _passwordSpecialCharPattern =
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;']''');

  static List<String> _passwordRequirementGaps(String password) {
    final gaps = <String>[];
    if (password.length < 8) gaps.add('8+ characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) gaps.add('1 uppercase');
    if (!RegExp(r'[a-z]').hasMatch(password)) gaps.add('1 lowercase');
    if (!RegExp(r'[0-9]').hasMatch(password)) gaps.add('1 number');
    if (!_passwordSpecialCharPattern.hasMatch(password)) {
      gaps.add('1 special character');
    }
    return gaps;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Required';
    final gaps = _passwordRequirementGaps(password);
    if (gaps.isEmpty) return null;
    return 'Needs: ${gaps.join(', ')}';
  }

  String? _validateLocation(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (AppEnv.googleMapsApiKey.isEmpty) {
      return null;
    }
    final picked = ref.read(registerLocationProvider);
    if (picked == null || picked.formattedAddress.trim() != text.trim()) {
      return 'Choose a location from the suggestions';
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _travelMilesController.dispose();
    _gphcController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _dateOfBirthController.dispose();
    _qualificationDateController.dispose();
    _proRef1NameController.dispose();
    _proRef1PhoneController.dispose();
    _proRef1DetailsController.dispose();
    _proRef2NameController.dispose();
    _proRef2PhoneController.dispose();
    _proRef2DetailsController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: BrandColors.primaryBlue, width: 1.4),
      ),
    );
  }

  Widget _requiredLabel(
    String text, {
    required bool isRequired,
    bool uppercase = true,
  }) {
    final labelText = uppercase ? text.toUpperCase() : text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _labelColor,
            letterSpacing: 0.4,
          ),
          children: [
            TextSpan(text: labelText),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      ),
    );
  }

  Future<_DocPickSource?> _askDocPickSource() {
    return showDialog<_DocPickSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _DocPickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _DocPickSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Browse files (PDF, Word, Excel, …)'),
              onTap: () => Navigator.pop(ctx, _DocPickSource.document),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _locumRoleForApi() {
    switch (_yourRole) {
      case 'Technician':
        return 'technician';
      case 'Dispenser':
        return 'dispenser';
      default:
        return 'pharmacist';
    }
  }

  bool get _isPharmacist => _yourRole == 'Pharmacist';

  String _formatDdMmYyyy(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  String _dateToApi(String ddMmYyyy) {
    final parts = ddMmYyyy.split('/');
    if (parts.length != 3) return ddMmYyyy.trim();
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  String? _validateDdMmYyyy(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final parts = text.split('/');
    if (parts.length != 3) return 'Use dd/mm/yyyy';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return 'Use dd/mm/yyyy';
    }
    if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
      return 'Invalid date';
    }
    return null;
  }

  Future<void> _pickDate(
    TextEditingController controller, {
    required DateTime lastDate,
    DateTime? initialDate,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: lastDate,
    );
    if (!mounted || picked == null) return;
    setState(() => controller.text = _formatDdMmYyyy(picked));
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link')),
      );
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _phoneForApiFromText(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('44')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return '+44$digits';
  }

  String _phoneForApi() => _phoneForApiFromText(_phoneController.text);

  Widget _dateField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    required DateTime lastDate,
    DateTime? initialDate,
  }) {
    Future<void> pick() => _pickDate(
          controller,
          lastDate: lastDate,
          initialDate: initialDate,
        );
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: _decoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          onPressed: pick,
        ),
      ),
      validator: validator,
      onTap: pick,
    );
  }

  Widget _phoneWithCountryCode() {
    return _UkPhoneField(
      controller: _phoneController,
      decoration: _decoration,
      radius: _radius,
      border: _border,
    );
  }

  Future<void> _pickDocument(int index) async {
    final source = await _askDocPickSource();
    if (!mounted || source == null) return;

    if (source == _DocPickSource.document) {
      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          allowMultiple: false,
          type: FileType.any,
        );
      } on MissingPluginException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File picker isn’t linked yet. Stop the app completely (not hot '
              'reload), then run: flutter clean && flutter pub get && flutter run. '
              'On iOS also run: cd ios && pod install. Or use Camera / Gallery.',
            ),
          ),
        );
        return;
      }
      if (!mounted || result == null || result.files.isEmpty) return;
      final p = result.files.first;
      final path = p.path;
      late final XFile file;
      if (path != null && path.trim().isNotEmpty) {
        file = XFile(path.trim(), name: p.name);
      } else if (p.bytes != null && p.bytes!.isNotEmpty) {
        file = XFile.fromData(p.bytes!, name: p.name);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not read that file. Try another.'),
          ),
        );
        return;
      }
      ref.read(registerDocumentsProvider.notifier).setFile(index, file);
      return;
    }

    final XFile? image = await _imagePicker.pickImage(
      source: source == _DocPickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 60,
    );
    if (!mounted || image == null) return;

    ref.read(registerDocumentsProvider.notifier).setFile(index, image);
  }

  String? _validateExperience(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  String? _validateTravelMiles(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final n = double.tryParse(value.trim());
    if (n == null || n < 0) return 'Enter a valid number';
    return null;
  }

  String? _validateDocuments() {
    final docs = ref.read(registerDocumentsProvider);
    for (final entry in _documentEntries(_isPharmacist)) {
      if (entry.isRequired && docs[entry.index] == null) {
        return 'Please attach: ${entry.label}';
      }
    }
    return null;
  }

  String? _validateTermsAgreements() {
    if (!_agreedPharmacistTc || !_agreedPrivacyPolicy) {
      return 'Please agree to the Pharmacist T&Cs and Privacy Policy';
    }
    return null;
  }

  Future<void> _onRegister() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final experience = int.tryParse(_experienceController.text.trim());
    final travelMiles = double.tryParse(_travelMilesController.text.trim());
    if (experience == null || travelMiles == null) {
      return;
    }

    final docs = ref.read(registerDocumentsProvider);
    final picked = ref.read(registerLocationProvider);

    setState(() => _submitting = true);
    try {
      final res = await ref.read(registerApiProvider).register(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            location: _locationController.text,
            latitude: picked?.latitude ?? 0,
            longitude: picked?.longitude ?? 0,
            phone: _phoneForApi(),
            qualifications: _qualificationsController.text,
            experienceYears: experience,
            locumRole: _locumRoleForApi(),
            travelDistanceMiles: travelMiles,
            gphcNumber: _gphcController.text.trim(),
            address: _addressController.text,
            city: _cityController.text,
            zipCode: _zipCodeController.text,
            dateOfBirth: _dateToApi(_dateOfBirthController.text.trim()),
            gender: _gender!,
            qualificationDate:
                _dateToApi(_qualificationDateController.text.trim()),
            independentPrescriber: _isPharmacist
                ? (_independentPrescriber! ? '1' : '0')
                : null,
            agreedPharmacistTerms: _agreedPharmacistTc,
            agreedPrivacyPolicy: _agreedPrivacyPolicy,
            passport: docs[RegisterDocSlot.passport]!,
            nationalInsurance: docs[RegisterDocSlot.nationalInsurance]!,
            qualificationCert: docs[RegisterDocSlot.qualificationCert]!,
            professionalReference1Name: _proRef1NameController.text,
            professionalReference1Phone:
                _phoneForApiFromText(_proRef1PhoneController.text),
            professionalReference1Details: _proRef1DetailsController.text,
            professionalReference2Name: _proRef2NameController.text,
            professionalReference2Phone:
                _phoneForApiFromText(_proRef2PhoneController.text),
            professionalReference2Details: _proRef2DetailsController.text,
            visaWorkPermit: docs[RegisterDocSlot.visaWorkPermit],
            dbsCheck: _isPharmacist ? docs[RegisterDocSlot.dbsCheck] : null,
          );

      if (!mounted) return;
      ref.read(registerDocumentsProvider.notifier).clearAll();
      ref.read(registerLocationProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res.message?.trim().isNotEmpty == true
                ? res.message!.trim()
                : 'User registered successfully',
          ),
        ),
      );
      context.go(AppRoute.login);
    } on RegisterApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final docFiles = ref.watch(registerDocumentsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF424242)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoute.login);
            }
          },
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  _RegisterHeader(),
                  const SizedBox(height: 28),
                  _twoCol(
                    wide: wide,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Name', isRequired: true),
                        TextFormField(
                          controller: _nameController,
                          decoration: _decoration('Enter full name'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Email', isRequired: true),
                        TextFormField(
                          controller: _emailController,
                          decoration: _decoration('name@example.com'),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _requiredLabel('Password', isRequired: true),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _decoration('Strong password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: _validatePassword,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _requiredLabel('Location', isRequired: true),
                  RegisterLocationAutocomplete(
                    controller: _locationController,
                    decoration: _decoration('Search by address / area'),
                    validator: _validateLocation,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppEnv.googleMapsApiKey.isEmpty
                        ? 'Add GOOGLE_MAPS_API_KEY to .env for suggestions, or enter a location manually.'
                        : 'Start typing to search — tap a suggestion to save coordinates locally.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  _twoCol(
                    wide: wide,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Phone', isRequired: true),
                        _phoneWithCountryCode(),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Qualifications', isRequired: true),
                        TextFormField(
                          controller: _qualificationsController,
                          decoration: _decoration('PharmD, B.Pharm, etc.'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _twoCol(
                    wide: wide,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Experience years', isRequired: true),
                        TextFormField(
                          controller: _experienceController,
                          decoration: _decoration('Years'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          validator: _validateExperience,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Travel distance (miles)', isRequired: true),
                        TextFormField(
                          controller: _travelMilesController,
                          decoration: _decoration('e.g. 25'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          validator: _validateTravelMiles,
                          textInputAction: TextInputAction.done,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _twoCol(
                    wide: wide,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Your role', isRequired: true),
                        InputDecorator(
                          decoration:
                              _decoration('').copyWith(hintText: null),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _yourRole,
                              isExpanded: true,
                              isDense: true,
                              items: _yourRoleOptions
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() {
                                  _yourRole = v;
                                  if (v != 'Pharmacist') {
                                    _independentPrescriber = null;
                                    ref
                                        .read(
                                          registerDocumentsProvider.notifier,
                                        )
                                        .setFile(
                                          RegisterDocSlot.dbsCheck,
                                          null,
                                        );
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel(
                          'GPhC number (7 digits)',
                          isRequired: true,
                          uppercase: false,
                        ),
                        TextFormField(
                          controller: _gphcController,
                          decoration: _decoration('1234567'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(7),
                          ],
                          validator: (v) {
                            final t = v?.trim() ?? '';
                            if (t.isEmpty) return 'Required';
                            if (t.length != 7) {
                              return 'Enter exactly 7 digits';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _requiredLabel('Address', isRequired: true),
                  TextFormField(
                    controller: _addressController,
                    decoration: _decoration('Street address'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _threeCol(
                    wide: wide,
                    a: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('City', isRequired: true),
                        TextFormField(
                          controller: _cityController,
                          decoration: _decoration('City'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    b: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Zip code', isRequired: true),
                        TextFormField(
                          controller: _zipCodeController,
                          decoration: _decoration('Postcode'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    c: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Date of birth', isRequired: true),
                        _dateField(
                          controller: _dateOfBirthController,
                          hint: 'dd/mm/yyyy',
                          validator: _validateDdMmYyyy,
                          lastDate: DateTime.now(),
                          initialDate: DateTime.now(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _threeCol(
                    wide: wide,
                    a: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Gender', isRequired: true),
                        FormField<String>(
                          initialValue: _gender,
                          validator: (v) => v == null ? 'Required' : null,
                          builder: (field) {
                            return InputDecorator(
                              decoration: _decoration('Select gender').copyWith(
                                errorText: field.errorText,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: field.value,
                                  isExpanded: true,
                                  isDense: true,
                                  hint: const Text('Select gender'),
                                  items: _genderOptions
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    field.didChange(v);
                                    setState(() => _gender = v);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    b: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Qualification date', isRequired: true),
                        _dateField(
                          controller: _qualificationDateController,
                          hint: 'dd/mm/yyyy',
                          validator: _validateDdMmYyyy,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: DateTime.now(),
                        ),
                      ],
                    ),
                    c: _isPharmacist
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _requiredLabel(
                                'Independent prescriber',
                                isRequired: true,
                              ),
                              FormField<bool?>(
                                key: ValueKey(
                                  'independent_prescriber_$_yourRole',
                                ),
                                initialValue: _independentPrescriber,
                                validator: (value) =>
                                    value == null ? 'Required' : null,
                                builder: (field) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _IndependentPrescriberField(
                                        value: field.value,
                                        onChanged: (v) {
                                          field.didChange(v);
                                          setState(
                                            () => _independentPrescriber = v,
                                          );
                                        },
                                      ),
                                      if (field.hasError)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 6),
                                          child: Text(
                                            field.errorText!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  _ProfessionalReferencesSection(
                    requiredLabel: _requiredLabel,
                    decoration: _decoration,
                    radius: _radius,
                    border: _border,
                    proRef1Name: _proRef1NameController,
                    proRef1Phone: _proRef1PhoneController,
                    proRef1Details: _proRef1DetailsController,
                    proRef2Name: _proRef2NameController,
                    proRef2Phone: _proRef2PhoneController,
                    proRef2Details: _proRef2DetailsController,
                  ),
                  const SizedBox(height: 28),
                  FormField<void>(
                    key: ValueKey('documents_$_isPharmacist'),
                    validator: (_) => _validateDocuments(),
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DocumentsCard(
                            docSlots: _documentEntries(_isPharmacist),
                            docFiles: docFiles,
                            onPick: (index) async {
                              await _pickDocument(index);
                              field.didChange(null);
                            },
                            onClear: (index) {
                              ref
                                  .read(registerDocumentsProvider.notifier)
                                  .setFile(index, null);
                              field.didChange(null);
                            },
                            borderColor: _border,
                            radius: _radius,
                            hasError: field.hasError,
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                field.errorText!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  FormField<void>(
                    validator: (_) => _validateTermsAgreements(),
                    builder: (field) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _PharmacistTermsSection(
                            agreedPharmacistTc: _agreedPharmacistTc,
                            agreedPrivacyPolicy: _agreedPrivacyPolicy,
                            onPharmacistTcChanged: (v) {
                              setState(() => _agreedPharmacistTc = v);
                              field.didChange(null);
                            },
                            onPrivacyPolicyChanged: (v) {
                              setState(() => _agreedPrivacyPolicy = v);
                              field.didChange(null);
                            },
                            onOpenUrl: _openExternalUrl,
                            pharmacistTcUrl: _pharmacistTcUrl,
                            privacyPolicyUrl: _privacyPolicyUrl,
                            hasError: field.hasError,
                          ),
                          if (field.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                field.errorText!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_radius),
                        ),
                      ),
                      onPressed: _submitting ? null : _onRegister,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 14,
                        ),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go(AppRoute.login),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: BrandColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _twoCol({
    required bool wide,
    required Widget left,
    required Widget right,
  }) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        left,
        const SizedBox(height: 16),
        right,
      ],
    );
  }

  Widget _threeCol({
    required bool wide,
    required Widget a,
    required Widget b,
    required Widget c,
  }) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
          const SizedBox(width: 12),
          Expanded(child: c),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        a,
        const SizedBox(height: 16),
        b,
        const SizedBox(height: 16),
        c,
      ],
    );
  }
}

class _IndependentPrescriberField extends StatelessWidget {
  const _IndependentPrescriberField({
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  static const _radius = 8.0;
  static const _border = Color(0xFFE0E0E0);

  Widget _option({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
                size: 20,
                color: selected ? BrandColors.primaryBlue : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option(
          label: 'Yes',
          selected: value == true,
          onTap: () => onChanged(true),
        ),
        const SizedBox(width: 12),
        _option(
          label: 'No',
          selected: value == false,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _PharmacistTermsSection extends StatelessWidget {
  const _PharmacistTermsSection({
    required this.agreedPharmacistTc,
    required this.agreedPrivacyPolicy,
    required this.onPharmacistTcChanged,
    required this.onPrivacyPolicyChanged,
    required this.onOpenUrl,
    required this.pharmacistTcUrl,
    required this.privacyPolicyUrl,
    this.hasError = false,
  });

  final bool agreedPharmacistTc;
  final bool agreedPrivacyPolicy;
  final ValueChanged<bool> onPharmacistTcChanged;
  final ValueChanged<bool> onPrivacyPolicyChanged;
  final Future<void> Function(String url) onOpenUrl;
  final String pharmacistTcUrl;
  final String privacyPolicyUrl;
  final bool hasError;

  static const _border = Color(0xFFE0E0E0);
  static const _linkBlue = BrandColors.primaryBlue;

  Widget _linkText(String label, String url) {
    return GestureDetector(
      onTap: () => onOpenUrl(url),
      child: Text(
        label,
        style: const TextStyle(
          color: _linkBlue,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _agreementBox({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(child: label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red.shade700 : _border,
          width: hasError ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pharmacist T&Cs',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 4,
            children: [
              const Text(
                'Please check each box to confirm that you have read and agree to the ',
                style: TextStyle(fontSize: 13, color: Color(0xFF424242)),
              ),
              _linkText('Capital Locum pharmacist terms and conditions', pharmacistTcUrl),
              const Text(
                ' and ',
                style: TextStyle(fontSize: 13, color: Color(0xFF424242)),
              ),
              _linkText('Capital Locum data and privacy policy', privacyPolicyUrl),
              const Text(
                '.',
                style: TextStyle(fontSize: 13, color: Color(0xFF424242)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _agreementBox(
                    value: agreedPharmacistTc,
                    onChanged: onPharmacistTcChanged,
                    label: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'I agree to the ',
                          style: TextStyle(fontSize: 13),
                        ),
                        _linkText('Pharmacist T&Cs', pharmacistTcUrl),
                        const Text('.', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _agreementBox(
                    value: agreedPrivacyPolicy,
                    onChanged: onPrivacyPolicyChanged,
                    label: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'I agree to the ',
                          style: TextStyle(fontSize: 13),
                        ),
                        _linkText('Privacy Policy', privacyPolicyUrl),
                        const Text('.', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _agreementBox(
              value: agreedPharmacistTc,
              onChanged: onPharmacistTcChanged,
              label: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('I agree to the ', style: TextStyle(fontSize: 13)),
                  _linkText('Pharmacist T&Cs', pharmacistTcUrl),
                  const Text('.', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _agreementBox(
              value: agreedPrivacyPolicy,
              onChanged: onPrivacyPolicyChanged,
              label: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('I agree to the ', style: TextStyle(fontSize: 13)),
                  _linkText('Privacy Policy', privacyPolicyUrl),
                  const Text('.', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UkPhoneField extends StatelessWidget {
  const _UkPhoneField({
    required this.controller,
    required this.decoration,
    required this.radius,
    required this.border,
  });

  final TextEditingController controller;
  final InputDecoration Function(String hint) decoration;
  final double radius;
  final Color border;

  static const _labelColor = Color(0xFF424242);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: const Text(
            '+44',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _labelColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: decoration('Enter phone number'),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
              if (digits.isEmpty) return 'Required';
              if (digits.length < 9) return 'Enter a valid UK number';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }
}

class _ProfessionalReferencesSection extends StatelessWidget {
  const _ProfessionalReferencesSection({
    required this.requiredLabel,
    required this.decoration,
    required this.radius,
    required this.border,
    required this.proRef1Name,
    required this.proRef1Phone,
    required this.proRef1Details,
    required this.proRef2Name,
    required this.proRef2Phone,
    required this.proRef2Details,
  });

  final Widget Function(String text, {required bool isRequired}) requiredLabel;
  final InputDecoration Function(String hint) decoration;
  final double radius;
  final Color border;
  final TextEditingController proRef1Name;
  final TextEditingController proRef1Phone;
  final TextEditingController proRef1Details;
  final TextEditingController proRef2Name;
  final TextEditingController proRef2Phone;
  final TextEditingController proRef2Details;

  static const _detailsHint =
      'Please give details of the company and relationships.';

  Widget _referenceBlock({
    required String title,
    required TextEditingController name,
    required TextEditingController phone,
    required TextEditingController details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 12),
        requiredLabel('Name', isRequired: true),
        TextFormField(
          controller: name,
          decoration: decoration(''),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        requiredLabel('Phone number', isRequired: true),
        _UkPhoneField(
          controller: phone,
          decoration: decoration,
          radius: radius,
          border: border,
        ),
        const SizedBox(height: 12),
        requiredLabel('Details', isRequired: true),
        TextFormField(
          controller: details,
          decoration: decoration(_detailsHint),
          maxLines: 3,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Professional references',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 20),
          _referenceBlock(
            title: 'Professional Reference 1',
            name: proRef1Name,
            phone: proRef1Phone,
            details: proRef1Details,
          ),
          const SizedBox(height: 24),
          _referenceBlock(
            title: 'Professional Reference 2',
            name: proRef2Name,
            phone: proRef2Phone,
            details: proRef2Details,
          ),
        ],
      ),
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/branding/app_icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.local_pharmacy,
              size: 64,
              color: BrandColors.locumsGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'CAPITAL LOCUMS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          'Register',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF37474F),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({
    required this.docSlots,
    required this.docFiles,
    required this.onPick,
    required this.onClear,
    required this.borderColor,
    required this.radius,
    this.hasError = false,
  });

  final List<({int index, String label, bool isRequired})> docSlots;
  final List<XFile?> docFiles;
  final Future<void> Function(int index) onPick;
  final void Function(int index) onClear;
  final Color borderColor;
  final double radius;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red.shade700 : borderColor,
          width: hasError ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Locum documents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Photos, scans, PDF, Word or Excel.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 560;
              return _docGrid(
                context: context,
                wide: wide,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _docGrid({
    required BuildContext context,
    required bool wide,
  }) {
    final children = <Widget>[];
    for (final slot in docSlots) {
      children.add(
        _DocUploadRow(
                label: slot.label,
                isRequired: slot.isRequired,
                fileName: docFiles[slot.index]?.name,
                onChoose: () => onPick(slot.index),
                onClear: docFiles[slot.index] != null
                    ? () => onClear(slot.index)
                    : null,
                borderColor: borderColor,
                radius: radius,
              ),
      );
    }

    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _intersperse(children, const SizedBox(height: 12)),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      final a = children[i];
      final b = i + 1 < children.length ? children[i + 1] : const SizedBox();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        ),
      );
      rows.add(const SizedBox(height: 12));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return Column(children: rows);
  }

  List<Widget> _intersperse(List<Widget> list, Widget spacer) {
    if (list.isEmpty) return list;
    final out = <Widget>[list.first];
    for (var i = 1; i < list.length; i++) {
      out.add(spacer);
      out.add(list[i]);
    }
    return out;
  }
}

class _DocUploadRow extends StatelessWidget {
  const _DocUploadRow({
    required this.label,
    required this.isRequired,
    required this.fileName,
    required this.onChoose,
    this.onClear,
    required this.borderColor,
    required this.radius,
  });

  final String label;
  final bool isRequired;
  final String? fileName;
  final VoidCallback onChoose;
  final VoidCallback? onClear;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onChoose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.primaryBlue,
                  side: BorderSide(color: Colors.grey.shade400),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Choose file'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileName ?? 'No file chosen',
                  style: TextStyle(
                    fontSize: 13,
                    color: fileName != null
                        ? Colors.grey.shade800
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  tooltip: 'Remove attachment',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
