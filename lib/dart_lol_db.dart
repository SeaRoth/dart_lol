library dart_lol;

import 'package:dart_lol/LeagueStuff/responses/summoner_response.dart';
import 'package:dart_lol/dart_lol_api.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dart_lol/LeagueStuff/game_stats.dart';
import 'package:dart_lol/LeagueStuff/match.dart';
import 'package:http/http.dart' as http;
import 'LeagueStuff/champion_mastery.dart';
import 'LeagueStuff/rank.dart';
import 'LeagueStuff/summoner.dart';
import 'lol_storage.dart';

class LeagueDB extends LeagueAPI {

  LeagueDB({required apiToken, required String server}) : super(apiToken: apiToken, server: server) {
    this.server = server.toLowerCase();
    if(this.server == "na1")
      this.matchServer = "americas";
  }

  /// Get summoner from database
  /// If fallbackAPI == true then if not found then will call RIOT API
  Future<SummonerResponse?> getSummonerFromDb(String name, bool fallbackAPI) async {
    final s = storage.summonerStorage.getItem("$name");
    if(s != null){
      return s;
    }else if(fallbackAPI)
      return getSummonerInfo(name);
    else return null;
  }

  /// https://americas.api.riotgames.com/lol/match/v5/matches/NA1_4056249988?api_key=RGAPI-8567f359-587c-4742-a791-7fd5748be91a
  /// Get a match from RIOT api MatchV5
  /// Takes a matchID from matchHistoryV5
  Future<Match?> getMatch(String matchId, bool fallbackAPI) async {
    final m = storage.matchStorage.getItem("$matchId");
    if(m != null) {
      final valueMap = json.decode(m);
      return Match.fromJson(valueMap);
    }else if (fallbackAPI == false)
      return null;
    var url =
        'https://$matchServer.api.riotgames.com/lol/match/v5/matches/$matchId?api_key=$apiToken';
    var response = await http.get(Uri.parse(url),);
    storage.saveMatch(matchId, response.body);
    return Match.fromJson(json.decode(response.body,),);
  }
}
