<style scoped>
</style>
<template>
  <div>
    <table>
      <item v-for="r in items" :key="r" :entity_id="r"></item>
    </table>
  </div>
</template>
<script>
module.exports = {
    data: function () {
	return {
	    items: ['Q603939', 'Q1115154', 'Q3674237', 'Q22980015', 'Q2479053']
	};
    },
    mounted: function(){
    },
    destroyed: function(){
    },
    methods: {
    },
    components: {
        item: httpVueLoader('components/item.vue'),
    },
}
</script>
