import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:society_app/core/network/error_message_mapper.dart';
import 'package:society_app/core/network/token_provider.dart';
final Map<String, Uint8List> imageMemoryCache = {}; // FAST memory cache

class FullScreenGallery extends ConsumerStatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends ConsumerState<FullScreenGallery> {
  late PageController _controller;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // 🔹 TOP BAR WITH SHARE BUTTON
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Gallery", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () async {
  final imageUrl = widget.images[currentIndex];
  final fileName = imageUrl.split('/').last;

  try {
    final tempDir = await getTemporaryDirectory();
    final filePath = "${tempDir.path}/$fileName";
    final file = File(filePath);

    // If file is NOT saved yet, get bytes from memory cache or network
    if (!await file.exists()) {
      Uint8List bytes;

      if (imageMemoryCache.containsKey(imageUrl)) {
        // Load from memory cache
        bytes = imageMemoryCache[imageUrl]!;
      } else {
        // Force download IF not cached anywhere
        bytes = await _loadProtectedImage(imageUrl);
      }

      // Save to file
      await file.writeAsBytes(bytes, flush: true);
    }

    // NOW SHARE THE CACHED FILE
    await Share.shareXFiles([XFile(filePath)], text: "Shared Image");

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ErrorMessageMapper.map(e))),
    );
  }
},
          ),
        ],
      ),

      // 🔹 MAIN VIEWER WITH ZOOM + JWT IMAGE LOADING
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        itemBuilder: (ctx, idx) {
          return FutureBuilder<Uint8List>(
            future: _loadProtectedImage(widget.images[idx]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 100,
                  ),
                );
              }

              return InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔹 LOAD IMAGE USING JWT TOKEN
  Future<Uint8List> _loadProtectedImage(String url) async {
  final fileName = url.split('/').last;

  // 1️⃣ CHECK MEMORY CACHE
  if (imageMemoryCache.containsKey(url)) {
    debugPrint("⚡ Loaded from MEMORY cache: $url");
    return imageMemoryCache[url]!;
  }

  // 2️⃣ CHECK DISK CACHE
  final tempDir = await getTemporaryDirectory();
  final filePath = "${tempDir.path}/$fileName";
  final file = File(filePath);

  if (await file.exists()) {
    final bytes = await file.readAsBytes();
    imageMemoryCache[url] = bytes; // store to memory
    debugPrint("💾 Loaded from DISK cache: $filePath");
    return bytes;
  }

  // 3️⃣ DOWNLOAD (ONLY IF NOT CACHED)
  debugPrint("⬇ Downloading image: $url");

  final response = await http.get(
    Uri.parse(url),
    headers: {
      "Authorization": "Bearer ${ref.read(tokenProvider).accessToken}",
      "Accept": "*/*",
    },
  );

  if (response.statusCode == 200) {
    final bytes = response.bodyBytes;

    // Save to temp folder
    await file.writeAsBytes(bytes, flush: true);

    // Save to memory cache
    imageMemoryCache[url] = bytes;

    return bytes;
  } else {
    throw Exception("HTTP ${response.statusCode}");
  }
}

}
