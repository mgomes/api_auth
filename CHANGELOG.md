# 1.4 (?)

## IMPORTANT SECURITY FIX (with backwards compatible fallback)

  This version introduces a security fix. In previous versions, the canonical
  string does not include the http method used to make the request, this means
  two requests that would otherwise be identical (such as a GET and DELETE)
  would have the same signature allowing for a MITM to swap one method for
  another.

  In ApiAuth v1.4 `ApiAuth.authentic?` will allow for requests signed using either
  the canonical string WITH the http method, or WITHOUT it. `ApiAuth.sign!` will,
  by default, still sign the request using the canonical string without the
  method. However, passing in the `:with_http_method => true` option into
  `ApiAuth.sign?` will cause the request to use the http method as part of the
  canonical string.

  Example:

  ```ruby
    ApiAuth.sign!(request, access_id, secret_key, {:with_http_method => true})
  ```

  This allows for an upgrade strategy that would look like the following.

  1. Update server side code to use ApiAuth v1.4
  2. Update client side code to use ApiAuth v1.4
  3. Update all client side code to sign with http method
  4. Update server side code to ApiAuth v2.0 (removes the ability to authenticate without the http method)
  5. Update all client side code to ApiAuth v2.0 (forces all signatures to contain the http method)

## Additional changes

  - Performance enhancement: reduce allocation of Headers object (#81 pd)
  - Performance enhancement: avoid reallocating static Regexps (#82 pd)

# 1.3.2 (2015-08-28)
- Fixed a bug where some client adapters didn't treat an empty path as
  "/" in the canonical string (#75 managr)

# 1.3.1 (2015-03-13)
- Fixed a bug where Faraday requests with no parameters were not signed
  correctly (#65 nathanhoel)

# 1.3.0 (2015-03-12)
- Add a Faraday Request Driver (#64 nathanhoel)

# 1.2.6 (2014-10-01)
- Fix a bug in the ActionController request driver where calculated_md5 was
  incorrect in certain scenarios. (#53 karl-petter)

# 1.2.5 (2014-09-09)
- Fix a bug where ApiAuth.authentic? would cause an ArgumentError when given a
  request with an invalid date in the date header. It will now return false
  instead. (#51 Nakort)

# 1.2.4 (2014-08-27)
- Fix a bug in the Net::HTTP request driver where the md5 isn't calculated
  correctly when the content of the request is set with the `.body_stream`
  method. (#49 adamcrown)

# 1.2.3 (2014-08-01)
- Update action controller request driver to fix a bug with OLD versions of
  Rails using CGI

# 1.2.2 (2014-07-08)
- Fix Rest Client driver to account for the generated date when signing (cjeeky)

# 1.2.1 (2014-07-03)

- Fix Rest Client driver to account for the generated md5 when signing
  (#45 cjeeky)
- Support for testing against Rails 4.1 (#42  awendt)
- Support all requests inheriting from Rack::Request (#43 mcls)

# 1.2.0 (2014-05-16)

- Fix ruby 1.8.7 support
- Test / support all major versions of rails 2.3 - 4.0
- Add support for sinatra requests
- Add support for HTTPI requests
