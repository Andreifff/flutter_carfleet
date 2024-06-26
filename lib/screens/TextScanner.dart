import 'dart:io';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_application_2/screens/ResultScreen.dart';

class TextScanner extends StatefulWidget {
  const TextScanner({Key? key}) : super(key: key);

  @override
  State<TextScanner> createState() => _TextScannerState();
}

class _TextScannerState extends State<TextScanner> with WidgetsBindingObserver {
  bool isPermissionGranted = false;
  late final Future<void> future;
  List<String> carMakes = [];
  //For controlling camera
  CameraController? cameraController;
  final textRecogniser = TextRecognizer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    future = requestCameraPermission();
    loadCarMakes().then((makes) {
      setState(() {
        carMakes = makes;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopCamera();
    textRecogniser.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        cameraController != null &&
        cameraController!.value.isInitialized) {
      startCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          return Stack(
            children: [
              //Show camera content behind everything
              if (isPermissionGranted)
                FutureBuilder<List<CameraDescription>>(
                    future: availableCameras(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        initCameraController(snapshot.data!);
                        return Center(
                          child: CameraPreview(cameraController!),
                        );
                      } else {
                        return LinearProgressIndicator();
                      }
                    }),
              Scaffold(
                appBar: AppBar(
                  title: Text('Registration document scanning'),
                ),
                backgroundColor:
                    isPermissionGranted ? Colors.transparent : null,
                body: isPermissionGranted
                    ? Column(
                        children: [
                          Expanded(child: Container()),
                          Container(
                            padding: EdgeInsets.only(bottom: 30),
                            child: ElevatedButton(
                                onPressed: () {
                                  scanImage();
                                },
                                child: Text('Scan Text')),
                          ),
                        ],
                      )
                    : Center(
                        child: Container(
                          padding: EdgeInsets.only(left: 24.0, right: 24.0),
                          child: Text(
                            'Camera Permission Denied',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
            ],
          );
        });
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    isPermissionGranted = status == PermissionStatus.granted;
  }

  //It is used to initialise the camera controller
  //It also check the available camera in your device
  //It also check if camera controller is initialised or not.
  void initCameraController(List<CameraDescription> cameras) {
    if (cameraController != null) {
      return;
    }
    //Select the first ream camera
    CameraDescription? camera;
    for (var a = 0; a < cameras.length; a++) {
      final CameraDescription current = cameras[a];
      if (current.lensDirection == CameraLensDirection.back) {
        camera = current;
        break;
      }
    }
    if (camera != null) {
      cameraSelected(camera);
    }
  }

  Future<void> cameraSelected(CameraDescription camera) async {
    cameraController =
        CameraController(camera, ResolutionPreset.max, enableAudio: false);
    await cameraController?.initialize();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void startCamera() {
    if (cameraController != null) {
      cameraSelected(cameraController!.description);
    }
  }

  void stopCamera() {
    if (cameraController != null) {
      cameraController?.dispose();
    }
  }

  Future<List<String>> loadCarMakes() async {
    final String response =
        await rootBundle.loadString('assets/car_makes.json');
    final List<dynamic> data = json.decode(response);
    return data.cast<String>();
  }

  Future<void> scanImage() async {
    if (cameraController == null) {
      return;
    }
    final navigator = Navigator.of(context);
    try {
      final pictureFile = await cameraController!.takePicture();
      final file = File(pictureFile.path);

      // Cropping the image
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: file.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
        ],
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Crop Image',
              toolbarColor: Color.fromARGB(255, 0, 140, 255),
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Crop Image',
          ),
        ],
      );

      if (croppedFile != null) {
        File croppedImageFile =
            File(croppedFile.path); // Correctly converting CroppedFile to File
        final inputImage = InputImage.fromFile(croppedImageFile);
        final RecognizedText recognizedText =
            await textRecogniser.processImage(inputImage);
        //debug
        print("Loaded car makes: $carMakes");
        // Extract VIN and License Plate using Regex
        String vinPattern = r'\b[A-HJ-NPR-Z0-9]{17}\b';
        String licensePlatePattern =
            r'\b([A-Z]{2}-\d{2}-[A-Z]{3}|B-\d{2,3}-[A-Z]{3})\b';

        RegExp vinRegex = RegExp(vinPattern);
        RegExp licensePlateRegex = RegExp(licensePlatePattern);

        String? vin;
        String? licensePlate;
        String? carMake;

        // Search through all the blocks of text to find matches
        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            // Check for VIN
            if (vin == null && vinRegex.hasMatch(line.text)) {
              vin = vinRegex.firstMatch(line.text)?.group(0);
            }
            // Check for License Plate
            if (licensePlate == null && licensePlateRegex.hasMatch(line.text)) {
              licensePlate = licensePlateRegex.firstMatch(line.text)?.group(0);
            }
            print("Processing line: ${line.text}");
            //Check if car make is found
            if (carMake == null) {
              for (String make in carMakes) {
                if (line.text.toUpperCase().contains(make.toUpperCase())) {
                  carMake = make;
                  print("Car make found: $carMake");
                  break; // Stop searching once the first make is found
                }
              }
            }
          }
        }

        // Navigate to ResultScreen with extracted information
        await navigator.push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(
                text: recognizedText.text,
                licensePlate: licensePlate,
                vin: vin,
                carMake: carMake),
          ),
        );
      }
    } catch (e) {
      print('Error taking picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred when scanning text: $e'),
        ),
      );
    }
  }
}
