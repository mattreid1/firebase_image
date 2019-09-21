import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageObject {
  int id;
  int version;
  StorageReference reference;
  String localPath;
  String remotePath;
  String bucket;
  String uri;

  FirebaseImageObject({
    this.id = -1,
    this.version = -1,
    this.reference,
    this.localPath,
    this.bucket,
    this.remotePath,
  }) : uri = '$bucket$remotePath';

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'version': this.version,
      'localPath': this.localPath,
      'bucket': this.bucket,
      'remotePath': this.remotePath,
      'uri': this.uri,
    };
  }

  FirebaseImageObject.fromMap(Map<String, dynamic> map) {
    this.id = map["id"] ?? -1;
    this.version = map["version"] ?? -1;
    this.reference = map["reference"] ?? null;
    this.localPath = map["localPath"] ?? null;
    this.remotePath = map["remotePath"] ?? null;
    this.bucket = map["bucket"] ?? null;
    this.uri = '${this.bucket}${this.remotePath}' ?? null;
  }
}
