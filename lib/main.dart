import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:firebase_storage/firebase_storage.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(FirebaseInitialize());
}

class FirebaseInitialize extends StatefulWidget {
  const FirebaseInitialize({Key? key}) : super(key: key);

  @override
  _FirebaseInitializeState createState() => _FirebaseInitializeState();
}

class _FirebaseInitializeState extends State<FirebaseInitialize> {
  final Future<FirebaseApp> initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MyApp();
        } else {
          return CircularProgressIndicator();
        }
      }
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shopping App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(title: 'Home Page'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomeScreen createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.add_alert),
                tooltip: 'Notifications',
                onPressed: () {},
              )
            ],
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.add_shopping_cart)),
                Tab(icon: Icon(Icons.sell)),
              ],
            ),
            title: Text(widget.title),
          ),
          body: TabBarView(
            children: [
              BuyScreen(),
              SellScreen(),
            ],
          ),
        )
    );
  }
}

class BuyScreen extends StatefulWidget {
  const BuyScreen({Key? key}) : super(key: key);

  @override
  _BuyScreenState createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final Stream<QuerySnapshot> listedItemsStream = FirebaseFirestore.instance.collection('listedItems').snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong',
              style: TextStyle(
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold
              )
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Text('Fetching results',
              style: TextStyle(
                  fontSize: 48.0,
                  fontWeight: FontWeight.bold
              )
          );
        } else {
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return CustomItemListing(
                  itemName: data['name'],
                  itemDesc: data['description'],
                  itemPrice: data['price'],
                  itemImages: data.containsKey('images') && data['images'].length > 0 ? data['images'] : null,
              );
            }).toList(),
          );
        }
      },
      stream: listedItemsStream,
    );
  }
}

// class CustomItemListTile extends StatefulWidget {
//   const CustomItemListTile({Key? key}) : super(key: key);
//
//   @override
//   _CustomItemListTileState createState() => _CustomItemListTileState();
// }
//
// class _CustomItemListTileState extends State<CustomItemListTile> {
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       Image.network(data['images'][0])
//     );
//   }
// }


class CustomItemListing extends StatefulWidget {
  const CustomItemListing({Key? key, required this.itemName, required this.itemDesc, required this.itemPrice, required this.itemImages}) : super(key: key);

  final String itemName;
  final String itemDesc;
  final String itemPrice;
  final List<dynamic>? itemImages;

  @override
  _CustomItemListingState createState() => _CustomItemListingState();
}

class _CustomItemListingState extends State<CustomItemListing> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      child: GestureDetector(
        child: Container(
          child: SingleChildScrollView(
            child:Column(
              children: <Widget>[
                widget.itemImages != null ? Image.network(widget.itemImages![0]) : Text('No images'),

                Text(widget.itemName,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(widget.itemDesc,
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                Text('\$ ${widget.itemPrice}',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onTap: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Tapped'),
                );
              }
              );
          },
      ),
      padding: EdgeInsets.all(5.0),
    );
  }
}

class SellScreen extends StatefulWidget {
  const SellScreen({Key? key}) : super(key: key);

  @override
  _SellScreenState createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? itemName;
  String? itemDesc;
  String? itemPrice;
  final RegExp priceMatch = RegExp(r'^[1-9]\d*(\.\d{2})$');
  List<String> itemImages = [];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child:Center(
          child: Column(
            children: <Widget>[
              Container(
                child: Text("Sell Screen", style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold)
                ),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.black,
                        width: 8
                    )
                ),
                margin: const EdgeInsets.all(10.0),
              ),

              Container(
                child: Form(
                    key: formKey,
                    child: Column(
                        children: <Widget>[
                          Row(
                              children: <Widget>[
                                Icon(Icons.new_label),
                                Expanded(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        hintText:  'Item Name'
                                    ),
                                    onChanged: (value) => itemName = value,
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an item name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                          ),

                          Row(
                              children: <Widget>[
                                Icon(Icons.description),
                                Expanded(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                        hintText:  'Item Description'
                                    ),
                                    onChanged: (value) => itemDesc = value,
                                    maxLines: 8,
                                    validator: (String? value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter an item name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                          ),

                          Row(
                              children: <Widget>[
                                Icon(Icons.price_change),
                                Expanded(
                                  child: TextFormField(
                                      decoration: InputDecoration(
                                          hintText:  'Item Price'
                                      ),
                                      keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
                                      onChanged: (value) => itemPrice = value,
                                      validator: (String? value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter an item price';
                                        } else {
                                          if (priceMatch.hasMatch(value)) {
                                            return null;
                                          }
                                          return 'Please enter a valid item price';
                                        }
                                      }),
                                ),
                              ],
                          ),
                        ],
                    )
                ),
                margin: const EdgeInsets.all(10.0),
                width: 300.0,
              ),

              ElevatedButton(
                  child: Container(
                    child: Row(
                        children: <Widget>[
                          Spacer(),
                          Icon(Icons.photo_camera),
                          Expanded(
                            child: Text('Camera'),
                          ),
                          Spacer(),
                        ]
                    ),
                    margin: const EdgeInsets.all(20.0),
                    height: 50.0,
                    width: 200.0,
                  ),
                  onPressed: () async {
                    final String newImage = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TakePicture()),
                    );
                    setState(() {
                      itemImages.add(newImage);
                    });
                  },
              ),

              SizedBox(
                height: 5.0,
              ),

