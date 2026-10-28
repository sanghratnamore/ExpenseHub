import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  final List<Map<String, dynamic>> _selectedFriends = [];

  String? _currentUserId;

  bool _isLoadingFriends = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showGroupCreatedPopup(
    BuildContext context,
    dynamic group,
  ) async {
    final inviteCode = group.inviteCode ?? '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF4F46E5)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Group created!',
                  style: TextStyle(
                    color: kInk,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Share this invite code with\nyour friends to add them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: kPrimary.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'INVITE CODE',
                        style: TextStyle(
                          color: kMuted,
                          fontSize: 10.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        inviteCode.isEmpty ? 'Not available' : inviteCode,
                        style: const TextStyle(
                          color: kPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: inviteCode),
                          );

                          if (!dialogContext.mounted) return;

                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Invite code copied')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text(
                          'Copy',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kInk,
                          side: const BorderSide(color: kBorder),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Join my ExpenseHub group "${group.name}" using invite code: $inviteCode',
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text(
                          'Share',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: kMuted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadFriends() async {
    try {
      _currentUserId = await _authService.getUserId();

      final friends = await _groupService.getFriends();

      if (!mounted) return;

      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _isLoadingFriends = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoadingFriends = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      final search = query.trim().toLowerCase();

      if (search.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          final name = (friend['name'] ?? '').toString().toLowerCase();
          final email = (friend['email'] ?? '').toString().toLowerCase();

          return name.contains(search) || email.contains(search);
        }).toList();
      }
    });
  }

  void _toggleFriend(Map<String, dynamic> friend) {
    final userId = friend['id'].toString();

    setState(() {
      final alreadySelected = _selectedFriends.any(
        (item) => item['id'].toString() == userId,
      );

      if (alreadySelected) {
        _selectedFriends.removeWhere((item) => item['id'].toString() == userId);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _authService.getUserId();

      if (userId == null) {
        throw Exception('Please log in again');
      }
      final descriptionController = TextEditingController();

      final memberIds = _selectedFriends
          .map((friend) => friend['id'].toString())
          .toList();

      final group = await _groupService.createGroup(
        name: _nameController.text.trim(),
        createdBy: userId,
        memberIds: memberIds,
        description: descriptionController.text.trim(),
      );

      if (!mounted) return;

      await _showGroupCreatedPopup(context, group);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kInk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Text(
            error.toString().replaceAll('Exception: ', ''),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kInk,
            size: 20,
          ),
        ),
        title: const Text(
          'New group',
          style: TextStyle(
            color: kInk,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  const _GroupHero(),
                  const SizedBox(height: 26),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _CardTitle(title: 'Group details'),
                        const SizedBox(height: 18),
                        _PremiumField(
                          controller: _nameController,
                          label: 'Group name',
                          hint: 'Goa Trip, Flat 304',
                          prefixIcon: Icons.groups_2_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a group name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _PremiumField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'What is this group for?',
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _CardTitle(title: 'Add friends'),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedFriends.length} selected',
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedFriends.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedFriends.map((friend) {
                              final name = (friend['name'] ?? '').toString();

                              return _SelectedFriendChip(
                                name: name,
                                onRemove: () => _toggleFriend(friend),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _searchController,
                          onChanged: _filterFriends,
                          decoration: InputDecoration(
                            hintText: 'Search friends',
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: kMuted,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: kSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingFriends)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: kPrimary),
                            ),
                          )
                        else if (_filteredFriends.isEmpty)
                          const _NoFriendsCard()
                        else
                          ..._filteredFriends.map((friend) {
                            final userId = friend['id'].toString();

                            if (userId == _currentUserId) {
                              return const SizedBox.shrink();
                            }

                            final isSelected = _selectedFriends.any(
                              (item) => item['id'].toString() == userId,
                            );

                            return _FriendTile(
                              name: (friend['name'] ?? '').toString(),
                              email: (friend['email'] ?? '').toString(),
                              isSelected: isSelected,
                              onToggle: () => _toggleFriend(friend),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          20 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: _isLoading ? null : _createGroup,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _selectedFriends.isEmpty
                        ? 'Create group'
                        : 'Create group with '
                              '${_selectedFriends.length} '
                              'friend${_selectedFriends.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GroupHero extends StatelessWidget {
  const _GroupHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF0E7490), Color(0xFF4F46E5)],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.28),
            blurRadius: 38,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.diversity_3_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Start a new group',
            style: TextStyle(
              color: Colors.white,
              fontSize: 29,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends, split expenses and\nkeep everyone settled.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String title;

  const _CardTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: kInk,
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ),
    );
  }
}

class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _PremiumField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: kInk,
        fontSize: 14.5,
        fontWeight: FontWeight.w800,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines == 1
            ? Icon(prefixIcon, color: kPrimary, size: 20)
            : null,
        labelStyle: const TextStyle(
          color: kMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: kMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: kPrimary, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SelectedFriendChip extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _SelectedFriendChip({required this.name, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: kInk,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded, size: 15, color: kMuted),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String name;
  final String email;
  final bool isSelected;
  final VoidCallback onToggle;

  const _FriendTile({
    required this.name,
    required this.email,
    required this.isSelected,
    required this.onToggle,
  });

  Color get _accent {
    final colors = [
      kPrimary,
      const Color(0xFF6366F1),
      const Color(0xFFEA580C),
      const Color(0xFF059669),
      const Color(0xFFDB2777),
    ];

    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withValues(alpha: 0.08) : kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _accent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accent, _accent.withValues(alpha: 0.70)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: kInk,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? _accent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _accent : kBorder,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoFriendsCard extends StatelessWidget {
  const _NoFriendsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_add_disabled_rounded, color: kMuted, size: 30),
          SizedBox(height: 12),
          Text(
            'No friends found',
            style: TextStyle(color: kInk, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 5),
          Text(
            'Add friends first, then create\na shared group.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kMuted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
