import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_face/cubit/save_cubit.dart';
import 'package:test_face/services/facenet_service.dart';
import 'package:test_face/services/ml_kit_service.dart';
import 'package:test_face/ui/page/signup.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late CameraDescription cameraDescription;
  FaceNetService _faceNetService = FaceNetService.faceNetService;
  MLKitService _mlKitService = MLKitService();
  bool loading = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _startup();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SaveCubit(),
        )
      ],
      child: MaterialApp(
        theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity),
        home: SignUpPage(
          cameraDescription: cameraDescription,
        ),
      ),
    );
  }

  void _startup() async {
    _setLoading(true);

    List<CameraDescription> cameras = await availableCameras();

    /// takes the front camera
    cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );

    // start the services
    await _faceNetService.loadModel();
    //  await _dataBaseService.loadDB();
    _mlKitService.initialize();

    _setLoading(false);
  }

  void _setLoading(bool value) {
    setState(() {
      loading = value;
    });
  }
}
