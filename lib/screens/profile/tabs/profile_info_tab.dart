import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProfileInfoTab extends StatefulWidget {
  final UserProfile? userProfile;
  final VoidCallback onRefresh;

  const ProfileInfoTab({
    super.key,
    required this.userProfile,
    required this.onRefresh,
  });

  @override
  State<ProfileInfoTab> createState() => _ProfileInfoTabState();
}

class _ProfileInfoTabState extends State<ProfileInfoTab> {
  final _profileController = ProfileController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _usernameController.text = widget.userProfile?.username ?? '';
    _phoneController.text = widget.userProfile?.phoneNumber ?? '';
    _selectedGender = widget.userProfile?.gender;
    _selectedDate = widget.userProfile?.dateOfBirth;
  }

  Future<void> _saveProfile() async {
    if (Authentication.user == null) return;

    try {
      final updated = widget.userProfile!.copyWith(
        username: _usernameController.text,
        phoneNumber: _phoneController.text,
        gender: _selectedGender,
        dateOfBirth: _selectedDate,
      );

      await _profileController.updateUserProfile(updated);
      widget.onRefresh();

      if (!mounted) return;
      _showTopMessage('Profile updated successfully');
    } catch (e) {
      if (!mounted) return;
      _showTopMessage('Error updating profile: $e', success: false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2001, 5, 30),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'Personal Information',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your profile details',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernTextField(
                    context: context,
                    label: 'Username',
                    controller: _usernameController,
                    icon: Icons.person_outline_rounded,
                    hintText: 'Enter your username',
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    context: context,
                    label: 'Email',
                    controller: null,
                    icon: Icons.email_outlined,
                    readOnly: true,
                    value: Authentication.user?.email ?? '',
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    context: context,
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hintText: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildGenderSelector(context),
                  const SizedBox(height: 20),
                  _buildDateSelector(context),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 2,
                shadowColor: colorScheme.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.save_rounded),
              label: Text(
                'Save Changes',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your email address is verified and cannot be changed',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required BuildContext context,
    required String label,
    required IconData icon,
    TextEditingController? controller,
    String? value,
    String? hintText,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: readOnly
                ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              Expanded(
                child: controller != null
                    ? TextField(
                        controller: controller,
                        readOnly: readOnly,
                        keyboardType: keyboardType,
                        style: textTheme.bodyLarge,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          contentPadding: const EdgeInsets.only(right: 16),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          value ?? '',
                          style: textTheme.bodyLarge?.copyWith(
                            color: readOnly
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(
                  Icons.wc_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    hint: Text(
                      'Select gender',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    padding: const EdgeInsets.only(right: 16),
                    borderRadius: BorderRadius.circular(12),
                    items: ['Male', 'Female', 'Other'].map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(
                          gender,
                          style: textTheme.bodyLarge,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedGender = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth',
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('MMMM dd, yyyy').format(_selectedDate!)
                        : 'Select your date of birth',
                    style: textTheme.bodyLarge?.copyWith(
                      color: _selectedDate != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showTopMessage(String message, {bool success = true}) {
    final messenger = ScaffoldMessenger.of(context);
    final cs = Theme.of(context).colorScheme;

    messenger.hideCurrentSnackBar();
    messenger.hideCurrentMaterialBanner();

    final bg = success ? cs.primaryContainer : cs.errorContainer;
    final fg = success ? cs.onPrimaryContainer : cs.onErrorContainer;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    final banner = MaterialBanner(
      backgroundColor: bg,
      surfaceTintColor: bg,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Icon(icon, color: fg),
      content: Text(
        message,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600),
      ),
      dividerColor: Colors.transparent,
      actions: [
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text('Dismiss', style: TextStyle(color: fg)),
        ),
      ],
    );

    messenger.showMaterialBanner(banner);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
  }
}
