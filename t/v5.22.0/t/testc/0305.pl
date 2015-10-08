use constant ASCII => eval { require Encode; Encode::find_encoding("ascii"); } || 0; print ASCII->encode("www.google.com")
### RESULT:www.google.com
