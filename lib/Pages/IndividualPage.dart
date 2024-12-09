import 'package:blogapp/CustomWidget/OwnMessageCard.dart';
import 'package:blogapp/CustomWidget/ReplyCard.dart';
import 'package:blogapp/Models/ChatModel.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants.dart'; // Import the constants file

class IndividualPage extends StatefulWidget {
  const IndividualPage({super.key, required this.chatModel});

  final ChatModel chatModel;

  @override
  State<IndividualPage> createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {

  late IO.Socket socket;
  bool sendButton = false;

  /// Function to create a lighter version of a color
  Color lightenColor(Color color, [double amount = 0.2]) {
    if (color == Colors.black) {
      return Colors.grey[850]!; // Special case for black
    }
    final hsl = HSLColor.fromColor(color);
    final lighterHSL = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lighterHSL.toColor();
  }
  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect (){
    socket = IO.io("http://192.168.88.5:5001",<String,dynamic>{
      "transports": ["websocket"],
      "autoConnect":false,
    });
    socket.connect();
    socket.emit("/test", "Hello World");
    socket.onConnect((data)=> print("Connected"));
    print(socket.connected);
    socket.emit("/test", "Hello World");
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ValueListenableBuilder<Color>(
      valueListenable: appColorNotifier, // Listen to appColorNotifier
      builder: (context, mainColor, child) {
        final messageBubbleColor = lightenColor(mainColor, 0.2); // Slightly lighter than mainColor
        final backgroundColor = lightenColor(mainColor, 0.4); // Much lighter than mainColor

        return Scaffold(
          backgroundColor: backgroundColor, // Lighter shade of mainColor
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: AppBar(
              backgroundColor: mainColor, // Main color used for AppBar
              titleSpacing: 0,
              leadingWidth: screenWidth * 0.25,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: screenWidth * 0.02),
                    Icon(
                      Icons.arrow_back,
                      size: screenWidth * 0.06,
                      color: Colors.white,
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: Colors.white,
                      child: Icon(
                        widget.chatModel.icon,
                        color: mainColor,
                        size: screenWidth * 0.05,
                      ),
                    ),
                  ],
                ),
              ),
              title: InkWell(
                onTap: () {},
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.002),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatModel.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        "last seen at 12:30",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.videocam,
                    size: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.call,
                    size: screenWidth * 0.06,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: screenWidth * 0.06,
                  ),
                  onSelected: (value) {},
                  itemBuilder: (BuildContext context) {
                    return const [
                      PopupMenuItem(value: "View Contact", child: Text("View Contact")),
                      PopupMenuItem(value: "Media, links, and docs", child: Text("Media, links, and docs")),
                      PopupMenuItem(value: "Hajzi web", child: Text("Hajzi web")),
                      PopupMenuItem(value: "Search", child: Text("Search")),
                      PopupMenuItem(value: "Mute Notifications", child: Text("Mute Notifications")),
                      PopupMenuItem(value: "Wall Paper", child: Text("Wall Paper")),
                    ];
                  },
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    OwnMessageCard(
                      messageColor: messageBubbleColor,
                      textColor: Colors.black,
                    ),
                    ReplyCard(),
                    OwnMessageCard(
                      messageColor: messageBubbleColor,
                      textColor: Colors.black,
                    ),
                    ReplyCard(),
                    OwnMessageCard(
                      messageColor: messageBubbleColor,
                      textColor: Colors.black,
                    ),
                    ReplyCard(),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      margin: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextFormField(

                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: TextInputType.multiline,
                        maxLines: 5,
                        minLines: 1,
                        onChanged: (value){
                          if(value.length>0){
                            setState(() {
                              sendButton = true;
                            });
                          }
                          else {
                            setState(() {
                              sendButton = false;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type a message",
                          contentPadding: const EdgeInsets.only(
                            left: 20,
                            top: 10,
                            bottom: 10,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    backgroundColor: Colors.transparent,
                                    context: context,
                                    builder: (builder) => BottomSheet(),
                                  );
                                },
                                icon: Icon(Icons.attach_file),
                                padding: const EdgeInsets.only(right: 0, left: 30),
                              ),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.camera_alt),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 10, left: 5),
                    child: CircleAvatar(
                      backgroundColor: mainColor,
                      radius: 25,
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                         sendButton? Icons.send : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget BottomSheet(){
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCreation(Icons.insert_drive_file,Colors.indigo,"Document"),
                  SizedBox(width: 40,),
                  IconCreation(Icons.camera_alt,Colors.pink,"Camera"),
                  SizedBox(width: 40,),
                  IconCreation(Icons.insert_photo,Colors.purple,"Gallery"),

                ],),
              SizedBox(height: 25,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCreation(Icons.headset,Colors.orange,"Audio"),
                  SizedBox(width: 40,),
                  IconCreation(Icons.location_pin,Colors.teal,"Location"),
                  SizedBox(width: 40,),
                  IconCreation(Icons.person,Colors.blue,"Contact"),

                ],)
            ],
          ),
        ),
      ),
    );
  }

  Widget IconCreation(IconData icon,Color color, String text){
    return InkWell(
      onTap: () {},
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, size: 29, color: Colors.white,),
          ),
          SizedBox(height: 5,),
          Text(text, style: TextStyle(fontSize: 13),),
        ],
      ),
    );
  }
}
