import 'package:blogapp/Models/addBlogModel.dart';
import 'package:json_annotation/json_annotation.dart';

import 'addBlogApproval.dart';
part 'ListBlogModel.g.dart';// flutter pub run build_runner build
//it will create automatically profileModel.g.dart file
//it will automatically do the mapping from the model to server
//thats why constructor parameters have to be the exact name as the server's ones
@JsonSerializable(includeIfNull: false)
class ListBlogModel{

 List<AddBlogModel>data;

 // List<AddBlogApproval>data;

  ListBlogModel(this.data);
  factory ListBlogModel.fromJson(Map<String, dynamic> json) => _$ListBlogModelFromJson(json);

  Map<String, dynamic> toJson() => _$ListBlogModelToJson(this);
}