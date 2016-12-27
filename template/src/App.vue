<template>
  <div class="view">
    <hello></hello>
  </div>
</template>

<script>
  import Hello from './components/hello.vue'

  export default {
    name: 'app',
    components: {
      Hello
    }
  }
</script>

<style scoped>
  .view {
    width: 100%;
    height: 100%;
    background-color: #F5F5F5;
  }
</style>
