import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:camera/camera.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.camera,});
  
  // This widget is the root of your application.
  final CameraDescription camera;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', camera: camera),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.camera});

  final CameraDescription camera;
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
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  List<String> appBarNames = ["Compendium", "Scan", "Profile"];
  int currentPageIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          selectedIndex: currentPageIndex,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book), 
              label: "Compendium"),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt),
              label: "Scan",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined),
              selectedIcon: Icon(Icons.person),
              label: "Profile",
            )
          ],
        ),
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(appBarNames[currentPageIndex]),
        actions: <Widget>[
          IconButton(onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MySettingsPageState()));
          },
          icon: const Icon(Icons.menu))
        ]
      ),
      body: <Widget>[
        Icon(Icons.book_outlined),
        Column(children: [
          FutureBuilder<void>(future: _initializeControllerFuture, builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_controller);
            } else {
              return const Center(child: CircularProgressIndicator(),);
            }
          }),
          Container(padding: const EdgeInsets.only(top: 24), child: FloatingActionButton(onPressed: () async {
            try {
              await _initializeControllerFuture;
              final image = await _controller.takePicture();
              if (!context.mounted) return;
              // throw image into roboflow here, change to compendium, enable card
              
            } catch (e) {
              print(e);
            }
          },
          child: const Icon(Icons.camera_alt),
          ))
        ],),
        Icon(Icons.home_filled),
      ][currentPageIndex], // This trailing comma makes auto-formatting nicer for build methods.
      
    );
  }
}

class MySettingsPageState extends StatelessWidget {
  const MySettingsPageState({super.key});
  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Options"),
        ),
        body: const Center(
          child: Text("Nothing here!")
        )
      );
  }
}

class ScannedItemCard extends StatelessWidget {
  const ScannedItemCard({super.key, requires this.image, })
}