import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/pages/region_page.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/query_cache_service.dart';
import 'package:watch_next/services/user_action_service.dart';

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
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "select_streaming".tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "streaming_subtitle".tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                    fontSize: 14,
                    height: 1.4,
                  ),
            ),
          ),
          const SizedBox(height: 20),
          _stepDots(1),
          const SizedBox(height: 20),
          Expanded(child: streamingGrid()),
          const SizedBox(height: 8),
          _selectionCount(),
          const SizedBox(height: 8),
          closeButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _selectionCount() {
    if (selectedStreamingServices.isEmpty) return const SizedBox.shrink();
    final count = selectedStreamingServices.length;
    return Text(
      "services_selected".tr(namedArgs: {'count': '$count'}),
      style: TextStyle(
        color: Colors.orange[300],
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _stepDots(int step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == step ? 20 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: i == step ? Colors.orange : Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget streamingGrid() {
    return FutureBuilder<dynamic>(
      future: resultList,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    "error_occurred".tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        resultList = HttpService().getWatchProvidersByLocale();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('retry'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  await DatabaseService.saveStreamingServices(selectedStreamingServices);
                  await QueryCacheService.clearAllCaches();
                  UserActionService.logStreamingServicesUpdated();

                  if (mounted && seen) {
                    prefs.setBool('skip_intro', true);
                    Navigator.of(context).pop();
                  } else if (mounted && !seen) {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, _) => const RegionIntroPage(),
                        transitionsBuilder: (context, animation, _, child) => SlideTransition(
                          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                              .chain(CurveTween(curve: Curves.easeInOut))
                              .animate(animation),
                          child: child,
                        ),
                        transitionDuration: const Duration(milliseconds: 550),
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
