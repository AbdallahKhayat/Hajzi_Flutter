//this file for Preview button

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OverlayCard extends StatefulWidget {
  const OverlayCard({super.key, this.imageFile,required this.title});

  final XFile? imageFile;
  final String title;

  @override
  State<OverlayCard> createState() => _OverlayCardState();
}

class _OverlayCardState extends State<OverlayCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(5),
      child: Stack(
        //image and text on top of image
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: FileImage(
                  File(widget.imageFile!.path),
                ),
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
          Positioned(
            bottom: 2, // set the container on bottom 2 pixels up from bottom
            child: Container(//to add title for Profile Picture
              padding: EdgeInsets.all(8),
              height: 55, //height of title container
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Text(widget.title,style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),),
                ),
          ),
        ],
      ),
    );
  }
}
