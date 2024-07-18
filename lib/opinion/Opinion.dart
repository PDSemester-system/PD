import 'package:spaghetti/classroom/classroom.dart';

class Opinion {
  String opinionId;
  String opinion;
  Classroom? classroom;

  Opinion({
    this.opinionId = "",
    required this.opinion,
    this.classroom,
  });

  factory Opinion.fromJson(Map<String, dynamic> json) {
    return Opinion(
      opinionId: json['opinionId'],
      opinion: json['opinion'],
      classroom: Classroom.fromJson_notArray(json['classroom']),
    );
  }
}
