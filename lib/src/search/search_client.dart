import 'dart:convert';

import '../../youtube_explode_dart.dart';
import '../extensions/helpers_extension.dart';
import '../reverse_engineering/pages/search_page.dart';

/// YouTube search queries.
class SearchClient {
  final YoutubeHttpClient _httpClient;

  /// Initializes an instance of [SearchClient]
  SearchClient(this._httpClient);

  String? nextToken;

  /// Enumerates videos returned by the specified search query
  /// (from the video search page).
  /// The videos are sent in batch of 20 videos.
  /// You [VideoSearchList.nextPage] to get the next batch of videos.
  Future<VideoSearchList> search(String searchQuery,
      {String ytSearchFilterId = TypeFilters.video,
      String? priorityNextToken}) async {
    final page = await SearchPage.get(_httpClient, searchQuery,
        ytSearchFilterId: ytSearchFilterId, priorityNextToken: priorityNextToken);

    nextToken = page.nextToken;

    return VideoSearchList(
      page.searchContent
          .whereType<SearchVideo>()
          .map(
            (e) => Video(
              e.id,
              e.title,
              e.author,
              ChannelId(e.channelId),
              e.uploadDate.toDateTime(),
              e.uploadDate?.toString(),
              null,
              e.description,
              e.duration.toDuration(),
              ThumbnailSet(e.id.value),
              null,
              Engagement(e.viewCount, null, null),
              e.isLive,
            ),
          )
          .toList(),
      page,
      _httpClient,
    );
  }

  @Deprecated('Use SearchClient.search')
  Future<VideoSearchList> getVideos(
    String searchQuery, {
    String ytSearchFilterId = "",
  }) =>
      search(searchQuery, ytSearchFilterId: ytSearchFilterId);

  /// Enumerates results returned by the specified search query.
  /// The contents are sent in batch of 20 elements.
  /// The list can either contain a [SearchVideo], [SearchPlaylist] or a [SearchChannel].
  /// You [SearchList.nextPage] to get the next batch of content.
  Future<SearchList> searchContent(
    String searchQuery, {
    String ytSearchFilterId = "",
  }) async {
    final page = await SearchPage.get(_httpClient, searchQuery, ytSearchFilterId: ytSearchFilterId);

    return SearchList(page.searchContent, page, _httpClient);
  }

  /// Enumerates results returned by the specified search query.
  /// The contents are sent in batch of 20 elements.
  /// The list can either contain a [SearchVideo], [SearchPlaylist] or a [SearchChannel].
  /// You [SearchList.nextPage] to get the next batch of content.
  /// Same as [SearchClient.search]
  Future<VideoSearchList> call(
    String searchQuery, {
    String ytSearchFilterId = "",
  }) async =>
      search(searchQuery, ytSearchFilterId: ytSearchFilterId);

  /// Returns the suggestions youtube provide while search on the page.
  Future<List<String>> getQuerySuggestions(String query) async {
    final request = await _httpClient.get(
      Uri.parse(
        'https://suggestqueries-clients6.youtube.com/complete/search?client=youtube&hl=en&gl=en&q=${Uri.encodeComponent(query)}&callback=func',
      ),
    );
    final body = request.body;
    final startIndex = body.indexOf('func(');
    final jsonStr = body.substring(startIndex + 5, body.length - 1);
    final data = json.decode(jsonStr) as List<dynamic>;
    final suggestions = data[1] as List<dynamic>;
    return suggestions.map((e) => e[0]).toList().cast<String>();
  }

  /// Queries to YouTube to get the results.
  /// You need to manually read [SearchQuery.content] and/or [SearchQuery.relatedVideos].
  /// For most cases [SearchClient.search] is enough.
  Future<SearchQuery> searchRaw(
    String searchQuery, {
    String ytSearchFilterId = "",
  }) =>
      SearchQuery.search(_httpClient, searchQuery, ytSearchFilterId: ytSearchFilterId);

  @Deprecated('Use searchRaw')
  Future<SearchQuery> queryFromPage(
    String searchQuery, {
    String ytSearchFilterId = "",
  }) =>
      searchRaw(searchQuery, ytSearchFilterId: ytSearchFilterId);
}
