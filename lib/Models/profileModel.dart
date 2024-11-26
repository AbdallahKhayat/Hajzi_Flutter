import 'package:json_annotation/json_annotation.dart';
part 'profileModel.g.dart';// flutter pub run build_runner build
//it will create automatically profileModel.g.dart file
//it will automatically do the mapping from the model to server
//thats why constructor parameters have to be the exact name as the server's ones
@JsonSerializable(includeIfNull: false)
class ProfileModel{

 //we dont need img variable since in NetWork handler we pass username to ImageNetwork
  String? name;
  String? username;
  String? profession;
  String? DOB;
  String? titleline;
  String? about;

  ProfileModel([this.name,this.username,this.profession,this.DOB,this.titleline,this.about]);

  factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}