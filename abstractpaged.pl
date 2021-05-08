#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::File qw/path/;
use Mojo::JSON qw/decode_json/;

app->types->type(vue => 'text/plain');

plugin 'Config';
plugin Config => { file => 'icons.conf' };

helper version => sub { state $ver = app->config->{version} || sprintf('%d', time() * rand()) };

helper components => sub {
    state $components = path('.')->list_tree->grep(sub { /vue$/ });
};

get '/' => sub ($c) { $c->render(template => 'index') };

get '/version' => sub { my $c = shift; $c->render(text => $c->version) };

get '/app.js' => sub { my $c = shift; $c->render(template => 'app', format => 'js') };

get '/components/index.vue' => sub { my $c = shift; $c->render(template => 'components/index', format => 'vue') };


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

get '/components' => [format => ['json'] ] => sub {
    my $c = shift;
    my $components = path('.')->list_tree->grep(sub { /vue$/ })->map(sub { shift() })->grep(sub { ! /base/ })->to_array;
    return $c->render(json => $components);
};

get '/components' => sub {
    my $c = shift;
    # ->to_rel('./public')
    # ->map(sub { shift()->stat->mtime })
    my $components = path('.')->list_tree->grep(sub { /vue$/ })->map(sub { shift() })->to_array;

    $c->log->info($c->stash('format'));
    $c->stash('components', $components);
    $c->render(template => 'components');
};

get '/icons/:map_category' => [format => ['png'] ] => sub {
    my $c = shift;
    $c->res->code(301);
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
@@ app.js.ep
var app = new Vue({
    el: '#app',
    router: (new VueRouter({
	routes: [
	        { path: '/', component: httpVueLoader('components/index.vue') },
		% for my $component (@{app->components->grep(sub { ! /base/ } )->map(sub { s/^public//; $_ })}) {
		     { path: "<%= $component =~ s/components.//r =~ s/\.vue$//r; %>", component: httpVueLoader("<%= $component %>?version=<%= app->version %>") },
	         % }
    		 ],
    })),
    data(){
	return {
	}
    },
});
@@ components/index.vue.ep
<style scoped>
</style>
<template>
  <div>
  <div><h1>Welcome to <%= app->moniker %>!</h1></div>
  % for my $component (@{app->components->grep(sub { ! /base/ } )->map(sub { s/^public//; $_ })}) {
  <div><a href="#<%= $component =~ s/components.//r =~ s/\.vue$//r; %>"><%= $component =~ s/components.//r =~ s/\.vue$//r; %></a></div>
  % }
  </div>
</template>
<script>
module.exports = {
    data: function () {
	return {
	};
    },
    mounted: function(){
    },
    destroyed: function(){
    },
    methods: {
    },
}
</script>
