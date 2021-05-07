<style scoped>
* { font-family: Courier }

div.row                { background-color: #aaaaaa }
div.row:nth-child(odd) { background-color: #dddddd }
div.cell { padding: 12px }

div.cell  { display: table-cell; border: none; vertical-align: top; margin-top: auto }

div.group  { display: table-cell;  border: none; vertical-align:top; }

div.row   { display: table-row; border: none;  }
div.table { display: table }
div.tbody { display: table-row-group }

div.label   { width: 24em }
div.picture { width: 120px }

</style>
<template>
  <div>
    <div class="table">
      <div class="tbody" :key="update">
	<div :key="r.idx" :class="['row', (i + 1) == lastItem ? 'last' : undefined]" v-for="(r, i) in items.slice(0, lastItem)">
	  <div class="group">
	    <div class="cell">{{ i + 1 }}</div>
	    <div class="cell eclass">{{ r.entity_class }}</div>
	    <div class="cell mapcat">{{ r.map_category }}</div>
	  </div>
	  <div class="group">
	    <div class="cell label">{{ (r.entity_data || {}).label }}</div>
	    <div class="cell picture"><img @error="imgError($event, r)" v-if="r.entity_data && r.entity_data.picture" :src="r.entity_data.picture"></div>
	  </div>
	</div>
      </div>
    </div>
  </div>
</template>
<script>
module.exports = {
    data: function () {
	return {
	    items:   [ ],
	    lastItem: 40,
	    update: 0,
	    observer: undefined,
	};
    },
    mounted: function(){
	var c = this;
	axios.get('https://www.wikidata.org/wiki/Special:EntityData/Q28937423.json')
	    .then(d => console.log(d.data))
	    .catch(e => console.log(e))

	axios.get('/items')
	    .then(d => {
		// console.log(JSON.stringify(d.data.value.slice(0, 10)));
		c.items = d.data.value;

		Vue.nextTick(function () {
		    c.startLazyLoader();
		})
		c.loadEntities()
	    })
	    .catch(e => console.log(e))
    },
    components: {
        item: httpVueLoader('components/base/item.vue'),
    },
    destroyed: function(){

    },
    methods: {
	imgError: function(e, r){
	    var c = this;
	    c.items.forEach(i => {
		if (i.entity_data && i.entity_data.picture == e.originalTarget.src) {
		    console.log(e.originalTarget.src, r.picture, i.entity_data.picture);
		    i.entity_data.picture = null
		}
	    })
	    r.picture = null;
	},
	preloadImage: function(src){
	    var c = this;
	    var img = new Image;
	    function markError(src){
		c.items.forEach(i => {
		    if (i.entity_data && i.entity_data.picture == src) {
			i.entity_data.picture = null
		    }
		})
	    }
	    
	    img.onerror = function(e) {
		markError(e.target.src);
	    }
	    img.onload  = function() {  }
	    img.src = src;
	},
	imgUrl: function(file, size){
	    var file_nsp = file.replace(/ /g, '_');
	    var md5 = SparkMD5.hash(file_nsp);
	    var url = size ?
		`https://upload.wikimedia.org/wikipedia/commons/thumb/${md5.substr(0, 1)}/${md5.substr(0, 2)}/${file_nsp}/${size}px-${file_nsp}`
		:
		`https://upload.wikimedia.org/wikipedia/commons/${md5.substr(0, 1)}/${md5.substr(0, 2)}/${file_nsp}`
	    ;
	    return url
	},
	getEntityFromWikidata: function(entity_id, langs, pictureSize){
	    var c = this;
	    var url = 'https://www.wikidata.org/wiki/Special:EntityData/' + entity_id + '.json';
	    
	    var lang = ['en', 'it', 'de', 'fr', 'es'];
	    return axios.get(url)
		.then(d => {
		    var entity = Object.values(d.data.entities)[0]
		    var labels = lang.map(l => { return entity.labels[l] }).filter(l => l).map(l => l.value);
		    var links  = lang.map(l => { return entity.sitelinks[l + 'wiki'] }).filter(l => l).map(l => l.url);
		    var picture; try { picture = entity.claims.P18[0].mainsnak.datavalue.value } catch(e){};
		    return Promise.resolve({ label: (labels ||[])[0], link: (links || [])[0], picture: picture ? c.imgUrl(picture, 100) : false });
		})
	},
	loadEntities: function(){
	    var c = this;
	    c.items.slice(0, c.lastItem)
		.forEach((i, k) => {
		    if (!i.entity_data) {
			axios.get('/entity/' + i.entity_id)
			    .then(d => {
				i.entity_data = d.data;
				if (i.entity_data && i.entity_data.picture) { c.preloadImage(i.entity_data.picture) };
				if (!(k % 10)) {
				    c.update = Math.random()
				    Vue.nextTick(function () { c.observer.observe(document.querySelector('.last')) })
				}
			    })
			    .catch(e => console.log(e))
			// c.getEntityFromWikidata(i.entity_id)
			//     .then(d => {
			// 	i.entity_data = d;
			// 	if (i.entity_data && i.entity_data.picture) { c.preloadImage(i.entity_data.picture) };
			// 	if (!(k % 10)) {
			// 	    c.update = Math.random()
			// 	    Vue.nextTick(function () { c.observer.observe(document.querySelector('.last')) })
			// 	}
			//     })
			//     .catch(e => console.log(e))
		    }
		});
	},
	observerCallback: function(entries, observer){
	    var c = this;
            if (entries.filter(entry => entry.isIntersecting).length) {
		c.lastItem = c.lastItem + 80;
		console.log('loading ' + c.lastItem)
		c.loadEntities();
		Vue.nextTick(function () {
		    observer.observe(document.querySelector('.last'))
		})
            }
	},
	startLazyLoader: function(){
	    var c = this;
	    var screenHeight = window.screen.height + 'px';
            let options = { rootMargin: screenHeight, threshold: 0 }
            var observer = new IntersectionObserver(c.observerCallback, options);
            observer.observe(document.querySelector('.last'))
	    c.observer = observer;
	},
    },
}
</script>
