import 'package:design_thinking/Home/Account/Quiz.dart';
import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/Quiz/quizsplash.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoPlayScreen extends StatefulWidget {
  final String moduleName;
  final List<Map<String, dynamic>> lessons;

  const VideoPlayScreen({
    Key? key,
    required this.moduleName,
    required this.lessons,
  }) : super(key: key);

  @override
  State<VideoPlayScreen> createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int currentIndex = 0;
  bool isLoadingVideo = true;
  Set<String> completedLessons = {};
  bool isDisposed = false;
  double? resumeAtPosition;
  VoidCallback? _videoListener;

  @override
  void initState() {
    super.initState();
    fetchCompletedLessons().then((_) => loadVideo(currentIndex));
  }

  Future<void> fetchCompletedLessons() async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("completedLessons")
              .doc(widget.moduleName)
              .get();

      if (doc.exists) {
        completedLessons = Set<String>.from(doc.data()?['lessons'] ?? []);
      }
    } catch (e) {
      print("Error fetching completed lessons: $e");
    }
  }

  Future<void> loadVideo(int index) async {
    final lesson = widget.lessons[index];
    final name = lesson['title'];

    // Show black screen while loading
    setState(() {
      isLoadingVideo = true;
    });

    // Cleanup existing player
    await stopVideo();

    try {
      final ref = FirebaseStorage.instance.ref().child(
        '${widget.moduleName}/$name.mp4',
      );
      final url = await ref.getDownloadURL();

      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();

      // Resume if applicable
      if (resumeAtPosition != null && index == currentIndex) {
        await _videoController!.seekTo(
          Duration(seconds: resumeAtPosition!.toInt()),
        );
      }

      _videoListener = () async {
        if (!_videoController!.value.isInitialized || isDisposed) return;
        final isFinished =
            _videoController!.value.position >=
            _videoController!.value.duration;
        if (isFinished && mounted && !completedLessons.contains(name)) {
          await markLessonCompleted(name);
          await autoPlayNextLesson();
        }

        // Save the current position
        final currentPosition = _videoController!.value.position.inSeconds;
        await saveVideoPosition(currentPosition);
      };

      _videoController!.addListener(_videoListener!);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );

      if (mounted) {
        setState(() {
          isLoadingVideo = false;
        });
      }
    } catch (e) {
      print("Error loading video: $e");
      if (mounted) {
        setState(() => isLoadingVideo = false);
      }
    }
  }

  Future<void> markModuleAsCompleted() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Add to completedModules
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('completedModules')
          .add({'name': widget.moduleName});

      // Remove from ongoingModules
      QuerySnapshot ongoingSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('ongoingModules')
              .where('name', isEqualTo: widget.moduleName)
              .get();

      for (var doc in ongoingSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print("Error marking module as completed from VideoPlayScreen: $e");
    }
  }

  Future<void> saveVideoPosition(int position) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'lastVideoPosition': position,
      'lastViewedModule': widget.moduleName,
      'lastLesson': widget.lessons[currentIndex]['title'],
    });
  }

  Future<void> stopVideo() async {
    if (_videoListener != null) {
      _videoController?.removeListener(_videoListener!);
    }

    // Pause video playback and dispose of the controllers
    _chewieController?.pause();
    _videoController?.pause();

    // Dispose the controllers (no need to await, as dispose is void)
    _chewieController?.dispose();
    _videoController?.dispose();

    // Clean up references
    _chewieController = null;
    _videoController = null;
    _videoListener = null;
  }

  Future<void> autoPlayNextLesson() async {
    if (currentIndex + 1 < widget.lessons.length) {
      final nextIndex = currentIndex + 1;
      final nextLessonTitle = widget.lessons[nextIndex - 1]['title'];

      final isUnlocked = completedLessons.contains(nextLessonTitle);
      if (isUnlocked || nextIndex == 0) {
        setState(() => currentIndex = nextIndex);
        await loadVideo(nextIndex);
      }
    }
  }

  Future<void> markLessonCompleted(String lessonName) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      completedLessons.add(lessonName);
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("completedLessons")
          .doc(widget.moduleName)
          .set({"lessons": completedLessons.toList()});
      if (mounted) setState(() {});
    } catch (e) {
      print("Error marking lesson completed: $e");
    }
  }

  bool get allLessonsCompleted =>
      completedLessons.length >= widget.lessons.length;

  @override
  void dispose() {
    isDisposed = true;
    stopVideo();
    super.dispose();
  }

  Widget buildPlaylist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            "Playlist",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.lessons.length,
          itemBuilder: (context, index) {
            final lesson = widget.lessons[index];
            final lessonTitle = lesson['title'] ?? "Untitled";
            final isLocked =
                index > 0 &&
                !completedLessons.contains(widget.lessons[index - 1]['title']);

            return ListTile(
              leading: Icon(
                isLocked ? Icons.lock_outline : Icons.play_circle_fill,
                color: isLocked ? Colors.grey : Colors.green,
              ),
              title: Text(lessonTitle),
              subtitle: Text(lesson['duration'] ?? "0:00"),
              onTap:
                  isLocked
                      ? null
                      : () async {
                        await stopVideo();
                        setState(() => currentIndex = index);
                        await loadVideo(index);
                      },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lessons[currentIndex];
    final lessonTitle = lesson['title'] ?? "Lesson";
    final lessonDescription =
        lesson['description'] ?? "No description available.";

    return WillPopScope(
      onWillPop: () async {
        await stopVideo();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.moduleName)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child:
                      isLoadingVideo
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : (_chewieController != null
                              ? Chewie(controller: _chewieController!)
                              : const Center(
                                child: Text(
                                  "Video not available",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lessonTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lessonDescription,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed:
                    allLessonsCompleted
                        ? () async {
                          await stopVideo();

                          // Call function to mark module completed
                          await markModuleAsCompleted();

                          int quizIndex = getQuizIndexForModule(
                            widget.moduleName,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => Quizsplash(
                                    lessonIndex: quizIndex,
                                    lessonTitle: widget.moduleName,
                                    onComplete:
                                        () => Home(), // or pop if you prefer
                                  ),
                            ),
                          );
                        }
                        : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allLessonsCompleted ? Colors.teal : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Start Quiz"),
              ),
              const SizedBox(height: 20),
              buildPlaylist(),
            ],
          ),
        ),
      ),
    );
  }
}

int getQuizIndexForModule(String moduleName) {
  switch (moduleName) {
    case 'What is Design Thinking':
      return 0;
    case 'Empathize':
      return 1;
    case 'Define':
      return 2;
    case 'Ideate':
      return 3;
    case 'Prototype':
      return 4;
    case 'Test':
      return 5;
    default:
      return 0; // fallback
  }
}
