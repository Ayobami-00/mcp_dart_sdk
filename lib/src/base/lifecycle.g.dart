// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lifecycle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InitializeParams _$InitializeParamsFromJson(Map<String, dynamic> json) =>
    InitializeParams(
      clientInfo:
          ClientInfo.fromJson(json['clientInfo'] as Map<String, dynamic>),
      capabilities: ClientCapabilities.fromJson(
          json['capabilities'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InitializeParamsToJson(InitializeParams instance) =>
    <String, dynamic>{
      'clientInfo': instance.clientInfo,
      'capabilities': instance.capabilities,
    };

InitializeResult _$InitializeResultFromJson(Map<String, dynamic> json) =>
    InitializeResult(
      serverInfo:
          ServerInfo.fromJson(json['serverInfo'] as Map<String, dynamic>),
      capabilities: ServerCapabilities.fromJson(
          json['capabilities'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$InitializeResultToJson(InitializeResult instance) =>
    <String, dynamic>{
      'serverInfo': instance.serverInfo,
      'capabilities': instance.capabilities,
    };

ShutdownParams _$ShutdownParamsFromJson(Map<String, dynamic> json) =>
    ShutdownParams();

Map<String, dynamic> _$ShutdownParamsToJson(ShutdownParams instance) =>
    <String, dynamic>{};

ShutdownResult _$ShutdownResultFromJson(Map<String, dynamic> json) =>
    ShutdownResult();

Map<String, dynamic> _$ShutdownResultToJson(ShutdownResult instance) =>
    <String, dynamic>{};

ExitParams _$ExitParamsFromJson(Map<String, dynamic> json) => ExitParams();

Map<String, dynamic> _$ExitParamsToJson(ExitParams instance) =>
    <String, dynamic>{};
