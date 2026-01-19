export default defineNuxtPlugin(() => {
  const user = useUser()
  const stored = localStorage.getItem('user')
  if (stored) {
    try {
      user.value = JSON.parse(stored)
    } catch (e) {
      localStorage.removeItem('user')
    }
  }
})
