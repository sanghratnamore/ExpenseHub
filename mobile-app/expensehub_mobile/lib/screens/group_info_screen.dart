import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/group.dart';
import '../services/group_service.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';
import 'add_group_members_screen.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);
const Color kExpenseColor = Color(0xFFE11D48);

class GroupInfoScreen extends StatefulWidget {
  final Group group;

  const GroupInfoScreen({super.key, required this.group});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupService _groupService = GroupService();
  final FriendService _friendService = FriendService();

  late Group group;
  String? currentUserId;
  List<Friend> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    group = widget.group;
    _loadData();
  }

  Future<void> _openAddMembersSheet() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddGroupMembersScreen(group: group)),
    );

    if (added == true) {
      await _refreshGroup();
    }
  }

  Future<void> _loadData() async {
    try {
      final userId = await _groupService.authService.getUserId();
      final friendsList = await _friendService.getFriends();

      if (!mounted) return;

      setState(() {
        currentUserId = userId;
        friends = friendsList;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> confirmDeleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete group?'),
          content: const Text(
            'This will permanently delete this group along with its expenses, '
            'splits and settlement history. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deleteGroup();
    }
  }

  Future<void> _refreshGroup() async {
    try {
      final updatedGroup = await _groupService.getGroupById(group.id);

      if (!mounted) return;

      setState(() {
        group = updatedGroup;
      });
    } catch (error) {
      _showError(error.toString());
    }
  }

  bool get isAdmin {
    return group.members.any(
      (member) =>
          member.id == currentUserId && member.role.toUpperCase() == 'ADMIN',
    );
  }

  bool isFriend(String userId) {
    return friends.any((friend) => friend.id == userId);
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kInk,
        content: Text(
          message.replaceAll('Exception: ', ''),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _showMemberPopup(GroupMember member) async {
    final friend = isFriend(member.id);
    final isSelf = member.id == currentUserId;
    final memberIsAdmin = member.role.toUpperCase() == 'ADMIN';
    final canRemove = isAdmin && !isSelf && !memberIsAdmin;

    await showDialog(
      context: context,
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
                CircleAvatar(
                  radius: 34,
                  backgroundColor: kPrimary.withValues(alpha: 0.12),
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  member.name,
                  style: const TextStyle(
                    color: kInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
                const SizedBox(height: 18),
                if (isSelf)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'This is you',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else if (friend)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'You are friends',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        try {
                          await _friendService.sendRequest(member.email);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: kInk,
                              content: Text(
                                'Friend request sent to ${member.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        } catch (error) {
                          _showError(error.toString());
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                      label: const Text(
                        'Send friend request',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                if (canRemove) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);

                        await _removeMember(member);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kExpenseColor,
                        side: const BorderSide(color: kExpenseColor),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(
                        Icons.person_remove_alt_1_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Remove from group',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Close',
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

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await _confirmAction(
      title: 'Remove member?',
      message:
          'Remove ${member.name} from '
          'this group?',
      actionText: 'Remove',
    );

    if (confirmed != true) return;

    try {
      await _groupService.removeGroupMember(
        groupId: group.id,
        memberId: member.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kInk,
          content: Text(
            '${member.name} removed',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

      await _refreshGroup();
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _shareGroup() async {
    final inviteCode = group.inviteCode ?? '';

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Join my ExpenseHub group '
            '"${group.name}" using invite '
            'code: $inviteCode',
      ),
    );
  }

  Future<void> _copyInviteCode() async {
    final inviteCode = group.inviteCode ?? '';

    await Clipboard.setData(ClipboardData(text: inviteCode));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Invite code copied'),
      ),
    );
  }

  Future<void> _leaveGroup() async {
    final confirmed = await _confirmAction(
      title: 'Leave group?',
      message:
          'You will no longer see this '
          'group or its expenses.',
      actionText: 'Leave',
    );

    if (confirmed != true) return;

    try {
      await _groupService.leaveGroup(group.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await _confirmAction(
      title: 'Delete group?',
      message:
          'This will permanently delete '
          'the group, its expenses and '
          'settlements.',
      actionText: 'Delete',
    );

    if (confirmed != true) return;

    try {
      await _groupService.deleteGroup(group.id);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      _showError(error.toString());
    }
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String actionText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel', style: TextStyle(color: kMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: kExpenseColor,
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
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
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFCCFBF1), Color(0xFFE0F2FE)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                group.name.isNotEmpty
                    ? group.name.characters.first.toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                group.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kInk,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: kBorder),
                  ),
                  child: Text(
                    group.description.isEmpty
                        ? 'No description added'
                        : group.description,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        color: kInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    if (isAdmin)
                      GestureDetector(
                        onTap: _openAddMembersSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${group.members.length} members',
                        style: const TextStyle(
                          color: kPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...group.members.map((member) {
                  final memberIsAdmin = member.role.toUpperCase() == 'ADMIN';

                  return GestureDetector(
                    onTap: () => _showMemberPopup(member),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: kPrimary.withValues(alpha: 0.12),
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name.characters.first.toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(
                                    color: kInk,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  member.email,
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (memberIsAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: kMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: kPrimary.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 5),
                                  Text(
                                    (group.inviteCode?.isEmpty ?? true)
                                        ? 'Not available'
                                        : group.inviteCode!,
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _copyInviteCode,
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: kPrimary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _shareGroup,
                          style: FilledButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text(
                            'Share group',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isAdmin)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _deleteGroup,
                      style: FilledButton.styleFrom(
                        backgroundColor: kExpenseColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        'Delete group',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _leaveGroup,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kExpenseColor,
                        side: const BorderSide(color: kExpenseColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Leave group',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
