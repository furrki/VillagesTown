enum MissionType { story, delivery, bounty, escort, trade }

enum MissionState { available, active, completed, failed }

enum ObjectiveType {
  travelTo,
  deliverGoods,
  winBattles,
  recruitUnits,
  earnGold,
  haveCargo,
}

class MissionObjective {
  final String id;
  final ObjectiveType type;
  final String description;
  final String? targetCityId;
  final String? targetGoodName;
  final int targetAmount;
  int currentAmount;
  bool completed;

  MissionObjective({
    required this.id,
    required this.type,
    required this.description,
    this.targetCityId,
    this.targetGoodName,
    this.targetAmount = 1,
    this.currentAmount = 0,
    this.completed = false,
  });

  void markComplete() {
    completed = true;
    currentAmount = targetAmount;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'description': description,
    'targetCityId': targetCityId,
    'targetGoodName': targetGoodName,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'completed': completed,
  };

  factory MissionObjective.fromJson(Map<String, dynamic> json) {
    return MissionObjective(
      id: json['id'] as String,
      type: ObjectiveType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ObjectiveType.travelTo,
      ),
      description: json['description'] as String? ?? '',
      targetCityId: json['targetCityId'] as String?,
      targetGoodName: json['targetGoodName'] as String?,
      targetAmount: json['targetAmount'] as int? ?? 1,
      currentAmount: json['currentAmount'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class Mission {
  final String id;
  final String title;
  final String description;
  final String giverName;
  final String? giverCityId;
  final MissionType type;
  final List<MissionObjective> objectives;
  final int goldReward;
  final int reputationReward;
  final String? reputationFactionId;
  final int? expiresAtTick;
  MissionState state;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.giverName,
    this.giverCityId,
    this.type = MissionType.story,
    required this.objectives,
    this.goldReward = 0,
    this.reputationReward = 0,
    this.reputationFactionId,
    this.expiresAtTick,
    this.state = MissionState.active,
  });

  bool get allObjectivesComplete => objectives.every((o) => o.completed);

  double get progress => objectives.isEmpty
      ? 0
      : objectives.where((o) => o.completed).length / objectives.length;

  int get completedCount => objectives.where((o) => o.completed).length;

  void checkCompletion() {
    if (state == MissionState.active && allObjectivesComplete) {
      state = MissionState.completed;
    }
  }

  void checkExpiry(int currentTick) {
    if (expiresAtTick != null &&
        currentTick >= expiresAtTick! &&
        state == MissionState.active) {
      state = MissionState.failed;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'giverName': giverName,
    'giverCityId': giverCityId,
    'type': type.name,
    'objectives': objectives.map((o) => o.toJson()).toList(),
    'goldReward': goldReward,
    'reputationReward': reputationReward,
    'reputationFactionId': reputationFactionId,
    'expiresAtTick': expiresAtTick,
    'state': state.name,
  };

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      giverName: json['giverName'] as String? ?? '',
      giverCityId: json['giverCityId'] as String?,
      type: MissionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MissionType.story,
      ),
      objectives: (json['objectives'] as List<dynamic>?)
              ?.map((o) => MissionObjective.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      goldReward: json['goldReward'] as int? ?? 0,
      reputationReward: json['reputationReward'] as int? ?? 0,
      reputationFactionId: json['reputationFactionId'] as String?,
      expiresAtTick: json['expiresAtTick'] as int?,
      state: MissionState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => MissionState.active,
      ),
    );
  }
}
