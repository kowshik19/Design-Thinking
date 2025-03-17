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
  String videoUrl = "";
  List<String> selectedVideos = [];
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
        .setEndpoint("https://cloud.appwrite.io/v1")
        .setProject("67d037a100204739d319");
    storage = Storage(client);
  }

  Future<void> fetchVideoUrl(String fileId) async {
    try {
      final Uint8List response = await storage.getFileView(
        bucketId: '67d039f800168f252c0c',
        fileId: fileId,
      );

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/video.mp4');
      await file.writeAsBytes(response);

      setState(() {
        _controller = VideoPlayerController.file(file)
          ..initialize().then((_) {
            setState(() {});
          });
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
            CircularProgressIndicator(),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, size: 30, color: Colors.grey),
                onPressed: () {
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
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, size: 30, color: Colors.grey),
                onPressed: () {
                  _controller?.seekTo(
                    _controller!.value.position + Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child:
                selectedVideos.isNotEmpty
                    ? ListView.builder(
                      itemCount: selectedVideos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                selectedVideos[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              leading: Icon(
                                Icons.video_library,
                                color: Colors.green,
                              ),
                              trailing: Icon(
                                Icons.play_arrow,
                                color: Colors.green,
                              ),
                              onTap: () {},
                            ),
                          ),
                        );
                      },
                    )
                    : Center(
                      child: Text(
                        "No videos available",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
          ),
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

extension on Uint8List {}

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
            controller.value.isPlaying ? controller.pause() : controller.play();
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
