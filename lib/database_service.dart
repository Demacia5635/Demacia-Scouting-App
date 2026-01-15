import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> create({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final DatabaseReference ref = _dbRef.child(path);
    await ref.set(data);
  }

  Future<DataSnapshot?> read({required String path}) async {
    final DatabaseReference ref = _dbRef.child(path);
    final DataSnapshot snapshot = await ref.get();
    return snapshot.exists ? snapshot : null;
  }

  Future<void> update({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final DatabaseReference ref = _dbRef.child(path);
    await ref.update(data);
  }

  Future<void> delete({required String path}) async {
    final DatabaseReference ref = _dbRef.child(path);
    await ref.remove();
  }

  static Future<void> signUp({
    required String email,
    required String password,
    required String userName,
  }) async {
    final res = await supabase.auth.signUp(email: email, password: password);

    if (res.user == null) {
      throw Exception('Signup failed');
    }
    createPlayerProfile(userName);
    print('=== user signed up ===');
  }

  static Future<void> signInWithPW({
    required String email,
    required String password,
  }) async {
    final res = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (res.user == null) {
      throw Exception('SignIn failed');
    }
    print('=== User Signed In succesfuly ===');
  }

  static Future<void> createPlayerProfile(String username) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Not authenticated');
    }

    // await supabase.from('Player').insert({
    //   'id': user.id,
    //   'userName': username,
    //   'rank': 400,
    //   'games_played': 0,
    //   'games_won': 0,
    // });
  }

  static Future<void> updatePlayerProfile(String uuid) async {}

  ///**Retrieves all the data from the table in real time**
  static Stream getAllRealTime() {
    /**TODO: change to real table and real primary key */
    return supabase.from("").stream(primaryKey: ["primary_key"]);
  }
}
