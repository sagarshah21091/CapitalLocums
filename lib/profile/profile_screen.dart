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
import 'profile_providers.dart';
import 'profile_repository.dart';

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.qualifications,
    required this.experienceYears,
    required this.locumRole,
    required this.travelKm,
  });

  final String name;
  final String email;
  final String phone;
  final String location;
  final String qualifications;
  final String experienceYears;
  final String locumRole;
  final String travelKm;
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

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  late final TextEditingController _qualificationsController;
  late final TextEditingController _experienceController;
  late final TextEditingController _travelKmController;
  String _locumRole = 'Pharmacist';

  static const _roleOptions = ['Pharmacist', 'Technician'];
  static const _cardRadius = 12.0;
  static const _borderColor = Color(0xFFE0E0E0);

  static const _emptyProfile = _ProfileData(
    name: '',
    email: '',
    phone: '',
    location: '',
    qualifications: '',
    experienceYears: '',
    locumRole: 'Pharmacist',
    travelKm: '',
  );

  @override
  void initState() {
    super.initState();
    _saved = _emptyProfile;
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _qualificationsController = TextEditingController();
    _experienceController = TextEditingController();
    _travelKmController = TextEditingController();
    _locationController.addListener(_onLocationFieldChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  static String _displayLocumRole(String? apiRole) {
    final r = apiRole?.trim().toLowerCase() ?? '';
    if (r == 'technician') return 'Technician';
    if (r == 'pharmacist') return 'Pharmacist';
    if (r.isEmpty) return 'Pharmacist';
    return r[0].toUpperCase() + r.substring(1);
  }

  static String _apiLocumRole(String display) {
    switch (display) {
      case 'Technician':
        return 'technician';
      default:
        return 'pharmacist';
    }
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

  void _applyProfileDetails(ProfileDetails profile, {String? name, String? email}) {
    _serverProfile = profile;
    final displayName = name ?? _saved.name;
    final displayEmail = email ?? _saved.email;
    final role = _displayLocumRole(profile.locumRole);

    _saved = _ProfileData(
      name: displayName,
      email: displayEmail,
      phone: profile.phone.trim(),
      location: profile.location.trim(),
      qualifications: profile.qualifications.trim(),
      experienceYears: '${profile.experienceYears}',
      locumRole: role,
      travelKm: '${profile.travelDistance}',
    );

    _nameController.text = displayName;
    _phoneController.text = _saved.phone;
    _locationController.text = _saved.location;
    _qualificationsController.text = _saved.qualifications;
    _experienceController.text = _saved.experienceYears;
    _travelKmController.text = _saved.travelKm;
    _locumRole = role;
  }

  void _applyPayload(ProfilePayload payload) {
    final user = payload.user;
    final profile = payload.profile;
    _documents = List<ProfileDocument>.from(payload.documents);

    if (profile != null) {
      _applyProfileDetails(
        profile,
        name: user?.name.trim(),
        email: user?.email.trim(),
      );
      ref.read(registerLocationProvider.notifier).clear();
      _seedLocationFromProfile(profile);
    } else {
      _serverProfile = null;
      _saved = _emptyProfile;
    }
  }

  ProfileDetails? _buildUpdateBody() {
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
      phone: _phoneController.text.trim(),
      qualifications: _qualificationsController.text.trim(),
      experienceYears: experience,
      location: location,
      latitude: lat.toString(),
      longitude: lng.toString(),
      travelDistance: travel,
      locumRole: _apiLocumRole(_locumRole),
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      coordinates: ProfileCoordinates(x: lng, y: lat),
    );
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
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _travelKmController.dispose();
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
    _nameController.text = _saved.name;
    _phoneController.text = _saved.phone;
    _locationController.text = _saved.location;
    _qualificationsController.text = _saved.qualifications;
    _experienceController.text = _saved.experienceYears;
    _travelKmController.text = _saved.travelKm;
    final profile = _serverProfile;
    if (profile != null) {
      _seedLocationFromProfile(profile);
    }
    setState(() {
      _locumRole = _saved.locumRole;
      _editing = false;
    });
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

    final body = _buildUpdateBody();
    if (body == null) {
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
          await ref.read(profileRepositoryProvider).updateProfile(body);
      if (!mounted) return;
      final updated = result.data!;
      _applyProfileDetails(updated);
      ref.read(registerLocationProvider.notifier).clear();
      _seedLocationFromProfile(updated);
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
          _professionalCard(context),
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
          Text(
              _saved.name.isEmpty ? '—' : _saved.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          if (_saved.email.isNotEmpty && !_editing) ...[
            const SizedBox(height: 6),
            Text(
              _saved.email,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 16),
          _headerContactRow(
            icon: Icons.phone_outlined,
            child: _editing
                ? TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Phone number',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  )
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
                      onChanged: (v) =>
                          setState(() => _locumRole = v ?? _locumRole),
                    ),
                  ),
                )
              : Text(
                  _saved.locumRole.isEmpty ? '—' : _saved.locumRole,
                  style: const TextStyle(fontSize: 15),
                ),
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
            'TRAVEL DISTANCE (KM)',
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
                  _saved.travelKm.isEmpty ? '—' : _saved.travelKm,
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
            'Tap images to preview; other files open externally',
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
