<template>
  <div class="container mx-auto px-4 py-8 max-w-4xl">
    <div class="mb-8">
      <NuxtLink to="/dashboard" class="text-emerald-500 hover:text-emerald-400 mb-4 inline-block">&larr; Back to Dashboard</NuxtLink>
      <h1 class="text-3xl font-bold text-white">Join a Meeting</h1>
    </div>

    <div v-if="loading" class="text-center py-12 text-gray-400">
      Loading meetings...
    </div>

    <div v-else-if="meetings.length === 0" class="text-center py-12 bg-gray-800 rounded-lg border border-gray-700">
      <p class="text-gray-400">No meetings found.</p>
      <NuxtLink to="/host" class="text-emerald-500 hover:text-emerald-400 mt-2 inline-block">Host one?</NuxtLink>
    </div>

    <div v-else class="grid gap-4">
      <NuxtLink
        v-for="meeting in meetings"
        :key="meeting.id"
        :to="`/meeting/${meeting.id}`"
        class="block p-6 bg-gray-800 rounded-lg border border-gray-700 hover:border-emerald-500 transition-all hover:shadow-lg hover:shadow-emerald-900/10"
      >
        <div class="flex justify-between items-start">
          <div>
            <h2 class="text-xl font-bold text-white mb-2">{{ meeting.title }}</h2>
            <p class="text-gray-400 text-sm line-clamp-2">{{ meeting.description }}</p>
          </div>
          <div class="text-xs text-gray-500">
            Hosted by {{ meeting.host?.username || 'Unknown' }}
          </div>
        </div>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
const client = useSupabaseClient()
const meetings = ref<any[]>([])
const loading = ref(true)

onMounted(async () => {
  try {
    const { data, error } = await client
      .from('meetings')
      .select(`
        *,
        host:users(username)
      `)
      .order('created_at', { ascending: false })
    
    if (error) throw error
    meetings.value = data
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>
