class FirebaseImageObject {
  int id;
  int version;
  String localPath;
  String remotePath;
  String bucket;

  FirebaseImageObject({
    this.id = -1,
    this.version = -1,
    this.localPath,
    this.bucket,
    this.remotePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': this.id,
      'version': this.version,
      'localPath': this.localPath,
      'bucket': this.bucket,
      'remotePath': this.remotePath,
    };
  }

  FirebaseImageObject.fromMap(Map<String, dynamic> map) {
    this.id = map["id"] ?? -1;
    this.version = map["version"] ?? -1;
    this.localPath = map["localPath"] ?? null;
    this.remotePath = map["remotePath"] ?? null;
    this.bucket = map["bucket"] ?? null;
  }
}
