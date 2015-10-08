package Master; use mro "c3"; sub me { "Master" } package Slave; use mro "c3"; use base "Master"; sub me { "Slave of ".(shift)->next::method } package main; print Master->me()."\n"; print Slave->me()."\n";
### RESULT:Master
Slave of Master
