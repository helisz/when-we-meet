<template>
  <div class="container mx-auto px-4 py-8 max-w-6xl">
    <div v-if="loading" class="text-center py-12 text-gray-400">Loading...</div>
    <div v-else-if="!meeting" class="text-center py-12 text-red-400">
      Meeting not found
    </div>
    <div v-else>
      <div class="mb-8">
        <NuxtLink
          to="/join"
          class="text-emerald-500 hover:text-emerald-400 mb-4 inline-block"
          >&larr; Back to List</NuxtLink
        >
        <div class="flex justify-between items-start gap-4">
          <div>
            <h1 class="text-3xl font-bold text-white mb-2">
              {{ meeting.title }}
            </h1>
            <p class="text-gray-400 whitespace-pre-wrap">
              {{ meeting.description }}
            </p>
          </div>
          <div
            class="text-right flex flex-col p-2 gap-2 items-end bg-gray-800 rounded-lg border border-gray-700"
            style="min-width: 200px"
          >
            <div>
              <span class="text-sm text-gray-500">Hosted by: </span>
              <span class="font-medium text-emerald-400">{{
                meeting.host?.username
              }}</span>
            </div>
            <button
              v-if="isHost"
              @click="deleteMeeting"
              class="text-red-500 hover:text-red-400 text-sm"
            >
              Delete Meeting
            </button>
          </div>
        </div>
      </div>

      <!-- View Toggle and Host Controls -->
      <div class="flex justify-between items-center mb-6">
        <div v-if="isHost" class="flex space-x-4">
          <button
            @click="showAddSlotModal = true"
            class="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors flex items-center space-x-2"
          >
            <span>+</span>
            <span>Add Date/Time</span>
          </button>
        </div>
        <div class="flex space-x-4">
          <button
            @click="viewMode = 'vote'"
            :class="[
              'px-4 py-2 rounded-md transition-colors',
              viewMode === 'vote'
                ? 'bg-emerald-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:bg-gray-700',
            ]"
          >
            Vote
          </button>
          <button
            @click="viewMode = 'result'"
            :class="[
              'px-4 py-2 rounded-md transition-colors',
              viewMode === 'result'
                ? 'bg-emerald-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:bg-gray-700',
            ]"
          >
            View Result
          </button>
        </div>
      </div>

      <!-- Voting Grid -->
      <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div
          v-for="(slots, date) in groupedSlots"
          :key="date"
          :class="[
            'rounded-lg border overflow-hidden',
            isDatePast(date)
              ? 'bg-gray-900 border-gray-800 opacity-70'
              : 'bg-gray-800 border-gray-700',
          ]"
        >
          <div
            :class="[
              'p-4 border-b flex justify-between items-center',
              isDatePast(date)
                ? 'bg-gray-800 border-gray-700'
                : 'bg-gray-900 border-gray-700',
            ]"
          >
            <div class="flex items-center space-x-2">
              <h3
                :class="[
                  'font-bold',
                  isDatePast(date) ? 'text-gray-500' : 'text-white',
                ]"
              >
                {{ format(new Date(date), "yyyy-MM-dd") }}
              </h3>
              <span
                v-if="isDatePast(date)"
                class="text-xs px-2 py-0.5 bg-gray-700 text-gray-400 rounded"
              >
                Past
              </span>
            </div>
            <button
              v-if="isHost"
              @click="deleteDate(date)"
              class="text-red-500 hover:text-red-400 text-md transition-colors"
              title="Delete entire date"
            >
              &times;
            </button>
          </div>
          <div class="p-4 space-y-3">
            <div
              v-for="slot in slots"
              :key="slot.id"
              class="flex items-center justify-between group"
            >
              <div class="flex items-center space-x-2 w-30">
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
              <div
                v-if="viewMode === 'vote'"
                class="flex-1 flex items-center justify-end space-x-3"
              >
                <!-- Others' avatars -->
                <div class="flex -space-x-2 overflow-hidden">
                  <div
                    v-for="participant in getParticipants(slot.id, false)"
                    :key="participant.id"
                    class="inline-block h-6 w-6 rounded-full ring-2 ring-gray-800 bg-gray-600 flex items-center justify-center text-xs text-white font-bold"
                    :title="participant.username"
                    :style="{
                      backgroundColor: stringToColor(participant.username),
                    }"
                  >
                    {{ getInitials(participant.username) }}
                  </div>
                  <div
                    v-if="getParticipants(slot.id, false).length > 3"
                    class="inline-block h-6 w-6 rounded-full ring-2 ring-gray-800 bg-gray-700 flex items-center justify-center text-xs text-gray-300"
                  >
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
                      : 'bg-gray-700 text-gray-400 hover:bg-gray-600',
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
                    :style="{
                      backgroundColor: stringToColor(participant.username),
                    }"
                  >
                    {{ participant.username }}
                  </div>
                  <span
                    v-if="getParticipants(slot.id, true).length === 0"
                    class="text-xs text-gray-600 italic"
                    >No votes</span
                  >
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Suggestion Box -->
      <div class="mt-12 bg-gray-800 p-6 rounded-lg border border-gray-700">
        <h3 class="text-lg font-bold text-white mb-2">Can't make it?</h3>
        <div class="flex gap-4 mb-4">
          <button
            @click="showSuggestionModal = true"
            class="text-emerald-500 hover:text-emerald-400 font-medium"
          >
            Suggest another date
          </button>
        </div>
        <div v-if="suggestions.length > 0" class="mb-6 space-y-4">
          <div
            v-for="s in suggestions"
            :key="s.id"
            class="bg-gray-900 p-4 rounded border border-gray-600"
          >
            <div class="flex justify-between items-start mb-2">
              <div class="font-medium text-emerald-400">
                {{ s.user?.username }}
              </div>
              <div class="text-xs text-gray-500">
                {{ format(new Date(s.created_at), "MMM d, HH:mm") }}
              </div>
            </div>
            <p class="text-gray-300 text-sm whitespace-pre-wrap">
              {{ s.suggestion }}
            </p>
          </div>
        </div>
      </div>
    </div>

    <!-- Suggestion Modal -->
    <div
      v-if="showSuggestionModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
    >
      <div
        class="bg-gray-800 rounded-lg p-6 max-w-md w-full border border-gray-700 shadow-xl"
      >
        <h3 class="text-xl font-bold text-white mb-4">Suggest Another Date</h3>
        <textarea
          v-model="suggestionText"
          rows="4"
          class="w-full px-4 py-2 bg-gray-900 border border-gray-600 rounded-md text-white focus:ring-2 focus:ring-emerald-500 outline-none mb-4"
          placeholder="I'm free on next Tuesday afternoon..."
        ></textarea>
        <div class="flex justify-end space-x-3">
          <button
            @click="showSuggestionModal = false"
            class="px-4 py-2 text-gray-400 hover:text-white"
          >
            Cancel
          </button>
          <button
            @click="submitSuggestion"
            class="px-4 py-2 bg-emerald-600 text-white rounded hover:bg-emerald-700"
          >
            Send Suggestion
          </button>
        </div>
      </div>
    </div>

    <!-- Add Date/Time Modal -->
    <div
      v-if="showAddSlotModal"
      class="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50"
    >
      <div
        class="bg-gray-800 rounded-lg p-6 max-w-md w-full border border-gray-700 shadow-xl"
      >
        <h3 class="text-xl font-bold text-white mb-4">Add Date and Time</h3>

        <!-- Date Selection -->
        <div class="mb-4">
          <label class="block text-sm font-medium text-gray-300 mb-2"
            >Select Date</label
          >
          <input
            type="date"
            v-model="newSlotDate"
            :min="minDate"
            @input="validateDateInput"
            class="w-full px-4 py-2 bg-gray-900 border border-gray-600 rounded-md text-white focus:ring-2 focus:ring-blue-500 outline-none"
          />
        </div>

        <!-- Time Selection -->
        <div class="mb-6">
          <label class="block text-sm font-medium text-gray-300 mb-2"
            >Select Time (Multiple Selection)</label
          >
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="time in timeOptions"
              :key="time"
              @click="toggleTimeSelection(time)"
              :class="[
                'px-3 py-2 rounded-md transition-colors',
                selectedTimes.includes(time)
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600',
              ]"
            >
              {{ formatTimeDisplay(time) }}
            </button>
          </div>
          <p class="text-xs text-gray-500 mt-2">
            Click to select/deselect multiple times
          </p>
        </div>

        <div class="flex justify-end space-x-3">
          <button
            @click="showAddSlotModal = false"
            class="px-4 py-2 text-gray-400 hover:text-white"
          >
            Cancel
          </button>
          <button
            @click="addSlot"
            :disabled="!canAddSlot"
            :class="[
              'px-4 py-2 rounded transition-colors',
              canAddSlot
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-700 text-gray-500 cursor-not-allowed',
            ]"
          >
            Add Time Slot
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { format } from "date-fns";

