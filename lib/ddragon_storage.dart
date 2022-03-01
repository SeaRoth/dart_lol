import 'dart:convert';

import 'package:dart_lol/LeagueStuff/champion_stand_alone.dart';
import 'package:localstorage/localstorage.dart';

import 'LeagueStuff/champions.dart';
import 'ddragon_api.dart';

class DDragonStorage {
  final dDragonLocalStorage = new LocalStorage('ddragon_storage');
  final versionsKey = "ddragon_versions";
  final versionsLastSaved = "versions_last_saved";
  var currentVersion = "";

  DDragonStorage() {
    getVersionFromDb();
  }

  /// VERSIONS
  Future saveVersions(List<String> versions) async {
    await dDragonLocalStorage.setItem(versionsKey, versions);
    await dDragonLocalStorage.setItem(versionsLastSaved, DateTime.now().millisecondsSinceEpoch);
  }

  Future<int> getVersionsLastUpdated() async {
    return await dDragonLocalStorage.getItem(versionsLastSaved);
  }

  Future<String> getVersionFromDb() async {
    print("Getting versions from db");
    if(currentVersion != "") {
      print("versions not equal to '': $currentVersion");
      return currentVersion;
    }
    final version = await dDragonLocalStorage.getItem(versionsKey);
    if(version == null) {
      final versionAPI = await DDragonAPI().getVersionsFromApi();
      currentVersion = versionAPI[0];
      print("version received from api: $currentVersion");
      return currentVersion;
    }
    currentVersion = version[0];
    print("version received from db: $currentVersion");
    return currentVersion;
  }

  /// Champions all
  final championsKey = "champions_key";
  final championsLastSaved = "champions_last_saved";
  saveChampions(String champions) {
    dDragonLocalStorage.setItem(championsKey, champions);
    dDragonLocalStorage.setItem(championsLastSaved, DateTime.now().millisecondsSinceEpoch);
  }

  int getChampionsLastUpdated() {
    return dDragonLocalStorage.getItem(championsLastSaved);
  }

  Future<Champions> getChampionsFromDb() async {
    final championsString = await dDragonLocalStorage.getItem(championsKey);
    if(championsString == null)
      return await DDragonAPI().getChampionsFromApi();
    return Champions.fromJson(json.decode(championsString));
  }
  /// Champions all end

  /// Champions Specific
  saveSpecificChampion(String json, String championName) {
    dDragonLocalStorage.setItem("$championsKey-$championName", json);
  }

  Future<ChampionStandAlone> getChampionStandAloneFromDb(String championName) async {
    final championsString = await dDragonLocalStorage.getItem("$championsKey-$championName");
    if(championsString == null) {
      print("Champion data not in db, calling API for specific champion data");
      return await DDragonAPI().getSpecificChampionFromApi(championName);
    }
    final championStandAlone = ChampionStandAlone.fromJson(json.decode(championsString), championName);
    print("comparing version ${championStandAlone.version} vs $currentVersion");
    if(championStandAlone.version != currentVersion) {
      print("Champion data out of date, calling API for specific champion data");
      return await DDragonAPI().getSpecificChampionFromApi(championName);
    }
    return championStandAlone;
  }
/// Champions Specific end
}
