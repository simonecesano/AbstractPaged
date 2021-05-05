#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::File qw/path/;
use Mojo::JSON qw/decode_json/;

app->types->type(vue => 'text/plain');

plugin 'Config';

get '/' => sub ($c) {
  $c->render(template => 'index');
};

get '/items' => sub {
    my $c = shift;
    my $json = decode_json(path('items.json')->slurp);
    $c->render(json => $json)
};

get '/entity/:id' => sub {
    my $c = shift;
    $c->render_later;
    $c->ua->get_p('https://test.ingi.ro/api/wd/entity/' . $c->stash('id'))
	->then(sub {
		   my $tx = shift;
		   $c->render(json => $tx->res->json);
	       })
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<div id="app">
  <router-view>
  </router-view>
</div>
@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <script src="https://cdnjs.cloudflare.com/ajax/libs/axios/0.19.0/axios.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/http-vue-loader@1.4.1/src/httpVueLoader.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/vue-router@3.1.5/dist/vue-router.js"></script>
  </head>
  <body><%= content %></body>
  <script type="module" src="/app.js"></script>
</html>
