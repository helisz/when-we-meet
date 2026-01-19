<template>
  <div class="container mx-auto px-4 py-8 max-w-4xl">
    <div class="mb-8">
      <NuxtLink to="/dashboard" class="text-emerald-500 hover:text-emerald-400 mb-4 inline-block">&larr; Back to Dashboard</NuxtLink>
      <h1 class="text-3xl font-bold text-white">Host a Meeting</h1>
    </div>

    <form @submit.prevent="publishMeeting" class="space-y-8">
      <!-- Title -->
      <div class="bg-gray-800 p-6 rounded-lg border border-gray-700">
        <label class="block text-sm font-medium text-gray-300 mb-2">Meeting Title</label>
        <input
          v-model="form.title"
          type="text"
          maxlength="200"
          required
          class="w-full px-4 py-2 bg-gray-900 border border-gray-600 rounded-md text-white focus:ring-2 focus:ring-emerald-500 outline-none"
          placeholder="e.g., Q3 Planning"
        />
        <div class="text-right text-xs text-gray-500 mt-1">{{ form.title.length }}/200</div>
      </div>

      <!-- Date & Time -->
      <div class="bg-gray-800 p-6 rounded-lg border border-gray-700">
        <h3 class="text-lg font-medium text-white mb-4">Select Dates & Times</h3>
        
        <div class="grid md:grid-cols-2 gap-8">
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">1. Pick Dates</label>
            <CalendarSelector v-model="selectedDates" />
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">2. Pick Times for Each Date</label>
            <div v-if="selectedDates.length === 0" class="text-gray-500 italic p-4 border border-gray-700 border-dashed rounded">
              Select dates from the calendar first.
            </div>
            <div v-else class="space-y-4 max-h-[400px] overflow-y-auto pr-2">
              <div v-for="date in sortedDates" :key="dateStr(date)" class="bg-gray-900 p-4 rounded border border-gray-700">
                <div class="font-medium text-emerald-400 mb-3">{{ format(date, 'EEEE, MMMM d') }}</div>
                <div class="grid grid-cols-2 gap-2">
                  <button
                    v-for="slot in timeSlots"
                    :key="slot.id"
                    type="button"
                    @click="toggleSlot(date, slot.id)"
                    :class="[
                      'px-2 py-1 text-xs rounded border transition-colors',
                      isSlotSelected(date, slot.id)
                        ? 'bg-emerald-600 border-emerald-600 text-white'
                        : 'bg-gray-800 border-gray-600 text-gray-300 hover:border-gray-500'
                    ]"
                  >
                    {{ slot.label }}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Notes -->
      <div class="bg-gray-800 p-6 rounded-lg border border-gray-700">
        <label class="block text-sm font-medium text-gray-300 mb-2">Meeting Notes</label>
        <textarea
          v-model="form.notes"
          rows="3"
          maxlength="1000"
          class="w-full px-4 py-2 bg-gray-900 border border-gray-600 rounded-md text-white focus:ring-2 focus:ring-emerald-500 outline-none"
          placeholder="Add any details..."
        ></textarea>
        <div class="text-right text-xs text-gray-500 mt-1">{{ form.notes.length }}/1000</div>
      </div>

      <!-- Actions -->
      <div class="flex justify-end">
        <button
          type="submit"
          :disabled="loading"
          class="px-6 py-3 bg-emerald-600 text-white font-bold rounded-md hover:bg-emerald-700 focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ loading ? 'Publishing...' : 'Publish Meeting' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { format } from 'date-fns'

const client = useSupabaseClient()
const user = useUser()
const router = useRouter()
const loading = ref(false)

const form = reactive({
  title: '',
  notes: ''
})

const selectedDates = ref<Date[]>([])
const selectedSlots = ref<Record<string, string[]>>({})

const timeSlots = [
  { id: '09:30', label: '09:30 - 10:30' },
  { id: '10:30', label: '10:30 - 11:30' },
  { id: '11:30', label: '11:30 - 12:30' },
  { id: '14:30', label: '14:30 - 15:30' },
  { id: '15:30', label: '15:30 - 16:30' },
  { id: '16:30', label: '16:30 - 17:30' },
]

const dateStr = (date: Date) => format(date, 'yyyy-MM-dd')

const sortedDates = computed(() => {
  return [...selectedDates.value].sort((a, b) => a.getTime() - b.getTime())
})

const isSlotSelected = (date: Date, slotId: string) => {
  const d = dateStr(date)
  return selectedSlots.value[d]?.includes(slotId)
}

const toggleSlot = (date: Date, slotId: string) => {
  const d = dateStr(date)
  if (!selectedSlots.value[d]) {
    selectedSlots.value[d] = []
  }
  
  const index = selectedSlots.value[d].indexOf(slotId)
  if (index === -1) {
    selectedSlots.value[d].push(slotId)
  } else {
    selectedSlots.value[d].splice(index, 1)
  }
}

const publishMeeting = async () => {
  if (!form.title.trim()) return
  if (selectedDates.value.length === 0) {
    alert('Please select at least one date.')
    return
  }
  
  // Check if any slots are selected
  const hasSlots = Object.values(selectedSlots.value).some(slots => slots && slots.length > 0)
  if (!hasSlots) {
    alert('Please select at least one time slot.')
    return
  }

  loading.value = true
  try {
    // 1. Create Meeting
    const { data: meeting, error: meetingError } = await client
      .from('meetings')
      .insert({
        title: form.title,
        description: form.notes,
        host_id: user.value?.id
      })
      .select()
      .single()

    if (meetingError) throw meetingError

    // 2. Create Slots
    const slotsToInsert = []
    for (const date of selectedDates.value) {
      const d = dateStr(date)
      const slots = selectedSlots.value[d] || []
      for (const slot of slots) {
        slotsToInsert.push({
          meeting_id: meeting.id,
          date: d,
          time_slot: slot
        })
      }
    }

    if (slotsToInsert.length > 0) {
      const { error: slotsError } = await client
        .from('meeting_slots')
        .insert(slotsToInsert)
      
      if (slotsError) throw slotsError
    }

    router.push(`/meeting/${meeting.id}`)
  } catch (e: any) {
    alert('Error: ' + e.message)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  if (!user.value) {
    router.push('/')
  }
})
</script>
