import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:watch_next/services/http_service.dart';
import 'package:watch_next/services/database_service.dart';
import 'package:watch_next/objects/streaming_service.dart';

class MediaDetailPage extends StatefulWidget {
  final int mediaId;
  final String title;
  final bool isMovie;
  final String? posterPath;

  const MediaDetailPage({
    super.key,
    required this.mediaId,
    required this.title,
    required this.isMovie,
    this.posterPath,
  });

  @override
  State<MediaDetailPage> createState() => _MediaDetailPageState();
}

class _MediaDetailPageState extends State<MediaDetailPage> {
  bool _isLoading = true;
  List<StreamingService> _availableProviders = [];
  List<int> _userServiceIds = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'viewed_media_detail',
        parameters: <String, Object>{
          'media_id': widget.mediaId,
          'title': widget.title,
          'is_movie': widget.isMovie ? 'true' : 'false',
        },
      );

      // Load user's streaming service IDs
      _userServiceIds = await DatabaseService.getStreamingServicesIds();

      // Fetch watch provider IDs for this media
      List<int> providerIds;
      if (widget.isMovie) {
        providerIds = await HttpService().getWatchProviders(widget.mediaId);
      } else {
        providerIds = await HttpService().getWatchProvidersSeries(widget.mediaId);
      }

      // Get all available providers with details
      final allProviders = await HttpService().getWatchProvidersByLocale();

      // Filter to only show providers that have this content
      final availableProviders = allProviders.where((service) => providerIds.contains(service.providerId)).toList();

      setState(() {
        _availableProviders = availableProviders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load streaming information';
      });

      FirebaseAnalytics.instance.logEvent(
        name: 'media_detail_error',
        parameters: <String, Object>{
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(11, 14, 23, 1),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Poster
            _buildPoster(),
            const SizedBox(height: 32),
            // Streaming providers section
            _buildStreamingProvidersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster() {
    if (widget.posterPath == null) {
      return Container(
        width: 250,
        height: 375,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: Colors.grey[600],
          size: 80,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: 'https://image.tmdb.org/t/p/w500${widget.posterPath}',
        width: 250,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          width: 250,
          height: 375,
          color: Colors.grey[800],
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 250,
          height: 375,
          color: Colors.grey[800],
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[600],
            size: 64,
          ),
        ),
      ),
    );
  }

  Widget _buildStreamingProvidersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available On',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_availableProviders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[800]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Not available on any streaming service in your region',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._availableProviders.map((provider) {
            final isSubscribed = _userServiceIds.contains(provider.providerId);
            return _buildProviderCard(provider, isSubscribed);
          }).toList(),
      ],
    );
  }

  Widget _buildProviderCard(StreamingService provider, bool isSubscribed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSubscribed ? Colors.green : Colors.grey[800]!,
          width: isSubscribed ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Provider logo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: provider.logoPath != null
                ? CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/original${provider.logoPath}',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.tv,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[800],
                    child: Icon(
                      Icons.tv,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          // Provider name
          Expanded(
            child: Text(
              provider.providerName ?? 'Unknown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Checkmark if subscribed
          if (isSubscribed)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}
