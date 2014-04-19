class Net::IMAP;

use Net::IMAP::Raw;

method new(:$server, :$port = 143, :$debug, :$raw, :$socket = IO::Socket::INET) {
    my role debug-connection {
        method send($string){
            my $tmpline = $string.substr(0, *-2);
            note '==> '~$tmpline;
            nextwith($string);
        }
        method get() {
            my $line = callwith();
            note '<== '~$line;
            return $line;
        }
    };
    if $raw {
        my $conn = $socket.defined ?? $socket !! $socket.new(:host($server), :$port);
        $conn.input-line-separator = "\r\n";
        $conn = $conn but debug-connection if $debug;
        return Net::IMAP::Raw.new(:$conn);
    } else {
        die "Simple mode NYI";
    }
}
