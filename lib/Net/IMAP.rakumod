use Net::IMAP::Raw;
use Net::IMAP::Simple;

unit class Net::IMAP:ver<1.0.3>:auth<zef:raku-community-modules>;

method new(
  Str  :$server,
  Int  :$port = 143,
  Bool :$debug,
  Bool :$raw,
  Mu   :$socket = IO::Socket::INET,
  Bool :$ssl,
  Bool :$starttls,
  Bool :$plain
) {
    my role debug-connection {
        method send($string){
            my $tmpline = $string.substr(0, *-2);
            note '==> '~$tmpline;
            nextwith($string);
        }
        method get() {
            my $line := callwith();
            note '<== '~$line;
            $line
        }
    }
    if $raw {
        my $conn = $socket.defined ?? $socket !! $socket.new(:host($server), :$port, :nl-in("\r\n"));
        $conn = $conn but debug-connection if $debug;
        $conn.nl-in = "\r\n";
        Net::IMAP::Raw.new(:$conn)
    }
    else {
        Net::IMAP::Simple.new:
          :$ssl, :tls($starttls), :$plain,
          raw => Net::IMAP.new(:$server, :$port, :$debug, :$socket, :raw)
    }
}

# vim: expandtab shiftwidth=4
