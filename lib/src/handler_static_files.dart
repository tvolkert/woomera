part of woomera;

//================================================================
/// Handler for returning a static files under a local directory.
///

class StaticFiles {
  /// Global MIME types.
  ///
  /// This is used for matching file extensions to MIME types. The file
  /// extensions are strings without the full stop (e.g. "png").
  ///
  /// This list is only examined if a match was not found in the
  /// local [mimeTypes]. If a match could not be found in this global map,
  /// the default of [ContentType.BINARY] is used.

  static Map<String, ContentType> globalMimeTypes = {
    "txt": ContentType.TEXT,
    "html": ContentType.HTML,
    "htm": ContentType.HTML,
    "json": ContentType.JSON,
    "css": new ContentType("text", "css"),
    "png": new ContentType("image", "png"),
    "jpg": new ContentType("image", "jpeg"),
    "jpeg": new ContentType("image", "jpeg"),
    "gif": new ContentType("image", "gif"),
    "xml": new ContentType("application", "xml"),
  };

  //================================================================
  /// The directory under which to look for files.

  String baseDir;

  /// Names of files to try to find if a directory is requested.
  ///
  /// If a request arrives for a directory and this is not null, an attempt is
  /// made to return one of these files from the directory. If none of these
  /// files are found, [allowDirectoryListing] determines if a listing is
  /// generated or an error is raised.

  List<String> defaultFilenames;

  /// Permit listing of directory contents.
  ///
  /// If a request arrives for a directory, the default file could not be
  /// used (i.e. [defaultFilename] is null or a file with that name could not
  /// be found in the directory), then this member indicates whether a
  /// listing of the directory is returned or [NotFoundException] is raised.

  bool allowDirectoryListing;

  /// Interpret paths that do not end in slash as directory if not a file.
  ///
  /// If a path does not end with a slash it is treated as a request for a
  /// file. But if a file does not exist with that name, this determines if
  /// it will then be treated as a path to a directory.

  bool allowFilePathsAsDirectories;

  /// Throws not found exceptions.
  ///
  /// If true, the handler will thrown a [StaticNotFoundException] if the
  /// file or directory could not produce a result.
  ///
  /// If false, the handler will return null.

  bool throwNotFoundExceptions;

  /// Local MIME types.
  ///
  /// This is used for matching file extensions to MIME types. The file
  /// extensions are strings without the full stop (e.g. "png").
  ///
  /// This list is examined in preference to the [globalMimeTypes] map.

  Map<String, ContentType> mimeTypes = new Map<String, ContentType>();

  //----------------------------------------------------------------
  /// Constructor
  ///
  /// Requests for a directory (i.e. path ending in "/")
  /// returns the [defaultFile] in the directory (if it is set and that file
  /// exists), otherwise if [allowDirectoryListing] is true
  /// a listing of the directory is produced, otherwise an exception is thrown.

  StaticFiles(String directory,
      {List<String> defaultFilenames,
      bool allowDirectoryListing: false,
      bool allowFilePathsAsDirectories: true,
      bool throwNotFoundExceptions: true}) {
    if (directory == null) {
      throw new ArgumentError.notNull("directory");
    }
    if (directory.isEmpty) {
      throw new ArgumentError.value(directory, "directory", "Empty string");
    }
    baseDir = directory;

    if (defaultFilenames != null) {
      this.defaultFilenames = defaultFilenames;
    } else {
      this.defaultFilenames = []; // empty list
    }
    this.allowDirectoryListing = allowDirectoryListing;
    this.allowFilePathsAsDirectories = allowFilePathsAsDirectories;
    this.throwNotFoundExceptions = throwNotFoundExceptions;
  }

  //----------------------------------------------------------------
  /// Handler

