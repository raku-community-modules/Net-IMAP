use IO::Socket::SSL;

unit class Net::IMAP::Raw;

has $.conn is rw;
has $.reqcode is rw = 'aaaa';

method get-response($code?){
    my $line = $.conn.get;
    return $line unless $code;

    my $response = $line;
    while $line.substr(0, $code.chars) ne $code {
        $line = $.conn.get;
        $response ~= "\r\n"~$line;
    }
    $response
}

method send($stuff) {
    my $code = $.reqcode;
    $.reqcode = $.reqcode.succ;
    $.conn.print($code ~ " $stuff\r\n");
    self.get-response($code)
}

method switch-to-ssl() {
    $!conn = IO::Socket::SSL.new(:client-socket($.conn), :input-line-separator("\r\n"));
    $!conn.input-line-separator = "\r\n";
}

method starttls { self.send: 'STARTTLS' }

method capability { self.send: 'CAPABILITY' }

method noop { self.send: 'NOOP' }

method logout { self.send: 'LOGOUT' }

method login($user, $pass) { self.send: "LOGIN $user $pass" }

method select($mailbox) { self.send: "SELECT $mailbox" }

method examine($mailbox) { self.send: "EXAMINE $mailbox" }

method create($mailbox) { self.send: "CREATE $mailbox" }

method delete($mailbox) { self.send: "DELETE $mailbox" }

method rename($oldbox, $newbox) { self.send: "RENAME $oldbox $newbox" }

method subscribe($mailbox) { self.send: "SUBSCRIBE $mailbox" }

method unsubscribe($mailbox) { self.send: "UNSUBSCRIBE $mailbox" }

method list($ref, $mbox) { self.send: "LIST $ref $mbox" }

method lsub($ref, $mbox) { self.send: "LSUB $ref $mbox" }

method status($mbox, $type) { self.send: "STATUS $mbox ($type.join(' '))" }

method append($name, $message, :$flags, :$datetime) {
    my $code = $.reqcode;
    $.reqcode = $.reqcode.succ;
    my $string = "APPEND $name";
    if $flags {
        $string ~= " ({ $flags.join(' ') })";
    }
    if $datetime {
        $string ~= " $datetime";
    }
    $.conn.send($code ~ " $string\r\n");
    my $resp = self.get-response;
    if $resp ~~ m:i/^\+\s/ {
        $.conn.send($message);
        self.get-response($code)
    }
    else {
        unless $resp ~~ /^$code/ {
            $resp ~= "\r\n" ~ self.get-response($code);
        }
        $resp
    }
}

method check() { self.send: "CHECK" }

method close() { self.send: "CLOSE" }

method expunge() { self.send: "EXPUNGE" }

method uid-search(*%query) {
    self.send: "UID SEARCH "~self!generate-search-query(%query)
}
method search(*%query) {
    self.send: "SEARCH "~self!generate-search-query(%query)
}
method !generate-search-query(%query) {
    my $output;
    if %query<charset> {
        $output ~= " CHARSET %query<charset>";
    }
    for %query.kv -> $k, $v {
        next unless $v;
        given $k {
            when any(<seq sid>) {
                $output ~= " $v";
            }
            when 'not' {
                $output ~= " NOT ({ self!generate-search-query($v) })";
            }
            when 'or' {
                $output ~= " OR ({ self!generate-search-query($v[0]) })";
                $output ~= " ({ self!generate-search-query($v[1]) })";
            }
            when any(<all answered deleted draft flagged new old recent seen unanswered undeleted undraft unflagged unseen>) {
                $output ~= " " ~ $k.uc;
            }
            when any(<bcc before body cc from keyword larger on sentbefore senton sentsince since smaller subject text to uid unkeyword>) {
                $output ~= " " ~ $k.uc ~ " $v";
            }
            when 'header' {
                $output ~= " HEADER $v[0] $v[1]";
            }
        }
    }
    $output
}

method uid-fetch($seq, $items) {
    self.send: "UID FETCH $seq ({ $items.join(' ') })"
}
method fetch($seq, $items) {
    self.send: "FETCH $seq ({ $items.join(' ') })"
}

method uid-store($seq, $action, $values) {
    self.send: "UID STORE $seq $action ({ $values.join(' ') })"
}
method store($seq, $action, $values) {
    self.send: "STORE $seq $action ({ $values.join(' ') })"
}

method uid-copy($seq, $mbox) { self.send: "UID COPY $seq $mbox" }
method copy($seq, $mbox) { self.send: "COPY $seq $mbox" }

# vim: expandtab shiftwidth=4
