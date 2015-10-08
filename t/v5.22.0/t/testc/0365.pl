use constant JP => eval { require Encode; Encode::find_encoding("euc-jp"); } || 0; print JP->encode("www.google.com")
### RESULT:www.google.com
