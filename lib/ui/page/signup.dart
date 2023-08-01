import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:test_face/cubit/save_cubit.dart';

import '../../services/camera_service.dart';
import '../../services/facenet_service.dart';
import '../../services/ml_kit_service.dart';
import '../widgets/FacePainter.dart';

class SignUpPage extends StatefulWidget {
  CameraDescription cameraDescription;

  SignUpPage({super.key, required this.cameraDescription});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late String imagePath;
  Face? faceDetected;
  late Size imageSize;

  bool _detectingFaces = false;
  bool pictureTaked = false;

  late Future _initializeControllerFuture;
  bool cameraInitializated = false;

  // switchs when the user press the camera
  bool _saving = false;
  bool _bottomSheetVisible = false;

  // service injection
  final MLKitService _mlKitService = MLKitService();
  final CameraService _cameraService = CameraService();
  final FaceNetService _faceNetService = FaceNetService.faceNetService;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    // Dispose of the controller when the widget is disposed.
    _cameraService.dispose();
  }

  void _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        // if its currently busy, avoids overprocessing
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          List<Face> faces = await _mlKitService.getFacesFromImage(image);

          if (faces.isNotEmpty) {
            setState(() {
              faceDetected = faces[0];
            });

            if (_saving) {
              _faceNetService.setCurrentPrediction(image, faceDetected!);
              var result = await _faceNetService.predictedData;
              print("RESUUULT");
              print(result);

              setState(() {
                _saving = false;
              });
            }
          } else {
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print(e);
          _detectingFaces = false;
        }
      }
    });
  }

  void _start() async {
    _initializeControllerFuture =
        _cameraService.startService(widget.cameraDescription);
    await _initializeControllerFuture;

    setState(() {
      cameraInitializated = true;
    });

    _frameFaces();
  }

  void _reset() async {
    List<CameraDescription> cameras = await availableCameras();

    /// takes the front camera
    widget.cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );
    _start();

    // start the services
    // await _faceNetService.loadModel();
    //  await _dataBaseService.loadDB();
    // _mlKitService.initialize();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    /// starts the camera & start framing faces
    _start();
  }

  @override
  Widget build(BuildContext context) {
    const double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (pictureTaked) {
                  return SizedBox(
                    width: width,
                    height: height,
                    child: Transform(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: Image.file(File(imagePath)),
                        ),
                        transform: Matrix4.rotationY(mirror)),
                  );
                } else {
                  return Transform.scale(
                    scale: 1.0,
                    child: AspectRatio(
                      aspectRatio: MediaQuery.of(context).size.aspectRatio,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: SizedBox(
                            width: width,
                            height: width *
                                _cameraService
                                    .cameraController.value.aspectRatio,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                CameraPreview(_cameraService.cameraController),
                                CustomPaint(
                                  painter: FacePainter(
                                      face: faceDetected, imageSize: imageSize),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          SafeArea(
            child: Column(
              children: [
                TextButton(
                    onPressed: () async {
                      if (faceDetected == null) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return const AlertDialog(
                              content: Text('No face detected!'),
                            );
                          },
                        );
                      } else {
                        _saving = true;

                        await Future.delayed(const Duration(milliseconds: 500));
                        await _cameraService.cameraController.stopImageStream();
                        await Future.delayed(const Duration(milliseconds: 200));
                        XFile file = await _cameraService.takePicture();

                        setState(() {
                          _bottomSheetVisible = true;
                          pictureTaked = true;
                          imagePath = file.path;
                        });

                        var result = await _faceNetService
                            // ignore: use_build_context_synchronously
                            .predict(context.read<SaveCubit>().state);
                        print("hasil nyo iko aaa");
                        print(result);
                        if (result!) {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const AlertDialog(
                                content: Text('COCOK!'),
                              );
                            },
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const AlertDialog(
                                content: Text('Tidak COCOK'),
                              );
                            },
                          );
                        }
                      }
                    },
                    child: Text("Tes COCOK")),
                TextButton(
                    onPressed: () async {
                      if (faceDetected == null) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return const AlertDialog(
                              content: Text('No face detected!'),
                            );
                          },
                        );
                      } else {
                        _saving = true;
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _cameraService.cameraController.stopImageStream();
                        await Future.delayed(const Duration(milliseconds: 200));
                        XFile file = await _cameraService.takePicture();
                        imagePath = file.path;

                        setState(() {
                          _bottomSheetVisible = true;
                          pictureTaked = true;
                        });
                        List? predictedData = _faceNetService.predictedData;
                        context.read<SaveCubit>().setNewValue(predictedData);

                        print('AuthactionPredicatedData: $predictedData');
                      }
                    },
                    child: Text(
                      "CEKREK",
                    )),
                TextButton(
                    onPressed: () {
                      _reset();
                    },
                    child: const Text("RESTART"))
              ],
            ),
          )
        ],
      ),
    );
  }
}
