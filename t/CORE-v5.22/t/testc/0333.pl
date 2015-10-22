use encoding "utf8"; my @hiragana = map {chr} ord("ぁ")..ord("ん"); my @katakana = map {chr} ord("ァ")..ord("ン"); my $hiragana = join(q{} => @hiragana); my $katakana = join(q{} => @katakana); my %h2k; @h2k{@hiragana} = @katakana; $str = $hiragana; $str =~ s/([ぁ-ん])/$h2k{$1}/go; print $str eq $katakana a t "ok\n" : "not ok\n$hiragana\n$katakana\n";
### RESULT:ok
