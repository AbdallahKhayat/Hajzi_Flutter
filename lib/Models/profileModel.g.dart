// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profileModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
      json['name'] as String?,
      json['username'] as String?,
      json['email'] as String?,
      json['profession'] as String?,
      json['DOB'] as String?,
      json['titleline'] as String?,
      json['about'] as String?,
      json['img'] as String?,
    );

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      if (instance.name case final value?) 'name': value,
      if (instance.username case final value?) 'username': value,
      if (instance.email case final value?) 'email': value,
      if (instance.profession case final value?) 'profession': value,
      if (instance.DOB case final value?) 'DOB': value,
      if (instance.titleline case final value?) 'titleline': value,
      if (instance.about case final value?) 'about': value,
      if (instance.img case final value?) 'img': value,
    };