              ElevatedButton(
                child: Container(
                  child: Row(
                      children: <Widget>[
                        Spacer(),
                        Icon(Icons.image),
                        Expanded(
                          child: Text('Images'),
                        ),
                        Spacer(),
                      ]
                  ),
                  margin: const EdgeInsets.all(20.0),
                  height: 50.0,
                  width: 200.0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DisplayImages(imagesList: itemImages)),
                  );
                },
              ),

              SizedBox(
                height: 5.0,
              ),

              ElevatedButton(
                child: Container(
                  child: Row(
                      children: <Widget>[
                        Spacer(),
                        Icon(Icons.upload),
                        Expanded(
                          child: Text('Upload'),
                        ),
                        Spacer(),
                      ]
                  ),
                  margin: const EdgeInsets.all(20.0),
                  height: 50.0,
                  width: 200.0,
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return UploadData(
                            name: itemName!,    // ! guarantees non-null
                            desc: itemDesc!,
                            price: itemPrice!,
                            imagePaths: itemImages,
                          );
                        }
                      )
                    );
                  }
                },
              ),
            ],
          ),
        )
    );
  }
}

class TakePicture extends StatefulWidget {
  const TakePicture({Key? key}) : super(key: key);

  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {
  late CameraController controller;
  late Future<void> initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras.first, ResolutionPreset.max);
    initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: CameraPreview(controller),
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await initializeControllerFuture;
            final image = await controller.takePicture();
            final String imagePath = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return ConfirmPicture(imagePath: image.path);
                }
              )
            );
            Navigator.pop(context, imagePath);
          } catch (e) {
            print(e);
          }
        },
      )
    );
  }
}

class ConfirmPicture extends StatefulWidget {
  ConfirmPicture({Key? key, required this.imagePath}) : super(key: key);

  final String imagePath;

  @override
  _ConfirmPictureState createState() => _ConfirmPictureState();
}

class _ConfirmPictureState extends State<ConfirmPicture> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.file(File(widget.imagePath))
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.upload),
        onPressed: () {
          Navigator.pop(context, widget.imagePath);
        }
      ),
    );
  }
}

class DisplayImages extends StatefulWidget {
  const DisplayImages({Key? key, required this.imagesList}) : super(key: key);

  final List<String> imagesList;

  @override
  _DisplayImagesState createState() => _DisplayImagesState();
}

class _DisplayImagesState extends State<DisplayImages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Display Images'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: 2/3,
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            child: Container(
              child: Image.file(File(widget.imagesList[index])),
              constraints: BoxConstraints(
                maxWidth: 100.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2.0,
                ),
              ),
              margin: EdgeInsets.all(5.0),
            ),
            onTap: () async {
              final String removeImage = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RemoveImage(imagePath: widget.imagesList[index])
                  )
              );
              setState(() {
                widget.imagesList.remove(removeImage);
              });
            }
            );
          },
        itemCount: widget.imagesList.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}

class RemoveImage extends StatefulWidget {
  const RemoveImage({Key? key, required this.imagePath}) : super(key: key);

  final String imagePath;

  @override
  _RemoveImageState createState() => _RemoveImageState();
}

class _RemoveImageState extends State<RemoveImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
          child: Image.file(File(widget.imagePath))
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.delete),
          onPressed: () {
            Navigator.pop(context, widget.imagePath);
          }
      ),
    );
  }
}


class UploadData extends StatefulWidget {
  const UploadData({Key? key, required this.name, required this.desc, required this.price, required this.imagePaths}) : super(key: key);

  final String name;
  final String desc;
  final String price;
  final List<String> imagePaths;

  @override
  _UploadDataState createState() => _UploadDataState();
}

class _UploadDataState extends State<UploadData> {
  CollectionReference listedItems = FirebaseFirestore.instance.collection('listedItems');
  String uploadDateTime = DateTime.now().millisecondsSinceEpoch.toString();
  List<String> imageUrls = [];

  Future<void> listItem() {
    for (String imagePath in widget.imagePaths) {
      File fileToUpload = File(imagePath);
      String fileName = "product-" + DateTime.now().millisecondsSinceEpoch.toString() + '.png';
      FirebaseStorage.instance.ref().child('products/' + uploadDateTime + '/' + fileName).putFile(
          fileToUpload).then((taskEvent) {
            if (taskEvent.state == TaskState.success) {
              FirebaseStorage.instance.ref().child("products/" + uploadDateTime + '/' + fileName).getDownloadURL()
                  .then((value) {
                    print(value);
                    imageUrls.add(value);
              }).catchError((error) {
                print("Failed to get URL");
                print(error);
              });
            }
          });
    }
    print(imageUrls);
    return listedItems.add({
      'name' : widget.name,
      'description' : widget.desc,
      'price' : widget.price,
      'images' : imageUrls,
    })
        .then((value) => print('Item listed'))
        .catchError((error) => print("Failed to list item: $error"));
  }

  @override
  Widget build(BuildContext context) {
    print(widget.name);
    print(widget.desc);
    print(widget.price);

    return Expanded(
      child: Column(
        children: <Widget>[
          Text(widget.name + ' ' + widget.desc + ' ' + widget.price),
          Expanded(
            child: ElevatedButton(
              child: Text("List Item",
                  style: TextStyle(fontSize: 50.0)),
              onPressed: listItem,
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.stretch,
      ),
    );
  }
}

class ItemScreen extends StatelessWidget{
  ItemScreen({required this.imageLink, required this.imageDescription});

  final String imageLink;
  final String imageDescription;

  @override
  Widget build(BuildContext context) {
    return Text('$imageLink, $imageDescription');
  }
}
