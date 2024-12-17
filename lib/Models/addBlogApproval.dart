import 'package:json_annotation/json_annotation.dart';

part 'addBlogApproval.g.dart';  // Make sure this matches the file name

@JsonSerializable(includeIfNull: false)
class AddBlogApproval {
  String? title;
  String? body;
  String? username;
  String?email;
  @JsonKey(name: "_id") // Assuming the backend uses '_id' as the field name
  String? id;
  String? type;
  double? lat;
  double? lng;

  AddBlogApproval({this.title, this.body, this.username,this.email,this.id,this.type,this.lat,this.lng});

  factory AddBlogApproval.fromJson(Map<String, dynamic> json) => _$AddBlogApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$AddBlogApprovalToJson(this);
}
