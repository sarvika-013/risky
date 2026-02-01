import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final supabase = Supabase.instance.client;
  final search = TextEditingController();

  int refresh = 0;

  String get myId => supabase.auth.currentUser!.id;

  // Fetch users by ids
  Future<Map<String, Map<String, dynamic>>> _getUsers(List<String> ids) async {
    if (ids.isEmpty) return {};

    final res = await supabase
        .from('User')
        .select('user_id, username, avatar_url')
        .inFilter('user_id', ids);

    final map = <String, Map<String, dynamic>>{};
    for (final u in res) {
      map[u['user_id']] = Map<String, dynamic>.from(u);
    }
    return map;
  }

  // Pending requests
  Future<List<Map<String, dynamic>>> pending() async {
    final rows = await supabase
        .from('friendship')
        .select('friendship_id, sender_id')
        .eq('receiver_id', myId)
        .eq('status', 'pending');

    final senderIds =
        rows.map<String>((e) => e['sender_id'] as String).toList();

    final users = await _getUsers(senderIds);

    return rows.map<Map<String, dynamic>>((e) {
      return {
        'friendship_id': e['friendship_id'],
        'user': users[e['sender_id']],
      };
    }).toList();
  }

  // Accepted friends
  Future<List<Map<String, dynamic>>> friends() async {
    final rows = await supabase
        .from('friendship')
        .select('friendship_id, sender_id, receiver_id')
        .eq('status', 'accepted')
        .or('sender_id.eq.$myId,receiver_id.eq.$myId');

    final ids = <String>{};

    for (final r in rows) {
      final sid = r['sender_id'];
      final rid = r['receiver_id'];
      ids.add(sid == myId ? rid : sid);
    }

    final users = await _getUsers(ids.toList());

    return rows.map<Map<String, dynamic>>((e) {
      final friendId = e['sender_id'] == myId ? e['receiver_id'] : e['sender_id'];
      return {
        'friendship_id': e['friendship_id'],
        'user': users[friendId],
      };
    }).toList();
  }

  Widget avatar(String? url) {
    if (url == null || url.isEmpty) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    if (url.startsWith('http')) {
      return CircleAvatar(backgroundImage: NetworkImage(url));
    }
    return CircleAvatar(backgroundImage: AssetImage(url));
  }

  Future<void> sendRequest() async {
    final name = search.text.trim();
    if (name.isEmpty) return;

    final user = await supabase
        .from('User')
        .select('user_id')
        .eq('username', name)
        .maybeSingle();

    if (user == null) return;

    final other = user['user_id'];

    if (other == myId) return;

    await supabase.from('friendship').insert({
      'sender_id': myId,
      'receiver_id': other,
      'status': 'pending',
    });

    search.clear();
    setState(() => refresh++);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: search,
                    decoration: const InputDecoration(
                        hintText: 'Search by username'),
                  ),
                ),
                IconButton(
                    onPressed: sendRequest,
                    icon: const Icon(Icons.person_add))
              ],
            ),
          ),

          // Pending
          FutureBuilder(
            key: ValueKey(refresh),
            future: pending(),
            builder: (_, s) {
              if (!s.hasData || s.data!.isEmpty) return const SizedBox();

              return Column(
                children: s.data!.map<Widget>((e) {
                  final u = e['user'];
                  return ListTile(
                    leading: avatar(u?['avatar_url']),
                    title: Text(u?['username'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await supabase
                                .from('friendship')
                                .update({'status': 'accepted'})
                                .eq('friendship_id', e['friendship_id']);
                            setState(() => refresh++);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () async {
                            await supabase
                                .from('friendship')
                                .delete()
                                .eq('friendship_id', e['friendship_id']);
                            setState(() => refresh++);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Friends
          Expanded(
            child: FutureBuilder(
              key: ValueKey(refresh + 1),
              future: friends(),
              builder: (_, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (s.data!.isEmpty) {
                  return const Center(child: Text("No friends yet"));
                }

                return ListView(
                  children: s.data!.map<Widget>((e) {
                    final u = e['user'];
                    return ListTile(
                      leading: avatar(u?['avatar_url']),
                      title: Text(u?['username'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove,
                            color: Colors.red),
                        onPressed: () async {
                          await supabase
                              .from('friendship')
                              .delete()
                              .eq('friendship_id', e['friendship_id']);
                          setState(() => refresh++);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
