import 'package:flutter/material.dart';
import '../models/friend.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kPrimarySoft = Color(0xFF14B8A6);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);

class FriendProfileScreen extends StatelessWidget {
  final Friend friend;

  const FriendProfileScreen({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final initials = friend.name.trim().isNotEmpty
        ? friend.name.trim().characters.first.toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Friend profile',
          style: TextStyle(
            color: kInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
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
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    friend.name,
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friend.email,
                    style: const TextStyle(
                      color: kMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Friends',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: kBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.group_outlined, color: kMuted),
                  SizedBox(height: 10),
                  Text(
                    'Shared groups will appear here',
                    style: TextStyle(
                      color: kMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}