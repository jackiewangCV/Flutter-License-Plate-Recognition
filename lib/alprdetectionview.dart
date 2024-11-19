import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alprsdk_plugin/alprdetection_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alprsdk_plugin/alprsdk_plugin.dart';

// ignore: must_be_immutable
class AlprRecognitionView extends StatefulWidget {
  AlprDetectionViewController? faceDetectionViewController;

  AlprRecognitionView({super.key});

  @override
  State<StatefulWidget> createState() => AlprRecognitionViewState();
}

class AlprRecognitionViewState extends State<AlprRecognitionView> {
  dynamic _plates;
  final _alprsdkPlugin = AlprsdkPlugin();
  AlprDetectionViewController? faceDetectionViewController;

  @override
  void initState() {
    super.initState();
  }

  Future<void> faceRecognitionStart() async {
    setState(() {
      _plates = null;
    });

    await faceDetectionViewController?.startCamera(0);
  }

  Future<bool> onAlprDetected(plates) async {
    if (!mounted) return false;

    setState(() {
      _plates = plates;
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        faceDetectionViewController?.stopCamera();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ALPR'),
          toolbarHeight: 70,
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            FaceDetectionView(faceRecognitionViewState: this),
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CustomPaint(
                painter: FacePainter(plates: _plates),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaceDetectionView extends StatefulWidget
    implements AlprDetectionInterface {
  AlprRecognitionViewState faceRecognitionViewState;

  FaceDetectionView({super.key, required this.faceRecognitionViewState});

  @override
  Future<void> onAlprDetected(plates) async {
    await faceRecognitionViewState.onAlprDetected(plates);
  }

  @override
  State<StatefulWidget> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      return UiKitView(
        viewType: 'facedetectionview',
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
  }

  void _onPlatformViewCreated(int id) async {
    widget.faceRecognitionViewState.faceDetectionViewController =
        AlprDetectionViewController(id, widget);

    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.initHandler();

    await widget.faceRecognitionViewState.faceDetectionViewController
        ?.startCamera(0);
  }
}

class FacePainter extends CustomPainter {
  dynamic plates;
  FacePainter({required this.plates});

  @override
  void paint(Canvas canvas, Size size) {
    if (plates != null) {
      var paint = Paint();
      paint.color = const Color.fromARGB(0xff, 0xff, 0, 0);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 3;

      for (var plate in plates) {
        double xScale = plate['frameWidth'] / size.width;
        double yScale = plate['frameHeight'] / size.height;

        String title = "";
        Color color = const Color.fromARGB(0xff, 0, 0xff, 0);
        title = plate['number'].toString();

        TextSpan span =
            TextSpan(style: TextStyle(color: color, fontSize: 20), text: title);
        TextPainter tp = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(
            canvas, Offset(plate['x1'] / xScale, plate['y1'] / yScale - 30));

        paint.color = color;
        canvas.drawRect(
            Offset(plate['x1'] / xScale, plate['y1'] / yScale) &
                Size((plate['x2'] - plate['x1']) / xScale,
                    (plate['y2'] - plate['y1']) / yScale),
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
