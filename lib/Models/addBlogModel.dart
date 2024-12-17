import 'package:json_annotation/json_annotation.dart';

part 'addBlogModel.g.dart'; // flutter pub run build_runner build

@JsonSerializable(includeIfNull: false)
class AddBlogModel {
  // We now have a list of images instead of a single image
  List<String>? coverImages;
  String? previewImage; // Single image for preview
  int? like;
  int? share;
  int? comment;

  @JsonKey(name: "_id") // Provide the actual name of id from the API
  String? id;
  String? username;
  String? email;
  String? title;
  String? body;
  String? status;
  String? type;
  DateTime? createdAt;
  double? lat;
  double? lng;

  AddBlogModel({
    this.coverImages,
    this.like,
    this.share,
    this.comment,
    this.id,
    this.username,
    this.email,
    this.title,
    this.body,
    this.status,
    this.type,
    this.createdAt,
    this.lat,
    this.lng,
  });

  factory AddBlogModel.fromJson(Map<String, dynamic> json) =>
      _$AddBlogModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddBlogModelToJson(this);
}
