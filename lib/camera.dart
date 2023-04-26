import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite/tflite.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'homePage.dart';
import 'main.dart';

class CameraTestScreen extends StatefulWidget {
  @override
  State<CameraTestScreen> createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  List<double>? _accelerometerValues;
  late CameraController mlInferenceController;
  XFile? videoFile;
  bool isWorking = false;
  String result = "";
  late CameraImage imgCamera;
  CameraController? cameraController;
  CameraController? controller;
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _result = '00:00:00';

  Future<String> saveImage(CameraImage image) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagePath =
        '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final File imageFile = File(imagePath);
    if (!appDir.existsSync()) {
      appDir.createSync(recursive: true);
    }
    await imageFile.writeAsBytes(image.planes[0].bytes);
    await GallerySaver.saveImage(imageFile.path, albumName: "Pictures");
    return imagePath;
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/mobilenet_v1_1.0_224.tflite',
      labels: 'assets/mobilenet_v1_1.0_224.txt',
    );
  }

  initCamera() {
    mlInferenceController =
        CameraController(cameras.first, ResolutionPreset.low);
    mlInferenceController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        mlInferenceController.startImageStream(
          (imageFromStream) => {
            if (!isWorking)
              {
                isWorking = true,
                imgCamera = imageFromStream,
                runModelOnStreamFrames(),
              }
          },
        );
      });
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }

  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      final String imagePath = await saveImage(imgCamera);

      var recognitions = await Tflite.runModelOnFrame(
        bytesList: imgCamera.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: imgCamera.height,
        imageWidth: imgCamera.width,
        imageMean: 127.5,
        imageStd: 127.5,
        rotation: 90,
        numResults: 1,
        threshold: 0.1,
        asynch: true,
      );

      result = "";
      recognitions?.forEach((response) {
        result += response["label"] +
            " " +
            (response["confidence"] as double).toStringAsFixed(2);
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  void _start() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (Timer t) {
      setState(() {
        _result =
            '${_stopwatch.elapsed.inMinutes.toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}:${(_stopwatch.elapsed.inMilliseconds % 100).toString().padLeft(2, '0')}';
      });
    });
    _stopwatch.start();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await Tflite.close();
    mlInferenceController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _start();
    initCamera();
    loadModel();

    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
  }

  void _stop() {
    _timer.cancel();
    _stopwatch.stop();
  }

  void showInSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    return Scaffold(
        body: Container(
            child: Column(
      children: [
        Stack(
          children: [
            Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 1,
                child: AspectRatio(
                    aspectRatio: 1,
                    child: CameraPreview(mlInferenceController))),
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 17,
                    fontFamily: 'RobotoSlab',
                    fontWeight: FontWeight.bold,
                    backgroundColor: Colors.black87,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 50,
              left: 10,
              child: Container(
                child: Text(
                  'Time:  $_result \nAccelerometer: $accelerometer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontFamily: 'RobotoSlab',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 10,
              child: SizedBox(
                width: 130,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  onPressed: () {
                    dispose();
                    _stop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomePage(),
                      ),
                    );
                  },
                  child: Text(
                    'Exit',
                    style: TextStyle(color: Colors.white, fontSize: 19),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    )));
  }
}
