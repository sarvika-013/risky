import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarList extends StatefulWidget {
  const AvatarList({super.key});

  @override
  State<AvatarList> createState() => _AvatarListState();
}

class _AvatarListState extends State<AvatarList> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final currentUserId = supabase.auth.currentUser!.id;

    try {
      // 1. Fetch accepted friendships
      final friendships = await supabase
          .from('friendship')
          .select()
          .eq('status', 'accepted')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId');

      if (friendships.isEmpty) {
        setState(() {
          friends = [];
          loading = false;
        });
        return;
      }

      // 2. Extract friend ids
      final friendIds = friendships.map<String>((f) {
        return f['sender_id'] == currentUserId
            ? f['receiver_id']
            : f['sender_id'];
      }).toList();

      // 3. Fetch user profiles
      final users = await supabase
          .from('User')
          .select('user_id, username, avatar_url')
          .inFilter('user_id', friendIds);

      setState(() {
        friends = List<Map<String, dynamic>>.from(users);
        loading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (friends.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text(
            "No friends yet",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];

          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: friend['avatar_url'] != null
                      ? NetworkImage(friend['avatar_url'])
                      : null,
                  child: friend['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    friend['username'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
