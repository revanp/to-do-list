import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:todo_list/screens/login.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  List<dynamic> todoList = [];
  String userId = "";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await getUser();
    fetchData();
  }

  Future<void> getUser() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    String? user = localStorage.getString('user');

    setState(() {
      userId = jsonDecode(user ?? '{}')['id'];
    });
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users/' +
            userId +
            '/todo_list'));

    if (response.statusCode == 200) {
      setState(() {
        print(response.body);
        todoList = jsonDecode(response.body);
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> createTask(String title, String description) async {
    final response = await http.post(
      Uri.parse('https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users/' +
          userId +
          '/todo_list'),
      body: {
        'name': title,
        'description': description,
        'status': 'false',
        'userId': '1'
      },
    );

    if (response.statusCode == 200) {
      fetchData();
    } else {
      print('Failed to create task. Status code: ${response.statusCode}');
    }
  }

  Future<void> updateTask(String id, String title, String description) async {
    final response = await http.put(
      Uri.parse('https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users/' +
          userId +
          '/todo_list/' +
          id),
      body: {'name': title, 'description': description, 'userId': '1'},
    );

    if (response.statusCode == 200) {
      fetchData();
    } else {
      print('Failed to update task. Status code: ${response.statusCode}');
    }
  }

  Future<void> changeStatus(String id, String status) async {
    final response = await http.put(
      Uri.parse('https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users/' +
          userId +
          '/todo_list/' +
          id),
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      fetchData();
    } else {
      print('Failed to update task. Status code: ${response.statusCode}');
    }
  }

  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('https://65e1e6e8a8583365b31795ff.mockapi.io/api/v1/users/' +
          userId +
          '/todo_list/' +
          id),
    );

    if (response.statusCode == 200) {
      fetchData();
    } else {
      print('Failed to delete task. Status code: ${response.statusCode}');
    }
  }

  Future<void> handleTask(String? id, String title, String description) async {
    if (id == null) {
      await createTask(title, description);
    } else {
      await updateTask(id, title, description);
    }
  }

  void _logout() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();

    localStorage.remove('user');

    Navigator.of(context).pushAndRemoveUntil(
        new MaterialPageRoute(builder: (context) => LoginForm()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Todo List"),
            IconButton(
                onPressed: () {
                  _logout();
                },
                icon: Icon(Icons.logout))
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(todoList[index]['name']),
                  subtitle: Text(todoList[index]['description']),
                  leading: Checkbox(
                    value: todoList[index]['status'] == 'true',
                    onChanged: (bool? value) {
                      changeStatus(
                          todoList[index]['id'],
                          todoList[index]['status'] == 'true'
                              ? 'false'
                              : 'true');
                    },
                  ),
                  onTap: () {
                    showEditDialog(
                        context,
                        todoList[index]['id'],
                        todoList[index]['name'],
                        todoList[index]['description']);
                  },
                  trailing: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      deleteTask(todoList[index]['id']);
                    },
                  ),
                );
              },
            )),
            ElevatedButton(
              onPressed: () {
                showTaskDialog(context);
              },
              child: Text("Add Task"),
            ),
            SizedBox(
              height: 50,
            )
          ],
        ),
      ),
    );
  }

  Future<void> showTaskDialog(BuildContext context) async {
    String title = '';
    String description = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(
                  labelText: "Title",
                ),
              ),
              TextField(
                onChanged: (value) {
                  description = value;
                },
                decoration: InputDecoration(
                  labelText: "Description",
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                handleTask(null, title, description);
                Navigator.of(context).pop();
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> showEditDialog(
      BuildContext context, String id, String title, String description) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: InputDecoration(
                  labelText: "Title",
                ),
                controller: TextEditingController(text: title),
              ),
              TextField(
                onChanged: (value) {
                  description = value;
                },
                decoration: InputDecoration(
                  labelText: "Description",
                ),
                controller: TextEditingController(text: description),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                handleTask(id, title, description);
                Navigator.of(context).pop();
              },
              child: Text("Edit"),
            ),
          ],
        );
      },
    );
  }
}
