import 'package:firebase_core/firebase_core.dart';
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

  factory FirebaseImageObject.fromMap(
    Map<String, dynamic> map,
    FirebaseApp? firebaseApp,
  ) {
    final remotePath = map['remotePath'] as String;
    final bucket = map['bucket'] as String;
    final reference = getImageRef(
      bucket: bucket,
      remotePath: remotePath,
      firebaseApp: firebaseApp,
    );

    return FirebaseImageObject(
      reference: reference,
      version: map['version'] as int? ?? -1,
      localPath: map['localPath'] as String?,
      bucket: bucket,
      remotePath: remotePath,
    );
  }

  static Reference getImageRef({
    required String bucket,
    required String remotePath,
    FirebaseApp? firebaseApp,
  }) {
    final storage =
        FirebaseStorage.instanceFor(app: firebaseApp, bucket: bucket);
    return storage.ref().child(remotePath);
  }
}
