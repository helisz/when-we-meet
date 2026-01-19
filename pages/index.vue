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
          <div class="relative">
            <input
              id="username"
              v-model="username"
              type="text"
              required
              autocomplete="off"
              class="w-full px-4 py-2 mt-1 text-white bg-gray-900 border border-gray-600 rounded-md focus:ring-2 focus:ring-emerald-500 focus:border-transparent outline-none transition-all"
              placeholder="Enter your name"
              @input="onInput"
              @focus="onInput"
              @blur="hideSuggestions"
            />
            <ul v-if="suggestions.length > 0" class="absolute z-10 w-full bg-gray-800 border border-gray-600 rounded-md mt-1 max-h-48 overflow-y-auto shadow-lg">
              <li
                v-for="s in suggestions"
                :key="s.id"
                @click="selectUser(s)"
                class="px-4 py-2 hover:bg-gray-700 cursor-pointer text-white"
              >
                {{ s.username }}
              </li>
            </ul>
          </div>
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
const suggestions = ref<any[]>([])
const loading = ref(false)
const router = useRouter()
let debounceTimer: any = null

const onInput = () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(async () => {
    if (username.value.length < 1) {
      suggestions.value = []
      return
    }
    const { data } = await client
      .from('users')
      .select('id, username')
      .ilike('username', `%${username.value}%`)
      .limit(5)
    
    suggestions.value = data || []
  }, 300)
}

const selectUser = (u: any) => {
  username.value = u.username
  suggestions.value = []
}

const hideSuggestions = () => {
  setTimeout(() => {
    suggestions.value = []
  }, 200)
}

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
    
    if (user.value) {
      localStorage.setItem('user', JSON.stringify(user.value))
    }
    
    const redirect = localStorage.getItem('redirectAfterLogin')
    if (redirect) {
      localStorage.removeItem('redirectAfterLogin')
      router.push(redirect)
    } else {
      router.push('/dashboard')
    }
  } catch (e: any) {
    alert('Error: ' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (user.value) {
    router.push('/dashboard')
  }
})
</script>
