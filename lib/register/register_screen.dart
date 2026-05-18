import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  final _travelKmController = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  String _yourRole = 'Pharmacist';

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

  static const _yourRoleOptions = ['Pharmacist', 'Technician'];

  static final _docSlots = <({String label, bool isRequired})>[
    (label: 'Passport', isRequired: true),
    (label: 'Visa/Work permit (if required)', isRequired: false),
    (label: 'National insurance', isRequired: true),
    (label: 'Qualification certificates', isRequired: true),
    (label: 'Professional reference 1', isRequired: true),
    (label: 'Professional reference 2', isRequired: true),
  ];

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
    _travelKmController.dispose();
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

  Widget _requiredLabel(String text, {required bool isRequired}) {
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
            TextSpan(text: text.toUpperCase()),
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
      default:
        return 'pharmacist';
    }
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

  Future<void> _onRegister() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final docs = ref.read(registerDocumentsProvider);
    for (var i = 0; i < _docSlots.length; i++) {
      if (_docSlots[i].isRequired && docs[i] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please attach: ${_docSlots[i].label}',
            ),
          ),
        );
        return;
      }
    }

    final experience = int.tryParse(_experienceController.text.trim());
    if (experience == null || experience < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid experience (years).')),
      );
      return;
    }

    final travelKm = double.tryParse(_travelKmController.text.trim());
    if (travelKm == null || travelKm < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid travel distance (km).')),
      );
      return;
    }

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
            phone: _phoneController.text,
            qualifications: _qualificationsController.text,
            experienceYears: experience,
            locumRole: _locumRoleForApi(),
            travelDistanceKm: travelKm,
            passport: docs[RegisterDocSlot.passport]!,
            nationalInsurance: docs[RegisterDocSlot.nationalInsurance]!,
            qualificationCert: docs[RegisterDocSlot.qualificationCert]!,
            professionalReference1: docs[RegisterDocSlot.professionalReference1]!,
            professionalReference2: docs[RegisterDocSlot.professionalReference2]!,
            visaWorkPermit: docs[RegisterDocSlot.visaWorkPermit],
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  _twoCol(
                    wide: wide,
                    left: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          validator: (v) =>
                              v == null || v.length < 8 ? 'Min 8 characters' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Role', isRequired: true),
                        InputDecorator(
                          decoration:
                              _decoration('').copyWith(hintText: null),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Locum',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        TextFormField(
                          controller: _phoneController,
                          decoration: _decoration('Enter contact number'),
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
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
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    right: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _requiredLabel('Travel distance (km)', isRequired: true),
                        TextFormField(
                          controller: _travelKmController,
                          decoration: _decoration('e.g. 25'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
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
                              onChanged: (v) =>
                                  setState(() => _yourRole = v ?? _yourRole),
                            ),
                          ),
                        ),
                      ],
                    ),
                    right: const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  _DocumentsCard(
                    docSlots: _docSlots,
                    docFiles: docFiles,
                    onPick: _pickDocument,
                    onClear: (index) {
                      ref
                          .read(registerDocumentsProvider.notifier)
                          .setFile(index, null);
                    },
                    borderColor: _border,
                    radius: _radius,
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
  });

  final List<({String label, bool isRequired})> docSlots;
  final List<XFile?> docFiles;
  final void Function(int index) onPick;
  final void Function(int index) onClear;
  final Color borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
    for (var i = 0; i < docSlots.length; i++) {
      final slot = docSlots[i];
      children.add(
        _DocUploadRow(
                label: slot.label,
                isRequired: slot.isRequired,
                fileName: docFiles[i]?.name,
                onChoose: () => onPick(i),
                onClear: docFiles[i] != null
                    ? () => onClear(i)
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
