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

  // Dummy Appwrite File IDs (Replace with actual file IDs from Appwrite)
  Map<String, String> flutterVideos = {
    "Flutter Introduction": "67d03b4c0007fd85311b",
    "State Management": "chapter_1",
  };

  Map<String, String> dartVideos = {
    "Dart Basics": "your_file_id_3",
    "Asynchronous Programming": "your_file_id_4",
  };

  @override
  void initState() {
    super.initState();

    // Initialize Appwrite Client and Storage
    client =
        Client()
          ..setEndpoint(
            "https://cloud.appwrite.io/v1",
          ) // Your Appwrite endpoint
          ..setProject("67d037a100204739d319"); // Your Appwrite project ID

    storage = Storage(client);

    if (widget.folder == "Flutter Basics") {
      selectedVideos = flutterVideos.keys.toList();
    } else if (widget.folder == "Dart Fundamentals") {
      selectedVideos = dartVideos.keys.toList();
    }
  }

  Future<void> loadVideo(String fileId) async {
    try {
      final response = await storage.getFileView(
        bucketId: "67d039f800168f252c0c",
        fileId: fileId,
      );

      // Convert Uint8List to a data URI
      final videoBytes = await response;
      final videoUri =
          Uri.dataFromBytes(videoBytes, mimeType: "video/mp4").toString();

      setState(() {
        videoUrl = videoUri;
        _controller?.dispose();
        _controller = VideoPlayerController.network(videoUrl)
          ..initialize().then((_) {
            setState(() {});
          });
      });
    } catch (e) {
      print("Error loading video: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load video")));
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
            ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.replay_10, size: 30, color: Colors.grey),
                onPressed: () {
                  if (_controller != null) {
                    _controller!.seekTo(
                      _controller!.value.position - Duration(seconds: 10),
                    );
                  }
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
                  if (_controller != null) {
                    setState(() {
                      _controller!.value.isPlaying
                          ? _controller!.pause()
                          : _controller!.play();
                    });
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.forward_10, size: 30, color: Colors.grey),
                onPressed: () {
                  if (_controller != null) {
                    _controller!.seekTo(
                      _controller!.value.position + Duration(seconds: 10),
                    );
                  }
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
                              onTap: () {
                                String fileId =
                                    widget.folder == "Flutter Basics"
                                        ? flutterVideos[selectedVideos[index]]!
                                        : dartVideos[selectedVideos[index]]!;
                                loadVideo(fileId);
                              },
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
              controller.pause();
            } else {
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
