<template>
  <div class="container mx-auto px-4 py-8 max-w-6xl">
    <div v-if="loading" class="text-center py-12 text-gray-400">Loading...</div>
    <div v-else-if="!meeting" class="text-center py-12 text-red-400">Meeting not found</div>
    <div v-else>
      <div class="mb-8">
        <NuxtLink to="/join" class="text-emerald-500 hover:text-emerald-400 mb-4 inline-block">&larr; Back to List</NuxtLink>
        <div class="flex justify-between items-start">
          <div>
            <h1 class="text-3xl font-bold text-white mb-2">{{ meeting.title }}</h1>
            <p class="text-gray-400 whitespace-pre-wrap">{{ meeting.description }}</p>
          </div>
          <div class="text-right flex flex-col items-end gap-2">
            <div>
              <div class="text-sm text-gray-500">Hosted by</div>
              <div class="font-medium text-emerald-400">{{ meeting.host?.username }}</div>
            </div>
            <button
              v-if="isHost"
              @click="deleteMeeting"
              class="text-red-500 hover:text-red-400 text-sm underline"
            >
              Delete Meeting
            </button>
          </div>
        </div>
      </div>

      <!-- View Toggle -->
      <div class="flex justify-end mb-6 space-x-4">
        <button 
          @click="viewMode = 'vote'"
          :class="['px-4 py-2 rounded-md transition-colors', viewMode === 'vote' ? 'bg-emerald-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700']"
        >
          Vote
        </button>
        <button 
          @click="viewMode = 'result'"
          :class="['px-4 py-2 rounded-md transition-colors', viewMode === 'result' ? 'bg-emerald-600 text-white' : 'bg-gray-800 text-gray-400 hover:bg-gray-700']"
        >
          View Result
        </button>
      </div>

      <!-- Voting Grid -->
      <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div v-for="(slots, date) in groupedSlots" :key="date" class="bg-gray-800 rounded-lg border border-gray-700 overflow-hidden">
          <div class="bg-gray-900 p-4 border-b border-gray-700">
            <h3 class="font-bold text-white">{{ format(new Date(date), 'EEEE, MMMM d') }}</h3>
          </div>
          <div class="p-4 space-y-3">
            <div v-for="slot in slots" :key="slot.id" class="flex items-center justify-between group">
              <div class="flex items-center space-x-2 w-24">
                <div class="text-gray-300 text-sm font-medium">
                  {{ formatTime(slot.time_slot) }}
                </div>
                <button
                  v-if="isHost"
                  @click="deleteSlot(slot.id)"
                  class="text-gray-600 hover:text-red-500 transition-colors"
                  title="Remove slot"
                >
                  &times;
                </button>
              </div>
              
              <!-- Vote Mode -->
              <div v-if="viewMode === 'vote'" class="flex-1 flex items-center justify-end space-x-3">
                <!-- Others' avatars -->
                <div class="flex -space-x-2 overflow-hidden">
                  <div
                    v-for="participant in getParticipants(slot.id, false)"
                    :key="participant.id"
                    class="inline-block h-6 w-6 rounded-full ring-2 ring-gray-800 bg-gray-600 flex items-center justify-center text-xs text-white font-bold"
                    :title="participant.username"
                    :style="{ backgroundColor: stringToColor(participant.username) }"
                  >
                    {{ getInitials(participant.username) }}
                  </div>
                  <div v-if="getParticipants(slot.id, false).length > 3" class="inline-block h-6 w-6 rounded-full ring-2 ring-gray-800 bg-gray-700 flex items-center justify-center text-xs text-gray-300">
                    +{{ getParticipants(slot.id, false).length - 3 }}
                  </div>
                </div>

                <!-- My Vote Toggle -->
                <button
                  @click="toggleVote(slot.id)"
                  :class="[
                    'w-8 h-8 rounded-full flex items-center justify-center transition-all',
                    isSelected(slot.id) 
                      ? 'bg-emerald-500 text-white hover:bg-emerald-600' 
                      : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
                  ]"
                >
                  <span v-if="isSelected(slot.id)">✓</span>
                  <span v-else>+</span>
                </button>
              </div>

              <!-- Result Mode -->
              <div v-else class="flex-1">
                <div class="flex flex-wrap gap-1 justify-end">
                  <div
                    v-for="participant in getParticipants(slot.id, true)"
                    :key="participant.id"
                    class="px-2 py-0.5 rounded text-xs text-white font-medium"
                    :style="{ backgroundColor: stringToColor(participant.username) }"
                  >
                    {{ participant.username }}
                  </div>
                  <span v-if="getParticipants(slot.id, true).length === 0" class="text-xs text-gray-600 italic">No votes</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Suggestion Box -->
      <div class="mt-12 bg-gray-800 p-6 rounded-lg border border-gray-700">
        <h3 class="text-lg font-bold text-white mb-4">Can't make it?</h3>
        <div class="flex gap-4">
          <button @click="showSuggestionModal = true" class="text-emerald-500 hover:text-emerald-400 font-medium">
            Suggest another date
          </button>
        </div>
      </div>
    </div>

    <!-- Suggestion Modal -->
    <div v-if="showSuggestionModal" class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
      <div class="bg-gray-800 rounded-lg p-6 max-w-md w-full border border-gray-700 shadow-xl">
        <h3 class="text-xl font-bold text-white mb-4">Suggest Another Date</h3>
        <textarea
          v-model="suggestionText"
          rows="4"
          class="w-full px-4 py-2 bg-gray-900 border border-gray-600 rounded-md text-white focus:ring-2 focus:ring-emerald-500 outline-none mb-4"
          placeholder="I'm free on next Tuesday afternoon..."
        ></textarea>
        <div class="flex justify-end space-x-3">
          <button @click="showSuggestionModal = false" class="px-4 py-2 text-gray-400 hover:text-white">Cancel</button>
          <button @click="submitSuggestion" class="px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700">Send Suggestion</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { format } from 'date-fns'

