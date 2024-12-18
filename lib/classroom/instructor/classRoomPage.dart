import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:spaghetti/Dialog/CicularProgress.dart';
import 'package:spaghetti/Websocket/UserCount.dart';
import 'package:spaghetti/Websocket/Websocket.dart';
import 'package:spaghetti/classroom/classroom.dart';
import 'package:spaghetti/classroom/instructor/EditClassDialog.dart';
import 'package:spaghetti/classroom/instructor/Indicator.dart';
import 'package:spaghetti/classroom/instructor/QuizCheckpage.dart';
import 'package:spaghetti/classroom/instructor/classroomService.dart';
import 'package:spaghetti/member/User.dart';
import 'package:spaghetti/member/UserProvider.dart';
import 'package:spaghetti/opinion/Opinion.dart';
import 'package:spaghetti/opinion/OpinionService.dart';
import 'package:spaghetti/opinion/OpinionVote.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'Quiz_class_dialog.dart';
import 'package:spaghetti/classroom/instructor/EvaluationResultPage.dart';

class ClassRoomPage extends StatefulWidget {
  final Classroom? classRoomData;
  Websocket? websocket;
  ClassRoomPage({super.key, this.classRoomData});

  @override
  _ClassRoomPageState createState() => _ClassRoomPageState();
}

