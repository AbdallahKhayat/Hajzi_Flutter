// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ListBlogModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListBlogModel _$ListBlogModelFromJson(Map<String, dynamic> json) =>
    ListBlogModel(
      (json['data'] as List<dynamic>)
          .map((e) => AddBlogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ListBlogModelToJson(ListBlogModel instance) =>
    <String, dynamic>{
      'data': instance.data,
    };