const route = useRoute();
const client = useSupabaseClient();
const user = useUser();
const router = useRouter();

const loading = ref(true);
const meeting = ref<any>(null);
const slots = ref<any[]>([]);
const availabilities = ref<any[]>([]);
const suggestions = ref<any[]>([]);
const viewMode = ref<"vote" | "result">("vote");
const showSuggestionModal = ref(false);
const suggestionText = ref("");

// Add Date/Time Modal State
const showAddSlotModal = ref(false);
const newSlotDate = ref("");
const selectedTimes = ref<string[]>([]);
// Define time slots matching the host page
const timeSlots = [
  { id: '09:00', label: '09:00 - 10:00' },
  { id: '10:00', label: '10:00 - 11:00' },
  { id: '11:00', label: '11:00 - 12:00' },
  { id: '14:30', label: '14:30 - 15:30' },
  { id: '15:30', label: '15:30 - 16:30' },
  { id: '16:30', label: '16:30 - 17:30' },
];

// Time options for the modal (just the IDs)
const timeOptions = timeSlots.map(slot => slot.id);

// Computed properties
const minDate = computed(() => {
  const today = new Date();
  const yyyy = today.getFullYear();
  const mm = String(today.getMonth() + 1).padStart(2, "0");
  const dd = String(today.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
});

const canAddSlot = computed(() => {
  if (!newSlotDate.value) return false;
  if (selectedTimes.value.length === 0) return false;

  // Check if any selected time already exists
  for (const time of selectedTimes.value) {
    const existing = slots.value.find(
      (s) => s.date === newSlotDate.value && s.time_slot === time,
    );
    if (existing) return false;
  }
  return true;
});

const isDatePast = (date: string) => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const targetDate = new Date(date);
  targetDate.setHours(0, 0, 0, 0);
  return targetDate < today;
};

