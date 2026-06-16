import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_constants.dart';
import '../api/models/profile_models.dart';
import '../brand_colors.dart';
import '../env/app_env.dart';
import '../register/register_location_autocomplete.dart';
import '../register/register_location_provider.dart';
import '../shell/shell_user_header_provider.dart';
import 'profile_providers.dart';
import 'profile_repository.dart';

class _ProfileData {
  const _ProfileData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.qualifications,
    required this.experienceYears,
    required this.locumRole,
    required this.travelMiles,
    required this.gphcNumber,
    required this.address,
    required this.city,
    required this.zipCode,
    required this.dateOfBirth,
    required this.gender,
    required this.qualificationDate,
    required this.independentPrescriber,
    required this.refName1,
    required this.refPhone1,
    required this.refDetails1,
    required this.refName2,
    required this.refPhone2,
    required this.refDetails2,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String qualifications;
  final String experienceYears;
  final String locumRole;
  final String travelMiles;
  final String gphcNumber;
  final String address;
  final String city;
  final String zipCode;
  final String dateOfBirth;
  final String gender;
  final String qualificationDate;
  final String independentPrescriber;
  final String refName1;
  final String refPhone1;
  final String refDetails1;
  final String refName2;
  final String refPhone2;
  final String refDetails2;

  bool get isPharmacist => locumRole == 'Pharmacist';

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()].where((p) => p.isNotEmpty);
    return parts.join(' ');
  }
}

