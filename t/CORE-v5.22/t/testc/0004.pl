$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/g; print $_
### RESULT:zzz2y2y2
