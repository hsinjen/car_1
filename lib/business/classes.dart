//library engineu;

class KeyValueItem<T, U> {
  T key;
  U value;

  KeyValueItem(this.key, this.value);
}

class FileItem {
  final FileSourceType fileSourceType;
  final String fileName;
  final String fileExtName;
  final int fileSize;
  final String fileUrl;
  final String fileRef1;
  final String fileRef2;
  final String fileRef3;

  FileItem(this.fileSourceType, this.fileName, this.fileExtName, this.fileSize,
      this.fileUrl,
      {this.fileRef1 = '', this.fileRef2 = '', this.fileRef3 = ''});
}

enum FileSourceType { online, offline }