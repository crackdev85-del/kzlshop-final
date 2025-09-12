import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moegyi/constants.dart';

class Announcement {
  final String title;
  final String message;
  final String imageUrl;

  Announcement(
      {required this.title, required this.message, required this.imageUrl});

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Announcement(
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class AnnouncementSlideshow extends StatefulWidget {
  const AnnouncementSlideshow({super.key});

  @override
  State<AnnouncementSlideshow> createState() => _AnnouncementSlideshowState();
}

class _AnnouncementSlideshowState extends State<AnnouncementSlideshow> {
  final PageController _pageController = PageController();
  Timer? _timer;
  List<Announcement> _announcements = [];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(announcementsCollectionPath)
          .orderBy('createdAt', descending: true)
          .get();
      if (snapshot.docs.isNotEmpty) {
        if (mounted) {
          setState(() {
            _announcements = snapshot.docs
                .map((doc) => Announcement.fromFirestore(doc))
                .toList();
          });
          _startTimer();
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_announcements.isNotEmpty) {
        int nextPage = (_currentPage + 1) % _announcements.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_announcements.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no announcements
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _announcements.length,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          Uint8List? imageBytes;
          if (announcement.imageUrl.isNotEmpty &&
              announcement.imageUrl.startsWith('data:image')) {
            try {
              imageBytes = base64Decode(announcement.imageUrl.split(',').last);
            } catch (e) {
              // Handle invalid base64 string
              imageBytes = null;
            }
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageBytes != null)
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.campaign, size: 50, color: Colors.grey),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.6)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        if (announcement.message.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            announcement.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  blurRadius: 8.0,
                                  color: Colors.black,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
