export const useUser = () => {
  return useState<{ id: string; username: string } | null>('user', () => null)
}
