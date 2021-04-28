import 'package:flutter/material.dart';
import 'package:firebase_image/firebase_image.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Image Provider Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Firebase Image Provider example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Image(
        image: FirebaseImage('gs://bucket123/userIcon123.jpg',
            shouldCache: true, // The image should be cached (default: True)
            maxSizeBytes: 3000 * 1000, // 3MB max file size (default: 2.5MB)
            cacheRefreshStrategy: CacheRefreshStrategy.NEVER,
            errorAssetImage:
                'assets/some_image.png' // Switch off update checking
            ),
        width: 100,
      ),
    );
  }
}
