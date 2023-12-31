import 'package:flutter/material.dart';

//Klasse für den Lernplan
class Note {
  int id;
  String title;
  String content;
  DateTime modifiedTime;
  String? imagePath;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.modifiedTime,
    this.imagePath,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? 0,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      modifiedTime: map['modifiedTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['modifiedTime']) //Zeitangabe bei Erstellung
          : DateTime.now(),
      imagePath: map['imagePath'],
    );
  }
}

//Beispiele von Lernplänen
List<Note> sampleNotes = [
  Note(
    id: 0,
    title: 'Schreib dir einen Lernplan',
    content: 'Lernplan',
    modifiedTime: DateTime(2022),
  ),
  Note(
    id: 1,
    title: 'Mathelernplan:',
    content:
    'Ein Mathelernplan ist eine organisierte Methode, um mathematische Fähigkeiten zu verbessern. Er beinhaltet klare Ziele, Themenauswahl und Zeitpläne für das eigenständige Lernen.',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 2,
    title: 'Mobile Systeme',
    content: 'Beispiel Code zum lernen:',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 3,
    title: 'Deutschlernplan',
    content: 'Beispiel. ',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 4,
    title: 'Physik',
    content: 'Beispiel',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 5,
    title: 'Sport',
    content: 'Beispiel',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 6,
    title: 'Weltkunde',
    content: "Beispiel.",
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 7,
    title: 'Webanwendungen',
    content: 'Beispiel',
    modifiedTime: DateTime(2023),
  ),
  Note(
    id: 8,
    title: 'EasterEgg',
    content:
    'Hab ein bisschen Spaß am Lernen und wenn du das hier liest, hast du meine letzte Notiz entdeckt. Mit freundlichen Grüßen Nils und Direncan',
    modifiedTime: DateTime(2023),
  ),
];

//Anzeige des Lernplans
class NotesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sampleNotes.length,
      itemBuilder: (context, index) {
        final note = sampleNotes[index];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(note.content),
          trailing: note.imagePath != null
              ? Container(
            width: 50,
            height: 50,
            child: Image.network(
              note.imagePath!,
              fit: BoxFit.cover,
            ),
          )
              : null,
        );
      },
    );
  }
}
