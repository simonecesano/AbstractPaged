<style scoped>
</style>
<template>
  <svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="16" height="16" style="float:center">
    <defs>
      <filter :id="'colorMask1' + iconColor(color) + icon">
	<feFlood :flood-color="iconColor(color)" result="flood" />
	<feComposite in="SourceGraphic" in2="flood" operator="arithmetic" k1="1" k2="0" k3="0" k4="0" />
      </filter>
    </defs>
    <image width="100%" height="100%" v-bind:xlink:href="'/icons/' + icon + '.png'" :filter="'url(#colorMask1' + iconColor(color) + icon + ')'" />
  </svg>
</template>
<script>
module.exports = {
    props: ['icon', 'color'],
    data: function () {
	return {
	    colors: { 'C': '#ffffd4', 'B': '#fe9929', 'A': '#993404' }
	};
    },
    methods: {
	iconColor: function(i){
	    // iconColor(color) + icon
	    // console.log(i, this.colors[i]);
	    return this.colors[i];
	}
    }
}
</script>
