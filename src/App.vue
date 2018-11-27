<template>
  <div style="justify-content:center">
    <text class="text">{{greeting}}</text>
  </div>
</template>

<script>
  export default {
    data () {
      return {
        greeting: 'Hello World!'
      }
    }
  }
</script>

<style scoped>
  .text {
    color: #41B883;
    text-align: center;
    font-size: 100px;
  }
</style>
