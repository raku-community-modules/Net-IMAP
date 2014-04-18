method get-response($code?){
    my $line = $.conn.get;
    return $line unless $code;
    my $response = $line;
    while $line.substr(0, $code.chars) ne $code {
        $line = $.conn.get;
        $response ~= "\r\n"~$line;
    }
    return $response;
}

method send($stuff) {
    my $code = $.reqcode;
    $.reqcode = $.reqcode.succ;
    $.conn.send($code ~ " $stuff\r\n");
    return self.get-response($code);
}

method capability {
    return self.send('CAPABILITY');
}

method noop {
    return self.send('NOOP');
}

method logout {
    return self.send('LOGOUT');
}

method login($user, $pass) {
    return self.send("LOGIN $user $pass");
}

method select($mailbox) {
    return self.send("SELECT $mailbox");
}

method examine($mailbox) {
    return self.send("EXAMINE $mailbox");
}

method create($mailbox) {
    return self.send("CREATE $mailbox");
}

method delete($mailbox) {
    return self.send("DELETE $mailbox");
}

method rename($oldbox, $newbox) {
    return self.send("RENAME $oldbox $newbox");
}

method subscribe($mailbox) {
    return self.send("SUBSCRIBE $mailbox");
}

method unsubscribe($mailbox) {
    return self.send("UNSUBSCRIBE $mailbox");
}

method list($ref, $mbox) {
    return self.send("LIST $ref $mbox");
}

method lsub($ref, $mbox) {
    return self.send("LSUB $ref $mbox");
}

method status($mbox, $type) {
    return self.send("STATUS $mbox $type");
}

method append($name, $flags, $datetime, $message) {
    die "NYI";
}

method check {
    return self.send("CHECK");
}

method close {
    return self.send("CLOSE");
}

method expunge {
    return self.send("EXPUNGE");
}

method search(*@args) {
    die "NYI";
}

method fetch($seq, $items) {
    die "NYI";
}

method store(*@args) {
    die "NYI";
}

method copy(*@args) {
    die "NYI";
}

method uid {
    die "NYI";
}
