import 'dart:io';
import 'dio.dart';

/// ResponseType indicates which transformation should
/// be automatically applied to the response data by Dio.
enum ResponseType {
  /// Transform the response data to JSON object.
  json,

  /// Get the response stream without any transformation.
  stream,

  /// Transform the response data to a String encoded with UTF8.
  plain
}

typedef bool ValidateStatus(int status);

/// Dio instance request config
/// `dio.options` is a instance of [BaseOptions]
class BaseOptions extends _RequestConfig {
  BaseOptions({
    String method,
    int connectTimeout,
    int receiveTimeout,
    Iterable<Cookie> cookies,
    this.baseUrl,
    this.queryParameters,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError: true,
    bool followRedirects: true,
  }) : super(
          method: method,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          cookies: cookies,
        );

  /// Create a new Option from current instance with merging attributes.
  BaseOptions merge({
    String method,
    String baseUrl,
    String path,
    int connectTimeout,
    int receiveTimeout,
    dynamic data,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
  }) {
    return new BaseOptions(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? new Map.from(this.extra ?? {}),
      headers: headers ?? new Map.from(this.headers ?? {}),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
    );
  }

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  Map<String, dynamic /*String|Iterable<String>*/ > queryParameters;
}

/**
 * Every request can pass an [Options] object which will be merged with [Dio.options]
 */
class Options extends _RequestConfig {
  Options({
    String method,
    String baseUrl,
    int connectTimeout:0,
    int receiveTimeout:0,
    Iterable<Cookie> cookies,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError: true,
    bool followRedirects: true,
  }) : super(
          method: method,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
          cookies: cookies,
        );

  /// Create a new Option from current instance with merging attributes.
  Options merge({
    String method,
    String baseUrl,
    String path,
    int connectTimeout,
    int receiveTimeout,
    dynamic data,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    Iterable<Cookie> cookies,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError,
    bool followRedirects,
  }) {
    return new Options(
      method: method ?? this.method,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      extra: extra ?? new Map.from(this.extra ?? {}),
      headers: headers ?? new Map.from(this.headers ?? {}),
      responseType: responseType ?? this.responseType,
      contentType: contentType ?? this.contentType,
      cookies: cookies?? this.cookies??[],
      validateStatus: validateStatus ?? this.validateStatus,
      receiveDataWhenStatusError:
          receiveDataWhenStatusError ?? this.receiveDataWhenStatusError,
      followRedirects: followRedirects ?? this.followRedirects,
    );
  }
}

class RequestOptions extends Options {
  RequestOptions({
    String method,
    int connectTimeout,
    int receiveTimeout,
    Iterable<Cookie> cookies,
    this.data,
    this.path,
    this.queryParameters,
    this.baseUrl,
    Map<String, dynamic> extra,
    Map<String, dynamic> headers,
    ResponseType responseType,
    ContentType contentType,
    ValidateStatus validateStatus,
    bool receiveDataWhenStatusError: true,
    bool followRedirects: true,
  }) : super(
          method: method,
          baseUrl: baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          cookies:cookies,
          extra: extra,
          headers: headers,
          responseType: responseType,
          contentType: contentType,
          validateStatus: validateStatus,
          receiveDataWhenStatusError: receiveDataWhenStatusError,
          followRedirects: followRedirects,
        );

  /// generate uri
  Uri get uri {
    String _url=path;
    if (!_url.startsWith(new RegExp(r"https?:"))) {
      _url = baseUrl + _url;
      List<String> s = _url.split(":/");
      _url = s[0] + ':/' + s[1].replaceAll("//", "/");
    }
    _url += (_url.contains("?") ? "&" : "?") +
        Uri(queryParameters: queryParameters).query;
    // Normalize the url.
    return Uri.parse(_url).normalizePath();
  }

  /// Request data, can be any type.
  dynamic data;

  /// Request base url, it can contain sub path, like: "https://www.google.com/api/".
  String baseUrl;

  /// If the `path` starts with "http(s)", the `baseURL` will be ignored, otherwise,
  /// it will be combined and then resolved with the baseUrl.
  String path = "";

  /// See [Uri.queryParameters]
  Map<String, dynamic /*String|Iterable<String>*/ > queryParameters;
}

/**
 * The [_RequestConfig] class describes the http request information and configuration.
 */
class _RequestConfig {
  _RequestConfig({
    this.method,
    this.connectTimeout,
    this.receiveTimeout,
    this.extra,
    this.headers,
    this.responseType,
    this.contentType,
    this.validateStatus,
    this.cookies,
    this.receiveDataWhenStatusError: true,
    this.followRedirects: true,
  }) {
    // set the default user-agent with Dio version
    this.headers = headers ?? {};

    this.extra = extra ?? {};
  }

  /// Http method.
  String method;

  /// Http request headers.
  Map<String, dynamic> headers;

  /// Timeout in milliseconds for opening  url.
  int connectTimeout;

  ///  Whenever more than [receiveTimeout] (in milliseconds) passes between two events from response stream,
  ///  [Dio] will throw the [DioError] with [DioErrorType.RECEIVE_TIMEOUT].
  ///
  ///  Note: This is not the receiving time limitation.
  int receiveTimeout;

  /// The request Content-Type. The default value is [ContentType.json].
  /// If you want to encode request body with "application/x-www-form-urlencoded",
  /// you can set `ContentType.parse("application/x-www-form-urlencoded")`, and [Dio]
  /// will automatically encode the request body.
  ContentType contentType;

  /// [responseType] indicates the type of data that the server will respond with
  /// options which defined in [ResponseType] are `JSON`, `STREAM`, `PLAIN`.
  ///
  /// The default value is `JSON`, dio will parse response string to json object automatically
  /// when the content-type of response is "application/json".
  ///
  /// If you want to receive response data with binary bytes, for example,
  /// downloading a image, use `STREAM`.
  ///
  /// If you want to receive the response data with String, use `PLAIN`.
  ResponseType responseType;

  /// `validateStatus` defines whether the request is successful for a given
  /// HTTP response status code. If `validateStatus` returns `true` ,
  /// the request will be perceived as successful; otherwise, considered as failed.
  ValidateStatus validateStatus;

  bool receiveDataWhenStatusError;

  /// Custom field that you can retrieve it later in [Interceptor]、[Transformer] and the [Response] object.
  Map<String, dynamic> extra;

  /// see [HttpClientRequest.followRedirects]
  bool followRedirects;

  /// Custom Cookies
  List<Cookie> cookies;
}
