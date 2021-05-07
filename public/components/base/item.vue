<style scoped>
</style>
<template>
  <div class="group">
    <div class="cell label">{{ item.label }}</div>
    <div class="cell picture"><img @error="imgError($event, item)" v-if="item && item.picture" :src="item.picture"></div>
  </div>
</template>
<script>
module.exports = {
    props: ['entity_id', 'lang'],
    data: function () {
	return {
	    done: false,
	    item: {}
	};
    },
    mounted: function(){
	var c = this;
	var url = 'https://www.wikidata.org/wiki/Special:EntityData/' + this.entity_id + '.json';
	
	var lang = ['en', 'it', 'de', 'fr', 'es'];

	axios.get(url)
	    .then(d => {
		var entity = Object.values(d.data.entities)[0]
		var labels = lang.map(l => { return entity.labels[l] }).filter(l => l).map(l => l.value);
		var links  = lang.map(l => { return entity.sitelinks[l + 'wiki'] }).filter(l => l).map(l => l.url);
		var picture; try { picture = entity.claims.P18[0].mainsnak.datavalue.value } catch(e){};
		c.done = true;
		c.item = { label: (labels ||[])[0], link: (links || [])[0], picture: picture ? c.imgUrl(picture, 100) : false };
	    })
	    .catch(e => console.log(e))
    },
    destroyed: function(){
    },
    methods: {
	imgError: function(e){
	    console.log(e)
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
	async imgLoadPromise(url){
	    var img = new Image;
	    return new Promise((resolve, reject) => {
		img.onload = () => resolve(img);
		img.onerror = reject;
		img.src = url;
	    })
	}
    },
}
</script>
