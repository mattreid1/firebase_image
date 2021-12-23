// ignore_for_file: constant_identifier_names
enum CacheRefreshStrategy {
  // BY_METADATA_DATE uses the Storage Object updated timestamp as a version
  // number and checks for updates every time.
  BY_METADATA_DATE,
  // NEVER will never check for any updates. It will still reload a previously-
  // cached version that has been cleaned up by the OS.
  NEVER,
}
