import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

//file to handle flutter with rest server

class NetworkHandler{

  String baseurl = "http://192.168.88.4:5000";
  String baseurl2="http://192.168.88.4:5000/";
 // String baseurl = "https://flutter-sign-up-production.up.railway.app";

  var log = Logger();

  FlutterSecureStorage storage = FlutterSecureStorage();

  Future<dynamic> get(String url) async {
    String? token = await storage.read(key: "token");
    url = formater(url);
    var uri = Uri.parse(url);
    var response = await http.get(uri,headers: { //to verify token
      "Authorization":"Bearer $token" //add token to header
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      log.i(response.body);
      return json.decode(response.body);
    } else {
      log.e('Error: ${response.statusCode}, Body: ${response.body}');
      return {'Status': false}; // Return a map with Status false if there's an error
    }
  }

  Future<dynamic> get2E(String url, {bool requireAuth = true}) async {
    String? token = requireAuth ? await storage.read(key: "token") : null;
    url = formater(url);
    var uri = Uri.parse(url);
    var headers = {
      "Content-Type": "application/json",
    };

    // Add Authorization header only if token is available and required
    if (requireAuth && token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    print("GET Request to URL: $uri");
    print("Headers: $headers");

    var response = await http.get(uri, headers: headers);

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      return {'Status': false}; // Return a map with Status false if there's an error
    }
  }

  Future<http.Response> patch2E(String url, Map<String, dynamic> body, {bool requireAuth = true}) async {
    url = formater(url);
    var uri = Uri.parse(url);
    String? token = requireAuth ? await storage.read(key: "token") : null;

    var headers = {
      "Content-Type": "application/json",
    };

    // Add Authorization header only if a token is available and required
    if (requireAuth && token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    print("PATCH Request to URL: $uri");
    print("Headers: $headers");
    print("Body: ${json.encode(body)}");

    var response = await http.patch(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    return response;
  }


  Future post2(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    try {
      String? token = await FlutterSecureStorage().read(key: 'token');
      if (token != null) {
        headers ??= {};
        headers["Authorization"] = "Bearer $token";  // Add Authorization header
      }

      var url = Uri.parse(baseurl + endpoint);
      var response = await http.post(url, headers: headers, body: json.encode(data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to post data");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Error occurred while posting data");
    }
  }



  Future get2(String endpoint, {Map<String, String>? headers}) async {
    try {
      String? token = await FlutterSecureStorage().read(key: 'token');
      if (token != null) {
        headers ??= {}; // Initialize headers if null
        headers["Authorization"] = "Bearer $token";  // Add Authorization header
      }

      var url = Uri.parse(baseurl + endpoint);
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error: $e");
      throw Exception("Error occurred while fetching data");
    }
  }

  Future<dynamic> delete(String url) async {
    String? token = await storage.read(key: "token");
    url = formater(url); // Ensure URL is formatted correctly
    var uri = Uri.parse(url);

    var response = await http.delete( // Change to DELETE
      uri,
      headers: {
        "Authorization": "Bearer $token", // Send the token in the header
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      log.i("Delete Success: ${response.body}");
      return json.decode(response.body); // Expecting { "Status": true }
    } else {
      log.e("Delete Failed: ${response.statusCode}, Body: ${response.body}");
      return {'Status': false}; // Return failure
    }
  }

  Future<dynamic> delete2(String url, {Map<String, String>? headers, String? body}) async {
    String? token = await storage.read(key: "token");

    // Merge additional headers if provided
    final combinedHeaders = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json", // Ensure JSON content type
      if (headers != null) ...headers,
    };

    final response = await http.delete(
      Uri.parse(baseurl + url),
      headers: combinedHeaders,
      body: body, // Add support for request body
    );

    // Return decoded response
    return json.decode(response.body);
  }


  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    url = formater(url);
    var uri = Uri.parse(url);
    String? token = await storage.read(key: "token");
    // Encode the body to JSON
    var response = await http.post(
      uri,
      headers: {"Content-Type": "application/json","Authorization":"Bearer $token"},  // Specify the content type
      body: json.encode(body),  // Convert body to JSON string
    );

 return response;

  }


  Future<http.Response> post1(String url, var body) async {
    url = formater(url);
    var uri = Uri.parse(url);
    String? token = await storage.read(key: "token");
    // Encode the body to JSON
    var response = await http.post(
      uri,
      headers: {"Content-Type": "application/json","Authorization":"Bearer $token"},  // Specify the content type
      body: json.encode(body),  // Convert body to JSON string
    );

    return response;

  }

//for sending image we do it with patch here
  Future<http.StreamedResponse> patchImage(String url,String filePath) async {
    url = formater(url);
    var uri = Uri.parse(url);
    String? token = await storage.read(key: "token");

    var request = http.MultipartRequest('PATCH', uri);//send multi data like img,name,profession etc.. from front to  backend
    request.files.add(await http.MultipartFile.fromPath('img',filePath));
    request.headers.addAll({
      "Authorization":"Bearer $token",
      "Content-Type": "multipart/form-data"

    });
    //send it
    var response= await request.send();
    return response;


  }

  Future<http.Response>patch(String url,Map<String,dynamic>body)async{

    url = formater(url);
    var uri = Uri.parse(url);
    String? token = await storage.read(key: "token");

    var response = await http.patch(
      uri,
      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      body: json.encode(body),
    );
    return response;
  }



  String formater(String url){
    return baseurl+url;
  }

  String formater2(String url){
    return baseurl2+url;
  }

  // Check if the current user has liked the blog post
  Future<bool> isLiked(String url,String blogId) async {
    final token = await storage.read(key: "token");
    final uri = Uri.parse(url);

    try {
      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['isLiked'] ?? false;
      } else {
        log.e("Error checking like status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      log.e("Exception while checking like status: $e");
      return false;
    }
  }
  //get the image for MainProfile
  NetworkImage getImage(String imageName){
    String url=formater("/uploads/$imageName.jpg");// if u notice the image name in backend is the same as username
    return NetworkImage(url);
  }

  NetworkImage getImageBlog(String imageName){
    String url=formater("/$imageName");// if u notice the image name in backend is the same as username
    return NetworkImage(url);
  }

  List<NetworkImage> getImages(List<String> imagePaths) {
    return imagePaths.map((imagePath) {
      // Use `formater` to build the full URL, ensuring no duplicate "uploads/"
      String url = imagePath.startsWith("/uploads/")
          ? formater(imagePath) // If the path already includes "/uploads/", use it as-is
          : formater("/$imagePath"); // Otherwise, prepend "/uploads/"
      return NetworkImage(url); // Create the NetworkImage
    }).toList();
  }

// List<NetworkImage> getImages(List<String> imageNames) {
  //   return imageNames.map((imageName) {
  //     String url = formater("/uploads/$imageName.jpg");
  //     return NetworkImage(url);
  //   }).toList();
  // }

  // // Method to get all images for a blog post
  // List<NetworkImage> getImages(List<String> imagePaths) {
  //   return imagePaths.map((path) => getImage(path)).toList();
  // }
}
