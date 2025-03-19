// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientInfo _$ClientInfoFromJson(Map<String, dynamic> json) => ClientInfo(
      name: json['name'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$ClientInfoToJson(ClientInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
    };

ServerInfo _$ServerInfoFromJson(Map<String, dynamic> json) => ServerInfo(
      name: json['name'] as String,
      version: json['version'] as String,
    );

Map<String, dynamic> _$ServerInfoToJson(ServerInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
    };

RequestMeta _$RequestMetaFromJson(Map<String, dynamic> json) => RequestMeta(
      id: json['id'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$RequestMetaToJson(RequestMeta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
    };

ClientCapabilities _$ClientCapabilitiesFromJson(Map<String, dynamic> json) =>
    ClientCapabilities(
      roots: json['roots'] as Map<String, dynamic>?,
      sampling: json['sampling'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ClientCapabilitiesToJson(ClientCapabilities instance) =>
    <String, dynamic>{
      'roots': instance.roots,
      'sampling': instance.sampling,
    };

ServerCapabilities _$ServerCapabilitiesFromJson(Map<String, dynamic> json) =>
    ServerCapabilities(
      prompts: json['prompts'] as Map<String, dynamic>?,
      resources: json['resources'] as Map<String, dynamic>?,
      tools: json['tools'] as Map<String, dynamic>?,
      logging: json['logging'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ServerCapabilitiesToJson(ServerCapabilities instance) =>
    <String, dynamic>{
      'prompts': instance.prompts,
      'resources': instance.resources,
      'tools': instance.tools,
      'logging': instance.logging,
    };

Uri _$UriFromJson(Map<String, dynamic> json) => Uri(
      json['uri'] as String,
    );

Map<String, dynamic> _$UriToJson(Uri instance) => <String, dynamic>{
      'uri': instance.uri,
    };

McpError _$McpErrorFromJson(Map<String, dynamic> json) => McpError(
      code: (json['code'] as num).toInt(),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$McpErrorToJson(McpError instance) => <String, dynamic>{
      'code': instance.code,
      'message': instance.message,
      'data': instance.data,
    };
