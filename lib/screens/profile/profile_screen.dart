import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/screens/profile/tabs/achievement_tab.dart';
import 'package:check_bird/screens/profile/tabs/inventory_tab.dart';
import 'package:check_bird/screens/profile/tabs/profile_info_tab.dart';
import 'package:check_bird/screens/profile/tabs/title_tab.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile-screen';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileController _profileController = ProfileController();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (Authentication.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile =
        await _profileController.getUserProfile(Authentication.user!.uid);

    if (profile == null) {
      // Initialize profile if it doesn't exist
      await _profileController.initializeProfile(
        Authentication.user!.uid,
        Authentication.user!.email ?? '',
        Authentication.user!.displayName ?? 'User',
      );
      final newProfile =
          await _profileController.getUserProfile(Authentication.user!.uid);
      setState(() {
        _userProfile = newProfile;
        _isLoading = false;
      });
    } else {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (Authentication.user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Please sign in to view your profile'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProfileHeader(),

          // Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.label,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            tabAlignment: TabAlignment.center,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Inventory'),
              Tab(text: 'Titles'),
              Tab(text: 'Achievements'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                ProfileInfoTab(
                  userProfile: _userProfile,
                  onRefresh: _loadUserProfile,
                ),
                InventoryTab(
                  userProfile: _userProfile,
                  onRefresh: _loadUserProfile,
                ),
                TitleTab(
                  userProfile: _userProfile,
                  onRefresh: _loadUserProfile,
                ),
                AchievementTab(
                  userProfile: _userProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final selectedBg = _userProfile?.selectedBackgroundId;
    final selectedFrame = _userProfile?.selectedFrameId;
    final hasFrame = selectedFrame != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        image: selectedBg != null
            ? const DecorationImage(
                image: AssetImage('assets/images/bg_space.png'),
                fit: BoxFit.cover,
              )
            : null,
        gradient: selectedBg == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _darken(Theme.of(context).colorScheme.primary, 0.12),
                  Theme.of(context).colorScheme.primary,
                ],
              )
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: hasFrame
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: _getAvatarImage(),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: _getAvatarImage() == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _changeAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Authentication.user?.displayName ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getUserTitle(),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  value: '${_userProfile?.achievementProgress.length ?? 0}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  label: 'Items',
                  value:
                      '${(_userProfile?.ownedFrames.length ?? 0) + (_userProfile?.ownedBackgrounds.length ?? 0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getUserTitle() {
    if (_userProfile?.selectedTitleId == null) {
      return 'Danh hiệu';
    }

    final titles = _profileController.getAvailableTitles();
    final selectedTitle = titles.firstWhere(
      (t) => t.id == _userProfile?.selectedTitleId,
      orElse: () => ProfileTitle(id: 'default', name: 'Danh hiệu'),
    );

    return selectedTitle.name;
  }

  ImageProvider? _getAvatarImage() {
    // Priority: UserProfile avatarUrl > Firebase Auth photoURL
    if (_userProfile?.avatarUrl != null) {
      return NetworkImage(_userProfile!.avatarUrl!);
    }
    if (Authentication.user?.photoURL != null) {
      return NetworkImage(Authentication.user!.photoURL!);
    }
    return null;
  }

  Future<ImageSource?> _showImageSourceBottomSheet() async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Choose Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to add your profile picture',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Camera option
              _buildImageSourceOption(
                icon: Icons.camera_alt_rounded,
                title: 'Camera',
                subtitle: 'Take a new photo',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, ImageSource.camera);
                },
                theme: theme,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Gallery option
              _buildImageSourceOption(
                icon: Icons.photo_library_rounded,
                title: 'Gallery',
                subtitle: 'Choose from your photos',
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context, ImageSource.gallery);
                },
                theme: theme,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.secondary.withOpacity(0.8),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ),

              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: gradient.colors.first.withOpacity(0.1),
          highlightColor: gradient.colors.first.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    if (Authentication.user == null) return;

    // Show image source selection bottom sheet
    final imageSource = await _showImageSourceBottomSheet();
    if (imageSource == null) return;

    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Updating avatar...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Pick and crop image with selected source
      final imageFile =
          await _profileController.pickAndCropImage(context, imageSource);
      if (imageFile == null) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          // Don't show error if user simply cancelled
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image selection was cancelled'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      // Upload to Firebase Storage
      final avatarUrl = await _profileController.uploadAvatar(
        Authentication.user!.uid,
        imageFile,
      );

      if (avatarUrl != null) {
        // Update Firestore profile
        await _profileController.updateAvatar(
          Authentication.user!.uid,
          avatarUrl,
        );

        // Update Firebase Auth profile
        await Authentication.user!.updatePhotoURL(avatarUrl);
        await Authentication.user!.reload();
        Authentication.user = FirebaseAuth.instance.currentUser;

        // Refresh profile
        await _loadUserProfile();

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog

          // Add haptic feedback for success
          HapticFeedback.mediumImpact();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Profile picture updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        // Add haptic feedback for error
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to update profile picture. Please try again.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
