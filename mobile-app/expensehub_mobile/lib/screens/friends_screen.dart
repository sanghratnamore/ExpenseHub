import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/friend_service.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';
import 'friend_profile_screen.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);
const Color kDanger = Color(0xFFE11D48);

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final FriendService _friendService = FriendService();

  List<Friend> friends = [];
  int requestCount = 0;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _friendService.getFriends(),
        _friendService.getIncomingRequests(),
      ]);

      if (!mounted) return;

      final List<Friend> loadedFriends = results[0] as List<Friend>;
      final requests = results[1] as List;

      setState(() {
        friends = loadedFriends;
        requestCount = requests.length;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _openRequests() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
    );

    if (!mounted) return;
    loadFriends();
  }

  Future<void> _openAddFriend() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFriendScreen()),
    );

    if (!mounted) return;
    loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Friends',
          style: TextStyle(
            color: kInk,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: _openRequests,
                icon: const Icon(Icons.notifications_none_rounded, color: kInk),
                tooltip: 'Friend requests',
              ),
              if (requestCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: kDanger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        requestCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: _openAddFriend,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: kInk),
            tooltip: 'Add friend',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : errorMessage != null
          ? _ErrorView(message: errorMessage!, onRetry: loadFriends)
          : friends.isEmpty
          ? const _EmptyFriends()
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: loadFriends,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: friends.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final friend = friends[index];

                  return _FriendTile(
                    friend: friend,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendProfileScreen(friend: friend),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const _FriendTile({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            _Avatar(name: friend.name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    friend.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : 'U';

    return Container(
      width: 46,
      height: 46,
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
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  const _EmptyFriends();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.group_outlined,
                color: kPrimary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No friends yet',
              style: TextStyle(
                color: kInk,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add friends using their email to split\nexpenses together.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kMuted,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: kMuted, size: 38),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
