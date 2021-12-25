import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageObject {
  int version;
  final Reference reference;
  String? localPath;
  final String remotePath;
  final String bucket;
  final String uri;

  FirebaseImageObject({
    this.version = -1,
    required this.reference,
    this.localPath,
    required this.bucket,
    required this.remotePath,
  }) : uri = '$bucket$remotePath';

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'localPath': localPath,
      'bucket': bucket,
      'remotePath': remotePath,
      'uri': uri,
    };
  }

  factory FirebaseImageObject.fromMap(Map<String, dynamic> map,
      [FirebaseApp? firebaseApp]) {
    final String bucket = map['bucket'];
    final String remotePath = map['remotePath'];
    return FirebaseImageObject(
      version: map["version"] ?? -1,
      reference: _getImageRef(bucket, remotePath, firebaseApp),
      localPath: map["localPath"],
      bucket: bucket,
      remotePath: remotePath,
    );
  }

  static Reference _getImageRef(
      String bucket, String remotePath, FirebaseApp? firebaseApp) {
    FirebaseStorage storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: bucket);
    return storage.ref().child(remotePath);
  }
}
