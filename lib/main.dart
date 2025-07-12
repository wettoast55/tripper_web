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

  // Define pages for each tab
  List<Widget> get _pages => [
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("item 1"),
        Text("item 2"),
        Text("item 3"),
        Text('$_counter'),
      ],
    ),
    const ChatView(), // chat widget!
  ];

  // Function to handle tab changes
  @override
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

      body:Center(child: _pages[_selectedIndex]), // Display the selected page

      // bottom navigation bar with two tabs
      // The BottomNavigationBar widget is used to create a bottom navigation bar.
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabTapped, // Handle tab changes
      ),

      //function for floating action button
      // This button will only appear on the first tab (Home)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                print("Home tab button tapped");
                print(_counter);
                _incrementCounter(); // Increment the counter when the FAB is pressed
              },
              tooltip: 'Action',
              child: const Icon(Icons.add),
            )
          : null,
    );

    
      ////////////////
      //   // Center is a layout widget. It takes a single child and positions it in the 
      // //middle of the parent.
      // body: Column(
      //   mainAxisAlignment:MainAxisAlignment.center, 
      //   children: [
          
      //     Text("item 1"),
      //     Text("item 2"),
      //     Text("item 3"),
      //     Text('$_counter'),
      //     //ChatView(), //cannot be in lcolumn or row

      //   ],
      // ),

      ////////////
            

      ///////////////////////////// 
    

      // // button to increment count
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), 

    
  }
}

