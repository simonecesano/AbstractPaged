<style scoped>
* { font-family: Courier }

div.row                { background-color: #aaaaaa }
div.row:nth-child(odd) { background-color: #dddddd }

div.cell { padding: 12px }

div.row   { display: table-row; border: none;  }
div.table { display: table; }
div.tbody { display: table-row-group }

@media screen and (max-width: 575.98px) {
    div.group  { display: table-cell;  border: none; vertical-align:top }
    div.label   { width: 10em }
    div.label.nopic   { width: 18em }

    div.cell  { display: inline-block; vertical-align: top; margin-top: auto }

    div.picture.cell     { width: 100px; display: inline-block }
    div.picture.cell img { margin-top: 0 }
    div.picture.cell.nopic { width: 0px; display: none }
}

@media screen and (min-width: 576px) {
    div.cell  { display: table-cell; vertical-align: top; margin-top: auto } 
    div.group  { display: table-cell;  border: none; vertical-align:top }
    div.label   { width: 24em }
    div.picture { width: 120px }
}

</style>
<template>
  <div>
    <div class="table">
      <div class="tbody" :key="update">
	<div :key="r.idx" :data-idx="r.idx" :class="['row', isLastItem(r) ? 'last' : undefined]" v-for="(r, i) in items.slice(firstItem, lastItem)">
	  <div class="group">
	    <div class="cell mapcat">
	      <icon :key="r.map_category + r.entity_class" :icon="r.map_category.replace(/ /g, '_')" :color="r.entity_class" />
	    </div>
	    <div :class="['cell', 'label', r.entity_data && r.entity_data.picture ? undefined : 'nopic']">{{ (r.entity_data || {}).label }}</div>
	    <div :class="['cell', 'picture', r.entity_data && r.entity_data.picture ? undefined : 'nopic']">
	      <img @error="imgError($event, r)" v-if="r.entity_data && r.entity_data.picture" :src="r.entity_data.picture">
	    </div>
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
	    firstItem: 0,
	    lastItem: 128,
	    update: 0,
	    observer: undefined,
	    minRow: 0,
	    maxRow: undefined,
	};
    },
    mounted: function(){
	var c = this;
	axios.get('/items')
	    .then(d => {
		c.items = d.data.value
		    .slice(0, 32)
		    .map((p, i) => {
			p.idx = i;
			p.entity_class = ['A', 'B', 'C'][Math.floor(Math.random() * 3)];
			return p
		    });
		Vue.nextTick(function () { c.startLazyLoader() })
		c.loadEntities()
	    })
	    .catch(e => console.log(e))
    },
    components: {
        item: httpVueLoader('components/base/item.vue'),
        icon: httpVueLoader('components/base/icon.vue'),
    },
    destroyed: function(){

    },
    methods: {
	isLastItem: function(item){
	    return (item.idx + 1) == this.lastItem || (item.idx + 1) == this.items.length;
	},
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
	isInViewport: function(element) {
	    const rect = element.getBoundingClientRect();
	    return (
		rect.top >= 0 &&
		    rect.left >= 0 &&
		    rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
		    rect.right <= (window.innerWidth || document.documentElement.clientWidth)
	    );
	},
	getScrollTops: function(){
	    var c = this;
	    var rows = Array.from(document.querySelectorAll('.row'))
		.map((row, i) => [ i, c.isInViewport(row), row.dataset.idx ])
	    console.log(rows);
	    c.minRow = Math.min(...rows.filter(r => r[1]).map(r => r[2]));
	    c.maxRow = Math.max(...rows.filter(r => r[1]).map(r => r[2]));
	    return [ c.minRow, c.maxRow ];
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
	    var l = 0;
	    
	    c.items.slice(c.firstItem, c.lastItem)
		.forEach((i, k) => {
		    if (!i.entity_data) {
			axios.get('/entity/' + i.entity_id)
			    .then(d => {
				i.entity_data = d.data;
				if (i.entity_data && i.entity_data.picture) { c.preloadImage(i.entity_data.picture) };
				if (!(l++ % 16)) {
				    c.update = Math.random()
				    Vue.nextTick(function () { c.observer.observe(document.querySelector('.last')) })
				}
			    })
			    .catch(e => console.log(e))
		    }
		});
	},
	observerCallback: function(entries, observer){
	    var c = this;
            if (entries.filter(entry => entry.isIntersecting).length) {
		if (c.lastItem <= c.items.length) {
		    c.lastItem = c.lastItem + 128;
		    c.loadEntities();
		    Vue.nextTick(function () {
			observer.observe(document.querySelector('.last'))
		    })
		} else {
		    c.loadEntities();
		    Vue.nextTick(function () {
			observer.observe(document.querySelector('.last'))
		    })
		}
            }
	},
	startLazyLoader: function(){
	    var c = this;
	    var screenHeight = 2 * window.screen.height + 'px';
            let options = { rootMargin: screenHeight, threshold: 0 }
            var observer = new IntersectionObserver(c.observerCallback, options);
            observer.observe(document.querySelector('.last'))
	    c.observer = observer;
	},
    },
}
</script>
