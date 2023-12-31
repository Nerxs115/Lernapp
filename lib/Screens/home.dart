
//Importe
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:math';
import 'package:first_pp/Constants/color.dart';
import 'package:first_pp/models/note.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/edit.dart';

//Widget für die Startseite
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}): super(key: key);

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}
//Klasse für die Startseite
class _HomeScreenState extends State<HomeScreen> {
  List<Note> filteredNotes = []; //Gefiltert
  bool sorted = false;
  Map<int, File?> imageMap = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; //Firebase Instanzen
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Firestore Database
  @override
  void initState() {
    super.initState(); //Daten von Firebase abrufen
    fetchLernFromFirebase();
  }
//Lernpläne abrufen
  Future<void> fetchLernFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;
        final querySnapshot = await _firestore
            .collection('Lernpläne')
            .doc(userId)
            .collection('Lernpläne_user')
            .get();

        setState(() {
          filteredNotes = querySnapshot.docs
              .map((doc) => Note.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      print('Fehler: $e');
    }
  }
//Speichern von Lernplänen
  Future<void> saveNoteToFirebase(Note note, File? imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;

        String? imageUrl;
        if (imageFile != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('images/$userId/${note.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await storageRef.putFile(imageFile);
          imageUrl = await storageRef.getDownloadURL();
        }
//Speichern 2
        await _firestore
            .collection('Lernpläne')
            .doc(userId)
            .collection('Lernpläne_user')
            .add({
          'title': note.title,
          'content': note.content,
          'modifiedTime': note.modifiedTime,
          'imagePath': imageUrl,
        });
        //Aktualisiurung
        fetchLernFromFirebase();
      }
    } catch (e) {
      print('Fehler beim speichern: $e');
    }
  } // Methode zum Auswahl eines Bildes aus der Galerie
  Future<void> _pickImage(int noteId) async {
    final picker = ImagePicker();
    final status = await Permission.photos.request(); //Anfrage auf Erlaubnis
    if (status == PermissionStatus.granted) {
      final pickedImage = await picker.pickImage(source: ImageSource.gallery); //Gallerie

      if (pickedImage != null) {
        setState(() {
          imageMap[noteId] = File(pickedImage.path);
        });
      }
    } else {
      print('Keine Erlaubnis'); //Keine Erlaubnis auf die Gallerie
    }
  }
// Methode zum Aufnehmen eines Bildes mit der Kamera
  Future<void> _takePicture(int noteId) async {
    final picker = ImagePicker();
    final status = await Permission.camera.request();
    if (status == PermissionStatus.granted) {
      final pickedImage = await picker.pickImage(source: ImageSource.camera);

      if (pickedImage != null) {
        setState(() {
          imageMap[noteId] = File(pickedImage.path);
        });
      }
    } else {
      print('Keine Erlaubnis');
    }
  }
  // Methode zum Sortieren der Lernpläne nach der bearbeiteten Zeit
  List<Note> sortNotesByModifiedTime(List<Note> notes) {
    if (sorted) {
      notes.sort((a, b) => a.modifiedTime.compareTo(b.modifiedTime));
    } else {
      notes.sort((b, a) => a.modifiedTime.compareTo(b.modifiedTime));
    }
    sorted = !sorted;
    return notes;
  }
  //Zufällige Hintergrundfarbe für die Lernpläne
  Color getRandomColor() {
    Random random = Random();
    return backgroundColors[random.nextInt(backgroundColors.length)];
  }
  //Filtern nach Wörtern in der Suche
  void onSearchTextChanged(String searchText) {
    setState(() {
      filteredNotes = sampleNotes
          .where((note) =>
      note.content.toLowerCase().contains(searchText.toLowerCase()) ||
          note.title.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }
  //Lernplan löschen
  void deleteNote(int index) {
    setState(() {
      Note noteToDelete = filteredNotes[index];
      sampleNotes.removeWhere((note) => note.id == noteToDelete.id);
      filteredNotes = List.from(sampleNotes);
    });
  }
  //Benutzeroberfläche
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //titel
      backgroundColor: Colors.grey.shade900,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LernApp',
                    style: TextStyle(fontSize: 30, color: Colors.white)),
                IconButton(
                  onPressed: () {
                    setState(() {
                      filteredNotes = sortNotesByModifiedTime(filteredNotes);
                    });
                  },
                  padding: EdgeInsets.all(0),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade800.withOpacity(.8),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon( //Sotier Icon auf der rechten Seite
                      Icons.sort,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            //Suchfeld
            TextField(
              onChanged: (value) {
                onSearchTextChanged(value);
              },
              style: TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                  hintText: "Suche Lernpläne...",
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  fillColor: Colors.grey.shade800,
                  filled: true,
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                      const BorderSide(color: Colors.transparent)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide:
                      const BorderSide(color: Colors.transparent))),
            ),
            //Liste der Lernpläne
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 30),
                itemCount: filteredNotes.length,
                itemBuilder: (context, index) {
                  int noteId = filteredNotes[index].id;

                  return Card(
                    margin: EdgeInsets.only(bottom: 20),
                    color: getRandomColor(),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (BuildContext context) => EditScreen(
                                note: filteredNotes[index],
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              int originalIndex =
                              sampleNotes.indexOf(filteredNotes[index]);
                              sampleNotes[originalIndex] = (Note(
                                id: sampleNotes[originalIndex].id,
                                title: result[0],
                                content: result[1],
                                modifiedTime: DateTime.now(),
                                imagePath: imageMap[noteId]?.path,
                              ));

                              filteredNotes[index] = Note(
                                id: sampleNotes[originalIndex].id,
                                title: result[0],
                                content: result[1],
                                modifiedTime: DateTime.now(),
                                imagePath: imageMap[noteId]?.path,
                              );
                            });
                          }
                        },
                        title: RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            text: '${filteredNotes[index].title} \n',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: '${filteredNotes[index].content}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        //Uhrzeit und Erstelldatum
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Bearbeitet am: ${DateFormat('d MMM EEE, yyyy h:mm a').format(filteredNotes[index].modifiedTime)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        leading: imageMap[noteId] != null
                            ? CircleAvatar(
                          backgroundImage: FileImage(imageMap[noteId]!),
                        )
                            : filteredNotes[index].imagePath != null
                            ? CircleAvatar(
                          backgroundImage: FileImage(
                              File(filteredNotes[index].imagePath!)),
                        )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _pickImage(noteId),
                              icon: const Icon(Icons.image),         //Icon Bild
                            ),
                            IconButton(
                              onPressed: () => _takePicture(noteId),
                              icon: const Icon(Icons.camera_alt),   //Icon Bild
                            ),
                            IconButton(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Colors.grey.shade900,
                                      icon: Icon(Icons.info, color: Colors.grey),
                                      title: const Text(
                                        'Soll das Projekt gelöscht werden ?',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            child: const SizedBox(
                                              width: 60,
                                              child: Text(         //Ja button
                                                'Ja',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const SizedBox(
                                              width: 60,
                                              child: Text(            //Nein Button
                                                'Nein',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                                if (result != null && result) {
                                  deleteNote(index);
                                }
                              },
                              icon: const Icon(Icons.delete),  //Icon Mülltonne
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => EditScreen(),
            ),
          );
          if (result != null) {
            setState(() {
              sampleNotes.add(Note(
                id: sampleNotes.length,
                title: result[0],
                content: result[1],
                modifiedTime: DateTime.now(),
                imagePath: imageMap[sampleNotes.length]?.path,
              ));
              filteredNotes = sampleNotes;
            });
          }
        },
        elevation: 10,
        backgroundColor: Colors.blue.shade800,
        child: Icon(
          Icons.add,         //Icon Hinzufügen
          size: 38,
        ),
      ),
    );
  }
}