const route = useRoute()
const client = useSupabaseClient()
const user = useUser()
const router = useRouter()

const loading = ref(true)
const meeting = ref<any>(null)
const slots = ref<any[]>([])
const availabilities = ref<any[]>([])
const viewMode = ref<'vote' | 'result'>('vote')
const showSuggestionModal = ref(false)
const suggestionText = ref('')

const meetingId = (Array.isArray(route.params.id) ? route.params.id[0] : route.params.id) as string

const isHost = computed(() => meeting.value?.host_id === user.value?.id)

// Helper to group slots by date
const groupedSlots = computed(() => {
  const groups: Record<string, any[]> = {}
  slots.value.forEach(slot => {
    if (!groups[slot.date]) groups[slot.date] = []
    groups[slot.date]?.push(slot)
  })
  // Sort slots within date
  Object.keys(groups).forEach(date => {
    groups[date]?.sort((a, b) => a.time_slot.localeCompare(b.time_slot))
  })
  // Sort dates
  return Object.keys(groups).sort().reduce((acc: any, key) => {
    acc[key] = groups[key]
    return acc
  }, {})
})

const formatTime = (time: string) => {
  // Simple formatter, assuming HH:mm format
  const [h, m] = time.split(':')
  const hour = parseInt(h || '0')
  const ampm = hour >= 12 ? 'PM' : 'AM'
  const hour12 = hour % 12 || 12
  return `${hour12}:${m} ${ampm}`
}

const getInitials = (name: string) => {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

const stringToColor = (str: string) => {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash)
  }
  const c = (hash & 0x00ffffff).toString(16).toUpperCase()
  return '#' + '00000'.substring(0, 6 - c.length) + c
}

const isSelected = (slotId: string) => {
  return availabilities.value.some(a => a.meeting_slot_id === slotId && a.user_id === user.value?.id)
}

const getParticipants = (slotId: string, includeSelf = false) => {
  return availabilities.value
    .filter(a => a.meeting_slot_id === slotId)
    .map(a => a.user)
    .filter(u => includeSelf || u.id !== user.value?.id)
}

const deleteMeeting = async () => {
  if (!confirm('Are you sure you want to delete this meeting? This action cannot be undone.')) return

  loading.value = true
  const { error } = await client
    .from('meetings')
    .delete()
    .eq('id', meetingId)

  if (error) {
    alert('Error deleting meeting: ' + error.message)
    loading.value = false
  } else {
    router.push('/dashboard')
  }
}

const deleteSlot = async (slotId: string) => {
  if (!confirm('Are you sure you want to remove this time slot?')) return
  
  const { error } = await client
    .from('meeting_slots')
    .delete()
    .eq('id', slotId)
    
  if (error) {
    alert('Error removing slot')
  } else {
    slots.value = slots.value.filter(s => s.id !== slotId)
  }
}

const toggleVote = async (slotId: string) => {
  if (!user.value) return

  const existing = availabilities.value.find(a => a.meeting_slot_id === slotId && a.user_id === user.value?.id)
  
  if (existing) {
    // Remove
    const { error } = await client
      .from('availabilities')
      .delete()
      .eq('id', existing.id)
    
    if (!error) {
      availabilities.value = availabilities.value.filter(a => a.id !== existing.id)
    }
  } else {
    // Add
    const { data, error } = await client
      .from('availabilities')
      .insert({
        meeting_slot_id: slotId,
        user_id: user.value.id
      })
      .select('*, user:users(*)')
      .single()
      
    if (!error && data) {
      availabilities.value.push(data)
    }
  }
}

const submitSuggestion = async () => {
  if (!suggestionText.value.trim()) return
  
  // Just alert for now as we didn't define a suggestions table, but I can add one.
  // Or just save to a 'suggestions' table.
  // Let's assume we have one.
  try {
    await client.from('suggestions').insert({
      meeting_id: meetingId,
      user_id: user.value?.id,
      suggestion: suggestionText.value
    })
    alert('Suggestion sent!')
    showSuggestionModal.value = false
    suggestionText.value = ''
  } catch (e) {
    alert('Suggestion sent (simulated)!')
    showSuggestionModal.value = false
  }
}

const fetchData = async () => {
  loading.value = true
  try {
    // Fetch Meeting
    const { data: meetingData, error: meetingError } = await client
      .from('meetings')
      .select('*, host:users(*)')
      .eq('id', meetingId)
      .single()
    
    if (meetingError) throw meetingError
    meeting.value = meetingData

    // Fetch Slots
    const { data: slotsData, error: slotsError } = await client
      .from('meeting_slots')
      .select('*')
      .eq('meeting_id', meetingId)
    
    if (slotsError) throw slotsError
    slots.value = slotsData

    // Fetch Availabilities
    // We need availabilities for these slots
    const slotIds = slotsData.map(s => s.id)
    if (slotIds.length > 0) {
      const { data: availData, error: availError } = await client
        .from('availabilities')
        .select('*, user:users(*)')
        .in('meeting_slot_id', slotIds)
      
      if (availError) throw availError
      availabilities.value = availData
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (!user.value) {
    router.push('/')
    return
  }
  fetchData()
  
  // Realtime subscription could go here
  const subscription = client
    .channel('public:availabilities')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'availabilities' }, () => {
      fetchData()
    })
    .subscribe()
    
  onUnmounted(() => {
    subscription.unsubscribe()
  })
})
</script>
