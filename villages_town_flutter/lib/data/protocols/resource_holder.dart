import 'dart:math';
import '../models/resource.dart';

mixin ResourceHolder {
  Map<Resource, int> get resources;
  set resources(Map<Resource, int> value);

  void addResource(Resource resource, int amount) {
    resources = Map.from(resources)..[resource] = (resources[resource] ?? 0) + amount;
  }

  void subtractResource(Resource resource, int amount) {
    resources = Map.from(resources)..[resource] = max(0, (resources[resource] ?? 0) - amount);
  }

  bool isSufficient(Resource resource, int amount) => (resources[resource] ?? 0) >= amount;

  bool isSufficientAll(Map<Resource, int> cost) {
    for (final entry in cost.entries) {
      if (!isSufficient(entry.key, entry.value)) return false;
    }
    return true;
  }

  int getResource(Resource resource) => resources[resource] ?? 0;
}
