part of woomera;

//================================================================
// Exception Base class

/// Base class for all exceptions defined in the Woomera package.

abstract class WoomeraException implements Exception {}

//================================================================
// Limit exceptions

//----------------------------------------------------------------
/// Exception indicating the URL path is too large.
///
/// Usually this means a malformed or malicious request has been received.
/// It has stopped trying to parse/process it to avoid consuming
/// resources in what could be a denial-of-service attack.
///
/// If the request is a legitimate request for the application, the
/// limits on the server need to be increased.

class PathTooLongException extends WoomeraException {}

//----------------------------------------------------------------
/// Exception indicating the contents of the POST request is too large.
///
/// Usually this means a malformed or malicious request has been received.
/// It has stopped trying to parse/process it to avoid consuming
/// resources in what could be a denial-of-service attack.
///
/// If the request is a legitimate request for the application, the
/// limits on the server need to be increased.

class PostTooLongException extends WoomeraException {}

//================================================================
// Handler matching exceptions

//----------------------------------------------------------------
/// Exception indicating a response could not be created.
///
class NotFoundException extends WoomeraException {

  /// Value for [found] when no handlers for the HTTP method were found.

  static int foundNothing = 0;

  /// Value for [found] when at least one handler for the HTTP method
  /// was found, but none of them matched the request path.

  static int foundMethod = 1;

  /// Value for [found] when a handler was found, but no result was produced.

  static int foundHandler = 2;

  /// Value for [found] when a [StaticFile] handler failed to produce a response.
  ///
  /// The [StaticFile.handler] failed to find a file or directory. In the case
  /// of a directory, this could be because the directory could not be read,
  /// the default file in the directory could not be read, or an automatic
  /// listing of the directory was not permitted.

  static int foundStaticHandler = 3;

  /// Indicates how much was found before a result could not be created.
  ///
  /// This member is typically used to distinguish between the situation of
  /// the HTTP method not being supported (when its value is
  /// [NotFoundException.foundNothing] and when at least there were some rules
  /// for processing the HTTP method (when its value is any other value).
  /// In the former situation, the HTTP response should return a status of
  /// [HttpStatus.METHOD_NOT_ALLOWED]. In the later situation, the HTTP
  /// response should return a status of [HttpStatus.NOT_FOUND].

  int found;

  NotFoundException(int found) {
    this.found = found;
  }
}

//================================================================
// Exception handling exception

//----------------------------------------------------------------
/// Exception indicating an exception occurred in an exception handler.
///
/// The exception that was raised by the exception handler is stored in
/// [exception].
///
/// The exception that was passed into the exception handler was
/// [previousException]. Note: it could be an instance of
/// [ExceptionHandlerException] when multiple exception handlers are invoked
/// in processing an exception.
///
class ExceptionHandlerException extends WoomeraException {
  Object previousException;

  /// The exception that the exception handler was processing.
  Object exception;

  ExceptionHandlerException(this.previousException, this.exception);
}
