# Why a fork ?

This fork is meant to propose a solution to use FirebaseImage plugin on any platform, even if `sqflite` and `dart:io` are not available. In particular, it is now possible to use this plugin on the Web.

:warning: Warnings:

- This is not a maintained nor a tested fork. I use it only for a hobby project running on both Web and Android platforms.
- On `Web` platform, the "cache" is done in memory. This is an important limitation since memory is neither shared between tabs nor persistent.

## Fork implementation

I'm a complete beginner with Flutter/Dart so I went for the simplest solution here. I used [this blog article](https://medium.com/@rody.davis.jr/how-to-build-a-native-cross-platform-project-with-flutter-372b9e4b504f) as inspiration.

Main ideas:

- The `FirebaseImageCacheManager` class is abstracted by `AbstractedFirebaseImageCacheManager`.
- The sqflite-based `FirebaseImageCacheManager` is kept as it is (few minor naming changes).
- A memory-based `FirebaseImageCacheManager` is implemented using a simple `Map` object.
- Depending on the presence of `sqflite` dart package, the right cache manager is exported.

# 🔥 Firebase Image Provider

[![pub package](https://img.shields.io/pub/v/firebase_image.svg)](https://pub.dartlang.org/packages/firebase_image)

A cached Flutter ImageProvider for Firebase Cloud Storage image objects.

## How to use

Make sure you already have [Firebase set up](https://firebase.google.com/docs/flutter/setup) on all platforms you want to use this on.

Supply the `FirebaseImage` widget with the image's URI (e.g. `gs://bucket123/userIcon123.jpg`) and then put that in any widget that accepts an `ImageProvider` (most image related widgets will (e.g. `Image`, `ImageIcon`, etc.)). Please note that you do need the `gs://` prefix currently.

See the below for example code.

## How does it work?

The code downloads the image (object) into memory as a byte array.

Unless disabled using the `cacheRefreshStrategy: CacheRefreshStrategy.NEVER` option, it gets the object's last update time from metadata (a millisecond precision integer timstamp) and uses that as a defacto version number. Therefore, any update to that remote object will result in the new version being downloaded.

The image byte array in memory then gets saved to a file in the temporary directory of the app and that location is saved in a persistant database. The OS can clean up this directory at any time however.

Metadata retrival is a 'Class B Operation' and has 50,000 free operations per month. After that, it is billed at $0.04 / 100,000 operations and so the default behaviour of `cacheRefreshStrategy: CacheRefreshStrategy.BY_METADATA_DATE` may incur extra cost if the object never changes. This makes this implementation a cost effective stratergy for caching as the entire object doesn't have to be transfered just to check if there have been any updates. Essentailly, any images will only need to be downloaded once per device.

## Example

```dart
import 'package:flutter/material.dart';
import 'package:firebase_image/firebase_image.dart';

class IconImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase Image Provider example'),
      ),
      body: Image(
        image: FirebaseImage('gs://bucket123/userIcon123.jpg'),
        // Works with standard parameters, e.g.
        fit: BoxFit.fitWidth,
        width: 100,
        // ... etc.
      ),
    );
  }
}
```

## To Do

- [x] Add examples to [pub.dev](https://pub.dartlang.org/packages/firebase_image#-example-tab-)
- [ ] Clear items from cache if they haven't been accessed after a certain amount of time (2 weeks?)
- [ ] Add more documentation/comments
- [ ] Create unit tests

## Contributing

If you want to contribute, please fork the project and play around there!

If you're stuck for ideas, check [Issues](https://github.com/mattreid1/firebase_image/issues) or the above To Do list for inspiration.

Please check PRs and other peoples forks to see if anyone is working on something similiar to what you want to do.

Once you're ready, please submit a pull request.
