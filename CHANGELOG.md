# 2.3.1 (2018-11-06)
- Fixed a regression in the http.rb driver (#173 tycooon)

# 2.3.0 (2018-10-23)
- Added support for Grape API (#169 phuongnd08 & dunghuynh)
- Added option for specifying customer headers to sign via new `headers_to_sign`
  argument (#170 fakenine)
- Fix tests and drop support for Ruby < 2.3 (#171 fwininger)

# 2.2.0 (2018-03-12)
- Drop support ruby 1.x, rails 2.x, rails 3.x (#141 fwininger)
- Add http.rb request driver (#164 tycooon)
- Fix POST and PUT requests in RestClient (#151 fwininger)
- Allow clock skew to be user-defined (#136 mlarraz)
- Adds #original_uri method to all request drivers (#137 iMacTia)
- Rubocop and test fixes (fwininger & nicolasleger)
- Changed return type for request #content_md5 #timestamp #content_type (fwininger)
- Fix URI edge case where a URI contains another URI (zfletch)
- Updates to the README (zfletch)

# 2.1.0 (2016-12-22)
- Fixed a NoMethodError that might occur when using the NetHttp Driver (#130 grahamkenville)
- More securely compare signatures in a way that prevents timing attacks (#56 leishman, #133 will0)
- Remove support for MD2 and MD4 hashing algorithms since they are insecure (#134 will0)
- Disallow requests that are too far in the future to limit the time available for a brute force signature guess (#119 fwininger)

# 2.0.1 (2016-07-25)
- Support of `api_auth_options` in ActiveResource integration (#102 fwininger)
- Replace use of `#blank?` with `#nil?` to not depend on ActiveSupport (#114 packrat386)
- Fix Auth header matching to not match invalid SHA algorithms (#115 packrat386)
- Replace `alias_method_chain` with `alias_method` in the railtie since
  alias_method_chain is deprecated in Rails 5 (#118 mlarraz)

# 2.0.0 (2016-05-11)
- IMPORTANT: 2.0.0 is backwards incompatible with the default settings of v1.x
  v2.0.0 always includes the http method in the canonical string.
  You can use the upgrade strategy in v1.4.x and above to migrate to v2.0.0
  without any down time. Please see the 1.4.0 release nodes for more info
- Added support for other digest algorithms like SHA-256 (#98 fwininger)

# 1.5.0 (2016-01-21)
- Added a sign_with_http_method configuration option to the ActiveResource
  rails tie to correspond to passing the `:with_http_method => true` into
  `ApiAuth.sign!`

# 1.4.1 (2016-01-04)
- Fixed an issue where getters wouldn't immediately have the correct value after
  setting a date or content md5 in some of the request drivers (#91)

# 1.4.0 (2015-12-16)

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
