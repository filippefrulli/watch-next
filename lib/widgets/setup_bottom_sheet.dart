import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watch_next/objects/region.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/query_cache_service.dart';
import 'package:watch_next/services/user_action_service.dart';

/// A two-step bottom sheet that collects region and streaming services
/// on the user's first GO press, then calls [onComplete] when done.
class SetupBottomSheet extends StatefulWidget {
  final VoidCallback onComplete;

  const SetupBottomSheet({super.key, required this.onComplete});

  @override
  State<SetupBottomSheet> createState() => _SetupBottomSheetState();
}

class _SetupBottomSheetState extends State<SetupBottomSheet> {
  // 0 = region, 1 = streaming services
  int _step = 0;

  // Region state
  int _selectedRegionIndex = -1;
  String? _detectedRegion;

  // Streaming services state
  late Future<dynamic> _providersFuture;
  final Map<int, String> _selectedServices = {};

  @override
  void initState() {
    super.initState();
    _loadDetectedRegion();
  }

  Future<void> _loadDetectedRegion() async {
    final prefs = await SharedPreferences.getInstance();
    final region = prefs.getString('region');

    // Sort regions alphabetically
    availableRegions.sort((a, b) => a.englishName!.compareTo(b.englishName!));

    if (region != null && mounted) {
      // Find the pre-selected region index
      final index = availableRegions.indexWhere((r) => r.iso == region);
      setState(() {
        _detectedRegion = region;
        _selectedRegionIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // If on streaming step, go back to region step instead of closing
        if (_step == 1) {
          setState(() => _step = 0);
        }
        // On region step, do nothing — user must complete setup
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _step == 0 ? "select_country".tr() : "select_streaming".tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _step == 0 ? "setup_region_subtitle".tr() : "setup_streaming_subtitle".tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 16),
                // Content
                Expanded(
                  child: _step == 0 ? _buildRegionList(scrollController) : _buildStreamingGrid(scrollController),
                ),
                const SizedBox(height: 12),
                // Action button
                _buildActionButton(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegionList(ScrollController scrollController) {
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
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: availableRegions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outline,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              return _regionTile(
                availableRegions[index].englishName!,
                availableRegions[index].iso!,
                index,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _regionTile(String country, String iso, int index) {
    bool isSelected = _selectedRegionIndex == index;

    return Material(
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
      child: InkWell(
        onTap: () async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('region', iso);
          prefs.setInt('region_number', index);
          prefs.setBool('seen', true);

          setState(() {
            _selectedRegionIndex = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.orange : Theme.of(context).colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  country,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.orange : Colors.white,
                      ),
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingGrid(ScrollController scrollController) {
    return FutureBuilder<dynamic>(
      future: _providersFuture,
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
                    child: const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "error_occurred".tr(),
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _providersFuture = HttpService().getWatchProvidersByLocale();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "retry".tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                  controller: scrollController,
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
                          if (_selectedServices.containsKey(snapshot.data[index].providerId)) {
                            _selectedServices.removeWhere((key, value) => key == snapshot.data[index].providerId);
                          } else {
                            _selectedServices[snapshot.data[index].providerId] = snapshot.data[index].logoPath;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _gridItem(
                        snapshot.data[index].logoPath,
                        snapshot.data[index].providerId,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }
      },
    );
  }

  Widget _gridItem(String logo, int providerId) {
    bool isSelected = _selectedServices.keys.contains(providerId);

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

  Widget _buildActionButton() {
    final bool canProceed = _step == 0 ? _selectedRegionIndex > -1 : _selectedServices.isNotEmpty;

    if (!canProceed) return const SizedBox.shrink();

    return Container(
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
          onTap: _step == 0 ? _onRegionDone : _onStreamingDone,
          child: Center(
            child: Text(
              _step == 0 ? "next".tr() : "done".tr().toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  void _onRegionDone() {
    // Log region change if it changed from auto-detected
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) {
      final currentRegion = p.getString('region');
      if (_detectedRegion != currentRegion && currentRegion != null) {
        UserActionService.logRegionChanged(
          fromRegion: _detectedRegion ?? 'none',
          toRegion: currentRegion,
        );
      }
    });

    // Move to streaming services step
    _providersFuture = HttpService().getWatchProvidersByLocale();
    setState(() {
      _step = 1;
    });
  }

  Future<void> _onStreamingDone() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('setup_complete', true);

    await DatabaseService.saveStreamingServices(_selectedServices);
    await QueryCacheService.clearAllCaches();

    UserActionService.logStreamingServicesUpdated();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onComplete();
    }
  }
}

/// Show the setup bottom sheet and return a Future that completes when setup is done.
Future<bool> showSetupBottomSheet(BuildContext context) async {
  bool completed = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (context) {
      return SetupBottomSheet(
        onComplete: () {
          completed = true;
        },
      );
    },
  );

  return completed;
}
