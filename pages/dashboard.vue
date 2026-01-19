<template>
  <div class="container mx-auto px-4 py-12">
    <div class="flex justify-between items-center mb-12">
      <h1 class="text-2xl font-bold text-white">Welcome, {{ user?.username }}</h1>
      <button @click="logout" class="text-sm text-gray-400 hover:text-white">Change User</button>
    </div>

    <div class="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
      <!-- Host Card -->
      <NuxtLink to="/host" class="group relative p-8 bg-gray-800 rounded-xl border border-gray-700 hover:border-emerald-500 transition-all duration-300 hover:shadow-lg hover:shadow-emerald-900/20">
        <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-24 w-24 text-emerald-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
          </svg>
        </div>
        <h2 class="text-2xl font-bold text-white mb-4 group-hover:text-emerald-400 transition-colors">Host a meeting</h2>
        <p class="text-gray-400">Create a new meeting, set dates and times, and invite colleagues.</p>
      </NuxtLink>

      <!-- Join Card -->
      <NuxtLink to="/join" class="group relative p-8 bg-gray-800 rounded-xl border border-gray-700 hover:border-blue-500 transition-all duration-300 hover:shadow-lg hover:shadow-blue-900/20">
        <div class="absolute top-0 right-0 p-4 opacity-10 group-hover:opacity-20 transition-opacity">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-24 w-24 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
        </div>
        <h2 class="text-2xl font-bold text-white mb-4 group-hover:text-blue-400 transition-colors">Join a meeting</h2>
        <p class="text-gray-400">View available meetings, vote on times, and see who's attending.</p>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const user = useUser()
const router = useRouter()

onMounted(() => {
  if (!user.value) {
    router.push('/')
  }
})

const logout = () => {
  user.value = null
  router.push('/')
}
</script>
