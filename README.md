# ApiAuth #

Logins and passwords are for humans. Communication between applications need to
be protected through different means.

ApiAuth is a Ruby gem designed to be used both in your client and server
HTTP-based applications. It implements the same authentication methods (HMAC-SHA1)
used by Amazon Web Services.

The gem will sign your requests on the client side and authenticate that
signature on the server side. If your server resources are implemented as a
Rails ActiveResource, it will integrate with that. It will even generate the
secret keys necessary for your clients to sign their requests.

Since it operates entirely using HTTP headers, the server component does not
have to be written in the same language as the clients.

## How it works ##

1. A canonical string is first created using your HTTP headers containing the
content-type, content-MD5, request URI and the timestamp. If content-type or
content-MD5 are not present, then a blank string is used in their place. If the
timestamp isn't present, a valid HTTP date is automatically added to the
request. The canonical string string is computed as follows:

    canonical_string = 'content-type,content-MD5,request URI,timestamp'

2. This string is then used to create the signature which is a Base64 encoded
SHA1 HMAC, using the client's private secret key.

3. This signature is then added as the `Authorization` HTTP header in the form:

    Authorization = APIAuth 'client access id':'signature from step 2'

5. On the server side, the SHA1 HMAC is computed in the same way using the
request headers and the client's secret key, which is known to only
the client and the server but can be looked up on the server using the client's
access id that was attached in the header. The access id can be any integer or
string that uniquely identifies the client. The signed request expires after 15
minutes in order to avoid replay attacks.


## References ##

* [Hash functions](http://en.wikipedia.org/wiki/Cryptographic_hash_function)
* [SHA-1 Hash function](http://en.wikipedia.org/wiki/SHA-1)
* [HMAC algorithm](http://en.wikipedia.org/wiki/HMAC)
* [RFC 2104 (HMAC)](http://tools.ietf.org/html/rfc2104)

## Install ##

The gem doesn't have any dependencies outside of having a working OpenSSL
configuration for your Ruby VM. To install:

    [sudo] gem install api-auth

Please note the dash in the name versus the underscore.

## Clients ##

ApiAuth supports many popular HTTP clients. Support for other clients can be
added as a request driver.

Here is the current list of supported request objects:

* Net::HTTP
* ActionController::Request
* Curb (Curl::Easy)
* RestClient

### HTTP Client Objects ###

Here's a sample implementation of signing a request created with RestClient. For
more examples, please check out the ApiAuth Spec where every supported HTTP
client is tested.

Assuming you have a client access id and secret as follows:

``` ruby
    @access_id = "1044"
    @secret_key = ApiAuth.generate_secret_key
```

A typical RestClient PUT request may look like:

``` ruby
    headers = { 'Content-MD5' => "e59ff97941044f85df5297e1c302d260",
        'Content-Type' => "text/plain",
        'Date' => "Mon, 23 Jan 1984 03:29:56 GMT" }
    @request = RestClient::Request.new(:url => "/resource.xml?foo=bar&bar=foo",
        :headers => headers,
        :method => :put)
```

To sign that request, simply call the `sign!` method as follows:

``` ruby
    @signed_request = ApiAuth.sign!(@request, @access_id, @secret_key)
```

The proper `Authorization` request header has now been added to that request
object and it's ready to be transmitted. It's recommended that you sign the
request as one of the last steps in building the request to ensure the headers
don't change after the signing process which would cause the authentication
check to fail on the server side.

### ActiveResource Clients ###

ApiAuth can transparently protect your ActiveResource communications with a
single configuration line:

``` ruby
    class MyResource < ActiveResource::Base
      with_api_auth(access_id, secret_key)
    end
```

This will automatically sign all outgoing ActiveResource requests from your app.

## Server ##

ApiAuth provides some built in methods to help you generate API keys for your
clients as well as verifying incoming API requests.

To generate a Base64 encoded API key for a client:

``` ruby
    ApiAuth.generate_secret_key
```

To validate whether or not a request is authentic:

``` ruby
    ApiAuth.authentic?(signed_request, secret_key)
```

If your server is a Rails app, the signed request will be the `request` object.

In order to obtain the secret key for the client, you first need to look up the
client's access_id. ApiAuth can pull that from the request headers for you:

``` ruby
    ApiAuth.access_id(signed_request)
```

Once you've looked up the client's record via the access id, you can then verify
whether or not the request is authentic. Typically, the access id for the client
will be their record's primary key in the DB that stores the record or some other
public unique identifier for the client.

Here's a sample method that can be used in a `before_filter` if your server is a
Rails app:

``` ruby
    before_filter :api_authenticate

    def api_authenticate
      @current_account = Account.find_by_access_id(ApiAuth.access_id(request))
      return ApiAuth.authentic?(request, @current_account.secret_key) unless @current_account.nil?
      false
    end
```

## Development ##

ApiAuth uses bundler for gem dependencies and RSpec for testing. Developing the
gem requires that you have all supported HTTP clients installed. Bundler will
take care of all that for you.

To run the tests:

    rake spec

If you'd like to add support for additional HTTP clients, check out the already
implemented drivers in `lib/api_auth/request_drivers` for reference. All of
the public methods for each driver are required to be implemented by your driver.

## Authors ##

* [Mauricio Gomes](http://github.com/mgomes)
* [Kevin Glowacz](http://github.com/kjg)

## Copyright ##

Copyright (c) 2012 Gemini SBS LLC. See LICENSE.txt for further details.
