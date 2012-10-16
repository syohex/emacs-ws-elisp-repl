use strict;
use warnings;
use utf8;

use Amon2::Lite;
use Digest::MD5 ();

get '/' => sub {
    my $c = shift;
    return $c->render('index.tt');
};

my $clients = {};
my $emacs;

any '/emacs' => sub {
    my $c = shift;

    $c->websocket(sub {
        my $ws = shift;
        $emacs = $ws;

        $ws->on_receive_message(sub {
            my ($c, $evaled) = @_;
            for (keys %$clients) {
                $clients->{$_}->send_message($evaled);
            }
        });

        $ws->on_eof(sub {
            my $c = shift;
            print "Emacs EOF\n";
        });

        $ws->on_error(sub {
            my $c = shift;
            print "Emacs Error\n";
        });
    });
};

any '/repl' => sub {
    my ($c) = @_;
    my $id = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);

    $c->websocket(sub {
        my $ws = shift;
        $clients->{$id} = $ws;

        $ws->on_receive_message(sub {
            my ($c, $sexp) = @_;
            warn "Emacs is not connected!!" unless defined $emacs;
            $emacs->send_message($sexp);
        });
        $ws->on_eof(sub {
            my ($c) = @_;
            delete $clients->{$id};
        });
        $ws->on_error(sub {
            my ($c) = @_;
            delete $clients->{$id};
        });
    });
};

# load plugins
__PACKAGE__->load_plugin('Web::WebSocket');
__PACKAGE__->enable_middleware('AccessLog');
__PACKAGE__->enable_middleware('Lint');

__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Emacs Lisp REPL</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="/static/jquery.min.js"></script>
    <link rel="stylesheet" href="/static/bootstrap.min.css">
</head>
<body>
    <div class="container">
        <header><h1>Emacs Lisp REPL</h1></header>
        <section class="row">
            <form id="form">
                <textarea name="buffer" id="buffer" cols="40" rows="10"></textarea>
                <br />
                <input type="submit" value="eval">
            </form>
            <pre id="log"></pre>
        </section>
        <footer>Powered by <a href="http://amon.64p.org/">Amon2::Lite</a></footer>
    </div>
    <script type="text/javascript">
        function log(msg) {
            $('#log').text(msg + "\n" + $('#log').text());
        }

        $(function () {
            var ws = new WebSocket('ws://localhost:5000/repl');
            ws.onopen = function () {
                console.log('connected');
            };
            ws.onclose = function (ev) {
                console.log('closed');
            };
            ws.onmessage = function (ev) {
                log(ev.data);
                $('#buffer').val('');
            };
            ws.onerror = function (ev) {
                console.log(ev);
                log('error: ' + ev.data);
            };
            $('#form').submit(function () {
                var input = $('#buffer').val();
                log(input);
                ws.send(input);
                return false;
            });
        });
    </script>
</body>
</html>