class _ClassRoomPageState extends State<ClassRoomPage> {
  int? selectedRadio = 0;
  Websocket? websocket;
  String? jwt;
  final storage = FlutterSecureStorage();
  bool isLoading = false;
  User? user;
  UserCount? userCount;
  Future<void>? _webSocketFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (user == null || userCount == null) {
      user = Provider.of<UserProvider>(context).user;
      userCount = Provider.of<UserCount>(context);
    }
  }

  @override
  void initState() {
    super.initState();
    websocket = widget.websocket;
    _webSocketFuture = _initializeWebsocket();
  }

  Future<void> _initializeWebsocket() async {
    String classId = widget.classRoomData!.classId;
    jwt = await storage.read(key: "Authorization") ?? "";
    websocket = Websocket(classId, user, jwt, context);
    userCount?.evaluationList = [0, 0, 0, 0, 0];
  }

  @override
  void dispose() async {
    // await websocket?.unsubscribe();
    // websocket?.stomClient(jwt, context).deactivate(); // websocket 연결 해제
    // Provider.of<OpinionService>(context, listen: false).deleteAll();
    isLoading = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ClassroomService, OpinionService, UserCount>(
        builder: (context, classService, opinionService, userCount, child) {
      final mediaQuery = MediaQuery.of(context);
      final screenHeight = mediaQuery.size.height;
      final screenWidth = mediaQuery.size.width;

      String className = widget.classRoomData!.className;
      String classId = widget.classRoomData!.classId;
      // classNumber 생성
      String classNumber =
          (widget.classRoomData!.classId.hashCode.abs() % 100000000).toString();

      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight,
            child: Stack(
              children: [
                if (isLoading) CircularProgress.build(),
                Positioned(
                  left: screenWidth * 0.6,
                  top: screenHeight * 0.12,
                  child: Text("$className ${userCount.userList[classId] ?? 0}명",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'NanumB',
                      )),
                ),
                Positioned(
                  left: screenWidth * 0.1,
                  top: screenHeight * 0.84,
                  child: SizedBox(
                    width: screenWidth * 0.8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffce93d8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  isLoading = true;
                                });
                                //투표 초기화
                                opinionService.updateCountList();
                                //학생들에게 버튼 초기화 메세지
                                websocket?.opinionInit();
                                setState(() {
                                  isLoading = false;
                                });
                              },
                              child: Text("의견  초기화",
                                  style:
                                      TextStyle(fontSize: screenWidth * 0.039),
                                  textAlign: TextAlign.center),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xffba68c8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                addDialog(
                                    context, widget.classRoomData, websocket);
                              },
                              child: Text(
                                "퀴즈",
                                style: TextStyle(fontSize: screenWidth * 0.039),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(130, 230, 230, 230),
                                surfaceTintColor:
                                    Color.fromARGB(130, 230, 230, 230),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                // websocket?.unsubscribe();
                                // websocket?.stomClient(jwt, context).deactivate();
                                // opinionService.deleteAll();
                                // 평가 페이지에서 평가 완료 후 결과 페이지로 이동
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EvaluationResultPage(websocket),
                                  ),
                                );
                              },
                              child: Text(
                                "종료",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.05,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.1,
                  top: screenHeight * 0.11,
                  child: IconButton(
                    icon: Image.asset(
                      'assets/images/share_icon.png',
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                    ),
                    iconSize: screenWidth * 0.08,
                    onPressed: () {
                      classService.classroomMakePin(
                          context, classId, classNumber);
                      classService.sendPinToServer(context, classNumber);

                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return Consumer<ClassroomService>(
                            builder: (context, classService, child) {
                              return Container(
                                height: 300,
                                margin: const EdgeInsets.only(
                                  left: 25,
                                  right: 25,
                                  bottom: 40,
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "수업 참여코드",
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (int i = 0;
                                            i < classNumber.length;
                                            i++) ...[
                                          Container(
                                            width: 30, // 숫자 박스 너비
                                            height: 40, // 숫자 박스 높이
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black),
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                classNumber[i],
                                                style: TextStyle(
                                                  fontSize: 30, // 숫자 크기
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (i == 3)
                                            SizedBox(width: 20) // 4번과 5번 사이 간격
                                          else if (i < classNumber.length - 1)
                                            SizedBox(width: 5), // 다른 숫자 사이 간격
                                        ],
                                      ],
                                    ),
                                    SizedBox(height: 50),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple[400],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        showQRCodeModal(context, classNumber);
                                      },
                                      child: Text("QR코드 생성"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.36, // 적절히 조정
                  top: screenHeight * 0.11,
                  child: IconButton(
                    icon: Image.asset(
                      'assets/images/quiz.png', // 수정 아이콘 경로
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                    ),
                    iconSize: screenWidth * 0.08,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizCheckPage(websocket),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.23, // 적절히 조정
                  top: screenHeight * 0.11,
                  child: IconButton(
                    icon: Image.asset(
                      'assets/images/edit.png', // 퀴즈 결과 창
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                    ),
                    iconSize: screenWidth * 0.08,
                    onPressed: () {
                      showEditClassDialog(context, websocket!);
                    },
                  ),
                ),
                Positioned(
                  left: screenWidth * 0.1,
                  top: screenHeight * 0.16,
                  child: SizedBox(
                    width: screenWidth * 0.8,
                    height: screenHeight * 0.6, // 차트 높이 조정
                    child: BarChartExample(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void showEditClassDialog(BuildContext context, Websocket websocket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (BuildContext context) {
        return EditClassDialog(
          classRoomData: widget.classRoomData,
          websocket: websocket,
        );
      },
    );
  }
}

void addDialog(
    BuildContext context, Classroom? classroom, Websocket? websocket) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
    ),
    builder: (BuildContext context) {
      return QuizClassDialog(classroom, websocket);
    },
  );
}

void showQRCodeModal(BuildContext context, String classNumber) {
  ScreenshotController screenshotController = ScreenshotController();
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.only(
          left: 25,
          right: 25,
          bottom: 40,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Screenshot(
                controller: screenshotController,
                child: QrImageView(
                  data: classNumber,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (Platform.isAndroid || Platform.isIOS) {
                    await screenshotController
                        .capture(
                            delay: Duration(milliseconds: 10),
                            pixelRatio: MediaQuery.of(context).devicePixelRatio)
                        .then((Uint8List? image) async {
                      if (image != null) {
                        final directory =
                            await getApplicationDocumentsDirectory();
                        final imagePath =
                            await File('${directory.path}/image.jpg').create();
                        await imagePath.writeAsBytes(image);
                        await ImageGallerySaver.saveFile(imagePath.path,
                            name: 'firstScreenshot');

                        /// Share Plugin
                        // await Share.shareFiles([imagePath.path]);
                      }
                    });
                  }
                  Clipboard.setData(ClipboardData(text: classNumber));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('QR코드가 저장되었습니다')),
                  );
                },
                child: Text("수업코드 복사"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
    backgroundColor: Colors.transparent,
  );
}

class BarChartExample extends StatefulWidget {
  const BarChartExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => BarChartExampleState();
}

class BarChartExampleState extends State<BarChartExample> {
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
              child: Consumer2<ClassroomService, OpinionService>(
                builder: (context, classroomService, opinionService, child) {
                  List<Opinion> opinionList = opinionService.opinionList;
                  List<OpinionVote> opinionCount = opinionService.countList;

                  List<PieChartSectionData> sections =
                      List.generate(opinionList.length, (index) {
                    final isTouched = index == touchedIndex;
                    final fontSize = isTouched ? 25.0 : 16.0;
                    final radius = isTouched ? 60.0 : 50.0;
                    final double value = opinionCount[index].count.toDouble();
                    final double displayValue = value == 0 ? 0.1 : value;

                    return PieChartSectionData(
                      color: Colors.primaries[index % Colors.primaries.length],
                      value: displayValue,
                      title: '${opinionCount[index].count}명',
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
                        children: List.generate(opinionList.length, (index) {
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
                                opinionList[index].opinion,
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
