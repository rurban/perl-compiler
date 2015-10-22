BEGIN{unshift @INC,("t");} use qr_loaded_module; print "ok" if qr_loaded_module::qr_called_in_sub("name1")
### RESULT:ok
