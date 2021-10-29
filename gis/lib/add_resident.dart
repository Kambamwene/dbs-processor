import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gis/backend.dart';

class AddResident extends StatefulWidget {
  const AddResident({Key key}) : super(key: key);

  @override
  _AddResidentState createState() => _AddResidentState();
}

class _AddResidentState extends State<AddResident> {
  ImageProvider dp;
  StreamController<String> feedback = StreamController<String>();
  FilePickerResult picture;
  TextEditingController name = TextEditingController();
  TextEditingController NIDA = TextEditingController();
  TextEditingController phone = TextEditingController();
  String date = "Select your birth date";
  DateTime birthday;
  @override
  void dispose() {
    feedback.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: ListView(
          //crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 5),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    foregroundImage: dp,
                    radius: 60,
                  ),
                  Positioned(
                      bottom: 0,
                      right: -10,
                      child: IconButton(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: () async {
                          try {
                            picture = await FilePicker.platform.pickFiles(
                                type: FileType.image, withData: true);
                            setState(() {
                              dp = MemoryImage(picture.files.first.bytes);
                            });
                          } catch (err) {
                            picture = null;
                          }
                        },
                      ))
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                children: [
                  TextField(
                      controller: NIDA,
                      decoration:
                          const InputDecoration(hintText: "NIDA number")),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(hintText: "Name")),
                  const SizedBox(height: 10),
                  //TextField(decoration:InputDecoration(hintText:"Phone(s)")),
                  TextField(
                      controller: phone,
                      maxLines: 5,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              "Phone(s) (separate different numbers with a new line)")),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          birthday = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now());
                          setState(() {
                            date =
                                "${birthday.year}-${birthday.month}-${birthday.day}";
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      Text(date)
                    ],
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          child: const Text("Register"),
                          onPressed: () async {
                            if (NIDA.text.isEmpty ||
                                name.text.isEmpty ||
                                phone.text.isEmpty ||
                                birthday == null) {
                              feedback.add("All fields must be filled");
                              return;
                            }
                            UserData user = UserData();
                            List<String> numbers = phone.text.split("\n");
                            user.phoneNumbers.addAll(numbers);
                            user.NIDA = NIDA.text;
                            user.name = name.text;
                            user.birthday = birthday;
                            feedback.add("Uploading dp...");
                            if (picture != null) {
                              user.photo = await uploadPicture(
                                  picture.files.first, NIDA.text);
                            } else {
                              user.photo = "";
                            }
                            feedback.add("Saving resident...");
                            bool response = await saveResident(user);
                            if (!response) {
                              feedback.add("Error");
                            } else {
                              feedback.add("Success");
                            }
                          })),
                  const SizedBox(height: 3),
                  StreamBuilder(
                      stream: feedback.stream,
                      initialData: "",
                      builder: (context, snapshot) {
                        return Text(snapshot.data, textAlign: TextAlign.center);
                      })
                ],
              ),
            ),
          ],
        ));
  }
}
