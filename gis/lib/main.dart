import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gis/add_resident.dart';
import 'package:gis/backend.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mbeya',
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
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

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
  bool downloadReady = false;
  FilePickerResult file;
  String feedback = 'Press the button below '
      'to upload an excel file for processing';
  bool loading = false;
  List<Map<String, dynamic>> ids = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SizedBox.shrink(),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                const PopupMenuItem<int>(child: Text("Register"), value: 0)
              ];
            },
            onSelected: (value) {
              switch (value) {
                case 0:
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AddResident(),
                      fullscreenDialog: true));
                  break;
                  return;
                default:
                  return;
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (loading == false)
                ? Text(
                    feedback,
                    textAlign: TextAlign.center,
                  )
                : const CircularProgressIndicator(),
            const SizedBox(height: 5),
            //Text(ids.toString())
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!downloadReady) {
            await FilePicker.platform.clearTemporaryFiles();

            try {
              file = await FilePicker.platform.pickFiles(
                  allowedExtensions: ["xlsx", "xls", "xlsm"],
                  withData: true,
                  type: FileType.custom);
            } on Exception catch (e) {
              // TODO
              file = null;

              return;
            }
            setState(() {
              loading = true;
            });
            if (file == null) {
              setState(() {
                loading = false;
              });
              return;
            }
            List<String> dummy = await readExcelFile(file.paths.first);

            List<UserData> allData = await readUserDatabase();
            List<UserData> data = [];
            for (int n = 0; n < dummy.length; ++n) {
              if (dummy[n] == null) {
                data.add(UserData());
                continue;
              } else {
                if (dummy[n].isEmpty) {
                  data.add(UserData());
                  continue;
                }
                data.add(searchUserById(allData, dummy[n]));
              }
            }
            List<Map<String, dynamic>> map = [];
            for (int n = 0; n < data.length; ++n) {
              map.add(userDataToMap(data[n]));
            }
            
            if (await Permission.storage.request().isGranted) {
              await saveToFile(map, file.files.first);
            } else {
              setState(() {
                feedback = "Operation failed. Access to storage denied";
              });
              openAppSettings();
            }
            setState(() {
              loading = false;
            });
          } else {}
        },
        tooltip: 'Increment',
        child: Icon((downloadReady == true) ? Icons.download : Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
