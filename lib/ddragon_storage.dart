import 'dart:convert';

import 'package:dart_lol/LeagueStuff/queues.dart';
import 'package:dart_lol/LeagueStuff/champion_stand_alone.dart';
import 'package:dart_lol/LeagueStuff/runes_reforged.dart';
import 'package:dart_lol/LeagueStuff/summoner_spells.dart';
import 'package:localstorage/localstorage.dart';

import 'LeagueStuff/champions.dart';
import 'ddragon_api.dart';

class DDragonStorage {
  final dDragonLocalStorage = LocalStorage('ddragon_storage');
  final versionsKey = "ddragon_versions";
  final versionsLastSaved = "versions_last_saved";
  var currentVersion = "";

  /// VERSIONS
  Future saveVersions(String versions) async {
    print("saving versions to db");
    print(versions.runtimeType);
    print(versions);
    await dDragonLocalStorage.setItem(versionsKey, versions);
    await dDragonLocalStorage.setItem(versionsLastSaved, DateTime.now().millisecondsSinceEpoch);
    print("Done saving to db");
  }

  Future<int> getVersionsLastUpdated() async {
    return dDragonLocalStorage.getItem(versionsLastSaved);
  }

  Future<String> getVersionFromDb() async {
    if(currentVersion != "") {
      print("versions saved in class, returning: $currentVersion");
      return currentVersion;
    }
    final version = dDragonLocalStorage.getItem(versionsKey);
    if(version == null) {
      final versionAPI = await DDragonAPI().getVersionsFromApi();
      if(versionAPI.isEmpty) {
        print("setting to default version of 12.6.1");
        currentVersion = "12.6.1";
      }else {
        print("0th position: ${versionAPI[0]}");
        currentVersion = versionAPI[0];
      }
      return currentVersion;
    }
    currentVersion = json.decode(version)[0];
    return currentVersion;
  }

  /// Champions all
  final championsKey = "champions_key";
  final championsLastSaved = "champions_last_saved";
  Future saveChampions(String champions) async {
    await dDragonLocalStorage.setItem(championsKey, champions);
    await dDragonLocalStorage.setItem(championsLastSaved, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> getChampionsLastUpdated() async {
    return await dDragonLocalStorage.getItem(championsLastSaved);
  }

  Future<Champions> getChampionsFromDb() async {
    final championsString = await dDragonLocalStorage.getItem(championsKey);
    if(championsString == null)
      return await DDragonAPI().getChampionsFromApi();
    return Champions.fromJson(json.decode(championsString));
  }
  /// Champions all end

  /// Champions Specific
  Future saveSpecificChampion(String json, String championName) async {
    await dDragonLocalStorage.setItem("$championsKey-$championName", json);
  }

  Future<ChampionStandAlone> getChampionStandAloneFromDb(String championName) async {
    final championsString = await dDragonLocalStorage.getItem("$championsKey-$championName");
    if(championsString == null) {
      print("Champion $championName data not in db, calling API for specific champion data");
      return await DDragonAPI().getSpecificChampionFromApi(championName);
    }
    final championStandAlone = ChampionStandAlone.fromJson(json.decode(championsString), championName);
    print("getChampionStandAloneFromDb comparing version ${championStandAlone.version} vs $currentVersion");
    if(championStandAlone.version != currentVersion) {
      print("Champion data out of date, calling API for specific champion data");
      return await DDragonAPI().getSpecificChampionFromApi(championName);
    }
    return championStandAlone;
  }
  /// Champions Specific end
  final spellKey = "summoner_spells";
  Future<SummonerSpell> getSummonerSpellsFromDb() async {
    final spellString = await dDragonLocalStorage.getItem(spellKey);
    if(spellString == null) {
      print("summoner spells not in database, getting them from api");
      return await DDragonAPI().getSummonerSpellsFromApi();
    }
    final summonerSpells = SummonerSpell.fromJson(json.decode(spellString));
    print("comparing version ${summonerSpells.version} vs $currentVersion");
    if(summonerSpells.version != currentVersion) {
      print("Summoner spell data out of date, calling API");
      return await DDragonAPI().getSummonerSpellsFromApi();
    }
    return summonerSpells;
  }

  Future saveSummonerSpells(String json) async{
    await dDragonLocalStorage.setItem(spellKey, json);
  }
  ///Get summoner spell stuff

  /// Runes
  final runeKey = "runes_reforged";
  final runeKeyDate = "runes_reforged_date";
  Future<List<RunesReforged>> getRunesFromDb() async {
    final runesString = await dDragonLocalStorage.getItem(runeKey);
    if(runesString == null) {
      print("runes not in database, getting them from api");
      return await DDragonAPI().getRunesFromApi();
    }
    // Check runes version
    final runesVersion = dDragonLocalStorage.getItem(runeKeyDate);
    if(runesVersion != currentVersion) {
      print("Runes version not equal to currentVersion ($runesVersion vs $currentVersion), calling api");
      return await DDragonAPI().getRunesFromApi();
    }
    return runesReforgedFromJson(runesString);
  }

  Future saveRunesReforged(String json) async {
    await dDragonLocalStorage.setItem(runeKey, json);
    await dDragonLocalStorage.setItem(runeKeyDate, currentVersion);
  }
  /// Runes

  /// Queues
  final queueKey = "queue_key";
  final queueVersion = "queue_key_version";
  Future<List<Queues>> getQueuesFromDb() async {
    final queueSavedVersion = await dDragonLocalStorage.getItem(queueVersion);
    final queueString = await dDragonLocalStorage.getItem(queueKey);
    if(currentVersion != queueSavedVersion || queueString == null) {
      return await DDragonAPI().getQueuesFromApi();
    }
    return queuesFromJson(queueString);
  }

  Future saveQueuesToDb(String json) async {
    await dDragonLocalStorage.setItem(queueKey, json);
    await dDragonLocalStorage.setItem(queueVersion, currentVersion);
  }
  /// Queues
}
