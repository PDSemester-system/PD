import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
// kReleaseMode 사용을 위해 추가
import 'package:spaghetti/Websocket/UserCount.dart';
import 'package:spaghetti/classroom/instructor/classroomService.dart';
import 'package:spaghetti/classroom/student/EnrollmentService.dart';
import 'package:spaghetti/firebase_options.dart';
import 'package:spaghetti/main/startPage.dart';
import 'package:spaghetti/member/UserProvider.dart';
import 'package:spaghetti/opinion/OpinionService.dart';
import 'package:spaghetti/quiz/QuizService.dart';

final FlutterLocalNotificationsPlugin notiPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> cancelNotification() async {
  await notiPlugin.cancelAll();
}

Future<void> requestPermissions() async {
  await notiPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

Future<void> showNotification({
  //알림 주기 위한 메소드
  required title,
  required message,
}) async {
  notiPlugin.show(
    11,
    title,
    message,
    NotificationDetails(
      android: AndroidNotificationDetails(
        "channelId",
        "channelName",
        channelDescription: "channelDescription",
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //알림 주기 메소드
  RemoteNotification? notification = message.notification;
  print('noti - title : ${notification?.title}, body : ${notification?.body}');
  Map<String, dynamic> data = message.data;
  await cancelNotification();
  await requestPermissions();
  await showNotification(title: data['title'], message: data['value']);
}

void main() async {
  //firebase 초기 세팅
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Notification Channel 설정
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'default_channel_id', // 채널 ID
    'Default Channel', // 채널 이름
    importance: Importance.defaultImportance, // 중요도
  );

  // flutter_local_notifications 초기화
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await notiPlugin.initialize(initializationSettings);

  // Notification Channel 생성 (Android용)
  await notiPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp()
      // DevicePreview(
      //   enabled: !kReleaseMode, // 릴리즈 모드가 아닌 경우에만 활성화
      //   builder: (context) => MyApp(),
      // ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
    //   overlays: [SystemUiOverlay.top]);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ClassroomService()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => OpinionService()),
        ChangeNotifierProvider(create: (context) => EnrollmentService()),
        ChangeNotifierProvider(create: (context) => UserCount()),
        ChangeNotifierProvider(create: (context) => QuizService()),
      ],
      child: MaterialApp(
        // builder: DevicePreview.appBuilder, // DevicePreview.appBuilder 사용
        // useInheritedMediaQuery: true, // MediaQuery 정보를 상속 받음
        // locale: DevicePreview.locale(context), // DevicePreview 로케일 사용
        debugShowCheckedModeBanner: false,
        home: StartPage(),
        theme: ThemeData(
          fontFamily: 'NanumB',
          scaffoldBackgroundColor: Colors.white, // 전체 앱의 Scaffold 배경색을 흰색으로 설정
          dialogBackgroundColor: Colors.white, // 다이얼로그 배경색을 흰색으로 설정
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white, // AppBar 배경색을 흰색으로 설정
            iconTheme:
                IconThemeData(color: Colors.black), // AppBar 아이콘 색상을 검정으로 설정
            titleTextStyle: TextStyle(
              color: Colors.black, // AppBar 타이틀 텍스트 색상을 검정으로 설정
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'NanumB',
            ),
            elevation: 0, // AppBar 그림자 없애기
          ),
        ),
      ),
    );
  }
}
