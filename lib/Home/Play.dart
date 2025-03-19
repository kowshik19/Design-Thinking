import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:appwrite/appwrite.dart';

class VideoPlayScreen extends StatefulWidget {
  final String folder;
  const VideoPlayScreen({super.key, required this.folder});

  @override
  State<VideoPlayScreen> createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  VideoPlayerController? _controller;
  late Client client;
  late Storage storage;
  Map<String, String> flutterVideos = {
    "What is Design Thinking": "67d7ce26000d3520ae8a",
    "Empathize": "67d7ce9d003ac9672d11",
    "Define": "67d7ceb000105e38c7b8",
    "Ideate": "67d7ceb8003ae649eb81",
    "Prototype": "67d7cec800034d71269b",
    "Test": "67d7cecf00125a2cdb53",
  };

  @override
  void initState() {
    super.initState();
    client = Client()
        .setEndpoint('https://cloud.appwrite.io/v1')
        .setProject("67d037a100204739d319");
    storage = Storage(client);

    fetchVideoUrl(); // <-- Fetch video when screen loads
  }

  Future<void> fetchVideoUrl() async {
    try {
      print("Fetching video from Appwrite...");

      // Ensure fileId is retrieved correctly
      String? fileId = flutterVideos[widget.folder];
      if (fileId == null) {
        print("Error: No file ID found for ${widget.folder}");
        return;
      }

      final Uint8List response = await storage.getFileView(
        bucketId: '67d039f800168f252c0c',
        fileId: fileId,
      );

      print("Video fetched successfully! Writing to temporary storage...");

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/video.mp4');
      await file.writeAsBytes(response);

      print("File written successfully at: ${file.path}");

      _controller = VideoPlayerController.file(file)
        ..initialize()
            .then((_) {
              print("Video initialized successfully.");
              setState(() {});
            })
            .catchError((error) {
              print("Error initializing video: $error");
            });
    } catch (e) {
      print("Error fetching video: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      body: Column(
        children: [
          Text(
            widget.folder,
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 16),
          if (_controller != null && _controller!.value.isInitialized)
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      FullScreenVideo(controller: _controller!),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.white70,
                          child: Icon(Icons.fullscreen, color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            CircularProgressIndicator(), // Show loading while fetching video

          SizedBox(height: 10),

          /// Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, size: 30, color: Colors.grey),
                onPressed: () {
                  if (_controller == null ||
                      !_controller!.value.isInitialized) {
                    print(
                      "Error: Video controller is null or not initialized.",
                    );
                    return;
                  }
                  print("Seeking backward...");
                  _controller?.seekTo(
                    _controller!.value.position - Duration(seconds: 10),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _controller != null && _controller!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 50,
                  color: Colors.green,
                ),
                onPressed: () {
                  if (_controller == null) {
                    print("Error: Video controller is null.");
                    return;
                  }
                  if (!_controller!.value.isInitialized) {
                    print("Error: Video controller is not initialized.");
                    return;
                  }

                  setState(() {
                    if (_controller!.value.isPlaying) {
                      print("Pausing video...");
                      _controller!.pause();
                    } else {
                      print("Playing video...");
                      _controller!.play();
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, size: 30, color: Colors.grey),
                onPressed: () {
                  if (_controller == null ||
                      !_controller!.value.isInitialized) {
                    print(
                      "Error: Video controller is null or not initialized.",
                    );
                    return;
                  }
                  print("Seeking forward...");
                  _controller?.seekTo(
                    _controller!.value.position + Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Full-screen video player
class FullScreenVideo extends StatelessWidget {
  final VideoPlayerController controller;
  const FullScreenVideo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              print("Pausing full-screen video...");
              controller.pause();
            } else {
              print("Playing full-screen video...");
              controller.play();
            }
          },
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
