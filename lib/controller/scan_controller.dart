import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tflite/flutter_tflite.dart';

class ScanController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    initCamera();
    initTFLite();
  }

  @override
  void dispose() {

    super.dispose();
    cameraController.dispose();
    Tflite.close();
  }

  late CameraController cameraController;
  late List<CameraDescription> cameras;

  var isCameraInitialized = false.obs;
  var cameraCount = 0;

  var x, y, w, h = 0.0;
  var label = "";

  Future <void>  initCamera() async {
    if (await Permission.camera.request().isGranted) {
      cameras = await availableCameras();

      cameraController = CameraController(cameras[0], ResolutionPreset.max,
          imageFormatGroup: ImageFormatGroup.yuv420);
      await cameraController.initialize().then((value) {
        // isCameraInitialized = true.obs;
        cameraController.startImageStream((image) {
          cameraCount++;
          if (cameraCount % 5 == 0) {
            cameraCount = 0;
            objectDetect(image);
          }
          update();
        });
      });
      isCameraInitialized(true);
      update();
    } else {
      print("Permission denied");
    }
  }

  Future initTFLite() async {
    await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false);
  }

  Future objectDetect(CameraImage image) async {
    var detector = await Tflite.runModelOnFrame(
        bytesList: image.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        asynch: true,
        imageHeight: image.height,
        imageWidth: image.width,
        imageMean: 127.5,
        imageStd: 127.5,
        numResults: 1,
        rotation: 90,
        threshold: 0.4);

    if (detector != null) {
      var ourDetectorObject = detector.first;
      if (detector.first['confidenceInClass'] > 0.5) {
        label = detector.first['detectedClass'].toString();
        h = ourDetectorObject['rect']['h'];
        w = ourDetectorObject['rect']['w'] ;
        x = ourDetectorObject['rect']['x'] * (500);
        y = ourDetectorObject['rect']['y'] * (700);
      }
      update();
    }
  }
}
