using Sockets, MbedTLS, HTTP

capath = "/var/folders/0s/p7ggmk2s339dq2xbnzf1wm3r0000gn/T/tmpEwcTmO"
certpath = "/var/folders/0s/p7ggmk2s339dq2xbnzf1wm3r0000gn/T/tmpY3ZlRI"
keypath = "/var/folders/0s/p7ggmk2s339dq2xbnzf1wm3r0000gn/T/tmpa7fT14"
conf = MbedTLS.SSLConfig(certpath, keypath)

MbedTLS.config_defaults!(conf)
MbedTLS.authmode!(conf, MbedTLS.MBEDTLS_SSL_VERIFY_REQUIRED)
# MbedTLS.rng!(conf, rng)

# function show_debug(level, filename, number, msg)
#     @show level, filename, number, msg
# end
#
# MbedTLS.dbg!(conf, show_debug)

cacert = MbedTLS.crt_parse_file(capath)
println("capath: ", cacert)
MbedTLS.ca_chain!(conf, cacert)
#
# MbedTLS.setup!(ctx, conf)
# MbedTLS.set_bio!(ctx, sock)
#
# MbedTLS.handshake(ctx)
resp = HTTP.request("GET", "https://localhost:49642/api/v1/pods"; sslconfig=conf)
@show resp
# write(ctx, "GET /api/v1/pods HTTP/1.1\r\nHost: localhost\r\n\r\n")
# buf = String(read(ctx, 1000))
# println(buf)
