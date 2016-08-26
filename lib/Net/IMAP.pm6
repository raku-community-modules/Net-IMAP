unit class Net::IMAP;

use Net::IMAP::Raw;
use Net::IMAP::Simple;

method new(:$server, :$port = 143, :$debug, :$raw, :$socket = IO::Socket::INET, :$ssl, :$starttls, :$plain) {
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
        $conn = $conn but debug-connection if $debug;
        return Net::IMAP::Raw.new(:conn($conn));
    } else {
        return Net::IMAP::Simple.new(:$ssl, :tls($starttls), :$plain, raw => Net::IMAP.new(:$server, :$port, :$debug, :$socket, :raw));
    }
}