const formatTimeDisplay = (time: string) => {
  // Find the matching time slot to get the range label
  const slot = timeSlots.find(s => s.id === time);
  if (slot) {
    return slot.label;
  }
  
  // Fallback: convert to AM/PM format
  const [h, m] = time.split(":");
  const hour = parseInt(h || "0");
  const ampm = hour >= 12 ? "PM" : "AM";
  const hour12 = hour % 12 || 12;
  return `${hour12}:${m} ${ampm}`;
};

const toggleTimeSelection = (time: string) => {
  const index = selectedTimes.value.indexOf(time);
  if (index === -1) {
    selectedTimes.value.push(time);
  } else {
    selectedTimes.value.splice(index, 1);
  }
};

const validateDateInput = (event: Event) => {
  const input = event.target as HTMLInputElement;
  let value = input.value;
  // If empty, do nothing
  if (!value) return;
  
  // Check if year part has more than 4 digits
  // Date format is YYYY-MM-DD
  const parts = value.split('-');
  if (parts.length >= 1) {
    const year = parts[0];
    if (year && year.length > 4) {
      // Truncate to first 4 digits
      parts[0] = year.substring(0, 4);
      // Reconstruct date string
      const newValue = parts.join('-');
      // Update the input value
      input.value = newValue;
      newSlotDate.value = newValue;
    }
  }
};

