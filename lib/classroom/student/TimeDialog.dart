import 'dart:async';
import 'package:flutter/material.dart';

Future<void> TimeDialog(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: true,
    enableDrag: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    builder: (context) => const ProgressBottomSheet(),
  );
}

class ProgressBottomSheet extends StatefulWidget {
  const ProgressBottomSheet({super.key});

  @override
  _ProgressBottomSheetState createState() => _ProgressBottomSheetState();
}

class _ProgressBottomSheetState extends State<ProgressBottomSheet> {
  static const int durationInSeconds = 10;
  int elapsedSeconds = 0;
  double progressValue = 0.0;
  late Timer timer;

  @override
  void initState() {
    super.initState();
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
