import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_todo_list/model/todo_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'trash_view.dart';

class TableView extends StatefulWidget {
  const TableView({super.key});

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  late List data;
  bool isPending = false;

  TextEditingController todoListController = TextEditingController();

  XFile? imageFile;
  final ImagePicker picker = ImagePicker();
  File? imgFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo Lists'),
        actions: [
          IconButton(
            onPressed: () => Get.to(TrashView()),
            icon: Icon(Icons.delete),
          ),
          IconButton(
            onPressed: () {
              todoListController.text = '';
              imageFile = null;
              Get.defaultDialog(
                title: 'Todo List',
                content: StatefulBuilder(
                  builder: (context, dialogSetState) {
                    return Column(
                      children: [
                        TextField(
                          controller: todoListController,
                          decoration: InputDecoration(labelText: '추가할 내용'),
                          readOnly: isPending,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final XFile? selectedImage = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (selectedImage != null) {
                              dialogSetState(() {
                                imageFile = selectedImage;
                                imgFile = File(selectedImage.path);
                              });
                              setState(() {});
                            }
                          },
                          child: Text('Gallery'),
                        ),
                        Container(
                          width: Get.width,
                          height: 200,
                          color: Colors.grey,
                          child: Center(
                            child: imageFile == null
                                ? Text('Image is not selected')
                                : Image.file(File(imageFile!.path)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                textConfirm: '추가하기',
                onConfirm: () => attemptToInsert(),
              );
            },
            icon: Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('todo_list')
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
      image: doc['image'],
    );
    return Slidable(
      startActionPane: ActionPane(
        motion: ScrollMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (context) => deleteDataFromDB(
              doc.id,
              todoList.added_time,
              todoList.title,
              todoList.image!.isEmpty,
            ),
            backgroundColor: Color(0xFFFE4A49),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        child: Row(
          children: [
            todoList.image!.isEmpty
                ? Icon(Icons.calendar_month, size: 50)
                : Image.network(
                    todoList.image!,
                    width: 50,
                    height: 50,
                    fit: .fill,
                  ),
            Text(
              '  ${todoList.title}   /   ${todoList.added_time.substring(0, 10)}',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getImageFromGallery() async {
    final XFile? selectedImage = await picker.pickImage(
      source: ImageSource.gallery,
    );
    imageFile = selectedImage;
    imgFile = File(selectedImage!.path);
    setState(() {});
  }

  Future<String> preparingImage(String dateTime) async {
    final firebaseStorage = FirebaseStorage.instance
        .ref()
        .child('images')
        .child('$dateTime.png');
    await firebaseStorage.putFile(imgFile!);
    String downloadURL = await firebaseStorage.getDownloadURL();
    return downloadURL;
  }

  Future<void> attemptToInsert() async {
    isPending = true;
    setState(() {});
    String insertedTime = DateTime.now().toString();
    String image = imageFile != null ? await preparingImage(insertedTime) : '';

    await FirebaseFirestore.instance.collection('todo_list').add({
      'added_time': insertedTime,
      'image': image,
      'title': todoListController.text,
    });
    isPending = false;
    todoListController.text = '';
    imageFile = null;
    setState(() {});
    showSucceedDialog();
  }

  void showSucceedDialog() {
    Get.defaultDialog(
      title: '입력 결과',
      middleText: '입력이 완료되었습니다.',
      barrierDismissible: false,
      textConfirm: '확인',
      onConfirm: () {
        Get.back();
        Get.back();
      },
    );
  }

  void errorSnackBar() {
    Get.snackbar(
      '문제 발생',
      '입력 중 문제가 발생 했습니다.',
      snackPosition: .TOP,
      duration: const Duration(seconds: 2),
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
  }

  Future<void> deleteDataFromDB(
    String id,
    String added_date,
    String title,
    bool hasNoImage,
  ) async {
    if (!hasNoImage) {
      final firebaseStorage = FirebaseStorage.instance
          .ref()
          .child('images')
          .child('$added_date.png');
      await firebaseStorage.delete();
    }

    await FirebaseFirestore.instance.collection('removed_todo_list').add({
      'added_time': added_date,
      'title': title,
    });
    await FirebaseFirestore.instance.collection('todo_list').doc(id).delete();

    showDeleteSucceedDialog();
  }

  void showDeleteSucceedDialog() {
    Get.defaultDialog(
      title: '삭제 결과',
      middleText: '삭제가 완료되었습니다.',
      barrierDismissible: false,
      textConfirm: '확인',
      onConfirm: () {
        Get.back();
      },
    );
  }

  void errorDeleteSnackBar() {
    Get.snackbar(
      '문제 발생',
      '삭제 중 문제가 발생 했습니다.',
      snackPosition: .TOP,
      duration: const Duration(seconds: 2),
      colorText: Colors.white,
      backgroundColor: Colors.red,
    );
  }
}
