import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: "Lista de Tarefas", home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  TextEditingController _tarefa = TextEditingController();
  Map _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();

    setState(() {
      _readData().then((value) => {_toDoList = json.decode(value)});
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });
  }

  void _addToDo() {
    setState(() {
      Map task = new Map();
      if (_tarefa.text.isNotEmpty) {
        task["title"] = _tarefa.text;
        _tarefa.text = "";
        task["ok"] = false;
        _toDoList.add(task);

        _saveData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: (){
           setState(() {
             _toDoList = [];
             _saveData();
           });
          })
        ],
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
              padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: _tarefa,
                    decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  )),
                  RaisedButton(
                    onPressed: () {
                      _addToDo();
                    },
                    child: Text("ADD"),
                    textColor: Colors.white,
                    color: Colors.blueAccent,
                  )
                ],
              )),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem)))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);

            _saveData();

            final snack = SnackBar(
                content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
                action: SnackBarAction(
                    label: "Desfazer",
                    onPressed: () {
                      setState(() {
                        _toDoList.insert(_lastRemovedPos, _lastRemoved);
                        _saveData();
                      });
                    }),
                duration: Duration(seconds: 2));
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);

          });
        },
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        direction: DismissDirection.startToEnd,
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        child: CheckboxListTile(
          onChanged: (value) {
            setState(() {
              _toDoList[index]["ok"] = value;
              _saveData();
            });
          },
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"] ?? false,
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
          ),
        ));
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