/// Locum profile: header, professional, service area, documents (GET `/profile`).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  late _ProfileData _saved;
  ProfileDetails? _serverProfile;
  List<ProfileDocument> _documents = [];

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _travelKmController;
  late final TextEditingController _gphcController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _dobController;
  late final TextEditingController _qualificationDateController;
  late final TextEditingController _proRef1NameController;
  late final TextEditingController _proRef1PhoneController;
  late final TextEditingController _proRef1DetailsController;
  late final TextEditingController _proRef2NameController;
  late final TextEditingController _proRef2PhoneController;
  late final TextEditingController _proRef2DetailsController;

  String _locumRole = 'Pharmacist';
  String? _gender;
  bool? _independentPrescriber;

  static const _roleOptions = ['Pharmacist', 'Technician', 'Dispenser'];
  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _cardRadius = 12.0;
  static const _borderColor = Color(0xFFE0E0E0);

  static const _emptyProfile = _ProfileData(
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    location: '',
    qualifications: '',
    experienceYears: '',
    locumRole: 'Pharmacist',
    travelMiles: '',
    gphcNumber: '',
    address: '',
    city: '',
    zipCode: '',
    dateOfBirth: '',
    gender: '',
    qualificationDate: '',
    independentPrescriber: '',
    refName1: '',
    refPhone1: '',
    refDetails1: '',
    refName2: '',
    refPhone2: '',
    refDetails2: '',
  );

  static String _firstNonEmpty(String a, String b, [String fallback = '']) {
    if (a.trim().isNotEmpty) return a.trim();
    if (b.trim().isNotEmpty) return b.trim();
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _saved = _emptyProfile;
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _qualificationsController = TextEditingController();
    _experienceController = TextEditingController();
    _travelKmController = TextEditingController();
    _gphcController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _zipCodeController = TextEditingController();
    _dobController = TextEditingController();
    _qualificationDateController = TextEditingController();
    _proRef1NameController = TextEditingController();
    _proRef1PhoneController = TextEditingController();
    _proRef1DetailsController = TextEditingController();
    _proRef2NameController = TextEditingController();
    _proRef2PhoneController = TextEditingController();
    _proRef2DetailsController = TextEditingController();
    _locationController.addListener(_onLocationFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  static String _displayLocumRole(String? apiRole) {
    final r = apiRole?.trim().toLowerCase() ?? '';
    if (r == 'technician') return 'Technician';
    if (r == 'pharmacist') return 'Pharmacist';
    if (r == 'dispenser') return 'Dispenser';
    if (r.isEmpty) return 'Pharmacist';
    return r[0].toUpperCase() + r.substring(1);
  }

  static String _apiLocumRole(String display) {
    switch (display) {
      case 'Technician':
        return 'technician';
      case 'Dispenser':
        return 'dispenser';
      default:
        return 'pharmacist';
    }
  }

  static String _phoneDigitsForDisplay(String apiPhone) {
    var digits = apiPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('44')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  static String _phoneForApiFromText(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('44')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+44$digits';
  }

  bool? _independentFromDisplay(String display) {
    final s = display.trim().toLowerCase();
    if (s == 'yes') return true;
    if (s == 'no') return false;
    return null;
  }

  bool get _isPharmacistRole =>
      _editing ? _locumRole == 'Pharmacist' : _saved.isPharmacist;

  /// Required for Pharmacist; optional for Technician/Dispenser. If set, must be 7 digits.
  String? _gphcValidationMessage() {
    final t = _gphcController.text.trim();
    if (t.isEmpty) {
      return _locumRole == 'Pharmacist' ? 'Required' : null;
    }
    if (t.length != 7) {
      return 'Enter exactly 7 digits';
    }
    return null;
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: controller == _qualificationDateController
          ? now.add(const Duration(days: 365))
          : now,
    );
    if (!mounted || picked == null) return;
    final day = picked.day.toString().padLeft(2, '0');
    final month = picked.month.toString().padLeft(2, '0');
    setState(() => controller.text = '$day/$month/${picked.year}');
  }

  Widget _dateField(TextEditingController controller, {String hint = 'dd/mm/yyyy'}) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: _inputDecoration(hint: hint).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          onPressed: () => _pickDate(controller),
        ),
      ),
      onTap: () => _pickDate(controller),
    );
  }

  Widget _editableField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: _inputDecoration(hint: hint),
    );
  }

  void _seedLocationFromProfile(ProfileDetails profile) {
    final lat =
        double.tryParse(profile.latitude ?? '') ?? profile.coordinates?.y;
    final lng =
        double.tryParse(profile.longitude ?? '') ?? profile.coordinates?.x;
    if (lat == null || lng == null) return;
    ref.read(registerLocationProvider.notifier).setPick(
          PickedRegisterLocation(
            latitude: lat,
            longitude: lng,
            placeId: '',
            formattedAddress: profile.location,
          ),
        );
  }

  void _applyProfileDetails(
    ProfileDetails profile, {
    String? firstName,
    String? lastName,
    String? email,
    ProfileUser? user,
  }) {
    _serverProfile = profile;
    final displayFirst = firstName ??
        user?.name.trim() ??
        _saved.firstName;
    final displayLast = lastName ??
        user?.lastName.trim() ??
        _saved.lastName;
    final displayEmail = email ?? _saved.email;
    final role = _displayLocumRole(profile.locumRole);

    final address = _firstNonEmpty(
      user?.address ?? '',
      profile.address,
    );
    final city = _firstNonEmpty(user?.city ?? '', profile.city);
    final zipCode = _firstNonEmpty(user?.zipCode ?? '', profile.zipCode);
    final dobRaw = _firstNonEmpty(user?.dob ?? '', profile.dob);
    final genderRaw = _firstNonEmpty(user?.gender ?? '', profile.gender);
    final qualDateRaw = _firstNonEmpty(
      user?.qualificationDate ?? '',
      profile.qualificationDate,
    );
    final indepRaw = _firstNonEmpty(
      user?.independentPrescriber ?? '',
      profile.independentPrescriber,
    );

    _saved = _ProfileData(
      firstName: displayFirst,
      lastName: displayLast,
      email: displayEmail,
      phone: profile.phone.trim(),
      location: profile.location.trim(),
      qualifications: profile.qualifications.trim(),
      experienceYears: '${profile.experienceYears}',
      locumRole: role,
      travelMiles: '${profile.travelDistance}',
      gphcNumber: profile.gphcNumber.trim(),
      address: address,
      city: city,
      zipCode: zipCode,
      dateOfBirth: ProfileDetails.formatDobForDisplay(dobRaw),
      gender: ProfileDetails.formatGender(genderRaw),
      qualificationDate:
          ProfileDetails.formatDobForDisplay(qualDateRaw),
      independentPrescriber:
          ProfileDetails.formatIndependentPrescriber(indepRaw),
      refName1: user?.refName1.trim() ?? _saved.refName1,
      refPhone1: user?.refPhoneNumber1.trim() ?? _saved.refPhone1,
      refDetails1: user?.refDetails1.trim() ?? _saved.refDetails1,
      refName2: user?.refName2.trim() ?? _saved.refName2,
      refPhone2: user?.refPhoneNumber2.trim() ?? _saved.refPhone2,
      refDetails2: user?.refDetails2.trim() ?? _saved.refDetails2,
    );

    _firstNameController.text = displayFirst;
    _lastNameController.text = displayLast;
    _phoneController.text = _phoneDigitsForDisplay(_saved.phone);
    _locationController.text = _saved.location;
    _qualificationsController.text = _saved.qualifications;
    _experienceController.text = _saved.experienceYears;
    _travelKmController.text = _saved.travelMiles;
    _gphcController.text = _saved.gphcNumber;
    _addressController.text = _saved.address;
    _cityController.text = _saved.city;
    _zipCodeController.text = _saved.zipCode;
    _dobController.text = _saved.dateOfBirth;
    _qualificationDateController.text = _saved.qualificationDate;
    _proRef1NameController.text = _saved.refName1;
    _proRef1PhoneController.text = _phoneDigitsForDisplay(_saved.refPhone1);
    _proRef1DetailsController.text = _saved.refDetails1;
    _proRef2NameController.text = _saved.refName2;
    _proRef2PhoneController.text = _phoneDigitsForDisplay(_saved.refPhone2);
    _proRef2DetailsController.text = _saved.refDetails2;
    _locumRole = role;
    _gender = _saved.gender.isEmpty ? null : _saved.gender;
    _independentPrescriber =
        _independentFromDisplay(_saved.independentPrescriber);
  }

  void _applyPayload(ProfilePayload payload) {
    final user = payload.user;
    final profile = payload.profile;
    _documents = List<ProfileDocument>.from(payload.documents);

    if (profile != null) {
      _applyProfileDetails(
        profile,
        firstName: user?.name.trim(),
        lastName: user?.lastName.trim(),
        email: user?.email.trim(),
        user: user,
      );
      ref.read(registerLocationProvider.notifier).clear();
      _seedLocationFromProfile(profile);
    } else {
      _serverProfile = null;
      _saved = _emptyProfile;
    }
  }

  ProfileDetails? _buildProfileDetailsForUpdate() {
    final base = _serverProfile;
    if (base == null) return null;

    final experience = int.tryParse(_experienceController.text.trim());
    final travel = num.tryParse(_travelKmController.text.trim());
    if (experience == null || travel == null) return null;

    final location = _locationController.text.trim();
    final picked = ref.read(registerLocationProvider);

    var lat =
        double.tryParse(base.latitude ?? '') ?? base.coordinates?.y ?? 0.0;
    var lng =
        double.tryParse(base.longitude ?? '') ?? base.coordinates?.x ?? 0.0;

    if (picked != null &&
        picked.formattedAddress.trim() == location.trim()) {
      lat = picked.latitude;
      lng = picked.longitude;
    }

    return ProfileDetails(
      id: base.id,
      userId: base.userId,
      phone: _phoneForApiFromText(_phoneController.text),
      qualifications: _qualificationsController.text.trim(),
      experienceYears: experience,
      location: location,
      latitude: lat.toString(),
      longitude: lng.toString(),
      travelDistance: travel,
      locumRole: _apiLocumRole(_locumRole),
      gphcNumber: _gphcController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      zipCode: _zipCodeController.text.trim(),
      dob: ProfileDetails.dateToApi(_dobController.text),
      gender: (_gender ?? '').toLowerCase(),
      qualificationDate:
          ProfileDetails.dateToApi(_qualificationDateController.text),
      independentPrescriber: _locumRole == 'Pharmacist' &&
              _independentPrescriber != null
          ? (_independentPrescriber! ? '1' : '0')
          : '',
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      coordinates: ProfileCoordinates(x: lng, y: lat),
    );
  }

  Map<String, dynamic>? _buildUpdatePayload() {
    final profile = _buildProfileDetailsForUpdate();
    if (profile == null) return null;

    final payload = profile.toJson();
    payload['name'] = _firstNameController.text.trim();
    payload['last_name'] = _lastNameController.text.trim();
    payload['ref_Name_1'] = _proRef1NameController.text.trim();
    payload['ref_PhoneNumber_1'] =
        _phoneForApiFromText(_proRef1PhoneController.text);
    payload['ref_Details_1'] = _proRef1DetailsController.text.trim();
    payload['ref_Name_2'] = _proRef2NameController.text.trim();
    payload['ref_PhoneNumber_2'] =
        _phoneForApiFromText(_proRef2PhoneController.text);
    payload['ref_Details_2'] = _proRef2DetailsController.text.trim();
    return payload;
  }

  String? _validateEditLocation(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (AppEnv.googleMapsApiKey.isEmpty) return null;
    final picked = ref.read(registerLocationProvider);
    if (picked == null || picked.formattedAddress.trim() != text) {
      return 'Choose a location from the suggestions';
    }
    return null;
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final payload =
          await ref.read(profileRepositoryProvider).fetchProfile();
      if (!mounted) return;
      setState(() {
        _applyPayload(payload);
        _loading = false;
      });
    } on ProfileFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _onLocationFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationController.removeListener(_onLocationFieldChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _travelKmController.dispose();
    _gphcController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _dobController.dispose();
    _qualificationDateController.dispose();
    _proRef1NameController.dispose();
    _proRef1PhoneController.dispose();
    _proRef1DetailsController.dispose();
    _proRef2NameController.dispose();
    _proRef2PhoneController.dispose();
    _proRef2DetailsController.dispose();
    super.dispose();
  }

  void _startEdit() {
    final profile = _serverProfile;
    if (profile != null) {
      ref.read(registerLocationProvider.notifier).clear();
      _seedLocationFromProfile(profile);
    }
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    ref.read(registerLocationProvider.notifier).clear();
    final profile = _serverProfile;
    if (profile != null) {
      _applyProfileDetails(
        profile,
        firstName: _saved.firstName,
        lastName: _saved.lastName,
        email: _saved.email,
      );
      _seedLocationFromProfile(profile);
    }
    setState(() => _editing = false);
  }

  Future<void> _saveEdit() async {
    if (_saving || _serverProfile == null) return;

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone is required.')),
      );
      return;
    }
    if (_qualificationsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qualifications are required.')),
      );
      return;
    }

    final gphcError = _gphcValidationMessage();
    if (gphcError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(gphcError)),
      );
      return;
    }

    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name is required.')),
      );
      return;
    }
    if (_lastNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Last name is required.')),
      );
      return;
    }
    if (_gender == null || _gender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender.')),
      );
      return;
    }
    if (_locumRole == 'Pharmacist' && _independentPrescriber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Independent Prescriber (Yes or No).'),
        ),
      );
      return;
    }

    final payload = _buildUpdatePayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check experience years and travel distance.'),
        ),
      );
      return;
    }

    if (AppEnv.googleMapsApiKey.isNotEmpty) {
      final locErr = _validateEditLocation(_locationController.text);
      if (locErr != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locErr)),
        );
        return;
      }
    } else if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result =
          await ref.read(profileRepositoryProvider).updateProfile(payload);
      if (!mounted) return;
      final base = _serverProfile!;
      final updated = result.data!.mergeWith(base);
      final mergedUser = ProfileUser(
        id: base.userId,
        name: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _saved.email,
        role: 'locum',
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        dob: ProfileDetails.dateToApi(_dobController.text),
        gender: _gender!.toLowerCase(),
        qualificationDate:
            ProfileDetails.dateToApi(_qualificationDateController.text),
        independentPrescriber: _locumRole == 'Pharmacist' &&
                _independentPrescriber != null
            ? (_independentPrescriber! ? '1' : '0')
            : '',
        refName1: _proRef1NameController.text.trim(),
        refPhoneNumber1:
            _phoneForApiFromText(_proRef1PhoneController.text),
        refDetails1: _proRef1DetailsController.text.trim(),
        refName2: _proRef2NameController.text.trim(),
        refPhoneNumber2:
            _phoneForApiFromText(_proRef2PhoneController.text),
        refDetails2: _proRef2DetailsController.text.trim(),
      );
      _applyProfileDetails(
        updated,
        firstName: mergedUser.name,
        lastName: mergedUser.lastName,
        email: _saved.email,
        user: mergedUser,
      );
      ref.read(registerLocationProvider.notifier).clear();
      _seedLocationFromProfile(updated);
      refreshShellUserHeader(ref);
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message?.trim().isNotEmpty == true
                ? result.message!.trim()
                : 'Profile updated successfully',
          ),
        ),
      );
    } on ProfileFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static bool _isPreviewableImage(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp');
  }

  static bool _isPdf(String fileName) =>
      fileName.toLowerCase().endsWith('.pdf');

  static IconData _documentIcon(String fileName) {
    if (_isPdf(fileName)) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Future<void> _openDocumentExternally(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid document link.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open document: $e')),
      );
    }
  }

  Future<void> _previewDocument(ProfileDocument doc) async {
    final url = ApiConstants.documentUrl(doc.documentName);
    if (!_isPreviewableImage(doc.documentName)) {
      await _openDocumentExternally(url);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load image.\n$url',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (!_loading && _loadError == null)
            IconButton(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade600),
              const SizedBox(height: 16),
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _userHeaderCard(context),
          const SizedBox(height: 16),
          _personalDetailsCard(context),
          const SizedBox(height: 16),
          _professionalCard(context),
          const SizedBox(height: 16),
          _professionalReferencesCard(context),
          const SizedBox(height: 16),
          _serviceLocationCard(context),
          const SizedBox(height: 16),
          _documentsCard(context),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _userHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _editing
                ? [
                    IconButton.filled(
                      onPressed: _saving ? null : _saveEdit,
                      style: IconButton.styleFrom(
                        backgroundColor: BrandColors.locumsGreen,
                        foregroundColor: Colors.white,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded, size: 22),
                      tooltip: 'Save',
                    ),
                    IconButton(
                      onPressed: _saving ? null : _cancelEdit,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade800,
                      ),
                      tooltip: 'Cancel',
                    ),
                  ]
                : [
                    IconButton(
                      onPressed: _saving ? null : _startEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: BrandColors.locumsGreen,
                      ),
                      tooltip: 'Edit profile',
                    ),
                  ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: BrandColors.locumsMint.withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person_rounded,
                  size: 44,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _editing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(
                                'First name',
                                preserveCase: true,
                                isRequired: true,
                              ),
                              _editableField(
                                controller: _firstNameController,
                                hint: 'First name',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _fieldLabel(
                                'Last name',
                                preserveCase: true,
                                isRequired: true,
                              ),
                              _editableField(
                                controller: _lastNameController,
                                hint: 'Last name',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(
                  _saved.fullName.isEmpty ? '—' : _saved.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
          const SizedBox(height: 12),
          _fieldLabel('Email'),
          InputDecorator(
            decoration: _inputDecoration().copyWith(
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            child: Text(
              _saved.email.isEmpty ? '—' : _saved.email,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(height: 16),
          _headerContactRow(
            icon: Icons.phone_outlined,
            child: _editing
                ? _ProfileUkPhoneField(controller: _phoneController)
                : Text(
                    _saved.phone.isEmpty ? '—' : _saved.phone,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _headerContactRow(
            icon: Icons.location_on_outlined,
            child: Text(
              _editing
                  ? (_locationController.text.isEmpty
                      ? 'Edit location below'
                      : _locationController.text)
                  : (_saved.location.isEmpty ? '—' : _saved.location),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerContactRow({
    required IconData icon,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 22, color: BrandColors.locumsGreen),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(
    String text, {
    bool preserveCase = false,
    bool isRequired = false,
  }) {
    final label = preserveCase ? text : text.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            letterSpacing: preserveCase ? 0 : 0.4,
          ),
          children: [
            TextSpan(text: label),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyValue(String value, {int maxLines = 1}) {
    return Text(
      value.isEmpty ? '—' : value,
      style: const TextStyle(fontSize: 15, height: 1.35),
      maxLines: maxLines,
      overflow: maxLines > 1 ? TextOverflow.visible : TextOverflow.ellipsis,
    );
  }

  Widget _professionalCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.work_outline, 'Professional details'),
          const SizedBox(height: 16),
          Text(
            'QUALIFICATIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          _editing
              ? TextField(
                  controller: _qualificationsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Text(
                  _saved.qualifications.isEmpty ? '—' : _saved.qualifications,
                  style: const TextStyle(fontSize: 15),
                ),
          const SizedBox(height: 16),
          Text(
            'YEARS OF EXPERIENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          _editing
              ? TextField(
                  controller: _experienceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Text(
                  _saved.experienceYears.isEmpty ? '—' : _saved.experienceYears,
                  style: const TextStyle(fontSize: 15),
                ),
          const SizedBox(height: 16),
          Text(
            'LOCUM ROLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          _editing
              ? InputDecorator(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _roleOptions.contains(_locumRole)
                          ? _locumRole
                          : _roleOptions.first,
                      isExpanded: true,
                      items: _roleOptions
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _locumRole = v;
                          if (v != 'Pharmacist') {
                            _independentPrescriber = null;
                          }
                        });
                      },
                    ),
                  ),
                )
              : Text(
                  _saved.locumRole.isEmpty ? '—' : _saved.locumRole,
                  style: const TextStyle(fontSize: 15),
                ),
          const SizedBox(height: 16),
          _fieldLabel(
            'GPhC number (7 digits)',
            preserveCase: true,
            isRequired: _locumRole == 'Pharmacist',
          ),
          _editing
              ? TextField(
                  key: ValueKey('gphc_$_locumRole'),
                  controller: _gphcController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '1234567',
                  ),
                )
              : _readOnlyValue(_saved.gphcNumber),
          const SizedBox(height: 16),
          _fieldLabel('Qualification date'),
          _editing
              ? _dateField(_qualificationDateController)
              : _readOnlyValue(_saved.qualificationDate),
          if (_isPharmacistRole) ...[
            const SizedBox(height: 16),
            _fieldLabel('Independent prescriber'),
            _editing
                ? _ProfileIndependentPrescriberField(
                    value: _independentPrescriber,
                    onChanged: (v) =>
                        setState(() => _independentPrescriber = v),
                  )
                : _readOnlyValue(_saved.independentPrescriber),
          ],
        ],
      ),
    );
  }

  Widget _personalDetailsCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.badge_outlined, 'Personal details'),
          const SizedBox(height: 16),
          _fieldLabel('Address'),
          _editing
              ? _editableField(
                  controller: _addressController,
                  hint: 'Street address',
                )
              : _readOnlyValue(_saved.address),
          const SizedBox(height: 16),
          _fieldLabel('City'),
          _editing
              ? _editableField(controller: _cityController, hint: 'City')
              : _readOnlyValue(_saved.city),
          const SizedBox(height: 16),
          _fieldLabel('Zip code'),
          _editing
              ? _editableField(
                  controller: _zipCodeController,
                  hint: 'Postcode',
                )
              : _readOnlyValue(_saved.zipCode),
          const SizedBox(height: 16),
          _fieldLabel('Date of birth'),
          _editing
              ? _dateField(_dobController)
              : _readOnlyValue(_saved.dateOfBirth),
          const SizedBox(height: 16),
          _fieldLabel('Gender'),
          _editing
              ? InputDecorator(
                  decoration: _inputDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _gender,
                      isExpanded: true,
                      hint: const Text('Select gender'),
                      items: _genderOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                )
              : _readOnlyValue(_saved.gender),
        ],
      ),
    );
  }

  Widget _professionalReferencesCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(Icons.people_outline, 'Professional references'),
          const SizedBox(height: 20),
          Text(
            'Professional Reference 1',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Name'),
          _editing
              ? _editableField(controller: _proRef1NameController)
              : _readOnlyValue(_saved.refName1),
          const SizedBox(height: 12),
          _fieldLabel('Phone number'),
          _editing
              ? _ProfileUkPhoneField(controller: _proRef1PhoneController)
              : _readOnlyValue(_saved.refPhone1),
          const SizedBox(height: 12),
          _fieldLabel('Details'),
          _editing
              ? _editableField(
                  controller: _proRef1DetailsController,
                  maxLines: 3,
                )
              : _readOnlyValue(_saved.refDetails1, maxLines: 4),
          const SizedBox(height: 24),
          Text(
            'Professional Reference 2',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Name'),
          _editing
              ? _editableField(controller: _proRef2NameController)
              : _readOnlyValue(_saved.refName2),
          const SizedBox(height: 12),
          _fieldLabel('Phone number'),
          _editing
              ? _ProfileUkPhoneField(controller: _proRef2PhoneController)
              : _readOnlyValue(_saved.refPhone2),
          const SizedBox(height: 12),
          _fieldLabel('Details'),
          _editing
              ? _editableField(
                  controller: _proRef2DetailsController,
                  maxLines: 3,
                )
              : _readOnlyValue(_saved.refDetails2, maxLines: 4),
        ],
      ),
    );
  }

  Widget _serviceLocationCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.location_on_outlined, 'Service location'),
          const SizedBox(height: 16),
          Text(
            'LOCATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          _editing
              ? RegisterLocationAutocomplete(
                  controller: _locationController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Search by address / area',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: _validateEditLocation,
                )
              : Text(
                  _saved.location.isEmpty ? '—' : _saved.location,
                  style: const TextStyle(fontSize: 15),
                ),
          if (_editing) ...[
            const SizedBox(height: 4),
            Text(
              AppEnv.googleMapsApiKey.isEmpty
                  ? 'Enter location manually or add GOOGLE_MAPS_API_KEY to .env.'
                  : 'Start typing to search — tap a suggestion to update coordinates.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'TRAVEL DISTANCE (MILES)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          _editing
              ? TextField(
                  controller: _travelKmController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : Text(
                  _saved.travelMiles.isEmpty ? '—' : _saved.travelMiles,
                  style: const TextStyle(fontSize: 15),
                ),
        ],
      ),
    );
  }

  Widget _documentsCard(BuildContext context) {
    final count = _documents.length;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.description_outlined,
            'Documents ($count)',
          ),
          const SizedBox(height: 4),
          Text(
            _editing
                ? 'Documents cannot be changed here. Tap to preview only.'
                : 'Tap images to preview; other files open externally',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (_documents.isEmpty)
            Text(
              'No documents on file.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            )
          else
            ...List<Widget>.generate(_documents.length, (i) {
              final d = _documents[i];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _documentRow(context, d),
                  if (i < _documents.length - 1)
                    Divider(height: 1, color: Colors.grey.shade200),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _documentRow(BuildContext context, ProfileDocument doc) {
    return InkWell(
      onTap: () => _previewDocument(doc),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.circle,
                size: 10,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            if (_isPreviewableImage(doc.documentName))
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  ApiConstants.documentUrl(doc.documentName),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 44,
                    height: 44,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.grey.shade500),
                  ),
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  _documentIcon(doc.documentName),
                  color: _isPdf(doc.documentName)
                      ? Colors.red.shade700
                      : Colors.grey.shade600,
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.displayTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.documentName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _previewDocument(doc),
              icon: Icon(
                Icons.visibility_outlined,
                color: BrandColors.locumsGreen,
              ),
              tooltip: _isPreviewableImage(doc.documentName)
                  ? 'Preview'
                  : 'Open',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileUkPhoneField extends StatelessWidget {
  const _ProfileUkPhoneField({required this.controller});

  final TextEditingController controller;

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
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: const Text(
            '+44',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileIndependentPrescriberField extends StatelessWidget {
  const _ProfileIndependentPrescriberField({
    required this.value,
    required this.onChanged,
  });

  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget option(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(8),
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
                Text(label),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('Yes', value == true, () => onChanged(true)),
        const SizedBox(width: 12),
        option('No', value == false, () => onChanged(false)),
      ],
    );
  }
}
