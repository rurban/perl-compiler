use Net::SSLeay();use IO::Socket::SSL();Net::SSLeay::OpenSSL_add_ssl_algorithms(); my $ssl_ctx = IO::Socket::SSL::SSL_Context->new(SSL_server => 1); print q(ok)
### RESULT:ok
