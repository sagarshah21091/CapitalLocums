import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../brand_colors.dart';
import '../env/app_env.dart';
import '../router/app_router.dart';
import 'register_documents_provider.dart';
import 'register_location_autocomplete.dart';
import 'register_location_provider.dart';

enum _ImagePickSource { camera, gallery }

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

  Future<_ImagePickSource?> _askImagePickSource() {
    return showDialog<_ImagePickSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, _ImagePickSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, _ImagePickSource.gallery),
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

  Future<void> _pickDocument(int index) async {
    final source = await _askImagePickSource();
    if (!mounted || source == null) return;

    final XFile? image = await _imagePicker.pickImage(
      source: source == _ImagePickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted || image == null) return;

    var label = image.name.trim();
    if (label.isEmpty) {
      label = 'Photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    ref.read(registerDocumentNamesProvider.notifier).setName(index, label);
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;

    final files = ref.read(registerDocumentNamesProvider);
    for (var i = 0; i < _docSlots.length; i++) {
      if (_docSlots[i].isRequired && (files[i] == null || files[i]!.isEmpty)) {
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

    ref.read(registerDocumentNamesProvider.notifier).clearAll();
    ref.read(registerLocationProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration submitted (demo).')),
    );
    context.go(AppRoute.login);
  }

  @override
  Widget build(BuildContext context) {
    final fileNames = ref.watch(registerDocumentNamesProvider);
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
                    fileNames: fileNames,
                    onPick: _pickDocument,
                    onClear: (index) {
                      ref
                          .read(registerDocumentNamesProvider.notifier)
                          .setName(index, null);
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
                      onPressed: _onRegister,
                      child: const Text(
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
    required this.fileNames,
    required this.onPick,
    required this.onClear,
    required this.borderColor,
    required this.radius,
  });

  final List<({String label, bool isRequired})> docSlots;
  final List<String?> fileNames;
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
            'Take a photo or choose an image from your gallery.',
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
                fileName: fileNames[i],
                onChoose: () => onPick(i),
                onClear: fileNames[i] != null
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
