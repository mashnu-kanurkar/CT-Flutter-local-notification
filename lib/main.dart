import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_push/second_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
String? selectedNotificationPayload;
late CleverTapPlugin _clevertapPlugin;
void showNotification(RemoteMessage message) async {
  print("Showing notif: ${message.data}");
  // var title = message.data["nt"];
  // var msg = message.data["nm"];
  // var payload =message.data;
  // var android = const AndroidNotificationDetails(
  //     'fluttertest', 'channel NAME', channelDescription: 'CHANNEL DESCRIPTION',
  //     priority: Priority.max, importance: Importance.max);
  //
  // var platform = NotificationDetails(android: android);
  // await flutterLocalNotificationsPlugin.show(0, title, msg, platform,
  //     payload: payload.toString());

  CleverTapPlugin.createNotification(jsonEncode(message.data));
  CleverTapPlugin.pushNotificationViewedEvent(message.data);
}

NotificationAppLaunchDetails? notificationAppLaunchDetails;
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
  showNotification(message);
  print('on message'+message.data["nm"]+"working");
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // ignore: avoid_print
  print("onDidReceiveBackgroundNotificationResponse: ${notificationResponse.payload}");
  print('notification(${notificationResponse.id}) action tapped: '
      '${notificationResponse.actionId} with'
      ' payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    // ignore: avoid_print
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
  //CleverTapPlugin.pushNotificationClickedEvent(extras);
}


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationAppLaunchDetails? notificationAppLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String initialRoute = MyHomePage.routeName;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    print("didNotificationLaunchApp: ${notificationAppLaunchDetails!.notificationResponse?.payload}");
    selectedNotificationPayload =
        notificationAppLaunchDetails.notificationResponse?.payload;
    initialRoute = SecondPage.routeName;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform,);
  await init();
  runApp( MyApp());
}

Future<void> init() async {
  var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher'); // <- default icon name is @mipmap/ic_launcher

  var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse){
      switch(notificationResponse.notificationResponseType){
        case NotificationResponseType.selectedNotification:
        print("onDidReceiveNotificationResponse - selectedNotification: ${notificationResponse.payload}");
          break;
        case NotificationResponseType.selectedNotificationAction:
          // if (notificationResponse.actionId == navigationActionId) {
          //   selectNotificationStream.add(notificationResponse.payload);
          // }
          print("onDidReceiveNotificationResponse - selectedNotificationAction: ${notificationResponse.payload}");
          break;
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  FirebaseMessaging.instance.getToken().then((value) {
    String? token = value;
    print("FCM Token is:${token!}");
    //CleverTapPlugin.setPushToken(value!);
  });
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    showNotification(message);
    print("onMessage: ${message.data}");
  });
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  _clevertapPlugin = CleverTapPlugin();
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "Main Navigator");



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final didNotificationLaunchApp =
        notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
    String initialRoute = didNotificationLaunchApp ? SecondPage.routeName : MyHomePage.routeName;

    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: initialRoute,
      routes: <String, WidgetBuilder>{
      MyHomePage.routeName: (_) => MyHomePage(notificationAppLaunchDetails,),
      SecondPage.routeName: (_) => SecondPage(selectedNotificationPayload)
    },
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(notificationAppLaunchDetails),
    );

  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage(this.notificationAppLaunchDetails, {Key? key,}) : super(key: key);

  final NotificationAppLaunchDetails? notificationAppLaunchDetails;
  final String title = "Home";
  static const String routeName = '/home';
  bool get didNotificationLaunchApp =>
      notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: "Main Navigator");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    CleverTapPlugin.setDebugLevel(2);
    _clevertapPlugin.setCleverTapPushClickedPayloadReceivedHandler(pushClickedPayloadReceived);
    CleverTapPlugin.createNotificationChannel("fluttertest", "Flutter Test", "Flutter Test", 3, true);
    CleverTapPlugin.createNotificationChannel("Tester", "Tester", "Flutter Test", 4, true);

  }

  void pushClickedPayloadReceived(Map<String, dynamic> map) {
    print("pushClickedPayloadReceived called");
    setState(() async {
      var data = jsonEncode(map);
      print("on Push Click Payload = $data");
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'This is a test app for custom push notification handling',
            ),
            Text("init route: ${notificationAppLaunchDetails?.didNotificationLaunchApp}!"),
            Text("payload: ${notificationAppLaunchDetails?.notificationResponse?.payload.toString()}"),
            ElevatedButton(onPressed: (){
              var stuff = ["bags", "shoes"];
              var profile = {
                'Name': 'Captain America',
                'Identity': '100',
                'Email': 'captain@america.com',
                'Phone': '+14155551234',
                'stuff': stuff
              };
              CleverTapPlugin.onUserLogin(profile);
            }, child: const Text("Login")),
            ElevatedButton(onPressed: (){
              var eventData = {
                // Key:    Value
                'Amount': 100,
                'type': 'UPI'
              };

              CleverTapPlugin.recordEvent("Charged", eventData);
            }, child: const Text("Charged")),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
