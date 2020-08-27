enum ImageFetchStrategy {
  // Asynchronously downloads the object at the StorageReference to a list in memory.
  // A list of the provided max size will be allocated.
  FETCH_TO_MEMORY,
  // Asynchronously downloads the object to a specified system file.
  FETCH_TO_FILE,
}