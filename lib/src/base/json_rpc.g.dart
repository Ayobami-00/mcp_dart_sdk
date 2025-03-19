// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'json_rpc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JsonRpcRequest _$JsonRpcRequestFromJson(Map<String, dynamic> json) =>
    JsonRpcRequest(
      id: json['id'] as Object,
      method: json['method'] as String,
      params: json['params'],
    );

Map<String, dynamic> _$JsonRpcRequestToJson(JsonRpcRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'method': instance.method,
      'params': instance.params,
    };

JsonRpcNotification _$JsonRpcNotificationFromJson(Map<String, dynamic> json) =>
    JsonRpcNotification(
      method: json['method'] as String,
      params: json['params'],
    );

Map<String, dynamic> _$JsonRpcNotificationToJson(
        JsonRpcNotification instance) =>
    <String, dynamic>{
      'method': instance.method,
      'params': instance.params,
    };

JsonRpcSuccessResponse _$JsonRpcSuccessResponseFromJson(
        Map<String, dynamic> json) =>
    JsonRpcSuccessResponse(
      id: json['id'] as Object,
      result: json['result'],
    );

Map<String, dynamic> _$JsonRpcSuccessResponseToJson(
        JsonRpcSuccessResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'result': instance.result,
    };

JsonRpcErrorResponse _$JsonRpcErrorResponseFromJson(
        Map<String, dynamic> json) =>
    JsonRpcErrorResponse(
      id: json['id'] as Object,
      error: McpError.fromJson(json['error'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JsonRpcErrorResponseToJson(
        JsonRpcErrorResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'error': instance.error,
    };
