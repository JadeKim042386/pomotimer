part of 'custom_time_model.dart';

CustomTimeModel _$CustomTimeModelFromJson(Map<String, dynamic> json) =>
    CustomTimeModel(
      id: json['id'] as String?,
      breakTime: json['breakTime'] as int? ?? 0,
      workingTime: json['workingTime'] as int? ?? 0,
    );

Map<String, dynamic> _$CustomTimeModelToJson(CustomTimeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'breakTime': instance.breakTime,
      'workingTime': instance.workingTime,
    };
