    use encoding 'utf8';
    map { "a" . $a } ((1)x5000);
    print "ok\n";
