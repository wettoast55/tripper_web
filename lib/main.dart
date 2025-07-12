//true imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

// after your imports
import 'widgets/chat_view.dart';

//init app, start
void main() {
  runApp(const MyApp());
}

// init browser app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      //title of tab
      title: 'Demo - TripCliques',
      theme: ThemeData(

        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(136, 79, 97, 255)),
      ),

      //set title of appbar in homepage
      home: const MyHomePage(title: 'TripCliques Home Page'),
    );
  }
}

//This widget is the home page of your application. Fields in a Widget subclass are
  // always marked "final".
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// this class extends homepage
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; //temp counter
  int _selectedIndex = 0; //tracks tab selected

  // function to tell framework something changed and needs to update/rerun
  void _incrementCounter() {
    setState(() {
      _counter++;
      print(_counter);
    });
  }

 // This method is rerun every time setState is called, for instance as done   
 // by the _incrementCounter method above.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        //color of appbar
        backgroundColor: const Color.fromARGB(255, 241, 182, 5), //Theme.of(context).colorScheme.inversePrimary,
        
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),

      ////////////////
        // Center is a layout widget. It takes a single child and positions it in the 
      //middle of the parent.
      body: Column(
        mainAxisAlignment:MainAxisAlignment.center, 
        children: [
          
          Text("item 1"),
          Text("item 2"),
          Text("item 3"),
          Text('$_counter'),
          //ChatView(), //cannot be in lcolumn or row

        ],
      ),

      ////////////
            

      // //////////////////////////////////
      // // Center is a layout widget. It takes a single child and positions it in the 
      // //middle of the parent.
      // body: Center(

      //   // Column is also a layout widget. It takes a list of children and
      //     // arranges them vertically. By default, it sizes itself to fit its
      //     // children horizontally, and tries to be as tall as its parent.
      //   child: Column(
      //     // action in the IDE, or press "p" in the console), to see the wireframe for each widget.
          
      //     // center children vertically (from top down, start-center-end)
      //     mainAxisAlignment: MainAxisAlignment.center,

      //     // create widget with text and counter
      //     children: <Widget>[
      //       const Text('You have pushed the button this many times:'),
      //       Text(
      //         '$_counter',
      //         style: Theme.of(context).textTheme.headlineMedium,
      //       ),
      //     ],
      //   ),
      // ),

      ///////////////////////////// 
    

      // button to increment count
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), 

    );
  }
}

