import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContIdScanner extends StatefulWidget {
  const ContIdScanner({super.key});

  @override
  State<ContIdScanner> createState() => _ContIdScannerState();
}

class _ContIdScannerState extends State<ContIdScanner> {
  File? _image;
  String? _text;
  RegExp idContRegex = RegExp(r'^.{4} \d{6} [0-9]$');
  RegExp noSpaceIdRegex = RegExp(r'^.{4}\d{6}[0-9]$');
  RegExp bicCodeRegex = RegExp(r'^.{4}$');

  // Pick an image or take a photo using image_picker package
  Future getImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image != null) {
        File rotatedImage =
            await FlutterExifRotation.rotateImage(path: image.path);
        processImage(rotatedImage);
        setState(() {
          _image = rotatedImage;
        });
      }
    } on PlatformException catch (e) {
      print(e);
    }
  }

  // Detect container ID through image using google mlkit text recognition package
  Future processImage(File imageFile) async {
    final InputImage inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);
    if (recognizedText.text != "") {
      outerLoop:
      for (TextBlock block in recognizedText.blocks) {
        // This condition is for container ID that's NOT in the same line
        // in the image
        if (bicCodeRegex.hasMatch(block.lines[0].text)) {
          String mergeBlock = block.text.replaceAll(RegExp(r'\s+'), '');
          if (noSpaceIdRegex.hasMatch(mergeBlock)) {
            String finalIdCont =
                "${mergeBlock.substring(0, 4)} ${mergeBlock.substring(4, 10)} ${mergeBlock.substring(10)}";
            setState(() {
              _text = finalIdCont;
            });
            break outerLoop;
          }
        }
        for (TextLine line in block.lines) {
          // This condition is for container ID that's in the same line
          // in the image
          if (idContRegex.hasMatch(line.text)) {
            String text = line.text;
            setState(() {
              _text = text;
            });
            break outerLoop;
          } else {
            setState(() {
              _text = "Found the text, but didn't see the container ID.";
            });
          }
        }
      }
    } else {
      setState(() {
        _text = "This picture does not contain any text.";
      });
    }
    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ContainerID scanner',
          style:
              Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16.sp),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 8,
              child: SizedBox(
                child: Column(
                  children: [
                    SizedBox(
                      height: 30.h,
                    ),
                    _image != null
                        ? Image.file(
                            _image!,
                            width: 300.h,
                            height: 300.h,
                          )
                        : Image.asset(
                            "assets/images/blank_camera.jpg",
                            width: 300.h,
                            height: 300.h,
                            fit: BoxFit.cover,
                          ),
                    SizedBox(
                      height: 30.h,
                    ),
                    Container(
                      constraints: BoxConstraints(maxWidth: 300.w),
                      child: Center(
                        child: Text(
                          _text != null ? _text! : 'Nothing',
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Colors.black, fontSize: 16.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ImagePickerButton(
                    onTap: () {
                      getImage(ImageSource.gallery);
                    },
                    icon: Icons.image_outlined,
                    title: 'Choose from gallery',
                  ),
                  ImagePickerButton(
                    onTap: () {
                      getImage(ImageSource.camera);
                    },
                    icon: Icons.camera_outlined,
                    title: 'Take a photo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePickerButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const ImagePickerButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.white.withOpacity(0.2),
      highlightColor: Colors.white.withOpacity(0.2),
      onTap: onTap,
      child: Ink(
        width: 190.w,
        height: 50.h,
        decoration: const BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.all(1.w),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );
  }
}