  Future<Response> handler(Request req) async {
    if (baseDir == null) {
      throw new ArgumentError.notNull("baseDir");
    }
    if (baseDir.isEmpty) {
      throw new ArgumentError.value(baseDir, "baseDir", "Empty string");
    }

    // Get the relative path

    var values = req.pathParams.values("*");
    if (values.length < 1) {
      throw new ArgumentError("Static file handler registered with no *");
    } else if (1 < values.length) {
      throw new ArgumentError("Static file handler registered with multiple *");
    }
    var components = values[0].split("/");
    var depth = 0;
    while (0 <= depth && depth < components.length) {
      var c = components[depth];
      if (c == "..") {
        components.removeAt(depth);
        depth--;
        if (depth < 0) {
          if (throwNotFoundExceptions) {
            // tried to climb above base directory
            throw new NotFoundException(NotFoundException.foundStaticHandler);
          } else {
            return null;
          }
        }
      } else if (c == ".") {
        components.removeAt(depth);
      } else if (c.isEmpty && depth != components.length - 1) {
        components.removeAt(depth); // keep last "" to indicate dir listing
      } else {
        depth++;
      }
    }

    var path = baseDir + "/" + components.join("/");
    _logRequest
        .finer("[${req.id}] static file/directory requested: $path");

    bool wasFilePath = false;

    if (!path.endsWith("/")) {
      // Probably a file

      var file = new File(path);
      if (await file.exists()) {
        _logRequest.finest("[${req.id}] static file found: $path");
        return await _serveFile(req, file);
      }

      if (allowFilePathsAsDirectories) {
        path += "/"; // append a "/" to try and treat it as a directory
        wasFilePath = true;
      } else {
        _logRequest.finest("[${req.id}] static file not found");
      }
    }

    if (path.endsWith("/")) {
      // Try directory

      if (await new Directory(path).exists()) {
        // Try to find one of the default files in that directory

        for (var defaultFilename in defaultFilenames) {
          var dfName = path + defaultFilename;
          var df = new File(dfName);
          if (await df.exists()) {
            _logRequest.finest("[${req
                .id}] static directory: default file found: $dfName");
            return await _serveFile(req, df);
          }
        }

        if (allowDirectoryListing) {
          // List the contents of the directory
          _logRequest.finest("[${req.id}] returning directory listing");
          return await _serveDirectoryListing(req, path);
        } else {
          _logRequest.finest(
              "[${req.id}] static directory listing not allowed");
        }
      } else {
        if (wasFilePath) {
          _logRequest.finest(
              "[${req.id}] static file not found (even tried directory)");
        } else {
          _logRequest.finest("[${req.id}] static directory not found");
        }
      }
    }

    // Not found (or directory listing not allowed)

    if (throwNotFoundExceptions) {
      throw new NotFoundException(NotFoundException.foundStaticHandler);
    } else {
      return null;
    }
  }

  //----------------------------------------------------------------

  Future<Response> _serveDirectoryListing(Request req, String path) async {
    var dir = new Directory(path);
    if (!await dir.exists()) {
      if (throwNotFoundExceptions) {
        throw new NotFoundException(NotFoundException.foundStaticHandler);
      } else {
        return null;
      }
    }

    var str = """
<html>
<head>
<title>Listing</title>
</head>
<body>
<h1>Listing</h1>
<ul>
    """;

    await for (var entity in dir.list()) {
      var name;
      if (entity is Directory) {
        name =
            entity.uri.pathSegments[entity.uri.pathSegments.length - 2] + "/";
      } else {
        name = entity.uri.pathSegments.last;
      }
      str += "<li><a href=\"${name}\">${name}</a></li>\n";
    } // TODO: HEsc the above href and text

    str += """
</ul>
</body>
</html>
    """;

    var resp = new ResponseBuffered(ContentType.HTML);
    resp.write(str);
    return resp;
  }

  //----------------------------------------------------------------

  Future<Response> _serveFile(Request req, File file) async {
    // Determine content type

    var contentType;

    var p = file.path;
    var dotIndex = p.lastIndexOf(".");
    if (0 < dotIndex) {
      var slashIndex = p.lastIndexOf("/");
      if (slashIndex < dotIndex) {
        // Dot is in the last segment
        var suffix = p.substring(dotIndex + 1);
        suffix = suffix.toLowerCase();
        contentType = mimeTypes[suffix] ?? globalMimeTypes[suffix];
      }
    }

    contentType = contentType ?? ContentType.BINARY; // default if not known

    // Return contents of file

    var resp = new ResponseStream(contentType);
    return await resp.addStream(req, file.openRead());
  }
}
