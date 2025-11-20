import 'package:check_bird/models/user_profile.dart';
import 'package:check_bird/screens/profile/tabs/achievement_tab.dart';
import 'package:check_bird/screens/profile/tabs/inventory_tab.dart';
import 'package:check_bird/screens/profile/tabs/profile_info_tab.dart';
import 'package:check_bird/screens/profile/tabs/title_tab.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/services/profile_controller.dart';
import 'package:flutter/material.dart';

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
                  backgroundImage: Authentication.user?.photoURL != null
                      ? NetworkImage(Authentication.user!.photoURL!)
                      : null,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Authentication.user?.photoURL == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 40,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        )
                      : null,
                ),
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

  Color _darken(Color color, [double amount = .1]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