const meetingId = (
  Array.isArray(route.params.id) ? route.params.id[0] : route.params.id
) as string;

const isHost = computed(() => meeting.value?.host_id === user.value?.id);

// Helper to group slots by date
const groupedSlots = computed(() => {
  const groups: Record<string, any[]> = {};
  slots.value.forEach((slot) => {
    if (!groups[slot.date]) groups[slot.date] = [];
    groups[slot.date]?.push(slot);
  });
  // Sort slots within date
  Object.keys(groups).forEach((date) => {
    groups[date]?.sort((a, b) => a.time_slot.localeCompare(b.time_slot));
  });
  // Sort dates
  return Object.keys(groups)
    .sort()
    .reduce((acc: any, key) => {
      acc[key] = groups[key];
      return acc;
    }, {});
});

const formatTime = (time: string) => {
  // Find the matching time slot to get the range label
  const slot = timeSlots.find(s => s.id === time);
  if (slot) {
    return slot.label;
  }
  
  // Fallback: convert to AM/PM format
  const [h, m] = time.split(":");
  const hour = parseInt(h || "0");
  const ampm = hour >= 12 ? "PM" : "AM";
  const hour12 = hour % 12 || 12;
  return `${hour12}:${m} ${ampm}`;
};

const getInitials = (name: string) => {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);
};

const stringToColor = (str: string) => {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  const c = (hash & 0x00ffffff).toString(16).toUpperCase();
  return "#" + "00000".substring(0, 6 - c.length) + c;
};

const isSelected = (slotId: string) => {
  return availabilities.value.some(
    (a) => a.meeting_slot_id === slotId && a.user_id === user.value?.id,
  );
};

const getParticipants = (slotId: string, includeSelf = false) => {
  return availabilities.value
    .filter((a) => a.meeting_slot_id === slotId)
    .map((a) => a.user)
    .filter((u) => includeSelf || u.id !== user.value?.id);
};

const deleteMeeting = async () => {
  if (
    !confirm(
      "Are you sure you want to delete this meeting? This action cannot be undone.",
    )
  )
    return;

  loading.value = true;
  const { error } = await client.from("meetings").delete().eq("id", meetingId);

  if (error) {
    alert("Error deleting meeting: " + error.message);
    loading.value = false;
  } else {
    router.push("/dashboard");
  }
};

const deleteSlot = async (slotId: string) => {
  if (!confirm("Are you sure you want to remove this time slot?")) return;

  const { error } = await client
    .from("meeting_slots")
    .delete()
    .eq("id", slotId);

  if (error) {
    alert("Error removing slot");
  } else {
    slots.value = slots.value.filter((s) => s.id !== slotId);
  }
};

const deleteDate = async (date: string) => {
  if (
    !confirm(
      `Are you sure you want to delete all time slots on ${format(new Date(date), "MMMM d")}? This will remove ${groupedSlots.value[date]?.length || 0} time slot(s).`,
    )
  )
    return;

  try {
    // Get all slot IDs for this date
    const dateSlots = slots.value.filter((s) => s.date === date);
    const slotIds = dateSlots.map((s) => s.id);

    if (slotIds.length === 0) return;

    // Delete all slots for this date
    const { error } = await client
      .from("meeting_slots")
      .delete()
      .in("id", slotIds);

    if (error) throw error;

    // Update local state
    slots.value = slots.value.filter((s) => s.date !== date);
  } catch (e: any) {
    alert("Error deleting date: " + e.message);
  }
};

