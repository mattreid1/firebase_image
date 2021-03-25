import 'package:firebase_storage/firebase_storage.dart';

class FirebaseImageObject {
  int version;
  Reference reference;
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
    return <String, dynamic>{
      'version': version,
      'localPath': localPath,
      'bucket': bucket,
      'remotePath': remotePath,
      'uri': uri,
    };
  }

  factory FirebaseImageObject.fromMap(Map<String, dynamic> map) {
    return FirebaseImageObject(
      version: map['version'] as int? ?? -1,
      reference: map['reference'] as Reference,
      localPath: map['localPath'] as String?,
      bucket: map['bucket'] as String,
      remotePath: map['remotePath'] as String,
    );
  }
}
