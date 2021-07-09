![](http-transport.png)

<H1 align="center">HTTPTransport</H1>

<p align="center">
<a href="https://cocoapods.org/pods/incetro-http-transport"><img alt="Version" src="https://img.shields.io/cocoapods/v/incetro-http-transport.svg?style=flat"></a> 
<a href="https://github.com/Incetro/incetro-http-transport/blob/master/LICENSE"><img alt="Liscence" src="https://img.shields.io/cocoapods/l/incetro-http-transport.svg?style=flat"></a> 
<a href="https://developer.apple.com/"><img alt="Platform" src="https://img.shields.io/badge/platform-iOS-green.svg"/></a> 
<a href="https://developer.apple.com/swift"><img alt="Swift4.2" src="https://img.shields.io/badge/language-Swift5.3-orange.svg"/></a>
</p>

## Description

This library is an Alamofire wrapper allowing synchronous HTTP requests.

Basically, instead of using callbacks like this:

```swift
Alamofire.request(someRequest).response { reponse in
    if response ...
}
```

**HTTPTransport** allows you to use a regular flow of control like this:

```swift
let result = transport.send(someRequest)

if result ...
```

> **N.B.:** Library authors assume that you know your onions when it comes to build a mobile app, and leave the discussion about
multithreading and synchronous networking drawbacks behind brackets.

# Usage

