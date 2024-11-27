import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:spaghetti/Websocket/UserCount.dart';
import 'package:spaghetti/Websocket/Websocket.dart';
import 'package:spaghetti/opinion/OpinionService.dart';
import 'package:spaghetti/quiz/Quiz.dart';
import 'package:spaghetti/quiz/QuizService.dart';
import 'package:spaghetti/quiz/QuizVote.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class QuizCheckPage extends StatefulWidget {
  final Websocket? webSocket;

  const QuizCheckPage(this.webSocket, {super.key});
  @override
  _QuizCheckPage createState() => _QuizCheckPage();
}

class _QuizCheckPage extends State<QuizCheckPage> {
  String? jwt;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initializeJwt();
  }

  void _initializeJwt() async {
    jwt = await storage.read(key: "Authorization") ?? "";
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserCount userCount = Provider.of<UserCount>(context, listen: false);

    QuizService quizService = Provider.of<QuizService>(context, listen: false);
    List<QuizVote> quizCount = List<QuizVote>.from(quizService.quizCount);

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    // 계산된 평점을 바탕으로 전반적인 평가 점수를 계산합니다.
    double totalScore = 0;
    int totalReviews = 0;

    double averageRating = totalReviews > 0 ? totalScore / totalReviews : 0;

    return Consumer<UserCount>(builder: (context, userCount, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('퀴즈'),
        ),
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          height: screenHeight,
          child: Stack(
            children: [
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.05,
                child: SizedBox(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.55, // 차트 높이 조정
                  child: BarChartExample(),
                ),
              ),
              Positioned(
                left: screenWidth * 0.1,
                top: screenHeight * 0.7,
                child: SizedBox(
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.05,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff8e24aa),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text('확인',
                        style: TextStyle(fontSize: screenWidth * 0.05)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class BarChartExample extends StatefulWidget {
  const BarChartExample({Key? key}) : super(key: key);

  @override
  _BarChartExampleState createState() => _BarChartExampleState();
}

class _BarChartExampleState extends State<BarChartExample> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: Column(
        children: <Widget>[
          const SizedBox(
            height: 18,
          ),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: Consumer<QuizService>(
                builder: (context, quizService, child) {
                  List<Quiz> quizList = quizService.quizList;
                  List<QuizVote> quizCount = quizService.quizCount;

                  List<PieChartSectionData> sections =
                      List.generate(quizList.length, (index) {
                    final isTouched = index == touchedIndex;
                    final fontSize = isTouched ? 25.0 : 16.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final double value = quizCount[index].count.toDouble();
                    final double displayValue = value == 0 ? 0.1 : value;

                    return PieChartSectionData(
                      color: Colors.primaries[index % Colors.primaries.length],
                      value: displayValue,
                      title: '${quizCount[index].count}명',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 2)
                        ],
                      ),
                    );
                  });

                  return Column(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback:
                                  (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    touchedIndex = -1;
                                  } else {
                                    // 해당 항목의 index를 touchedIndex로 설정하여 확대
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  }
                                });
                              },
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            sectionsSpace: 0,
                            centerSpaceRadius: 40,
                            sections: sections,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 범례 추가 (opinion과 색상 매칭)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(quizList.length, (index) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.primaries[
                                      index % Colors.primaries.length],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                quizList[index].question ?? "",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(
            width: 28,
          ),
        ],
      ),
    );
  }
}
