import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:easy_loading_button/easy_loading_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learn Lens AI',
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
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

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

  List<String> appBarNames = ["Compendium", "Scan", "Profile"];
  Map<String, String> results = {};
  Map<String, Image> pictureResults = {};
  int currentPageIndex = 0;
  bool signedIn = false;
  String givenName = "";
  String logPfp = "";

  pickImage() async {
    final imagePicker = ImagePicker();
    final input = await imagePicker.pickImage(source: ImageSource.camera);
    if (input == null) {
      return;
    }
    File image = File(input.path);
    // do the flask stuff with image here, plus save into results
    final request = MultipartRequest("POST", Uri.parse("http://10.37.100.14:3000/infer"));
    final headers = {"Content-Type": "multipart/form-data"};

    request.files.add(MultipartFile('image', image.readAsBytes().asStream(), image.lengthSync(), filename: "upload.jpg", contentType: MediaType('image', "jpg")));
    request.headers.addAll(headers);
    final response = await request.send();
    Response extract = await Response.fromStream(response);
    final jsoned = jsonDecode(extract.body);
    String guess = jsoned["predictions"][0]["class"];
    final promptRequest = await post(Uri.parse("http://10.37.100.14:3000/explain"), headers: <String, String> {'Content-Type': 'application/json; charset=UTF-8',
    }, body: jsonEncode(<String, String> {
      'request': guess
    }));
    final actualPrompt = promptRequest.body;
    results[guess] = actualPrompt;
    pictureResults[guess] = Image.file(image, width: 156, height: 201);
    Navigator.push(context, MaterialPageRoute(builder: (context) =>  ScannedItemState(image: Image.file(image, width: 156, height: 201), result: guess, response: actualPrompt,)));
  }

  @override
  Widget build(BuildContext context) {
    Image pfpPath = signedIn ? Image.network(logPfp, width: 156, height: 201,) : Image.asset("images/app-image.png", width: 156, height: 201,);
    double currentXP = (300 * results.length) / 4500;
    
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
        Column(
          children: [
            Offstage(offstage: !results.isEmpty, child: Center(child: Text("Aw, no scans!"), )),
            Row(children: [
              Offstage(offstage: !results.containsKey("Cube"), child: ScannedItemCard(image: results.containsKey("Cube") ? pictureResults["Cube"] : Image.asset("images/app-image.png", width: 156, height: 201), result: "Cube", response: results.containsKey("Cube") ? results["Cube"] : "no",)),
              Offstage(offstage: !results.containsKey("Cylinder"), child: ScannedItemCard(image: results.containsKey("Cylinder") ? pictureResults["Cylinder"] : Image.asset("images/app-image.png", width: 156, height: 201), result: "Cylinder", response: results.containsKey("Cylinder") ? results["Cylinder"] : "no"),),
            ],), 
            Offstage(offstage: !results.containsKey("Pyramid"), child: ScannedItemCard(image: results.containsKey("Pyramid") ? pictureResults["Pyramid"] : Image.asset("images/app-image.png", width: 156, height: 201), result: "Pyramid", response: results.containsKey("Pyramid") ? results["Pyramid"] : "no"))
            ],
        ),
        Center(child: EasyButton(idleStateWidget: Icon(Icons.camera_alt), loadingStateWidget: CircularProgressIndicator(), useWidthAnimation: false, buttonColor: Theme.of(context).colorScheme.inversePrimary, borderRadius: 10, onPressed: () async => {
          await pickImage()
          
        }, width: 50, useEqualLoadingStateWidgetDimension: true, contentGap: 10,)),
        Column(
          children: [
            pfpPath,
            Text(!signedIn ? "Welcome Guest!" : "Welcome child of $givenName!",),
            Offstage(offstage: !signedIn, child: LinearProgressIndicator(value: currentXP)),
            Offstage(offstage: !signedIn, child: Text("$currentXP/4500")),
            Offstage(offstage: !signedIn, child: Text("Friends",)),
            Offstage(offstage: !signedIn, child: const Text( "What did you expect? There's no one else here."))
          ],
        ),
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
        body: Center(
          child: Column(
            children: [
              TextButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NoSettings()));
              }, child: const Text("Account Data")),
              TextButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NoSettings()));
              }, child: const Text("Support")),
              FloatingActionButton(onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const NoSettings()));
              }, child: const Text("Login"),)
            ],
          )
        )
      );
  }
}

class NoSettings extends StatelessWidget {
  const NoSettings({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Nothing!"),
      ),
      body: const Center(
        child: Text("Yea, nothing."),
      ),
    );
  }
}

class ScannedItemState extends StatelessWidget {
  const ScannedItemState({super.key, required this.image, this.result="nope", this.response="nope"});

  final image;
  final result;
  final response;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Text(result == "nope" ? response : result,),
          image,
          //throw result into prompt here
          Text(response)
        ],
      )
    );
  }
}

class ScannedItemCard extends StatelessWidget {
  const ScannedItemCard({super.key, required this.image, this.result="nope", this.response="nope"});

  final image;
  final result;
  final response;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(result),
          image,
          TextButton(onPressed: () => {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ScannedItemState(image: image, result: result, response: response,)))
          }, child: Text("Expand"))
        ],
      )
    );
  }
}