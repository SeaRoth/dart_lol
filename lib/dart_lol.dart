library dart_lol;

import 'dart:convert';

import 'package:dart_lol/LeagueStuff/responses/league_response.dart';
import 'package:dart_lol/dart_lol_api.dart';
import 'package:dart_lol/LeagueStuff/match.dart';
import 'package:localstorage/localstorage.dart';
import 'LeagueStuff/league_entry_dto.dart';
import 'LeagueStuff/rank.dart';
import 'LeagueStuff/summoner.dart';

class League extends LeagueAPI {
  League({required apiToken, required String server, int lowerLimitCount = 20, int upperLimitCount = 100}): super(apiToken: apiToken, server: server,
            appLowerLimitCount: lowerLimitCount,
            appUpperLimitCount: upperLimitCount);

  /// Summoner
  Future<LeagueResponse?> getSummonerFromDb(String puuid, bool fallbackAPI) async {
    final s = summonerStorage.getItem("$puuid");
    if (s != null) {
      final newS = Summoner.fromJson(json.decode(s));
      return returnLeagueResponse(summoner: newS);
    } else if (fallbackAPI) {
      final summoner = await getSummonerFromAPI(puuid);
      return summoner;
    }
    else {
      return null;
    }
  }
  /// Summoner


  /// Match
  Future<LeagueResponse> getMatch(String matchId, {bool fallbackAPI = true}) async {
    final valueMap = matchStorage.getItem("$matchId");
    if (valueMap != null) {
      final that = json.decode(valueMap);
      final matchFromJson = Match.fromJson((that));
      print(matchFromJson.metadata?.matchId);
      return returnLeagueResponse(match: matchFromJson);
    } else if (fallbackAPI == false)
      return returnLeagueResponse();
    else {
      var url =
          'https://$matchServer.api.riotgames.com/lol/match/v5/matches/$matchId?api_key=$apiToken';
      var match = await makeApiCall(url, APIType.match);
      return match;
    }
  }
  /// Match

  /// Match Histories
  Future<LeagueResponse> getMatchHistories(String puuid, {bool allMatches = true, int start = 0, int count = 100, bool fallBackAPI = true, bool forceApi = false}) async {
    final matchHistoryString = matchHistoryStorage.getItem(puuid);
    print("Match histories from db:");
    if (forceApi || matchHistoryString == null) {
      final histories = await getMatchHistoriesFromAPI(puuid, start: start, count: count);
      print("Returning from api");
      return histories;
    }
    final list = json.decode(matchHistoryString);
    if (allMatches) {
      final returnList = <String>[];
      list.forEach((element) {
        returnList.add(element as String);
      });
      returnList.sort();
      print("Returning all matches");
      return LeagueResponse(matchOverviews: returnList);
    }
      final returnList = <String>[];
      for (int i = start; i < count; i++) {
        returnList.add(list[i]);
      }
      returnList.sort();
      print("Returning at end");
      return LeagueResponse(matchOverviews: returnList);
    }
  /// Match Histories

  /// Challenger Players
  Future<List<LeagueEntryDto>?> getChallengerPlayers(String queue, String tier, String division, {int page = 1, bool fallbackAPI = true}) async {
    bool keepSearching = true;
    int pageNumber = 1;
    List<LeagueEntryDto> list = [];
    final newPlayers = rankedChallengerSoloStorage.getItem("$division-$pageNumber");
    if(newPlayers == null && fallbackAPI == true) {
      final rankedPlayed = await getChallengerPlayersFromAPI(queue, tier, division);
      saveChallengerPlayers(tier, division, json.encode(rankedPlayed));
      return rankedPlayed;
    }
    while(keepSearching) {
      final newPlayers = rankedChallengerSoloStorage.getItem("$division-$pageNumber");
      if (newPlayers == null) {
        keepSearching = false;
      }else {
        final myLeagueEntryForThisPage = leagueEntryDtoFromJson(newPlayers);
        list.addAll(myLeagueEntryForThisPage);
        pageNumber++;
      }
    }
    return list;
  }
  /// Challenger Players

  /*Future<List<Rank>> getRankedStatsForSummoner(String summonerId) async {
    final rank = storage.getChallengerPlayers(tier, division)
  }*/
}
