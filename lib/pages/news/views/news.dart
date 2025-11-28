import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/news_view_model.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<NewsViewModel>(context, listen: false).loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NewsViewModel>(
      builder: (context, vm, child) {

        if (vm.isLoading) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDFBF7),
            appBar: AppBar(
              title: const Text(
                "News",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF6389E2),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFDFBF7),
            appBar: AppBar(
              title: const Text(
                "News",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF6389E2),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(vm.error!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: vm.loadNews,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF7),
          appBar: AppBar(
            title: const Text(
              "News",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF6389E2),
            centerTitle: true,
          ),

          body: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vm.news.length,
            itemBuilder: (_, i) {
              final n = vm.news[i];
              final userId = vm.currentUserId ?? "";
              final liked = n.ratings.contains(userId);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------- FOTO ----------
                    if (n.photoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        child: Image.network(
                          n.photoUrl,
                          fit: BoxFit.cover,
                          height: 180,
                          width: double.infinity,
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.eventName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B3B3B),
                            ),
                          ),
                          const SizedBox(height: 6),

                          Text(
                            n.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.3,
                              color: Color(0xFF5A5A5A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => vm.toggleLike(n.id),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.favorite,
                                  color: liked ? Colors.red : Colors.grey,
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${n.ratings.length}",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: liked ? Colors.red : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
