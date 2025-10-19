import { createContext, useContext, useState } from 'react'
import { useForm } from '@inertiajs/react'

const RecordingsNewContext = createContext(undefined)

export function RecordingsNewProvider({ children }) {
  const form = useForm({
    recordable: {
      title: '',
      variant_gid: null,
    },
    blob: null,
    // UI-only fields (not sent to backend)
    product_query: '',
    variant_title: '',
    product_title: '',
  })

  const [uploading, setUploading] = useState(false)

  const value = {
    form,
    uploading,
    setUploading,
  }

  return (
    <RecordingsNewContext.Provider value={value}>
      {children}
    </RecordingsNewContext.Provider>
  )
}

export function useRecordingsNewContext() {
  const context = useContext(RecordingsNewContext)
  if (context === undefined) {
    throw new Error(
      'useRecordingsNewContext must be used within a RecordingsNewProvider'
    )
  }
  return context
}
