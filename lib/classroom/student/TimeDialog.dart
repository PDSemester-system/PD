import 'dart:async';
import 'package:flutter/material.dart';

class ProgressBottomSheet extends StatefulWidget {
  final int initialButtonClickCount;
  final Function(int) onButtonClickCountChanged;
  const ProgressBottomSheet(
      {super.key,
      required this.initialButtonClickCount,
      required this.onButtonClickCountChanged});

  @override
  _ProgressBottomSheetState createState() => _ProgressBottomSheetState();
}

class _ProgressBottomSheetState extends State<ProgressBottomSheet> {
  late int buttonClickCount;
  static const int durationInSeconds = 10;
  int elapsedSeconds = 0;
  double progressValue = 0.0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    buttonClickCount = widget.initialButtonClickCount;
    // 타이머 시작
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        elapsedSeconds += 1;
        progressValue = elapsedSeconds / durationInSeconds;

        // 시간이 끝나면 타이머를 취소하고 BottomSheet 닫기
        if (elapsedSeconds >= durationInSeconds) {
          timer.cancel();
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    // 타이머 정리
    if (timer.isActive) {
      timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = durationInSeconds - elapsedSeconds;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "10초안에 확인버튼을 누르세요",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            // 프로그레스바 업데이트
            LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            Text(
              "남은 시간: ${remainingSeconds}초",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () {
                  // 버튼을 눌렀을 때 타이머를 취소하고 BottomSheet 닫기
                  setState(() {
                    buttonClickCount++; // 버튼 클릭 카운트 증가
                  });
                  widget.onButtonClickCountChanged(
                      buttonClickCount); // 부모에게 카운트 전달
                  if (timer.isActive) {
                    timer.cancel();
                  }
                  Navigator.of(context).pop();
                },
                child: const Text("확인"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
