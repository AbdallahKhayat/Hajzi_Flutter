// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addBlogModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddBlogModel _$AddBlogModelFromJson(Map<String, dynamic> json) => AddBlogModel(
      coverImages: (json['coverImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      like: (json['like'] as num?)?.toInt(),
      share: (json['share'] as num?)?.toInt(),
      comment: (json['comment'] as num?)?.toInt(),
      id: json['_id'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      status: json['status'] as String?,
      type: json['type'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    )..previewImage = json['previewImage'] as String?;

Map<String, dynamic> _$AddBlogModelToJson(AddBlogModel instance) =>
    <String, dynamic>{
      if (instance.coverImages case final value?) 'coverImages': value,
      if (instance.previewImage case final value?) 'previewImage': value,
      if (instance.like case final value?) 'like': value,
      if (instance.share case final value?) 'share': value,
      if (instance.comment case final value?) 'comment': value,
      if (instance.id case final value?) '_id': value,
      if (instance.username case final value?) 'username': value,
      if (instance.email case final value?) 'email': value,
      if (instance.title case final value?) 'title': value,
      if (instance.body case final value?) 'body': value,
      if (instance.status case final value?) 'status': value,
      if (instance.type case final value?) 'type': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'createdAt': value,
      if (instance.lat case final value?) 'lat': value,
      if (instance.lng case final value?) 'lng': value,
    };
