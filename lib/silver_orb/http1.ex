defmodule SilverOrb.HTTP1 do
  def ok(), do: 200
  def created(), do: 201
  def accepted(), do: 202
  def non_authoritative_information(), do: 203
  def no_content(), do: 204
  def reset_content(), do: 205
  def partial_content(), do: 206
  def moved_permanently(), do: 301
  def found(), do: 302
  def see_other(), do: 303
  def not_modified(), do: 304
  def temporary_redirect(), do: 307
  def permanent_redirect(), do: 308
  def bad_request(), do: 400
  def unauthorized(), do: 401
  def forbidden(), do: 403
  def not_found(), do: 404
  def method_not_allowed(), do: 405
  def not_acceptable(), do: 406
  def conflict(), do: 409
  def gone(), do: 410
  def length_required(), do: 411
  def precondition_failed(), do: 412
  def payload_too_large(), do: 413
  def uri_too_long(), do: 414
  def unsupported_media_type(), do: 415
  def range_not_satisfiable(), do: 416
  def expectation_failed(), do: 417
  def im_a_teapot(), do: 418
  def misdirected_request(), do: 421
  def unprocessable_entity(), do: 422
  def locked(), do: 423
  def failed_dependency(), do: 424
  def upgrade_required(), do: 426
  def precondition_required(), do: 428
  def too_many_requests(), do: 429
  def request_header_fields_too_large(), do: 431
  def unavailable_for_legal_reasons(), do: 451
  def internal_server_error(), do: 500
  def not_implemented(), do: 501
  def bad_gateway(), do: 502
  def service_unavailable(), do: 503
  def gateway_timeout(), do: 504
  def http_version_not_supported(), do: 505
  def variant_also_negotiates(), do: 506
  def insufficient_storage(), do: 507
  def loop_detected(), do: 508
  def not_extended(), do: 510
  def network_authentication_required(), do: 511
end

# defprotocol SilverOrb.HTTP1.Request do
#   @doc "The HTTP method"
#   def method(config)

#   @doc "The HTTP host"
#   def host(config)

#   @doc "The HTTP path"
#   def path(config)

#   @doc "The HTTP headers"
#   def headers(config)

#   @doc "The HTTP body"
#   def body(config)
# end

defprotocol SilverOrb.HTTP1.Response do
  @doc "The HTTP status code"
  def status_code(config)

  @doc "The HTTP headers"
  def headers(config)

  @doc "The HTTP body"
  def body(config)
end
