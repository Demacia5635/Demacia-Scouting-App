import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  runApp(dataRoom());
}

class dataRoom extends StatefulWidget {
  const dataRoom({super.key});

  @override
  State<dataRoom> createState() => dataRoomState();
}

class dataRoomState extends State<dataRoom> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<dynamic> dataList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    myMethod();
  }

  Future<void> myMethod() async {
    final data = await _supabase.from('data').select();

    setState(() {
      dataList = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Room')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text('${dataList[index]}'));
              },
            ),
    );
  }
}
