import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_todo_list/model/todo_list.dart';
import 'package:flutter/material.dart';

class TrashView extends StatefulWidget {
  const TrashView({super.key});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  late List data;
  bool isPending = false;

  TextEditingController todoListController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Removed Todo Lists'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('removed_todo_list')
            .orderBy('added_time', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          return Center(
            child: !snapshot.hasData
                ? Text("아직 데이터가 없습니다.")
                : ListView(
                    children: snapshot.data!.docs
                        .map((e) => buildItemWidget(e))
                        .toList(),
                  ),
          );
        },
      ),
    );
  }

  Widget buildItemWidget(DocumentSnapshot doc) {
    final todoList = TodoList(
      added_time: doc['added_time'],
      title: doc['title'],
    );
    return Card(
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 50),
          Text(
            '  ${todoList.title}   /   ${todoList.added_time.substring(0, 10)}',
          ),
        ],
      ),
    );
  }
}