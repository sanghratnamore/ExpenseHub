import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../models/group.dart';
import '../services/friend_service.dart';
import '../services/group_service.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class AddGroupMembersScreen extends StatefulWidget {
  final Group group;

  const AddGroupMembersScreen({super.key, required this.group});

  @override
  State<AddGroupMembersScreen> createState() => _AddGroupMembersScreenState();
}

class _AddGroupMembersScreenState extends State<AddGroupMembersScreen> {
  final GroupService _groupService = GroupService();
  final FriendService _friendService = FriendService();

  final TextEditingController emailController = TextEditingController();

  List<Friend> friends = [];
  final Set<String> selectedIds = {};

  Map<String, dynamic>? searchedUser;

  bool isLoading = true;
  bool isSearching = false;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadFriends() async {
    setState(() => isLoading = true);

    try {
      final loadedFriends = await _friendService.getFriends();

      if (!mounted) return;

      setState(() {
        friends = loadedFriends;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  bool isAlreadyMember(String userId) {
    return widget.group.members.any((member) => member.id == userId);
  }

  Future<void> searchUser() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter an email address');
      return;
    }

    setState(() => isSearching = true);

    try {
      final user = await _groupService.searchUserByEmail(email);

      if (!mounted) return;

      setState(() {
        searchedUser = user;
        isSearching = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        searchedUser = null;
        isSearching = false;
      });

      _showMessage(error.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> addSelectedMembers() async {
    if (selectedIds.isEmpty) {
      _showMessage('Select at least one member');
      return;
    }

    setState(() => isAdding = true);

    try {
      await _groupService.addMembers(
        groupId: widget.group.id,
        memberIds: selectedIds.toList(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() => isAdding = false);

      _showMessage(error.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add members',
          style: TextStyle(
            color: kInk,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      _SearchCard(
                        emailController: emailController,
                        isSearching: isSearching,
                        searchedUser: searchedUser,
                        isSelected:
                            searchedUser != null &&
                            selectedIds.contains(
                              searchedUser!['id'].toString(),
                            ),
                        alreadyMember:
                            searchedUser != null &&
                            isAlreadyMember(searchedUser!['id'].toString()),
                        onSearch: searchUser,
                        onChanged: (value) {
                          final id = searchedUser!['id'].toString();

                          setState(() {
                            if (value == true) {
                              selectedIds.add(id);
                            } else {
                              selectedIds.remove(id);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Your friends',
                        style: TextStyle(
                          color: kInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (friends.isEmpty)
                        _EmptyFriends()
                      else
                        ...friends.map((friend) {
                          final alreadyMember = isAlreadyMember(friend.id);

                          return _FriendSelectTile(
                            friend: friend,
                            alreadyMember: alreadyMember,
                            isSelected: selectedIds.contains(friend.id),
                            onChanged: alreadyMember
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedIds.add(friend.id);
                                      } else {
                                        selectedIds.remove(friend.id);
                                      }
                                    });
                                  },
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: kBorder)),
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isAdding || selectedIds.isEmpty
                ? null
                : addSelectedMembers,
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: isAdding
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    selectedIds.isEmpty
                        ? 'Select members'
                        : 'Add ${selectedIds.length} member${selectedIds.length == 1 ? '' : 's'}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SearchCard extends StatelessWidget {
  final TextEditingController emailController;
  final bool isSearching;
  final Map<String, dynamic>? searchedUser;
  final bool isSelected;
  final bool alreadyMember;
  final VoidCallback onSearch;
  final ValueChanged<bool?> onChanged;

  const _SearchCard({
    required this.emailController,
    required this.isSearching,
    required this.searchedUser,
    required this.isSelected,
    required this.alreadyMember,
    required this.onSearch,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search by email',
            style: TextStyle(
              color: kInk,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: kInk, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'user@email.com',
              hintStyle: const TextStyle(
                color: kMuted,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: kMuted,
                size: 20,
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isSearching ? null : onSearch,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: kPrimary,
                      ),
                    )
                  : const Text(
                      'Search user',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
            ),
          ),
          if (searchedUser != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          searchedUser!['name'] ?? '',
                          style: const TextStyle(
                            color: kInk,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          searchedUser!['email'] ?? '',
                          style: const TextStyle(
                            color: kMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: alreadyMember ? null : onChanged,
                  ),
                ],
              ),
            ),
            if (alreadyMember)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'This user is already in the group',
                  style: TextStyle(
                    color: kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FriendSelectTile extends StatelessWidget {
  final Friend friend;
  final bool alreadyMember;
  final bool isSelected;
  final ValueChanged<bool?>? onChanged;

  const _FriendSelectTile({
    required this.friend,
    required this.alreadyMember,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? kPrimary : kBorder,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimary, kPrimarySoft],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              friend.name.isNotEmpty
                  ? friend.name.characters.first.toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
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
                  friend.name,
                  style: const TextStyle(
                    color: kInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alreadyMember ? 'Already in group' : friend.email,
                  style: const TextStyle(
                    color: kMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isSelected,
            onChanged: onChanged,
            activeColor: kPrimary,
          ),
        ],
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: const Text(
        'No friends yet.\nSearch by email to add someone directly.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: kMuted,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}