const toggleVote = async (slotId: string) => {
  if (!user.value) return;

  const existing = availabilities.value.find(
    (a) => a.meeting_slot_id === slotId && a.user_id === user.value?.id,
  );

  if (existing) {
    // Remove
    const { error } = await client
      .from("availabilities")
      .delete()
      .eq("id", existing.id);

    if (!error) {
      availabilities.value = availabilities.value.filter(
        (a) => a.id !== existing.id,
      );
    }
  } else {
    // Add
    const { data, error } = await client
      .from("availabilities")
      .insert({
        meeting_slot_id: slotId,
        user_id: user.value.id,
      })
      .select("*, user:users(*)")
      .single();

    if (!error && data) {
      availabilities.value.push(data);
    }
  }
};

const submitSuggestion = async () => {
  if (!suggestionText.value.trim()) return;

  try {
    const { data, error } = await client
      .from("suggestions")
      .insert({
        meeting_id: meetingId,
        user_id: user.value?.id,
        suggestion: suggestionText.value,
      })
      .select("*, user:users(*)")
      .single();

    if (error) throw error;

    suggestions.value.unshift(data);
    showSuggestionModal.value = false;
    suggestionText.value = "";
  } catch (e: any) {
    alert("Error sending suggestion: " + e.message);
  }
};

const addSlot = async () => {
  if (!canAddSlot.value) return;

  try {
    // Create slots for each selected time
    const promises = selectedTimes.value.map((time) =>
      client
        .from("meeting_slots")
        .insert({
          meeting_id: meetingId,
          date: newSlotDate.value,
          time_slot: time,
        })
        .select("*")
        .single(),
    );

    const results = await Promise.all(promises);
    const newSlots = results
      .filter((result) => !result.error && result.data)
      .map((result) => result.data);

    // Add to local state
    slots.value.push(...newSlots);

    // Reset modal state
    showAddSlotModal.value = false;
    newSlotDate.value = "";
    selectedTimes.value = [];
  } catch (e: any) {
    alert("Error adding time slots: " + e.message);
  }
};

const fetchData = async () => {
  loading.value = true;
  try {
    // Fetch Meeting
    const { data: meetingData, error: meetingError } = await client
      .from("meetings")
      .select("*, host:users(*)")
      .eq("id", meetingId)
      .single();

    if (meetingError) throw meetingError;
    meeting.value = meetingData;

    // Fetch Slots
    const { data: slotsData, error: slotsError } = await client
      .from("meeting_slots")
      .select("*")
      .eq("meeting_id", meetingId);

    if (slotsError) throw slotsError;
    slots.value = slotsData;

    // Fetch Availabilities
    // We need availabilities for these slots
    const slotIds = slotsData.map((s) => s.id);
    if (slotIds.length > 0) {
      const { data: availData, error: availError } = await client
        .from("availabilities")
        .select("*, user:users(*)")
        .in("meeting_slot_id", slotIds);

      if (availError) throw availError;
      availabilities.value = availData;
    }

    // Fetch Suggestions
    const { data: suggestionsData, error: suggestionsError } = await client
      .from("suggestions")
      .select("*, user:users(*)")
      .eq("meeting_id", meetingId)
      .order("created_at", { ascending: false });

    if (suggestionsError) throw suggestionsError;
    suggestions.value = suggestionsData;
  } catch (e) {
    console.error(e);
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  if (!user.value) {
    // Store the meeting ID to redirect back after login
    localStorage.setItem("redirectAfterLogin", route.fullPath);
    router.push("/");
    return;
  }
  fetchData();

  // Realtime subscription could go here
  const subscription = client
    .channel("public:availabilities")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "availabilities" },
      () => {
        fetchData();
      },
    )
    .subscribe();

  onUnmounted(() => {
    subscription.unsubscribe();
  });
});
</script>
