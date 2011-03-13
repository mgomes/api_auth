api-auth
========

Logins and passwords are for humans. Communication between applications need to 
be protected through different means.

api-auth is Ruby gem designed to be used both in your client and server
HTTP-based applications. It implements the same authentication methods (HMAC) 
used by Amazon Web Services.

The gem will sign your requests on the client side and authenticate that 
signature on the server side. If your server resources are implemented as a 
Rails ActiveResource, it will integrate with that. It will even generate the 
secret keys necessary for your clients to sign their requests.

Since it operates entirely using HTTP headers, the server component does not 
have to be written in the same language as the clients. Any language with 
OpenSSL bindings will suffice.

How it works
------------

1. A canonical string is first created using your HTTP headers containing the 
content-type, content-MD5, request URI and the 
timestamp. The canonical string string is computed as follows:

    canonical_string = "<content-type>,<content-MD5>,<URI>,<timestamp>"

If content-type or content-MD5 are not present, then a blank string is used in 
their place. If the timestamp isn't present, a valid HTTP date is automatically 
added to the request.

2. This string is then used to create the signature which is a Base64 encoded 
SHA1 HMAC, using the client's private secret key.

3. This signature is then added as the `Authorization` HTTP header in the form:

    Authorization = APIAuth <client access id>:<signature from step 2>
        
5. On the server side, the SHA1 HMAC is computed in the same way using the 
request headers and the client's secret key, which is known to only 
the client and the server but can be looked up on the server using the client's 
access id that was attached in the header. The access id can be any integer or 
string that uniquely identifies the client.


References
----------

* [Hash functions](http://en.wikipedia.org/wiki/Cryptographic_hash_function)
* [SHA-1 Hash function](http://en.wikipedia.org/wiki/SHA-1)
* [HMAC algorithm](http://en.wikipedia.org/wiki/HMAC)
* [RFC 2104 (HMAC)](http://tools.ietf.org/html/rfc2104)

Usage
-----

### Install ###

    [sudo] gem install api-auth
    
### Supported Request Objects ###

ApiAuth supports most request objects. With the support of 
ActionController::Request, ApiAuth is fully compatible with Rails. Support for 
other request objects can be added as a request driver.

Here is the current list of supported request objects:

* Net::HTTP
* ActionController::Request
* Curb (Curl::Easy)
* RestClient
    
### ActiveResource ###

    class MyResource < ActiveResource::Base
      with_api_auth(<access_id>, <secret_key>)
    end

### Server ###


Authors
-------

* [Mauricio Gomes](http://github.com/mgomes)

Copyright
---------

Copyright (c) 2011 Gemini SBS LLC. See LICENSE.txt for further details.
