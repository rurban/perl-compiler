use IO::Socket::SSL(); my IO::Handle $handle = IO::Socket::SSL->new(SSL_verify_mode =>0); $handle->blocking(0); print "ok";
### RESULT:ok
