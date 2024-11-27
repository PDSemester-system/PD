import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:spaghetti/Websocket/UserCount.dart';
import 'package:spaghetti/Websocket/Websocket.dart';
import 'package:spaghetti/opinion/OpinionService.dart';
import 'package:spaghetti/quiz/QuizService.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:spaghetti/classroom/instructor/classCreatePage.dart';

class EvaluationResultPage extends StatefulWidget {
  final Websocket? webSocket;

  const EvaluationResultPage(this.webSocket, {super.key});
  @override
  _EvaluationResultPage createState() => _EvaluationResultPage();
}

class _EvaluationResultPage extends State<EvaluationResultPage> {
  String? jwt;
  final storage = FlutterSecureStorage();
  bool isLoading = false;
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

  Future<void> _disposeWebSocket() async {
    if (widget.webSocket != null) {
      await widget.webSocket?.unsubscribe();
      widget.webSocket
          ?.stomClient(jwt, context)
          .deactivate(); // websocket 연결 해제
    }
    Provider.of<OpinionService>(context, listen: false).deleteAll();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserCount>(builder: (context, userCount, child) {
      List<int> evaluationList = userCount.evaluationList;
      double totalScore = 0; // 투표 점수
      int totalReviews = 0; // 투표 인원수

      for (int i = 0; i < evaluationList.length; i++) {
        if (evaluationList[i] >= 0) {
          totalScore += (i + 1) * evaluationList[i];
          totalReviews += evaluationList[i];
        }
      }
      double averageRating = totalReviews > 0 ? totalScore / totalReviews : 0;

      return Scaffold(
        appBar: AppBar(
          title: Text('수업 평가'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text('평균 점수'),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      Text(
                        '$totalReviews 명의 학생',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                _buildRatingChart(userCount.evaluationList),
                SizedBox(height: 50),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await widget.webSocket?.unsubscribe();
                      widget.webSocket
                          ?.stomClient(jwt, context)
                          .deactivate(); // websocket 연결 해제
                      Provider.of<OpinionService>(context, listen: false)
                          .deleteAll();
                      Provider.of<QuizService>(context,
                              listen: false) // 방 삭제시 퀴즈 초기화
                          .initializeQuizList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClassCreatePage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff4a148c),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      minimumSize: Size(double.infinity, 50), // 버튼 높이 설정
                    ),
                    child: Text('확인하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  static Widget _buildRatingChart(List<int> evaluationList) {
    List<OpinionData> chartData = List.generate(5, (index) {
      List<Color> colors = [
        Color(0xffce93d8), // 밝은 퍼플
        Color(0xffba68c8), // 중간 밝기의 퍼플
        Color(0xffab47bc), // 보라색
        Color(0xff8e24aa), // 진한 퍼플
        Color(0xff7b1fa2),
      ];
      return OpinionData((index + 1).toString(),
          evaluationList[index].toDouble(), colors[index]);
    });

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(width: 0),
        axisLine: AxisLine(width: 0),
      ),
      plotAreaBorderWidth: 0,
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<OpinionData, String>>[
        ColumnSeries<OpinionData, String>(
          // ColumnSeries로 변경하여 세로 막대 그래프 사용
          dataSource: chartData,
          xValueMapper: (OpinionData data, _) => data.opinion,
          yValueMapper: (OpinionData data, _) => data.count,
          pointColorMapper: (OpinionData data, _) => data.color,
          dataLabelSettings: DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }
}

class OpinionData {
  OpinionData(this.opinion, this.count, this.color);
  final String opinion;
  final double count;
  final Color color;
}
