import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final supabase = Supabase.instance.client;
  final usernameController = TextEditingController();

  bool loading = true;
  bool saving = false;

  String? currentAvatar;
  String? originalUsername;
  String? originalAvatar;

  static const avatars = [
    'assets/images/b1.jpg',
    'assets/images/b2.jpg',
    'assets/images/b3.jpg',
    'assets/images/b4.jpg',
    'assets/images/b5.jpg',
    'assets/images/b6.jpg',
    'assets/images/g1.jpg',
    'assets/images/g2.jpg',
    'assets/images/g3.jpg',
    'assets/images/g4.jpg',
    'assets/images/g5.jpg',
    'assets/images/g6.jpg',
  ];

  String get myId => supabase.auth.currentUser!.id;

  bool get hasChanges =>
      usernameController.text.trim() != (originalUsername ?? '') ||
      currentAvatar != originalAvatar;

  @override
  void initState() {
    super.initState();
    _loadCachedProfile();
    _loadProfileFromDb();
    usernameController.addListener(() => setState(() {}));
  }

  // Instant UI from cache
  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    usernameController.text = prefs.getString('username_$myId') ?? '';
    currentAvatar = prefs.getString('avatar_$myId');
    setState(() {});
  }

  // Real source of truth = Supabase
  Future<void> _loadProfileFromDb() async {
  try {
    final data = await supabase
        .from('User')
        .select('username, avatar_url')
        .eq('user_id', myId)
        .maybeSingle();

    if (data == null) {
      // Trigger hasn’t created row yet — retry once after short delay
      await Future.delayed(const Duration(milliseconds: 500));

      final retry = await supabase
          .from('User')
          .select('username, avatar_url')
          .eq('user_id', myId)
          .single();

      originalUsername = retry['username'];
      originalAvatar = retry['avatar_url'];
    } else {
      originalUsername = data['username'];
      originalAvatar = data['avatar_url'];
    }

    usernameController.text = originalUsername ?? '';
    currentAvatar = originalAvatar;

    await _cacheProfile();
  } finally {
    loading = false;
    if (mounted) setState(() {});
  }
}



  Future<void> _cacheProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username_$myId', usernameController.text.trim());
    if (currentAvatar != null) {
      await prefs.setString('avatar_$myId', currentAvatar!);
    }
  }

  Future<void> saveProfile() async {
    if (!hasChanges) return;

    final name = usernameController.text.trim();
    if (name.isEmpty) return;

    setState(() => saving = true);

    try {
      await supabase.from('User').update({
        'username': name,
        'avatar_url': currentAvatar,
      }).eq('user_id', myId);

      originalUsername = name;
      originalAvatar = currentAvatar;

      await _cacheProfile();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Profile saved")));
      }
    } finally {
      setState(() => saving = false);
    }
  }

  void selectAvatar(String path) {
    currentAvatar = path;
    setState(() {});
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  currentAvatar != null ? AssetImage(currentAvatar!) : null,
              child: currentAvatar == null
                  ? const Icon(Icons.person, size: 48)
                  : null,
            ),

            const SizedBox(height: 10),
            const Text("Username"),

            TextField(controller: usernameController),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: hasChanges && !saving ? saveProfile : null,
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Save"),
            ),

            const SizedBox(height: 20),
            const Text("Choose Avatar"),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3),
                itemCount: avatars.length,
                itemBuilder: (_, i) {
                  final selected = avatars[i] == currentAvatar;
                  return GestureDetector(
                    onTap: () => selectAvatar(avatars[i]),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: selected ? Colors.blue : Colors.transparent,
                            width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(avatars[i]),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton.icon(
              onPressed: logout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
