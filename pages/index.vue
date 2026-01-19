<template>
  <div class="flex flex-col items-center justify-center min-h-screen px-4">
    <div class="w-full max-w-md p-8 space-y-6 bg-gray-800 rounded-lg shadow-xl border border-gray-700">
      <div class="text-center">
        <h1 class="text-3xl font-bold text-emerald-400">When We Meet</h1>
        <p class="mt-2 text-gray-400">Coordinate meetings with your colleagues</p>
      </div>

      <form @submit.prevent="login" class="space-y-4">
        <div>
          <label for="username" class="block text-sm font-medium text-gray-300">Username</label>
          <input
            id="username"
            v-model="username"
            type="text"
            required
            class="w-full px-4 py-2 mt-1 text-white bg-gray-900 border border-gray-600 rounded-md focus:ring-2 focus:ring-emerald-500 focus:border-transparent outline-none transition-all"
            placeholder="Enter your name"
          />
        </div>

        <button
          type="submit"
          :disabled="loading"
          class="w-full px-4 py-2 font-medium text-white bg-emerald-600 rounded-md hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-emerald-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          <span v-if="loading">Loading...</span>
          <span v-else>Continue</span>
        </button>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
const client = useSupabaseClient()
const user = useUser()
const username = ref('')
const loading = ref(false)
const router = useRouter()

const login = async () => {
  if (!username.value.trim()) return
  loading.value = true
  
  try {
    // Check if user exists
    const { data: existingUser, error: fetchError } = await client
      .from('users')
      .select('*')
      .eq('username', username.value.trim())
      .maybeSingle()

    if (fetchError) throw fetchError

    if (existingUser) {
      user.value = existingUser
    } else {
      // Create new user
      const { data: newUser, error: createError } = await client
        .from('users')
        .insert({ username: username.value.trim() })
        .select()
        .single()
        
      if (createError) throw createError
      user.value = newUser
    }
    
    router.push('/dashboard')
  } catch (e: any) {
    alert('Error: ' + e.message)
  } finally {
    loading.value = false
  }
}
</script>
