$_ = "xyxyx"; %j=(1,2); s/x/$j{print("z")}/ge; print $_
### RESULT:zzz2y2y2
