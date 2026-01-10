import 'package:firebase_database/firebase_database.dart';

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
}
