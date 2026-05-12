import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand_colors.dart';

class _ProfileData {
  const _ProfileData({
    required this.name,
    required this.phone,
    required this.location,
    required this.qualifications,
    required this.experienceYears,
    required this.locumRole,
    required this.travelKm,
  });

  final String name;
  final String phone;
  final String location;
  final String qualifications;
  final String experienceYears;
  final String locumRole;
  final String travelKm;
}

/// Locum profile from portal reference: header, professional, service area, documents.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;

  late _ProfileData _saved;
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

  static final _documents = <({String title, String fileName})>[
    (
      title: 'Passport',
      fileName: '20260508115126_1_6uHGpAX20afqczGiND7Uw.png',
    ),
    (
      title: 'National insurance',
      fileName: '20260508115259_1_fqT4_2fEeUul1rQ4Vg7oew.png',
    ),
    (
      title: 'Qualification certificates',
      fileName: '20260508115420_1_hK8xY3lQ2nNp0mR5sT6uV.png',
    ),
    (
      title: 'Professional reference 1',
      fileName: '20260508115501_1_ref1_doc.pdf',
    ),
    (
      title: 'Professional reference 2',
      fileName: '20260508115544_1_ref2_doc.pdf',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _saved = const _ProfileData(
      name: 'peter',
      phone: '8978934780',
      location: 'London, UK',
      qualifications: 'PharmaB',
      experienceYears: '5',
      locumRole: 'Pharmacist',
      travelKm: '10',
    );
    _nameController = TextEditingController(text: _saved.name);
    _phoneController = TextEditingController(text: _saved.phone);
    _locationController = TextEditingController(text: _saved.location);
    _qualificationsController =
        TextEditingController(text: _saved.qualifications);
    _experienceController =
        TextEditingController(text: _saved.experienceYears);
    _travelKmController = TextEditingController(text: _saved.travelKm);
    _locumRole = _saved.locumRole;
    _locationController.addListener(_onLocationFieldChanged);
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

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    _nameController.text = _saved.name;
    _phoneController.text = _saved.phone;
    _locationController.text = _saved.location;
    _qualificationsController.text = _saved.qualifications;
    _experienceController.text = _saved.experienceYears;
    _travelKmController.text = _saved.travelKm;
    setState(() {
      _locumRole = _saved.locumRole;
      _editing = false;
    });
  }

  void _saveEdit() {
    setState(() {
      _saved = _ProfileData(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        qualifications: _qualificationsController.text.trim(),
        experienceYears: _experienceController.text.trim(),
        locumRole: _locumRole,
        travelKm: _travelKmController.text.trim(),
      );
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved (demo).')),
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
                      onPressed: _saveEdit,
                      style: IconButton.styleFrom(
                        backgroundColor: BrandColors.locumsGreen,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 22),
                      tooltip: 'Save',
                    ),
                    IconButton(
                      onPressed: _cancelEdit,
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade800,
                      ),
                      tooltip: 'Cancel',
                    ),
                  ]
                : [
                    IconButton(
                      onPressed: _startEdit,
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
          if (_editing)
            TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Display name',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            )
          else
            Text(
              _saved.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
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
                    _saved.phone,
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
                  : _saved.location,
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
                  _saved.qualifications,
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
              : Text(_saved.experienceYears,
                  style: const TextStyle(fontSize: 15)),
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
                      value: _locumRole,
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
              : Text(_saved.locumRole, style: const TextStyle(fontSize: 15)),
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
              ? TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: 'Search by address / area',
                  ),
                  onChanged: (_) => setState(() {}),
                )
              : Text(_saved.location, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Start typing to search for locations',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
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
              : Text(_saved.travelKm, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _documentsCard(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.description_outlined, 'Documents (5)'),
          const SizedBox(height: 4),
          Text(
            'Tap a row to preview',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
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

  Widget _documentRow(
    BuildContext context,
    ({String title, String fileName}) doc,
  ) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View: ${doc.title}')),
        );
      },
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doc.fileName,
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('View: ${doc.title}')),
                );
              },
              icon: Icon(
                Icons.visibility_outlined,
                color: BrandColors.locumsGreen,
              ),
              tooltip: 'View',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
