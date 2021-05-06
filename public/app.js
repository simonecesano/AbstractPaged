var app = new Vue({
    el: '#app',
    router: (new VueRouter({
	routes: [
	    { path: '/',        component: httpVueLoader('components/index.vue') },
	    { path: '/page/:p', component: httpVueLoader('components/paged.vue') },
	    { path: '/many',    component: httpVueLoader('components/many.vue') },
    	],
    })),
    data(){
	return {
	}
    },
    mounted: function(){
    },
    methods: {
    },
    components: {
    },
    filters: {
    }    
});
