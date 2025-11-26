import 'dart:io';

import 'package:check_bird/screens/group_detail/widgets/create_post/widgets/image_type_dialog.dart';
import 'package:check_bird/screens/groups/models/groups_controller.dart';
import 'package:check_bird/services/authentication.dart';
import 'package:check_bird/widgets/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

enum AppState {
  free,
  picked,
  cropped,
}

/// Data class to hold all view mode data loaded together
class _GroupViewData {
  final List<GroupMember> members;
  final bool isJoined;

  _GroupViewData({
    required this.members,
    required this.isJoined,
  });
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key, this.group});
  final Group? group;

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  File? _image;
  AppState state = AppState.free;
  var _descriptionText = "";
  var _nameText = "";
  var _nameController = TextEditingController();
  var _descriptionController = TextEditingController();
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  // View mode data - loaded together
  late Future<_GroupViewData>? _viewDataFuture;

  bool get _hasContent {
    return _nameText.trim().isNotEmpty;
  }

  bool get _isViewMode => widget.group != null;

  void _submit() {
    GroupsController().createGroup(
        groupName: _nameText,
        groupDescription: _descriptionText,
        image: _image);
  }

  Future<void> _pickImage(ImageSource imageSource) async {
    var pickedImg = await ImagePicker().pickImage(source: imageSource);
    if (pickedImg != null) {
      setState(() {
        _image = File(pickedImg.path);
        state = AppState.picked;
      });
    }
  }

  void _clearImage() {
    _image = null;
    setState(() {
      state = AppState.free;
    });
  }

  Future<void> _cropImage() async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: _image!.path,
      maxWidth: 180,
      maxHeight: 180,
      compressQuality: 50,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropFrameColor: Colors.white,
          showCropGrid: false,
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      _image = File(croppedFile.path);
      setState(() {
        state = AppState.cropped;
      });
    }
  }

  /// Load all view data together (members + isJoined)
  Future<_GroupViewData> _loadViewData() async {
    final controller = GroupsController();
    final results = await Future.wait([
      controller.getGroupMembers(widget.group!.groupId),
      controller.isJoined(groupId: widget.group!.groupId),
    ]);
    return _GroupViewData(
      members: results[0] as List<GroupMember>,
      isJoined: results[1] as bool,
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController = TextEditingController(text: widget.group!.groupName);
      _descriptionController =
          TextEditingController(text: widget.group!.groupDescription);
      _viewDataFuture = _loadViewData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isViewMode) {
      return _buildViewModeUI(context, l10n, theme, colorScheme);
    }

    return _buildCreateModeUI(context, l10n, theme, colorScheme);
  }

  Widget _buildViewModeUI(BuildContext context, AppLocalizations? l10n,
      ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: FutureBuilder<_GroupViewData>(
          future: _viewDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState(context, colorScheme);
            }

            if (snapshot.hasError) {
              return _buildErrorState(context, colorScheme, snapshot.error);
            }

            final viewData = snapshot.data!;
            return _buildLoadedContent(context, l10n, colorScheme, viewData);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, ColorScheme colorScheme) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeroHeader(context, colorScheme),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SkeletonCard(),
              const SizedBox(height: 16),
              const SkeletonMembersList(itemCount: 3),
              const SizedBox(height: 16),
              const SkeletonButton(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      BuildContext context, ColorScheme colorScheme, Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load group info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _viewDataFuture = _loadViewData();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, AppLocalizations? l10n,
      ColorScheme colorScheme, _GroupViewData viewData) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeroHeader(context, colorScheme),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoCard(context, colorScheme),
              const SizedBox(height: 16),
              _GroupMembersSection(members: viewData.members),
              const SizedBox(height: 16),
              _buildActionButtonFromData(
                  context, l10n, colorScheme, viewData.isJoined),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonFromData(BuildContext context,
      AppLocalizations? l10n, ColorScheme colorScheme, bool isJoined) {
    if (isJoined) {
      return _buildLeaveButton(context, l10n, colorScheme);
    } else {
      return _buildJoinButton(context, l10n, colorScheme);
    }
  }

  Widget _buildHeroHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withValues(alpha: 0.15),
            colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary,
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: widget.group!.groupsAvtUrl != null
                        ? NetworkImage(widget.group!.groupsAvtUrl!)
                        : null,
                    child: widget.group!.groupsAvtUrl == null
                        ? Icon(
                            Icons.group_rounded,
                            size: 48,
                            color: colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.group!.groupName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              if (widget.group!.groupDescription != null &&
                  widget.group!.groupDescription!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.group!.groupDescription!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              _buildStatsRow(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatItem(
          context,
          colorScheme,
          Icons.people_rounded,
          '${widget.group!.numOfMember}',
          'Members',
        ),
        Container(
          height: 32,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          color: colorScheme.outlineVariant,
        ),
        _buildStatItem(
          context,
          colorScheme,
          Icons.checklist_rounded,
          '${widget.group!.numOfTasks}',
          'Tasks',
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, ColorScheme colorScheme,
      IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme) {
    final createdDate =
        DateFormat.yMMMd().format(widget.group!.createdAt.toDate());
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          _buildInfoRow(
            context,
            colorScheme,
            Icons.calendar_today_rounded,
            'Created',
            createdDate,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ColorScheme colorScheme,
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveButton(
      BuildContext context, AppLocalizations? l10n, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Material(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              barrierDismissible: true,
              builder: (ctx) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(l10n?.leaveGroupQuestion ?? 'Leave group?'),
                  content: Text(l10n?.leaveGroupWarning ??
                      'Are you sure you want to leave this group?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(l10n?.cancel ?? 'Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                        foregroundColor: Theme.of(ctx).colorScheme.onError,
                      ),
                      child: Text(l10n?.leaveGroup ?? 'Leave'),
                    ),
                  ],
                );
              },
            );
            if (confirm == true) {
              await GroupsController().unJoinGroup(widget.group!.groupId);
              if (!mounted) return;
              Navigator.of(this.context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.exit_to_app_rounded, color: colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  l10n?.leaveGroup ?? 'Leave group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton(
      BuildContext context, AppLocalizations? l10n, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            GroupsController().joinGroup(widget.group!.groupId);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: colorScheme.onPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n?.joinGroup ?? 'Join group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateModeUI(BuildContext context, AppLocalizations? l10n,
      ThemeData theme, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Create group',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: _hasContent
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.secondaryContainer,
                ),
                onPressed: _hasContent
                    ? () {
                        _submit();
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text(
                  'Create group',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                )),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    final useCam = await showDialog(
                        context: context,
                        builder: (context) {
                          return const ImageTypeDialog();
                        });
                    if (useCam == null) return;
                    if (useCam) {
                      await _pickImage(ImageSource.camera);
                    } else {
                      await _pickImage(ImageSource.gallery);
                    }
                    if (_image != null) {
                      await _cropImage();
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    margin: const EdgeInsets.all(20),
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primaryContainer,
                      image: _image != null
                          ? DecorationImage(image: Image.file(_image!).image)
                          : null,
                    ),
                    child: _image == null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Take an image',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black12),
                              ),
                              Icon(
                                Icons.image,
                                color: Colors.black12,
                              )
                            ],
                          )
                        : null,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _clearImage();
                  },
                  child: const Text('Clear image'),
                ),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  maxLength: 50,
                  decoration: const InputDecoration(
                      hintText: "Enter group's name",
                      labelText: "Group's name"),
                  onChanged: (value) {
                    setState(() {
                      _nameText = value;
                    });
                  },
                ),
                TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocus,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  decoration: const InputDecoration(
                      hintText: "Enter group's description",
                      labelText: "Group's description"),
                  onChanged: (value) {
                    setState(() {
                      _descriptionText = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Expandable section showing group members
class _GroupMembersSection extends StatefulWidget {
  const _GroupMembersSection({required this.members});
  final List<GroupMember> members;

  @override
  State<_GroupMembersSection> createState() => _GroupMembersSectionState();
}

class _GroupMembersSectionState extends State<_GroupMembersSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.value = 1.0; // Start expanded
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final members = widget.members;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.people_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Members',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            '${members.length} ${members.length == 1 ? 'person' : 'people'}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ...members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isFirst = index == 0;
                  return _MemberListItem(
                    member: member,
                    isAdmin: isFirst,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  const _MemberListItem({
    required this.member,
    this.isAdmin = false,
  });

  final GroupMember member;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentUser = member.id == Authentication.user?.uid;
    final joinedDate = DateFormat.yMMMd().format(member.joinedAt.toDate());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCurrentUser
                        ? colorScheme.primary
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: member.avatarUrl != null
                      ? NetworkImage(member.avatarUrl!)
                      : null,
                  child: member.avatarUrl == null
                      ? Text(
                          member.name.isNotEmpty
                              ? member.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ),
              if (isAdmin)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.tertiary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined $joinedDate',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
