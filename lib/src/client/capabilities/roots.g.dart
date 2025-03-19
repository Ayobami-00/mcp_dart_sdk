// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roots.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RootsCapability _$RootsCapabilityFromJson(Map<String, dynamic> json) =>
    RootsCapability();

Map<String, dynamic> _$RootsCapabilityToJson(RootsCapability instance) =>
    <String, dynamic>{};

RootsListResult _$RootsListResultFromJson(Map<String, dynamic> json) =>
    RootsListResult(
      roots: (json['roots'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$RootsListResultToJson(RootsListResult instance) =>
    <String, dynamic>{
      'roots': instance.roots,
    };
