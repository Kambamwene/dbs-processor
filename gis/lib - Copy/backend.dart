import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:ext_storage/ext_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UserData {
  String NIDA;
  String name;
  String photo;
  DateTime birthday;
  String address;
  List<String> phoneNumbers = [];
}

UserData mapToUserData(Map<String, dynamic> map) {
  UserData data = UserData();
  data.NIDA = map["NIDA"].toString();
  data.name = map["name"];
  if (map["photo"] == null) {
    data.photo = "";
  } else {
    data.photo = map["photo"];
  }
  data.birthday = map["birthday"].toDate();
  data.address = map["address"];
  for (int n = 0; n < map["phoneNumber"].length; ++n) {
    data.phoneNumbers.add(map["phoneNumber"][n]);
  }
  return data;
}

Map<String, dynamic> userDataToMap(UserData data) {
  Map<String, dynamic> map = <String, dynamic>{};
  map["name"] = data.name;
  map["NIDA"] = data.NIDA.toString();
  map["birthday"] = data.birthday;
  map["address"] = data.address;
  map["photo"] = data.photo;
  map["phoneNumber"] = data.phoneNumbers;
  return map;
}

Future<List<String>> readExcelFile(String path) async {
  var bytes = File(path).readAsBytesSync();
  Excel excel = Excel.decodeBytes(bytes);
  List<String> nida = [];
  for (int n = 1; n < excel.sheets[excel.sheets.keys.first].maxRows; ++n) {
    nida.add((excel.sheets[excel.sheets.keys.first].rows[n][0]).toString());
  }
  return nida;
}

Future<List<UserData>> readUserDatabase() async {
  QuerySnapshot query;
  try {
    query = await FirebaseFirestore.instance.collection("Residents").get();
  } on Exception catch (e) {
    return null;
  }
  List<UserData> users = [];
  for (int n = 0; n < query.size; ++n) {
    users.add(mapToUserData(query.docs[n].data()));
  }
  return users;
}

Future<UserData> readUserData(String id) async {
  DocumentSnapshot doc;
  try {
    doc = await FirebaseFirestore.instance.doc("Residents/$id").get();
    if (!doc.exists) {
      return null;
    }
    UserData user = mapToUserData(doc.data());
    return user;
  } on Exception catch (e) {
    return null;
  }
}

Future<bool> saveFilePrep(Map<String, dynamic> map) async {
  return await saveToFile(map["users"], map["file"]);
}

Future<bool> saveToFile(
    List<Map<String, dynamic>> userData, PlatformFile file) async {
  Excel excel = Excel.decodeBytes(file.bytes);
  Sheet sheet = excel.sheets[excel.sheets.keys.first];
  List<String> names = [];
  List<dynamic> birthday = [];
  List<String> phoneNumbers = [];
  List<String> photos = [];
  phoneNumbers.add("Phone");
  birthday.add("Birthday");
  names.add("Name");
  photos.add("Photo");
  String numbers = "";
  for (int n = 0; n < userData.length; ++n) {
    names.add(userData[n]["name"]);
    birthday.add(userData[n]["birthday"]);
    for (var phone in userData[n]["phoneNumber"]) {
      numbers += phone + " , ";
    }
    phoneNumbers.add(numbers);
    numbers = "";
    photos.add(userData[n]["photo"]);
  }

  for (int n = 0; n < userData.length; ++n) {}
  sheet.insertColumn(1);
  for (int n = 0; n < names.length; ++n) {
    sheet.updateCell(CellIndex.indexByString("B${n + 1}"), names[n]);
  }
  sheet.insertColumn(2);
  for (int n = 0; n < names.length; ++n) {
    sheet.updateCell(CellIndex.indexByString("C${n + 1}"), photos[n]);
  }
  sheet.insertColumn(3);
  for (int n = 0; n < birthday.length; ++n) {
    sheet.updateCell(
        CellIndex.indexByString(
          "D${n + 1}",
        ),
        (n == 0)
            ? "Birthday"
            : (birthday[n] == null)
                ? ""
                : "${birthday[n].day}/${birthday[n].month}/${birthday[n].year}");
  }
  sheet.insertColumn(4);
  for (int n = 0; n < names.length; ++n) {
    sheet.updateCell(CellIndex.indexByString("E${n + 1}"), phoneNumbers[n]);
  }
  //Excel newExcel=Excel.createExcel();
  var bytes = await excel.encode();
  String path=await ExtStorage.getExternalStorageDirectory();
  Directory downloads = Directory(path + "/Mbeya Files");
  downloads.createSync(recursive: true);
  path = downloads.path + "/${file.name}";
  File(path).writeAsBytesSync(bytes);
  return true;
}

UserData searchUserById(List<UserData> users, String NIDA) {
  for (int n = 0; n < users.length; ++n) {
    if (users[n].NIDA == NIDA) {
      //found = true;
      return users[n];
    }
  }
  return UserData();
}

Future<String> uploadPicture(PlatformFile file, String NIDA) async {
  Reference ref = FirebaseStorage.instance.ref("/$NIDA/${file.name}");
  try {
    await ref.putData(file.bytes);
    return await ref.getDownloadURL();
  } catch (err) {
    return "";
  }
}

Future<bool> saveResident(UserData data) async {
  try {
    await FirebaseFirestore.instance
        .collection("Residents")
        .doc(data.NIDA)
        .set(userDataToMap(data));
    return true;
  } on Exception catch (e) {
    return false;
  }
}