* [Installation: CocoaPods](#pods)
* [Main actors](#actors)
* [Cook book](#book)
* [Evolution](#evolution)

<a name="pods" />

## Installation: CocoaPods

```ruby
pod 'incetro-http-transport'
```

<a name="actors" />

## Main actors

* [HTTPTransport](#transport)
* [HTTPRequest](#httprequest)
* [HTTPTransport.Result](#result)
* [HTTPRequestParameters](#parameters)
* [Session](#session)
* [Interceptors](#interceptors)
* [NSError](#nserror)

Fundamental concept of the library is pretty straightforward: you have a **request** to send over a **transport** in order to
receive some **result** — these are three main actors you are going to deal with.

<a name="transport" />

### HTTPTransport

Beside making actual HTTP calls, an `HTTPTransport` instance holds non-functional requirements to your connection, like
keeping alive an established HTTP session, applied security measures, and default request and response processing stacks,
including error processing.

```swift
// MARK: - HTTPTransport

open class HTTPTransport {

	// MARK: - Properties

    /// Default timeout gap for synchronous calls (calculated from `URLRequest` timeout)
    public static let defaultSemaphoreTimeoutGap: TimeInterval = 3

    /// TCP/HTTP session between client and server
    /// Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`)
    public let session: Session

    /// Synchronous calls' timeout (counting from `URLRequest` timeout)
    public let semaphoreTimeoutGap: TimeInterval

    /// Collection of interceptors for outgoing HTTP requests
    public let requestInterceptors: [HTTPRequestInterceptor]

    /// Collection of interceptors for incoming HTTP responses
    public let responseInterceptors: [HTTPResponseInterceptor]

    /// Allow using Alamofire `validate()` method
    public let useDefaultValidation: Bool
    
    /// Precondition failure on network calls on main thread is disabled
    public let allowNetworkingOnMainThread: Bool
    ...
}
```

Read about [Session](#session) and [interceptors](#interceptors) below.

<a name="httprequest" />

### HTTPRequest

A Swiss army knife multitool to satisfy all your needs when you are up to construct an HTTP request.

```swift
// MARK: - HTTPTransport

open class HTTPRequest {

    // MARK: - Properties

    /// Default HTTP `URLRequest` timeout
    public static let defaultTimeout: TimeInterval = 30

    /// GET, POST, PUT, PATCH etc.
    public let httpMethod: HTTPMethod

    /// URL endpoint
    public let endpoint: String

    /// HTTP request headers map
    open var headers: [String: String]

    /// Request parameters
    open var parameters: [HTTPRequestParameters]

    /// Collection of request interceptors, see `HTTPRequestInterceptor`
    open var requestInterceptors: [HTTPRequestInterceptor]

    /// Collection of response interceptors, see `HTTPResponseInterceptor`
    open var responseInterceptors: [HTTPResponseInterceptor]

    /// Custom session for this particular HTTP request
    public let session: Session?

    /// Timeout for this particular HTTP request. Default is 30 seconds
    public let timeout: TimeInterval
    ...
}
```

Works mostly as you would expect it to. First of all, it is a container object for an HTTP request envelope fields, including
an `HTTPMethod`, an `endpoint` (URL or its part), request headers and request body.

Second, each `HTTPRequest` instance specifies its own timeout interval, a custom [`Session`](#session) (if needed), and two sets of
[Interceptors](#interceptors) to be applied to this particular request and its response. Most of these options have their default values,
so they won't bother you much.

`HTTPRequest` class provides several ways to modify its contents, including an intelligent constructor, which allows to make
`HTTPRequest` instances based on other `HTTPRequest` instances, see Cook book's [Basic dependent requests](#dependent).

```swift
	/// Add HTTP request header
    @discardableResult open func with(header: String, value: String) -> Self {
        headers[header] = value
        return self
    }

    /// Add Cookie to HTTP request with Cookie name and value
    @discardableResult open func with(cookieName name: String, value: String) -> Self {
        with(cookie: HTTPCookie(name: name, value: value))
    }

    /// Add Cookie to HTTP request
    @discardableResult open func with(cookie: HTTPCookie) -> Self {
        let headers = HTTPCookie.requestHeaderFields(with: [cookie])
        for (header, value) in headers {
            self.headers[header] = value
        }
        return self
    }

    /// Add request parameter
    @discardableResult open func with(
        parameter: String,
        value: Any,
        encoding: HTTPRequestParameters.Encoding = .json
    ) -> Self {
        with(parameters: [parameter: value], encoding: encoding)
    }

    /// Add request parameters
    @discardableResult open func with(
        parameters: [String: Any],
        encoding: HTTPRequestParameters.Encoding = .json
    ) -> Self {
        let newParameters = HTTPRequestParameters(parameters: parameters, encoding: encoding)
        return with(parameters: newParameters)
    }

    /// Add request parameters
    @discardableResult open func with(parameters: HTTPRequestParameters) -> Self {
        with(parameters: [parameters])
    }

    /// Add request parameters
    @discardableResult open func with(parameters: [HTTPRequestParameters]) -> Self {
        self.parameters = type(of: self).merge(baseParameters: self.parameters, withParameters: parameters)
        return self
    }

    /// Add request interceptors
    @discardableResult public func with(interceptors: [HTTPRequestInterceptor]) -> Self {
        self.requestInterceptors += interceptors
        return self
    }

    /// Add response interceptors
    @discardableResult public func with(interceptors: [HTTPResponseInterceptor]) -> Self {
        self.responseInterceptors += interceptors
        return self
    }
```
Example usage:

```swift
let userSearchRequest = HTTPRequest(endpoint: "/user")
	.with(cookieName: "SESSION_ID", value: sessionId)
	.with(parameters: ["first_name": "John", "last_name": "Appleseed"], encoding: .url)
```

Request parameters are represented with a separate container class [`HTTPRequestParameters`](#parameters),
allowing each `HTTPRequest` to include a few sets of parameters encoded differently.

There are two children that extend `HTTPRequest`: `DataUploadHTTPRequest` and `FileUploadHTTPRequest`. Both are pretty much
self-explanatory; they serve to upload `Data` and files respectively.

<a name="result" />

### HTTPTransport.Result

The third main actor, representing the outcome of an HTTP call. Either a `.success` or a `.failure`:

```swift
// MARK: - Result
    
/// HTTP request result
public enum Result {

	// MARK: - Cases

	case success(response: HTTPResponse)
	case failure(error: NSError)

	// MARK: - Properties

	public static var timeout: Result {
		Result.failure(error: NSError.timeout)
	}
}
```

The main idea you need to know is that the definition of **successful** HTTP call or **failed** HTTP call varies depending on the
validation techniques you apply.

By default, Alamofire's `validate()` method is called (see `HTTPTransport.useDefaultValidation` property), which means only
the responses with a `2xx` status are considered successful, otherwise they are translated into an error.
Disabling `useDefaultValidation` will lead to success in cases when there was *any* kind of a response from the server,
no matter what the answer was, and fail in cases like when the Internet connection is down.

On the low level, responses are influenced by the set of [response interceptors](#interceptors), which are applied before the
Alamofire's validation. This is why you might consider putting a `ClarifyErrorInterceptor` into your transport response
interceptors' stack, as it enriches the resulting [`NSError` object](#nserror).

<a name="parameters" />

### HTTPRequestParameters

Essentially, a dictionary with an additional property of how this dictionary is going to be encoded.

```swift
// MARK: - HTTPRequestParameters

/// Map of parameters with encoding
open class HTTPRequestParameters {

    // MARK: - Properties

    /// Parameters map
    open var parameters: [String: Any]

    /// Parameters' encoding. Default is JSON
    public let encoding: Encoding

    // MARK: - Initializers

    /// Default initializer
    /// - Parameters:
    ///   - parameters: map of parameters
    ///   - encoding: parameters encoding; default is JSON
    public init(
        parameters: [String: Any],
        encoding: Encoding = Encoding.json
    ) {
        self.parameters = parameters
        self.encoding = encoding
    }

    /// Operate over the parameters map
    public subscript(parameterName: String) -> Any? {
        get {
            return self.parameters[parameterName]
        }
        set(parameterValue) {
            self.parameters[parameterName] = parameterValue
        }
    }

    // MARK: - Encoding

    /// Parameters encoding
    public enum Encoding {

        /// Encode parameters into provided URLRequest
        public typealias EncodeFunction = (_ request: URLRequest, _ parameters: [String: Any]?) throws -> URLRequest

        // MARK: - Cases

        /// JSON-encoded body
        case json

        /// Key=value-encoded URL
        case url

        /// Your custom format
        case custom(encode: EncodeFunction)

        /// Transform `Encoding` into `Alamofire.ParameterEncoding` instance
        func toAlamofire() -> ParameterEncoding {
            switch self {
                case .url: return URLEncoding.default
                case .json: return JSONEncoding.default
                case .custom(let encodeFunction): return CustomEncoder(encodeFunction: encodeFunction)
            }
        }
    }
    ...
```

`json` and `propertyList` are encoded into the body, `url` parameters go into the query string.

Your `HTTPRequest` may contain several sets of `HTTPRequestParameters`:

```swift
let request = HTTPRequest(
    parameters: [
        HTTPRequestParameters(parameters: ["name": "John"], encoding: .json),
        HTTPRequestParameters(parameters: ["dob": "12/12/12"], encoding: .json),
        HTTPRequestParameters(parameters: ["age": 5], encoding: .url),
    ]
)
```

The rules here:

* parameters with the same encoding are merged into a single dictionary;
* parameters with the same encoding and same keys override previous values in the merged dictionary;
* parameters are appended after the `base` request parameters with the same encoding;
* parameters override `base` parameters with the same encoding and same keys;
* `propertyList` parameters and `json` parameters do not mix in one body, they overwrite each other; last-in wins;
* `FileUploadHTTPRequest` requests ignore `json` parameters; `propertyList` parameters are appended after the file multipart;
* `DataUploadHTTPRequest` requests ignore both `propertyList` and `json` parameters.

<a name="session" />

### Session

Session object holds Alamofire's [`SessionManager`](https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#session-manager)
and provides convenient way to configure connection security with the `Security` object.

```swift
// MARK: - Session

/// TCP/HTTP session between client and server
/// Includes security settings (see `Security`) and request retry strategy (see `HTTPTransportRetrier`)
open class Session {

    // MARK: - Properties

    /// `Session` stands for URLSession reusage
    /// Includes security settings and request retry strategy
    public let manager: Alamofire.Session

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter manager: Alamofire's `Session`
    public init(manager: Alamofire.Session) {
        self.manager = manager
    }

    /// Default initializer with zero no-evaluation security preset
    public convenience init() {
        self.init(security: Security.noEvaluation)
    }

    /// Initializer for cases, if `Session` couldn't be reused
    /// - Parameters:
    ///   - security: Security: SSL pinning policy
    ///   - retrier: HTTP request retry policy
    public init(
        security: Security,
        retrier: HTTPTransportRetrier? = nil
    ) {
        self.manager = Alamofire.Session(
            startRequestsImmediately: true,
            interceptor: retrier,
            serverTrustManager: security.trustPolicyManager
        )
    }
}
```

`Security` object allows to check hosts against certificate fingerprints:

```swift
// MARK: - Security

/// SSL pinning policy
open class Security {

    // MARK: - Properties

    /// Alamofire's `ServerTrustPolicyManager`
    public let trustPolicyManager: ServerTrustManager

    /// Default SSL pinning policy: disabled
    open class var noEvaluation: Security {
        Security(trustPolicyManager: TrustPolicyManager.noEvaluation)
    }

    // MARK: - Initializers

    /// Default initializer
    /// - Parameter trustPolicyManager: Alamofire's `ServerTrustPolicyManager`
    public init(trustPolicyManager: ServerTrustManager) {
        self.trustPolicyManager = trustPolicyManager
    }

    /// Convinience initializer for cases, when you'd like to ommit importing Alamofire
    /// - Parameter certificates: collection of `TrustPolicyManager.Certificate` objects
    ///   - (each is actually a pair "host: fingerprint")
    public convenience init(certificates: [TrustPolicyManager.Certificate]) {
        self.init(trustPolicyManager: TrustPolicyManager(certificates: certificates))
    }
}
```
```swift
// MARK: - Certificate

/// A pair of host name and corresponding SSL certificate fingerprint
public struct Certificate {

    // MARK: - Properties

    /// Host name
    public let host: String

    /// Host's SSL certificate fingerprint, see `Certificate.Fingerprint`
    public let fingerprint: Fingerprint

    /// Allow all hosts with a dot "." in their names have SSL pinning disabled
    public static var wildcard: Certificate {
        Certificate(host: ".", fingerprint: Fingerprint.disable)
    }

    /// Convert `Certificate` to Alamofire's `ServerTrustPolicy`
    public var asTrustPolicy: ServerTrustEvaluating {
        switch fingerprint {
            case Certificate.Fingerprint.sha1(let fingerprint):
                let closure = createServerTrustCheckMethod(certificateFingerprintSHA1: fingerprint)
                return ClosureServerTrustEvaluating(closure: closure)
            case Certificate.Fingerprint.sha256(let fingerprint):
                let closure = createServerTrustCheckMethod(certificateFingerprintSHA256: fingerprint)
                return ClosureServerTrustEvaluating(closure: closure)
            case Certificate.Fingerprint.publicKey(let fingerprint):
                let closure = createServerTrustCheckMethod(certificatePublicKeyFingerprint: fingerprint)
                return ClosureServerTrustEvaluating(closure: closure)
            case Certificate.Fingerprint.debug:
                let closure = createServerTrustDebugMethod()
                return ClosureServerTrustEvaluating(closure: closure)
            case Certificate.Fingerprint.disable:
                return DisabledTrustEvaluator()
        }
    }
}
```

Host names are checked by the string intersection. This means `Certificate(host: "host.com", fingerprint:...)` is applied
for URLs like `https://www.host.com/query`, `https://host.com`, `https://api.host.com/v1` et al.

<a name="interceptors" />

### Interceptors

`HTTPRequestInterceptor` and `HTTPResponseInterceptor` are protocols, inspired by
[OkHTTP interceptors](https://github.com/square/okhttp/wiki/Interceptors),
[Django middlewares](https://docs.djangoproject.com/en/2.0/topics/http/middleware/) et al. Interceptors alter input and output,
each `HTTPTransport` instance contains two lists of request and reponse interceptors subsequently applied to every request and
response respectively.

In other words, when your **app** sends a **request** through the **transport**, latter passes this **request** through its list of
**request interceptors** before the actual sending. After the **response** is received, **transport** passes it through the list of
**response interceptors** before transfering it to your **app**.

```swift
// MARK: - HTTPRequestInterceptor

/// Abstract class for HTTP request interceptors.
/// Allows transforming original `URLRequest` before it is sent.
public protocol HTTPRequestInterceptor {

    /// Intercept outgoing HTTP request
    /// - Parameter request: original request
    /// - Returns: may return original or modified `URLRequest`
    func intercept(request: URLRequest) -> URLRequest
}
```

Interceptors may or may not alter the data they process. For instance, one of your request interceptors may add an
`Authentication` header to every request. Other request interceptor might only print request data into the console log.

You implement your own interceptors by extending the classes mentioned above. **HTTPTransport** library already includes some
basic utility interceptors, like:

* `LogRequestInterceptor` and `LogResponseInterceptor` — allow you to log requests and responses;
* `AddCookieInterceptor` — adds cookies from `cookieProvider` to each request;
* `ReceivedCookieInterceptor` — stores received cookies to `cookieStorage`;
* `ClarifyErrorInterceptor` — translates JSON payloads with API errors like `{"code": 500, "message": "Database error"}` into `NSError` instances, [see below](#nserror).

<a name="nserror" />

### NSError

**HTTPTransport** provides an extension for the existing `NSError` class with some utility properties with additional parts
of the received HTTP response, if any.

Most of them will only work if the `ClarifyErrorInterceptor` was engaged.

```swift
// MARK: - NSError

/// HTTP transport-related errors
public extension NSError {

    // MARK: - Properties

    /// Error domain
    static let transportDomain: String = "Transport.error.domain"

    /// Get request URL from `userInfo`, if any
    var url: String? {
        userInfo[UserInfoKey.url] as? String
    }

    /// Get response HTTP status code from `userInfo`, if any
    var httpStatusCode: HTTPStatusCode? {
        userInfo[UserInfoKey.httpStatus] as? HTTPStatusCode
    }

    /// Get response body as Data from `userInfo`, if any
    var responseBodyData: Data? {
        userInfo[UserInfoKey.responseBodyData] as? Data
    }

    /// Get response body as String from `userInfo`, if any
    var responseBodyString: String? {
        userInfo[UserInfoKey.responseBodyString] as? String
    }

    /// Get response body as JSON object from `userInfo`, if any
    var responseBodyJSON: Any? {
        userInfo[UserInfoKey.responseBodyJSON]
    }

    /// Get error.code from body JSON, if any
    var responseBodyErrorCode: String? {
        userInfo[UserInfoKey.responseBodyErrorCode] as? String
    }

    /// Get error.message from body JSON, if any
    var responseBodyErrorMessage: String? {
        userInfo[UserInfoKey.responseBodyErrorMessage] as? String
    }

    /// Get response body as dictionary from `userInfo`, if any
    var responseBodyJSONDictionary: [String: Any]? {
        guard let json: Any = self.responseBodyJSON else { return nil }
        if let dictionary = json as? [String: Any] {
            return dictionary
        } else {
            return ["data": json]
        }
    }

    /// Request was interrupted because of the semaphore timeout
    static var timeout: NSError {
        NSError(
            domain: transportDomain,
            code: NSURLErrorTimedOut,
            userInfo: [
                NSLocalizedDescriptionKey: "Request timed out on semaphore"
            ]
        )
    }

    /// Alamofire returned no HTTP response and no error
    static var noHTTPResponse: NSError {
        NSError(
            domain: transportDomain,
            code: TransportErrorCode.noHTTPResponse.rawValue,
            userInfo: [
                NSLocalizedDescriptionKey: "Alamofire didn't return HTTPURLResponse nor Error"
            ]
        )
    }

    /// Wrong URL format
    static func cannotInitURL(urlString: String) -> NSError {
        NSError(
            domain: transportDomain,
            code: TransportErrorCode.cannotInitURLWithString.rawValue,
            userInfo: [
                UserInfoKey.url: urlString,
                NSLocalizedDescriptionKey: "Cannot convert String to URL"
            ]
        )
    }
    ...
```

<a name="book" />

## Cook book

* [Basic GET request](#basic)
* [Basic dependent requests](#dependent)
* [Logging](#logging)
* [Send and receive cookies](#cookies)
* [POST request with body & URL parameters](#post_parameters)
* [SSL pinning with SHA1 fingerprint](#sha1_fingerprint)

<a name="basic" />

### Basic GET request

```swift
// assuming all following code runs in a background thread

let request = HTTPRequest(endpoint: "https://api.service.com")
let transport = HTTPTransport()

let result: HTTPTransport.Result = transport.send(request: request)

switch result {
    case .success(let httpResponse):
        print(httpResponse.httpStatus)
        do {
            if let json: [String: Any] = try httpResponse.getJSONDictionary() {
                print(json)
            }
        } catch {
            print("JSONSerialization error")
        }
    case .failure(let nsError):
        if let httpStatus: HTTPStatusCode = nsError.httpStatusCode {
            print(httpStatus)
        } else {
            print(nsError.localizedDescription)
        }
}
```

<a name="dependent" />

### Basic dependent requests

```swift
// assuming all following code runs in a background thread

let transport = HTTPTransport()

let baseRequest = HTTPRequest(endpoint: "https://api.service.com")
	.with(header: "User-Agent", value: "Application/iOS")

let authRequest = HTTPRequest(endpoint: "/session", base: baseRequest)
let authResult = transport.send(request: authRequest)

if let sessionId: String = getSessionId(authResult) {
    let userSearchRequest = HTTPRequest(endpoint: "/user", base: baseRequest)
        .with(cookieName: "SESSION_ID", value: sessionId)
        .with(parameters: ["first_name": "John", "last_name": "Appleseed"], encoding: .url)

    let searchResult = transport.send(request: userSearchRequest)
    if let users: [User] = getUsers(searchResult) {
        showUsers(users)
    } else {
        showEmptyScreen()
    }
} else {
    showError()
}
```

<a name="logging" />

### Logging

```swift
let transport = HTTPTransport(
    requestInterceptors: [
        LogRequestInterceptor(logLevel: LogRequestInterceptor.LogLevel.url),
    ],
    responseInterceptors: [
        LogResponseInterceptor(logLevel: LogResponseInterceptor.LogLevel.everything),
    ]
)

let result = transport.send(...)
```

<a name="cookies" />

### Send and receive cookies

```swift
let cookieStorage: CookieStoring & CookieProviding = getCookieStorage()

let transport = HTTPTransport(
    requestInterceptors: [
        AddCookieInterceptor(cookieProvider: cookieStorage),
    ],
    responseInterceptors: [
        ReceivedCookieInterceptor(cookieStorage: cookieStorage),
    ]
)

let result = transport.send(...)
```

<a name="post_parameters" />

### POST request with body & URL parameters

```swift
let urlParameters = HTTPRequestParameters(
    parameters: ["first_name" : "John"],
    encoding: .url
)

let bodyParameters = HTTPRequestParameters(
    parameters: ["salary" : 100000],
    encoding: .json
)

let updateSalaryRequest = HTTPRequest(
    httpMethod: HTTPRequest.HTTPMethod.post,
    endpoint: "https://api.company.com/employees",
    parameters: [urlParameters, bodyParameters]
)

let result = transport.send(request: updateSalaryRequest)
```

<a name="sha1_fingerprint" />

### SSL pinning with SHA1 fingerprint

```swift
let fingerprint =
    "ED D6 27 B8 8B 51 B0 24 B9 BF 90 4C D4 AB 9A AB E2 4B 93 00"
        .replacingOccurrences(of: " ", with: "")

let security = Security(
    certificates: [
        TrustPolicyManager.Certificate(host: "google.com", fingerprint: .sha1(fingerprint: fingerprint))
    ]
)

let transport = HTTPTransport(security: security)
let result = transport.send(request: HTTPRequest(endpoint: "https://google.com/ncr"))
```

<a name="evolution" />

## Evolution

You may have noticed that our library tries not to expose Alamofire interfaces. There is a simple idea to get rid of this transitive
dependency, and to erect an independent logic on top of the **URLSession** framework.

These far-reaching plans require significant efforts we cannot afford right now. Still, it is a major target we aspire to hit eventually.

So, pull requests are welcome, but consider creating a tentative issue before the actual coding.
