import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jnqbzzttvrjeudzbonix.supabase.co',
    anonKey: 'sb_publishable_W3CWjvB06rZEkSHJqccKEw_x5toioxg',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DataRoom(),
    );
  }
}

class DataRoom extends StatefulWidget {
  const DataRoom({super.key});

  @override
  State<DataRoom> createState() => _DataRoomState();
}

class _DataRoomState extends State<DataRoom> {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAllForms() async {
    final res = await _supabase.from('forms').select();
    return List<Map<String, dynamic>>.from(res);
  }

  List<dynamic> dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    myMethod();
  }

  Future<void> myMethod() async {
    try {
      final data = await _supabase.from('data').select();

      setState(() {
        dataList = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Room', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(
                    label: Text('From', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text(
                      'Created At',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text('Key', style: TextStyle(color: Colors.white)),
                  ),
                  DataColumn(
                    label: Text(
                      'Is Special',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                rows: dataList.map((row) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          row['from'].toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          row['created_at'].toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          row['Key'].toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          row['isSpecialForm'].toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
    );
  }
}
