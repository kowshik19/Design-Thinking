import 'package:design_thinking/Home/Home.dart';
import 'package:design_thinking/Quiz/quizsplash.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    initializeModule();
  }

  Future<void> initializeModule() async {
    await addToOngoingModulesIfNeeded();
    await fetchCompletedLessons();
    await loadResumeState();
    await loadVideo(currentIndex);
  }

  Future<void> addToOngoingModulesIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid);

    // ✅ Check if module is already marked as completed
    final completedModuleSnapshot =
        await userDocRef
            .collection("completedModules")
            .where("name", isEqualTo: widget.moduleName)
            .get();

    if (completedModuleSnapshot.docs.isNotEmpty) {
      // If module is already completed, skip adding to ongoingModules
      return;
    }

    // 🔄 Add to ongoingModules if not already there
    final ongoingRef = userDocRef.collection("ongoingModules");
    final existing =
        await ongoingRef.where("name", isEqualTo: widget.moduleName).get();

    if (existing.docs.isEmpty) {
      await ongoingRef.add({"name": widget.moduleName});
    }

    // 🔄 Update module status to "in progress"
    await userDocRef.collection("moduleStatus").doc(widget.moduleName).set({
      "status": "in progress",
      "updatedAt": FieldValue.serverTimestamp(),
    });
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

  Future<void> loadResumeState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('${widget.moduleName}_index') ?? 0;
    final savedPosition = prefs.getInt('${widget.moduleName}_position') ?? 0;

    setState(() {
      currentIndex = savedIndex;
      resumeAtPosition = savedPosition.toDouble();
    });
  }

  Future<void> saveLocalResume(int index, int positionSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('${widget.moduleName}_index', index);
    prefs.setInt('${widget.moduleName}_position', positionSeconds);
  }

  Future<void> clearResumePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${widget.moduleName}_index');
    await prefs.remove('${widget.moduleName}_position');
  }

  Future<void> loadVideo(int index) async {
    final lesson = widget.lessons[index];
    final name = lesson['title'];

    setState(() => isLoadingVideo = true);
    await stopVideo();

    try {
      final ref = FirebaseStorage.instance.ref().child(
        '${widget.moduleName}/$name.mp4',
      );
      final url = await ref.getDownloadURL();

      _videoController = VideoPlayerController.network(url);
      await _videoController!.initialize();

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

        final currentPosition = _videoController!.value.position.inSeconds;
        await saveVideoPosition(currentPosition);
        await saveLocalResume(currentIndex, currentPosition);
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
        setState(() => isLoadingVideo = false);
      }
    } catch (e) {
      print("Error loading video: $e");
      if (mounted) {
        setState(() => isLoadingVideo = false);
      }
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

  Future<void> markModuleAsCompleted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final completedRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("completedModules");

    final existing =
        await completedRef.where("name", isEqualTo: widget.moduleName).get();

    if (existing.docs.isEmpty) {
      await completedRef.add({"name": widget.moduleName});
    }

    final ongoingRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("ongoingModules");

    final ongoingSnap =
        await ongoingRef.where("name", isEqualTo: widget.moduleName).get();

    for (var doc in ongoingSnap.docs) {
      await doc.reference.delete();
    }

    // ✅ Mark the module as completed in moduleStatus
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("moduleStatus")
        .doc(widget.moduleName)
        .set({
          "status": "completed",
          "updatedAt": FieldValue.serverTimestamp(),
        });
  }

  Future<void> stopVideo() async {
    if (_videoListener != null) {
      _videoController?.removeListener(_videoListener!);
    }
    _chewieController?.pause();
    _videoController?.pause();
    _chewieController?.dispose();
    _videoController?.dispose();
    _chewieController = null;
    _videoController = null;
    _videoListener = null;
  }

  Future<void> autoPlayNextLesson() async {
    if (currentIndex + 1 < widget.lessons.length) {
      final nextIndex = currentIndex + 1;
      final prevLessonTitle = widget.lessons[nextIndex - 1]['title'];
      final isUnlocked = completedLessons.contains(prevLessonTitle);

      if (isUnlocked || nextIndex == 0) {
        setState(() => currentIndex = nextIndex);
        await loadVideo(nextIndex);
      }
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
        appBar: AppBar(
          leading: IconButton(
            onPressed:
                () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Home()),
                ),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          title: Text(widget.moduleName),
        ),
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
                          await clearResumePrefs();
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
                                    onComplete: () => Home(),
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
      return 0;
  }
}
