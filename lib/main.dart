import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'm38u Downloader',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'm38u Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _url = TextEditingController();
  List<Widget> _logs = [];
  bool _downloading = false;
  double _progress = 0.0;
  bool _isMp3 = true;
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                child: Row(
                  children: [
                    const Text("Url:"),
                    const SizedBox(width: 30),
                    Expanded(child: TextField(
                      controller: _url,
                      onEditingComplete: onDownload,
                      decoration: const InputDecoration(
                        hintText: "https://www.xxx.com/download/xxx.m38u",
                        hintStyle: TextStyle(color: Color(0xffcccccc),
                            fontSize: 14),
                        hoverColor: Colors.black12,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    )),
                    const SizedBox(width: 30),
                    TextButton(
                        onPressed: onDownload,
                        child: const Text("Download", style: TextStyle(color: Colors.white),),
                        style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(Colors.blue),
                            shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)
                                ))
                        )
                    )
                  ],
                ),
                height: 50,
              ),
              SizedBox(
                child: Row(
                  children: [
                    Text("Format: "),
                    SizedBox(width: 20),
                    Expanded(
                      child: ListTile(
                        leading: Icon(_isMp3 ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                        title: Text("mp3"),
                        onTap: ()=> setState(() {
                          _isMp3 = true;
                        })
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        leading: Icon(!_isMp3 ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.blue),
                        title: Text("mp4"),
                          onTap: ()=> setState(() {
                            _isMp3 = false;
                          })
                      )
                    ),
                  ],
                ),
                height: 60,
              ),
              Visibility(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    minHeight: 20,
                    value: _progress,
                  ),
                ),
                visible: _downloading,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                    ),
                    constraints: const BoxConstraints(
                        minHeight: double.infinity,
                        minWidth: double.infinity
                    ),
                    alignment: Alignment.topLeft,
                    padding: const EdgeInsets.all(15),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: _logs,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        )
    );
  }

  Future<void> onDownload() async {
    Dio _dio = Dio();
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler){
        if(err.response == null){
          return handler.resolve(Response(requestOptions: err.requestOptions, statusCode: 500, statusMessage: err.message));
        }
        return handler.resolve(Response(requestOptions: err.requestOptions, statusCode: err.response!.statusCode, statusMessage: err.response!.statusMessage));
      }
    ));
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client){
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    _index = 0;
    _progress = 0;
    _downloading = true;
    _logs.clear();
    addLog("downloading...");
    var res = await _dio.get(_url.text);
    if(res.statusCode != 200){
      addLog("download failed, errCode: ${res.statusCode}, errMsg: ${res.statusMessage}");
      _downloading = false;
      return;
    }
    String _fileName = _url.text.substring(_url.text.lastIndexOf("/") + 1, _url.text.lastIndexOf("?"));
    addLog("get file $_fileName.");
    String _root = _url.text.substring(0, _url.text.lastIndexOf("/") + 1);
    addLog("analyse file...");
    List<String> fileList = [];
    res.data.toString().split("\n").forEach((element) {
      if(element.indexOf("#") != 0 && element.isNotEmpty){
        fileList.add(element);
      }
    });
    addLog("download files...");
    for(var element in fileList){
      var name = element.contains("?") ? element.split("?")[0] : element;
      String url = element.contains("http") ? element : (_root + element);
      await _dio.download(url, "temp/$name");
      setState(() {
        _index++;
        _progress = _index / fileList.length;
      });
    }
    addLog("download files done...");
    _progress = 0;
    fileList.sort();
    addLog("Merge files...");
    File mergeFile = File("temp/${_fileName.split(".")[0]}.${_isMp3 ? "mp3" : "mp4"}");
    if(mergeFile.existsSync()){
      mergeFile.deleteSync();
    }
    mergeFile.createSync();
    List<int> bytes = [];
    for(var i = 0; i < fileList.length; i++){
      String element = fileList[i];
      var name = element.contains("?") ? element.split("?")[0] : element;
      File temp = File("temp/$name");
      bytes.addAll(temp.readAsBytesSync());
      temp.deleteSync();
      setState(() {
        _progress = i / fileList.length;
      });
    }
    addLog("Writing file...");
    mergeFile.writeAsBytesSync(bytes);

    addLog("out file: ${mergeFile.absolute}， size: ${getSize(bytes.length)}");
  }

  String getSize(int size){
    if(size < 1024){
      return "$size Byte";
    }else if(size < 1024 * 1024){
      return "${(size / 1024).toStringAsFixed(2)} KB";
    }
    return "${(size / 1024 / 1024).toStringAsFixed(2)} MB";
  }

  void addLog(String log){
    setState(() {
      _logs.add(Text(log));
    });
  }
}
