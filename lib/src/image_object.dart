import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageObject {
  int version;
  Reference? reference;
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
      'version': this.version,
      'localPath': this.localPath,
      'bucket': this.bucket,
      'remotePath': this.remotePath,
      'uri': this.uri,
    };
  }

  factory FirebaseImageObject.fromMap(Map<String, dynamic> map) {
    return FirebaseImageObject(
      version: map["version"] ?? -1,
      reference: map["reference"],
      localPath: map["localPath"],
      bucket: map["bucket"],
      remotePath: map["remotePath"],
    );
  }
}
