<template>
  <div class="bg-gray-800 p-4 rounded-lg border border-gray-700">
    <div class="flex justify-between items-center mb-4">
      <button @click="prevMonth" type="button" class="p-1 hover:bg-gray-700 rounded text-gray-400 hover:text-white">
        <
      </button>
      <span class="font-bold text-white">{{ format(currentMonth, 'MMMM yyyy') }}</span>
      <button @click="nextMonth" type="button" class="p-1 hover:bg-gray-700 rounded text-gray-400 hover:text-white">
        >
      </button>
    </div>
    <div class="grid grid-cols-7 gap-1 text-center text-sm mb-2">
      <div v-for="day in ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']" :key="day" class="text-gray-500">
        {{ day }}
      </div>
    </div>
    <div class="grid grid-cols-7 gap-1">
      <div
        v-for="day in days"
        :key="day.toString()"
        @click="toggleDate(day)"
        :class="[
          'p-2 rounded text-sm transition-colors',
          !isSameMonth(day, currentMonth) ? 'text-gray-600' : '',
          isSelected(day) ? 'bg-emerald-600 text-white hover:bg-emerald-700' : '',
          isPast(startOfDay(day)) ? 'text-gray-600 cursor-not-allowed' : 'cursor-pointer text-gray-300 hover:bg-gray-700'
        ]"
      >
        {{ format(day, 'd') }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { startOfMonth, endOfMonth, startOfWeek, endOfWeek, eachDayOfInterval, addMonths, subMonths, format, isSameMonth, isSameDay, isPast, startOfDay } from 'date-fns'

const props = defineProps<{
  modelValue: Date[]
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: Date[]): void
}>()

const currentMonth = ref(new Date())

const days = computed(() => {
  const start = startOfWeek(startOfMonth(currentMonth.value))
  const end = endOfWeek(endOfMonth(currentMonth.value))
  return eachDayOfInterval({ start, end })
})

const prevMonth = () => currentMonth.value = subMonths(currentMonth.value, 1)
const nextMonth = () => currentMonth.value = addMonths(currentMonth.value, 1)

const isSelected = (date: Date) => {
  return props.modelValue.some(d => isSameDay(d, date))
}

const toggleDate = (date: Date) => {
  // Disable past dates
  if (isPast(startOfDay(date))) return

  const exists = props.modelValue.find(d => isSameDay(d, date))
  if (exists) {
    emit('update:modelValue', props.modelValue.filter(d => !isSameDay(d, date)))
  } else {
    // Sort dates
    const newDates = [...props.modelValue, date].sort((a, b) => a.getTime() - b.getTime())
    emit('update:modelValue', newDates)
  }
}
</script>
