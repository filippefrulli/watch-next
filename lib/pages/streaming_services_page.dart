import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/home_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/query_cache_service.dart';

///This is the page where you enter the movie you saw
class StreamingServicesPage extends StatefulWidget {
  const StreamingServicesPage({
    super.key,
  });
  @override
  State<StreamingServicesPage> createState() => _StreamingServicesPage();
}

class _StreamingServicesPage extends State<StreamingServicesPage> with TickerProviderStateMixin {
  late Future<dynamic> resultList;

  Map<int, String> selectedStreamingServices = {};

  @override
  void initState() {
    resultList = HttpService().getWatchProvidersByLocale();
    DatabaseService.getAllStreamingServices().then(
      (mapList) => {
        for (var map in mapList)
          {
            selectedStreamingServices[int.parse(map['streaming_id'].toString())] = map['streaming_logo'].toString(),
          },
        setState(
          () {},
        )
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: body(),
    );
  }

  Widget body() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                "select_streaming".tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: streamingGrid(),
        ),
        const SizedBox(height: 16),
        closeButton(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget streamingGrid() {
    return FutureBuilder<dynamic>(
      future: resultList,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, size: 48, color: Colors.red),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "error_occurred".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        resultList = HttpService().getWatchProvidersByLocale();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Try Again",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data.length > 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (selectedStreamingServices.containsKey(snapshot.data[index].providerId)) {
                            selectedStreamingServices
                                .removeWhere((key, value) => key == snapshot.data[index].providerId);
                          } else {
                            selectedStreamingServices[snapshot.data[index].providerId] = snapshot.data[index].logoPath;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: gridItem(snapshot.data[index].logoPath, index, snapshot.data[index].providerId),
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
            ),
          );
        }
      },
    );
  }

  Widget closeButton() {
    return selectedStreamingServices.isNotEmpty
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.orange[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  bool seen = prefs.getBool('skip_intro') ?? false;
                  prefs.setBool('skip_intro', true);
                  await DatabaseService.saveStreamingServices(selectedStreamingServices);
                  // Clear query cache since streaming services changed
                  await QueryCacheService.clearAllCaches();
                  if (mounted && seen) {
                    Navigator.of(context).pop();
                  } else if (mounted && !seen) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const TabNavigationPage(),
                      ),
                    );
                  }
                },
                child: Center(
                  child: Text(
                    "done".tr().toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  Widget gridItem(String logo, int index, int providerId) {
    bool isSelected = selectedStreamingServices.keys.contains(providerId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 3,
          color: isSelected ? Colors.orange : Colors.grey[700]!,
        ),
        color: Theme.of(context).colorScheme.tertiary,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                fit: BoxFit.cover,
                imageUrl: "https://image.tmdb.org/t/p/original//$logo",
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.outline,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.tertiary,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
