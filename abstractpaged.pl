#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::File qw/path/;
use Mojo::JSON qw/decode_json/;

app->types->type(vue => 'text/plain');

plugin 'Config';
plugin Config => { file => 'icons.conf' };

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

get '/components' => sub {
    my $c = shift;
    # ->to_rel('./public')
    # ->map(sub { shift()->stat->mtime })
    my $components = path('.')->list_tree->grep(sub { /vue$/ })->map(sub { shift() })->to_array;
    $c->stash('components', $components);
    $c->render(template => 'components');
};

get '/icons/:map_category' => [format => ['png'] ] => sub {
    my $c = shift;
    $c->redirect_to('/icons/' . $c->config->{icons}->{$c->stash('map_category') } . '.png');
};

get '/icons/:map_category' => [format => ['json'] ] => sub {
    my $c = shift;
    $c->render(json => $c->config->{icons})
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
@@ components.html.ep
<table style="font-family: Courier">
  <tbody>
    % for (sort { $b->stat->mtime <=> $a->stat->mtime } @$components) {
    <tr><td><a href="<%= $_->to_rel('./public') %>"><%= $_->to_rel('./public') %></a></td><td><%= $_->stat->mtime %></td></tr>
    % }
    <tr>
  </tbody>
</table>
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

    <script src="https://cdn.jsdelivr.net/npm/jsonpath-plus@5.0.7/dist/index-browser-umd.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/spark-md5/3.0.0/spark-md5.min.js"
	    integrity="sha512-5Cmi5XQym+beE9VUPBgqQnDiUhiY8iJU+uCUbZIdWFmDNI+9u3A7ntfO8fRkigdZCRrbM+DSpSHSXAuOn5Ajbg==" crossorigin="anonymous"></script>    
    </head>
  <body><%= content %></body>
  <script type="module" src="/app.js"></script>
</html>
