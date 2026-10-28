import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import 'group_details_screen.dart';
import 'group_create_screen.dart';
import 'group_join_screen.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);
const Color kExpenseColor = Color(0xFFE11D48);

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupService _groupService = GroupService();

  late Future<List<Group>> _groupsFuture;

  bool _isSearching = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _groupsFuture = _groupService.getGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reloadGroups() {
    setState(() {
      _groupsFuture = _groupService.getGroups();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;

      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _openCreateGroupScreen() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GroupCreateScreen()),
    );

    if (created == true) {
      _reloadGroups();
    }
  }

  Future<void> _openJoinGroupScreen() async {
    final joined = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const GroupJoinScreen()),
    );

    if (joined == true) {
      _reloadGroups();
    }
  }

  Future<void> _openGroupDetails(Group group) async {
    final refreshed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
    );

    if (refreshed == true) {
      _reloadGroups();
    }
  }

  List<Group> _filterGroups(List<Group> groups) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return groups;

    return groups.where((group) {
      final name = group.name.toLowerCase();
      final description = (group.description).toLowerCase();

      return name.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Groups',
          style: TextStyle(
            color: kInk,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // Open notifications screen or sheet later
            },
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 20,
                    color: kInk,
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kExpenseColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Group>>(
        future: _groupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted),
                ),
              ),
            );
          }

          final allGroups = snapshot.data ?? [];

          if (allGroups.isEmpty) {
            return _EmptyGroups(
              onCreate: _openCreateGroupScreen,
              onJoin: _openJoinGroupScreen,
            );
          }

          final groups = _filterGroups(allGroups);

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: () async {
              _reloadGroups();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _GroupsHero(),
                const SizedBox(height: 30),

                _GroupsToolbar(
                  isSearching: _isSearching,
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  searchQuery: _searchQuery,
                  groupCount: groups.length,
                  onSearchToggle: _toggleSearch,
                  onSearchChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onJoin: _openJoinGroupScreen,

                  onCreate: _openCreateGroupScreen,
                ),

                const SizedBox(height: 18),

                if (groups.isEmpty)
                  const _NoSearchResults()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.92,
                        ),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];

                      return _CubicGroupChip(
                        group: group,
                        onTap: () => _openGroupDetails(group),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GroupsHero extends StatelessWidget {
  const _GroupsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 34),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    kPrimarySoft.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -25,
            bottom: -35,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.handshake_rounded,
                      size: 15,
                      color: Color(0xFF5EEAD4),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Shared expenses',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Split smarter.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 5),
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    colors: [Color(0xFF5EEAD4), Color(0xFF38BDF8)],
                  ).createShader(bounds);
                },
                child: const Text(
                  'Stay settled.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Shared expenses, clear balances\nand effortless settlements.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupsToolbar extends StatelessWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final int groupCount;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _GroupsToolbar({
    required this.isSearching,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.groupCount,
    required this.onSearchToggle,
    required this.onSearchChanged,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: isSearching
              ? _SearchField(
                  controller: searchController,
                  focusNode: searchFocusNode,
                  onChanged: onSearchChanged,
                  onClose: () {},
                )
              : Row(
                  children: [
                    const Text(
                      'Your groups',
                      style: TextStyle(
                        color: kInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        groupCount.toString(),
                        style: const TextStyle(
                          color: kPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 10),
        _ToolbarIconButton(
          icon: isSearching ? Icons.close_rounded : Icons.search_rounded,
          onTap: onSearchToggle,
        ),
        const SizedBox(width: 10),
        _ToolbarIconButton(icon: Icons.vpn_key_rounded, onTap: onJoin),
        const SizedBox(width: 10),
        _NewGroupButton(onTap: onCreate),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: kPrimary),
      ),
    );
  }
}

class _NewGroupButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NewGroupButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: kInk,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: kInk.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'New',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      cursorColor: kPrimary,
      style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: 'Search groups',
        hintStyle: const TextStyle(color: kMuted, fontWeight: FontWeight.w600),
        prefixIcon: const Icon(Icons.search_rounded, color: kMuted, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CubicGroupChip extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;

  const _CubicGroupChip({required this.group, required this.onTap});

  List<Color> get _gradient {
    final palettes = [
      [const Color(0xFFCCFBF1), const Color(0xFFE0F2FE)],
      [const Color(0xFFEDE9FE), const Color(0xFFFCE7F3)],
      [const Color(0xFFFFF7ED), const Color(0xFFFEE2E2)],
      [const Color(0xFFDCFCE7), const Color(0xFFD1FAE5)],
      [const Color(0xFFE0E7FF), const Color(0xFFE0F2FE)],
      [const Color(0xFFFDF2F8), const Color(0xFFF3E8FF)],
    ];

    return palettes[group.name.hashCode.abs() % palettes.length];
  }

  Color get _accent {
    final accents = [
      const Color(0xFF0F766E),
      const Color(0xFF6366F1),
      const Color(0xFFEA580C),
      const Color(0xFF059669),
      const Color(0xFF4F46E5),
      const Color(0xFFDB2777),
    ];

    return accents[group.name.hashCode.abs() % accents.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradient,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                group.name.isNotEmpty
                    ? group.name.characters.first.toUpperCase()
                    : '?',
                style: TextStyle(
                  color: _accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Spacer(),
            Text(
              group.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kInk,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              group.description.isNotEmpty == true
                  ? group.description
                  : '${group.members.length} members',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: kMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_rounded, size: 13, color: _accent),
                      const SizedBox(width: 5),
                      Text(
                        '${group.members.length}',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _EmptyGroups({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),

          const _GroupsHero(),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.diversity_3_rounded,
                    size: 30,
                    color: kPrimary,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'No groups yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Create a group or join one using an invite code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text(
                      'Create group',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: onJoin,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimary,
                      side: const BorderSide(color: kPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    icon: const Icon(Icons.vpn_key_rounded, size: 17),
                    label: const Text(
                      'Join with invite code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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
}


class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 36, color: kMuted),
          const SizedBox(height: 14),
          const Text(
            'No groups found',
            style: TextStyle(
              color: kInk,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different group name.',
            style: TextStyle(
              color: kMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinGroupSheet extends StatefulWidget {
  final VoidCallback onJoined;

  const _JoinGroupSheet({required this.onJoined});

  @override
  State<_JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<_JoinGroupSheet> {
  final GroupService _groupService = GroupService();

  final _inviteCodeController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    final code = _inviteCodeController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter an invite code')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final message = await _groupService.joinGroup(inviteCode: code);

      if (!mounted) return;

      Navigator.pop(context);
      widget.onJoined();

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyError(error).replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: kPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Join a group',
                  style: TextStyle(
                    color: kInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SheetField(
            controller: _inviteCodeController,
            label: 'Invite code',
            hint: 'GOA4821X',
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _joinGroup,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Join group',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.hint,
  }) : maxLines = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: kInk, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: kMuted,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
