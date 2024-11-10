import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:spaghetti/Dialog/CicularProgress.dart';
import 'package:spaghetti/classroom/instructor/classroomService.dart';
import 'package:spaghetti/opinion/Opinion.dart';
import 'package:spaghetti/opinion/OpinionService.dart';
import 'package:weekday_selector/weekday_selector.dart';

class AddClassDialog extends StatefulWidget {
  const AddClassDialog({super.key});

  @override
  _AddClassDialogState createState() => _AddClassDialogState();
}

class _AddClassDialogState extends State<AddClassDialog> {
  Future<void> _selectTime(BuildContext context, int day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTimes[day] = picked;
      });
    }
  }

  ScrollController? _scrollController;
  var className = "";
  List<String>? ops;
  bool isLoading = false;
  List<bool> selectedDays = List.filled(7, false);
  Map<int, TimeOfDay?> selectedTimes = {};
  TimeOfDay selectedTime = TimeOfDay.now();
  List<List<dynamic>> timeList = [];

  final List<String> weekDays = [
    '일요일', // 6
    '월요일', // 0
    '화요일', // 1
    '수요일', // 2
    '목요일', // 3
    '금요일', // 4
    '토요일', // 5
  ];
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final opinionService =
          Provider.of<OpinionService>(context, listen: false);
      List<Opinion> opinionList = opinionService.opinionList;

      if (opinionList.isEmpty) {
        opinionService.addOpinion(opinion: Opinion(opinion: "수업속도가 빨라요"));
        opinionService.addOpinion(opinion: Opinion(opinion: "수업속도가 느려요"));
        opinionService.addOpinion(opinion: Opinion(opinion: "이해하지 못했어요"));
      }
    });
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ClassroomService, OpinionService>(
        builder: (context, classService, opinionService, child) {
      List<Opinion> opinionList = opinionService.opinionList;

      final mediaQuery = MediaQuery.of(context);
      final screenHeight = mediaQuery.size.height;
      final screenWidth = mediaQuery.size.width;

      // ClassroomService classroomService = new ClassroomService();
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        controller: _scrollController, // ScrollController 추가
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: screenHeight * 0.9,
            width: double.infinity,
            child: PageView(
              children: [
                Container(
                  child: Stack(
                    children: [
                      if (isLoading) CircularProgress.build(),
                      Positioned(
                        left: screenWidth * 0.12,
                        top: screenHeight * 0.05,
                        child: Text('수업을 생성해주세요.',
                            style: TextStyle(fontSize: screenWidth * 0.05)),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.11,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.07,
                          child: TextField(
                            decoration: InputDecoration(
                              fillColor: Color(0xfff7f8fc),
                              filled: true,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: '수업명을 입력해주세요',
                            ),
                            onChanged: (value) {
                              className = value;
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: screenWidth * 0.1,
                        top: screenHeight * 0.1,
                        child: IconButton(
                          icon: Image.asset(
                            'assets/images/logout.png', // 이미지 경로
                            width: screenWidth * 0.08,
                            height: screenWidth * 0.08,
                          ),
                          iconSize: screenWidth * 0.08,
                          onPressed: () {},
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.12,
                        top: screenHeight * 0.425,
                        child: Text('수업 의견을 생성해주세요.',
                            style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.195,
                        child: Container(
                          height: 3,
                          width: screenWidth * 0.8,
                          color: Colors.black,
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.12,
                        top: screenHeight * 0.215,
                        child: Text('수업 시작 시간을 선택해주세요',
                            style: TextStyle(fontSize: screenWidth * 0.04)),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.24,
                        child: GestureDetector(
                          onTap: () {},
                          child: SizedBox(
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.07,
                            child: WeekdaySelector(
                              onChanged: (int day) {
                                int adjustedIndex = (day + 6) % 7;
                                setState(() {
                                  selectedDays[day % 7] =
                                      !selectedDays[day % 7];
                                  // 요일 선택 시 시간 선택
                                  if (selectedDays[day % 7]) {
                                    _selectTime(context, adjustedIndex);
                                  } else {
                                    selectedTimes
                                        .remove(adjustedIndex); // 선택 해제 시 시간 삭제
                                  }
                                });
                              },
                              values: selectedDays,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.3,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.125,
                          child: ListView.builder(
                            itemCount: selectedDays.length,
                            itemBuilder: (context, index) {
                              if (selectedDays[index]) {
                                final time = selectedTimes[index - 1];

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    "${weekDays[index]} - 수업 시작 시간: ${time != null ? time.format(context) : '선택되지 않음'}",
                                    style: TextStyle(fontSize: 16), // 스타일 조정 가능
                                  ),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.465,
                        child: Container(
                          height: 3,
                          width: screenWidth * 0.8,
                          color: Colors.black,
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.675,
                        top: screenHeight * 0.4,
                        child: IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          onPressed: () {
                            opinionService.addOpinion(
                                opinion: Opinion(opinion: ""));
                          },
                          iconSize: 35,
                          color: Color(0xff71cdcb),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.8,
                        top: screenHeight * 0.4,
                        child: IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            if (opinionList.isNotEmpty) {
                              opinionService
                                  .deleteOpinion(opinionList.length - 1);
                            }
                          },
                          iconSize: 35,
                          color: Color(0xfff9a3b6),
                        ),
                      ),
                      Positioned(
                        top: screenHeight * 0.425 + 40,
                        left: screenWidth * 0.1,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.32,
                          child: Scrollbar(
                            thumbVisibility: false,
                            controller:
                                _scrollController, // ScrollController 추가
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              padding: EdgeInsets.zero, // ListView의 패딩을 없앰
                              itemCount: opinionList.length,
                              itemBuilder: (context, index) {
                                TextEditingController controller =
                                    TextEditingController(
                                  text: opinionList[index]
                                      .opinion, // opinionList에서 값이 있으면 초기화
                                );

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    width: screenWidth * 0.8,
                                    height: screenHeight * 0.07,
                                    child: TextField(
                                      controller: controller,
                                      onChanged: (value) {
                                        opinionService.updateOpinion(
                                            index, Opinion(opinion: value));
                                      },
                                      decoration: InputDecoration(
                                        fillColor: Color(0xfff7f8fc),
                                        filled: true,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintText: '의견을 적어주세요',
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: screenWidth * 0.1,
                        top: screenHeight * 0.75 + 30,
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          height: screenHeight * 0.06, // 화면 너비의 80%
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff789ad0),
                              surfaceTintColor: Color(0xff789ad0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              selectedTimes.forEach((key, time) {
                                if (time != null) {
                                  // 이차원 리스트에 추가: [요일, '시간']
                                  timeList.add([
                                    key,
                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                                  ]);
                                }
                                print(timeList);
                              });
                              setState(() {
                                isLoading = true;
                              });
                              await classService.classroomCreate(
                                  context,
                                  className,
                                  opinionList,
                                  opinionService); //??:의견 추가안했을 때는 빈 배열
                              setState(() {
                                isLoading = false;
                              });
                              Navigator.pop(context);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "수업 생성하기",
                                  style: TextStyle(color: Colors.white),
                                ),
                                Text(
                                  "+",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
