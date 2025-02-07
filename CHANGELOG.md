# Changelog

## 4.3.0

- Include query parameters in URL of proxy requests.
- Added support for a low-level exception handler.
- Added headerAddDate method for adding headers with dates.
- Automatically add Content-Length header when using ResponseBuffered.
- Made settings headers in the Response case-independent.

## 4.2.0

- Removed warning when redirecting to an absolute path/URL.
- Updated dependencies to allow uuid v2.0.1 and test v1.6.3 to be used.

## 4.1.0

- Support for using static file handler with reverse proxies on non-standard ports.

## 4.0.1

- Fixed content-type for redirections.
- Fixed bug with redirection URL for directories with static files.

## 4.0.0

- Workaround for bug in Dart 2.1.x which prevents cookies from being deleted.
- Merged in changes from v2.2.2.
- Added proxy handler.
- Simulation mechanism for testing servers.
- Added external path to internal path conversion method.

## 3.0.1

- Fixed problem with publishing documentation on pub.dartlang.org.

## 3.0.0

- Updated the upper bound of the SDK constraint to <3.0.0.
- Changed names to use new Dart 2 names.

## 2.2.2

- Responds with HTTP 400 Bad Request if URL has malformed percent encodings.
- Change logging level for FormatExceptions when parsing query/POST params.

## 2.2.1

- This version runs under Dart 1.
- Updated dependencies to allow for Dart 2 compatible versions to be used.

## 2.2.0

- Changed RequestFactory to return FutureOr<Request> instead of Request.
- Added release method on Request class to perform cleanup operations.
- Deprecated requestFactory: renamed to requestCreator.

## 2.1.1

- Included Length, Last-Modified, and Date HTTP headers for StaticFiles.

## 2.1.0

- Added ability to retrieve the number of active sessions.
- Added access to creation time for sessions.
- Added expiry time for sessions.
- Stopping a server also terminates any sessions.

## 2.0.0

- Code made sound to support Dart strong mode.
- Removed arbitrary properties from Request and Session: use subtypes instead.
- Changed default bindAddress from LOOPBACK_IP_V6 to LOOPBACK_IP_V4.
- Added convenience methods for registering PUT, PATCH, DELETE and HEAD handlers.
- Added coverage tests.

## 1.0.5

- Upgraded version dependency on uuid package.

## 1.0.4

2016-09-29

- Fixed bug with parallel processing of HTTP requests.

## 1.0.3

2016-05-11

- Fixed potential issue with URL rewriting in Chrome with GET forms.

## 1.0.2

2016-05-06

- Improved exception catching in request processing loop.

## 1.0.1

2016-04-28

- Fixed homepage URL.

## 1.0.0

2016-04-23

- Initial release.
