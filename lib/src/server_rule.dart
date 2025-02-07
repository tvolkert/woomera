part of woomera;

//----------------------------------------------------------------
/// Represents a rule for processing HTTP requests.
///
/// A rule consists of a pattern and a handler. If the pattern
/// matches the request, then the handler is invoked to process
/// the request.
///
/// Rules are added to a [ServerPipeline], and piplelines are added to a
/// [Server].

class ServerRule {
  //----------------------------------------------------------------
  /// Constructor.
  ///
  /// The [pathPattern] determines if a HTTP request matches this rule or not.
  /// It is a path made up of segments separated by slashes "/".
  ///
  /// There are different types of segments:
  ///
  /// - variable
  /// - wildcard
  /// - literal
  ///
  /// Examples
  ///
  /// "" - no segments
  /// "/" - no segments
  /// "/foo" - one literal segment
  /// "/foo/bar" - two literal segments
  /// "/foo/bar/" - three literal segments
  ///
  /// "/foo/bar/:abc"
  /// "/foo/*"
  /// "/foo/bar?/baz"

  ServerRule(String pathPattern, this.handler) : assert(pathPattern != null) {
    _segments = pathPattern.split(_pathSeparator);

    assert(_segments.isNotEmpty);
    assert(_segments[0] == '~', 'ServerRule path does not start with ~');

    _segments.removeAt(0); // remove the leading "~".

    while (_segments.isNotEmpty && _segments[0].isEmpty) {
      _segments.removeAt(0); // remove leading slashes "/", "//", "/////"
    }

    // Examples:
    //  "" -> empty list
    //  "/" -> empty list
    //  "/foo -> "foo"
    //  "/foo/bar -> "foo", "bar"
    //  "/foo/bar/" -> "foo", "bar", ""
  }

  //================================================================
  // Defining the pattern syntax

  static const String _pathSeparator = "/";
  static const String _variablePrefix = ":";
  static const String _splat = "*";
  static const String _optionalSuffix = "?";

  //================================================================

  //----------------------------------------------------------------

  List<String> _segments;

  /// The request handler callback method.

  RequestHandler handler;

  //================================================================

  static bool _isWildcard(String s) => (s == _splat);

  static bool _isVariable(String s) => s.startsWith(_variablePrefix);

  static String _variableName(String str) {
    var s = str.substring(_variablePrefix.length);
    if (_isOptional(s)) {
      s = s.substring(0, s.length - _optionalSuffix.length);
    }
    return s;
  }

  static bool _isOptional(String s) => s.endsWith(_optionalSuffix);

  //----------------------------------------------------------------

  RequestParams _matches(List<String> components) {
    final result = new RequestParams._internalConstructor();

    var componentIndex = 0;
    var segmentIndex = 0;
    for (var segment in _segments) {
      String component;
      if (components.length <= componentIndex) {
        if (_isWildcard(segment)) {
          component = null; // wildcard can match no components
        } else {
          return null; // no component(s) to match this segment
        }
      } else {
        component = components[componentIndex];
      }

      if (_isVariable(segment)) {
        // Variable segment
        result._add(_variableName(segment), component);
        componentIndex++;
      } else if (_isWildcard(segment)) {
        // Wildcard segment
        final numSegmentsLeft = _segments.length - segmentIndex - 1;
        final numConsumed =
            components.length - componentIndex - numSegmentsLeft;
        if (numConsumed < 0) {
          return null; // insufficient components to satisfy rest of pattern
        }
        result._add(
            _splat,
            components
                .getRange(componentIndex, componentIndex + numConsumed)
                .join(_pathSeparator));
        componentIndex += numConsumed;
      } else if (segment == component) {
        // Fixed value segment
        componentIndex++;
      } else if (_isOptional(segment)) {
        // No match, but segment is optional so skip it
        // do nothing
      } else {
        // No match
        return null;
      }

      segmentIndex++;
    }

    if (componentIndex != components.length) {
      return null; // some components did not match
    }

    return result;
  }

  //----------------------------------------------------------------

  /// Prints the pattern
  ///
  @override
  String toString() {
    if (_segments.isEmpty) {
      return "~/";
    } else {
      return "~$_pathSeparator${_segments.join(_pathSeparator)}";
    }
  }
}
