<style scoped>
* { font-family: Courier }
tr                { background-color: #aaaaaa }
tr:nth-child(odd) { background-color: #dddddd; }

/* tr, tr * { opacity: 0 } */
td { padding: 12px }

table { table-layout: fixed; width: 32em }
td:nth-child(0) { column-width: 24em;  }
td:nth-child(1) { column-width: 8em;  }
</style>
<template>
  <div>
    <div>min row: {{ minRow }}</div>
    <div>max row: {{ maxRow }}</div>
    <div @click="nextPage">next</div>
    <div @click="prevPage">prev</div>
    <table>
      <col style="width:64em">
      <col style="width:8em">
      <tbody :key="update">
	<item v-for="(r, i) in items.slice(minRow, maxRow + 1)"
	      :data-idx="r.idx" :class="(i + 1) == lastItem ? 'last' : undefined"
	      :key="r.idx" :entity_id="r.entity_id"></item>
      </tbody>
    </table>
  </div>
</template>
<script>
module.exports = {
    data: function () {
	return {
	    pages: [],
	    items:   [ ],
	    lastItem: 40,
	    update: 0,
	    observer: undefined,
	    minRow: 0,
	    maxRow: 40,
	    currPage: 0,
	};
    },
    mounted: function(){
	var c = this;
	console.log(c);
	axios.get('/items')
	    .then(d => {
		console.log(JSON.stringify(d.data.value[0]));
		c.items = d.data.value.map((p, i) => { p.idx = i; return p });
		console.log(JSON.stringify(c.items[0]));

		// c.loadEntities()
	    })
	    .catch(e => console.log(e))
	setInterval(function(){
	    c.getScrollTops()
	}, 300);
    },
    components: {
        item: httpVueLoader('components/item.vue'),
    },
    destroyed: function(){

    },
    methods: {
	nextPage: function(){
	    var c = this;
	    this.minRow = this.maxRow + 1
	    this.maxRow = this.maxRow + 40;
	    this.loadEntities()
	    this.currPage = this.currPage + 1;
	},
	prevPage: function(){
	    if (this.currPage > 0) {
		this.minRow = this.pages[this.currPage - 1][0];
		this.maxRow = this.pages[this.currPage - 1][1];
		this.currPage = this.currPage - 1
	    }
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
	    var rows = Array.from(document.querySelectorAll('tr'))
		.map((row, i) => [ i, c.isInViewport(row), row.dataset.idx ])
	    c.minRow = Math.min(...rows.filter(r => r[1]).map(r => r[2]));
	    c.maxRow = Math.max(...rows.filter(r => r[1]).map(r => r[2]));
	    c.pages[c.currPage] = [c.minRow, c.maxRow];
	},
	scrollTop: function(e){
	    console.log('scrollTop', e);
	},
	loadEntities: function(){
	    var c = this;
	    c.items.slice(0, c.maxRow + 40)
		.forEach((i, k) => {
		    if (!i.entity_data) {
			// axios.get('https://www.wikidata.org/wiki/Special:EntityData/' + i.entity_id + '.json')
			axios.get('/entity/' + i.entity_id)
			    .then(d => {
				if(d.data.picture) {
				    var img = new Image;
				    img.onload = function(){ console.log('loaded', this) }
				    img.src = d.data.picture
				}
				i.entity_data = d.data;
				if (!(k % 10)) {
				    c.update = Math.random()
				}
			    })
			    .catch(e => console.log(e))
		    }
		});
	    c.update = c.update;
	},
	observerCallback: function(entries, observer){
	},
	startLazyLoader: function(){
	},
    },
}
</script>
