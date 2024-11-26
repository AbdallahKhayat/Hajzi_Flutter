import 'package:json_annotation/json_annotation.dart';

part 'addBlogApproval.g.dart';  // Make sure this matches the file name

@JsonSerializable(includeIfNull: false)
class AddBlogApproval {
  String? title;
  String? body;
  String? username;
  @JsonKey(name: "_id") // Assuming the backend uses '_id' as the field name
  String? id;
  String? type;

  AddBlogApproval({this.title, this.body, this.username,this.id,this.type});

  factory AddBlogApproval.fromJson(Map<String, dynamic> json) => _$AddBlogApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$AddBlogApprovalToJson(this);
}
