// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sampling.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SamplingCapability _$SamplingCapabilityFromJson(Map<String, dynamic> json) =>
    SamplingCapability();

Map<String, dynamic> _$SamplingCapabilityToJson(SamplingCapability instance) =>
    <String, dynamic>{};

SamplingStartParams _$SamplingStartParamsFromJson(Map<String, dynamic> json) =>
    SamplingStartParams(
      promptRequestId: json['promptRequestId'] as String,
      interval: (json['interval'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SamplingStartParamsToJson(
        SamplingStartParams instance) =>
    <String, dynamic>{
      'promptRequestId': instance.promptRequestId,
      'interval': instance.interval,
    };

SamplingStartResult _$SamplingStartResultFromJson(Map<String, dynamic> json) =>
    SamplingStartResult(
      id: json['id'] as String,
    );

Map<String, dynamic> _$SamplingStartResultToJson(
        SamplingStartResult instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

SamplingStopParams _$SamplingStopParamsFromJson(Map<String, dynamic> json) =>
    SamplingStopParams(
      id: json['id'] as String,
    );

Map<String, dynamic> _$SamplingStopParamsToJson(SamplingStopParams instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

SamplingStopResult _$SamplingStopResultFromJson(Map<String, dynamic> json) =>
    SamplingStopResult();

Map<String, dynamic> _$SamplingStopResultToJson(SamplingStopResult instance) =>
    <String, dynamic>{};

SamplingEventParams _$SamplingEventParamsFromJson(Map<String, dynamic> json) =>
    SamplingEventParams(
      id: json['id'] as String,
      output: json['output'] as String,
    );

Map<String, dynamic> _$SamplingEventParamsToJson(
        SamplingEventParams instance) =>
    <String, dynamic>{
      'id': instance.id,
      'output': instance.output,
    };
