INIT{ sub ASCII { eval { require Encode; Encode::find_encoding("ASCII"); } || 0; }} print ASCII->encode("www.google.com")
### RESULT:www.google.com
