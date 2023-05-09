import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'custom_time_model.g.dart';

typedef JsonMap = Map<String, dynamic>;

@JsonSerializable()
class CustomTimeModel extends Equatable {
  final String id;
  final int breakTime;
  final int workingTime;

  CustomTimeModel({
    String? id,
    required this.breakTime,
    required this.workingTime,
  }) : id = id ?? const Uuid().v4();

  CustomTimeModel copyWith({
    String? id,
    int? breakTime,
    int? workingTime,
  }) {
    return CustomTimeModel(
      id: id ?? this.id,
      breakTime: breakTime ?? this.breakTime,
      workingTime: workingTime ?? this.workingTime,
    );
  }

  static CustomTimeModel fromJson(JsonMap json) =>
      _$CustomTimeModelFromJson(json);

  JsonMap toJson() => _$CustomTimeModelToJson(this);

  @override
  List<Object?> get props => [id, breakTime, workingTime];
}
