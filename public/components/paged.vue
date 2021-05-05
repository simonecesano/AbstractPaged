<style scoped>
* { font-family: Courier }
tr                { background-color: #aaaaaa }
tr:nth-child(odd) { background-color: #dddddd; }
td { padding: 12px }
</style>
<template>
  <div>
    <table>
      <tbody :key="update">
	<tr :class="(i + 1) == lastItem ? 'last' : undefined" v-for="(r, i) in items.slice(0, lastItem)">
	  <td>{{ i }}</td>
	  <td>{{ r.entity_id }}</td>
	  <td>{{ r.entity_class }}</td>
	  <td>{{ r.map_category }}</td>
	  <td>{{ (r.entity_data || {}).title }}</td>
	</tr>
      </tbody>
    </table>
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
		console.log(JSON.stringify(d.data.value[0]));
		c.items = d.data.value;

		Vue.nextTick(function () {
		    c.startLazyLoader();
		})
		c.loadEntities()
	    })
	    .catch(e => console.log(e))
    },
    destroyed: function(){

    },
    methods: {
	loadEntities: function(){
	    var c = this;
	    c.items.slice(0, c.lastItem)
		.forEach((i, k) => {
		    if (!i.entity_data) {
			// axios.get('https://www.wikidata.org/wiki/Special:EntityData/' + i.entity_id + '.json')
			axios.get('/entity/' + i.entity_id)
			    .then(d => {
				i.entity_data = d.data;
			    })
			    .catch(e => console.log(e))
		    }
		});
	    c.update = c.update;
	},
	startLazyLoader: function(){
	    var c = this;
            let options = { rootMargin: '160px', threshold: 0 }
	    var observer;
            let callback = (entries, observer) => {
                if (entries.filter(entry => entry.isIntersecting).length) {
		    c.lastItem = c.lastItem + 20;
		    console.log('loading ' + c.lastItem)
		    c.loadEntities()
		    Vue.nextTick(function () {
			observer.observe(document.querySelector('.last'))
		    })
                }
            };
            observer = new IntersectionObserver(callback, options);
            observer.observe(document.querySelector('.last'))
	    c.observer = observer;
	},
    },
}
</script>
