// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addBlogApproval.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddBlogApproval _$AddBlogApprovalFromJson(Map<String, dynamic> json) =>
    AddBlogApproval(
      title: json['title'] as String?,
      body: json['body'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      id: json['_id'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$AddBlogApprovalToJson(AddBlogApproval instance) =>
    <String, dynamic>{
      if (instance.title case final value?) 'title': value,
      if (instance.body case final value?) 'body': value,
      if (instance.username case final value?) 'username': value,
      if (instance.email case final value?) 'email': value,
      if (instance.id case final value?) '_id': value,
      if (instance.type case final value?) 'type': value,
    };
