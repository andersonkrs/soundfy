import { Head, router } from '@inertiajs/react'
import { useAppBridge } from '@shopify/app-bridge-react'
import { useState, useCallback, useEffect, useRef } from 'react'
import { RecordingsNewProvider, useRecordingsNewContext } from './New/Context'
import { ProductField } from './New/ProductField'

function RecordingsNewPage({ allowed_content_types = [], allowed_extensions = [] }) {
  const { form, uploading, setUploading } = useRecordingsNewContext()
  const shopify = useAppBridge()
  const { setData, post, processing, errors, data } = form
  const pageRef = useRef(null)

  // Handle form submission
  const handleSubmit = useCallback((e) => {
    e?.preventDefault()

    post('/shopify/recordings', {
      onSuccess: () => {
        shopify.saveBar.hide('recording-save-bar')
      }
    })
  }, [post, shopify])

  // Handle discard
  const handleDiscard = useCallback((e) => {
    e?.preventDefault()
    shopify.saveBar.hide('recording-save-bar')
    router.visit('/shopify/recordings')
  }, [shopify])

  // Handle dropzone file upload
  const handleDropZoneDrop = useCallback(
    async (e) => {
      const files = e.detail?.files
      if (!files || files.length === 0) return

      const file = files[0]
      setData((prevData) => ({ ...prevData, blob: null }))

      setUploading(true)
      try {
        // Get CSRF token from meta tag
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

        // Upload to our custom endpoint
        const formData = new FormData()
        formData.append('file', file)

        const response = await fetch('/shopify/audio_uploads', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: formData,
        })

        if (!response.ok) {
          const errorData = await response.json()
          throw new Error(errorData.error || 'Upload failed')
        }

        const responseData = await response.json()
        setData((prevData) => ({ ...prevData, blob: responseData.blob }))
        shopify.toast.show('File uploaded')
      } catch (error) {
        shopify.toast.show(error.message || 'Upload failed', { isError: true })
      } finally {
        setUploading(false)
      }
    },
    [shopify, setData, setUploading]
  )

  const handleRemoveFile = useCallback(() => {
    setData((prevData) => ({ ...prevData, blob: null }))
  }, [setData])

  // Set up event listeners
  useEffect(() => {
    const dropZone = document.querySelector('s-drop-zone')
    if (dropZone) {
      dropZone.addEventListener('drop', handleDropZoneDrop)
      return () => {
        dropZone.removeEventListener('drop', handleDropZoneDrop)
      }
    }
  }, [handleDropZoneDrop])

  // Handle back navigation
  const handleBackAction = useCallback(() => {
    shopify.saveBar.leaveConfirmation().then(() => {
      shopify.saveBar.hide('recording-save-bar')
      router.visit('/shopify/recordings')
    })
  }, [shopify])

  // Handle form change to show save bar
  const handleFormChange = useCallback(() => {
    shopify.saveBar.show('recording-save-bar')
  }, [shopify])

  return (
    <>
      <Head title='New Recording' />
      <s-page
        ref={pageRef}
        heading="Add Recording"
      >
        <s-button
          slot="breadcrumb-actions"
          variant="plain"
          onClick={handleBackAction}
        >
          Recordings
        </s-button>

        {/* Error Banner */}
        {Object.keys(errors).length > 0 && (
          <s-banner tone="critical" style={{ marginBottom: '1rem' }}>
            <p>There were errors with your submission:</p>
            <ul>
              {Object.entries(errors).map(([field, messages]) => (
                <li key={field}>
                  {field}: {Array.isArray(messages) ? messages.join(', ') : messages}
                </li>
              ))}
            </ul>
          </s-banner>
        )}

        {/* Main Form */}
        <s-card>
          <form
            onSubmit={handleSubmit}
            onChange={handleFormChange}
            data-save-bar
          >
            <s-box padding="400">
              <s-stack vertical gap="400">
                <s-text variant="heading-md">Audio File</s-text>

                {!data.blob && (
                  <s-drop-zone
                    accept={allowed_content_types.join(',')}
                    disabled={uploading}
                    label="Add file"
                  >
                    <s-stack vertical align="center" gap="200">
                      <s-text>Drag and drop your songs, podcasts, or any audio file here</s-text>
                      <s-button>Add file</s-button>
                    </s-stack>
                  </s-drop-zone>
                )}

                {!uploading && data.blob && (
                  <s-box
                    border-width="025"
                    border-radius="200"
                    padding="300"
                  >
                    <s-stack gap="300" align="center">
                      {data.blob.cover_art ? (
                        <img
                          src={data.blob.cover_art}
                          alt={data.blob.filename}
                          style={{ width: '64px', height: '64px', borderRadius: '8px' }}
                        />
                      ) : (
                        <s-box
                          background="bg-fill-tertiary"
                          padding="300"
                          border-radius="200"
                        >
                          <s-icon source="note" />
                        </s-box>
                      )}

                      <s-stack vertical gap="100" style={{ flex: 1 }}>
                        <s-text variant="body-md" font-weight="bold">
                          {data.blob.filename}
                        </s-text>
                        {data.blob.artist && data.blob.title && (
                          <s-text variant="body-sm">
                            {data.blob.artist} - {data.blob.title}
                          </s-text>
                        )}
                        <s-text variant="body-sm" tone="subdued">
                          {data.blob.human_size}
                        </s-text>
                      </s-stack>

                      <s-button
                        icon="delete"
                        variant="plain"
                        tone="critical"
                        onClick={handleRemoveFile}
                      >
                        Remove
                      </s-button>
                    </s-stack>
                  </s-box>
                )}

                <ProductField />
              </s-stack>
            </s-box>
          </form>
        </s-card>

        {/* Debug card - Upload Response */}
        {data.blob && (
          <s-card>
            <s-box padding="400">
              <s-stack vertical gap="400">
                <s-text variant="heading-md">Upload Response</s-text>
                <pre style={{
                  background: '#f6f6f7',
                  padding: '16px',
                  borderRadius: '8px',
                  overflow: 'auto',
                  fontSize: '12px'
                }}>
                  {JSON.stringify(data.blob, null, 2)}
                </pre>
              </s-stack>
            </s-box>
          </s-card>
        )}

        {/* Save Bar */}
        <form data-save-bar>
          <input type="hidden" name="trigger" />
          <s-button
            variant="primary"
            slot="primary-action"
            onClick={handleSubmit}
            disabled={processing}
          >
            Save
          </s-button>
          <s-button
            slot="secondary-actions"
            onClick={handleDiscard}
          >
            Discard
          </s-button>
        </form>
      </s-page>
    </>
  )
}

export default function RecordingsNew(props) {
  return (
    <RecordingsNewProvider>
      <RecordingsNewPage {...props} />
    </RecordingsNewProvider>
  )
}
