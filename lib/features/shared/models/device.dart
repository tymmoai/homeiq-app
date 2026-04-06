// Device model for smart home devices
// This is a placeholder model structure

class Device {
  final String id;
  final String name;
  final String type;
  final String roomId;
  final bool isOn;
  final Map<String, dynamic>? properties;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.roomId,
    this.isOn = false,
    this.properties,
  });

  // Convert from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      roomId: json['room_id'] as String,
      isOn: json['is_on'] as bool? ?? false,
      properties: json['properties'] as Map<String, dynamic>?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'room_id': roomId,
      'is_on': isOn,
      'properties': properties,
    };
  }

  // Create a copy with updated values
  Device copyWith({
    String? id,
    String? name,
    String? type,
    String? roomId,
    bool? isOn,
    Map<String, dynamic>? properties,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      roomId: roomId ?? this.roomId,
      isOn: isOn ?? this.isOn,
      properties: properties ?? this.properties,
    );
  }
}
