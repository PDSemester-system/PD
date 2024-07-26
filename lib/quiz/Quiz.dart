import 'dart:convert';

import 'package:spaghetti/classroom/classroom.dart';

class Quiz {
  String? quizId;
  Classroom? classroom;
  String? question;

  Quiz(String quizId, Classroom classroom, String question) {
    this.quizId = quizId;
    this.classroom = classroom;
    this.question = this.question;
  }

  Map<String, dynamic> toJson() => {
        'quizId': quizId,
        'classroom': classroom?.toJson(),
        'question': question
      };

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(json['quizId'], Classroom.fromJson_notArray(json['classroom']),
        json['question']);
  }

  static String convertQuizListToJson(List<Quiz> quizList) {
    List<Map<String, dynamic>> quizMapList =
        quizList.map((quiz) => quiz.toJson()).toList();
    return jsonEncode(quizMapList);
  }
}
