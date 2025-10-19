import { Head, useForm, router } from '@inertiajs/react'
import {
  AppProvider,
  Page,
  Layout,
  Card,
  FormLayout,
  Banner,
  Text,
  BlockStack,
  DropZone,
  Thumbnail,
  ResourceList,
  ResourceItem,
} from '@shopify/polaris'
import { SaveBar, useAppBridge } from '@shopify/app-bridge-react'
import enTranslations from '@shopify/polaris/locales/en.json'
import { useState, useCallback } from 'react'
import { NoteIcon, DeleteIcon, SearchIcon } from '@shopify/polaris-icons'
import { RecordingsNewProvider, useRecordingsNewContext } from './New/Context'
import { ProductField } from './New/ProductField'

function RecordingsNewPage({ allowed_content_types = [], allowed_extensions = [] }) {
  const { form, uploading, setUploading } =
    useRecordingsNewContext()

  const shopify = useAppBridge()

  const { setData, post, processing, errors, data } = form

  const handleSubmit = (e) => {
    e.preventDefault()

    post('/shopify/recordings', {
      onSuccess: () => {
        shopify.saveBar.hide('recording-save-bar')
      }
    })
  }

  const handleDiscard = (e) => {
    e.preventDefault();
    shopify.saveBar.hide('recording-save-bar')
    router.visit('/shopify/recordings')
  }

  const handleDropZoneDrop = useCallback(
    async (_dropFiles, acceptedFiles, _rejectedFiles) => {
      if (acceptedFiles.length === 0) return

      const file = acceptedFiles[0]
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

        const data = await response.json()
        setData((prevData) => ({ ...prevData, blob: data.blob }))
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
  }, [])

  return (
    <AppProvider i18n={enTranslations}>
      <Head title='New Recording' />
      <Page
        title='Add Recording'
        backAction={{
          content: 'Recordings',
          onAction: () => {
            shopify.saveBar.leaveConfirmation().then(() => {
              shopify.saveBar.hide('recording-save-bar')
              router.visit('/shopify/recordings')
            })
          }
        }}
      >
        <Layout>
          <Layout.Section>
            {Object.keys(errors).length > 0 && (
              <Banner tone="critical">
                <p>There were errors with your submission:</p>
                <ul>
                  {Object.entries(errors).map(([field, messages]) => (
                    <li key={field}>
                      {field}: {Array.isArray(messages) ? messages.join(', ') : messages}
                    </li>
                  ))}
                </ul>
              </Banner>
            )}
          </Layout.Section>

          <Layout.Section>

            <Card>
              <form onSubmit={handleSubmit} onChange={() => shopify.saveBar.show('recording-save-bar')}>
                <FormLayout>
                  <Text variant="headingMd" as="h2">Audio File</Text>

                  {!data.blob && (
                    <DropZone
                      accept={allowed_content_types.join(',')}
                      type="file"
                      onDrop={handleDropZoneDrop}
                      disabled={uploading}
                      allowMultiple={false}
                      labelAction="Add file"
                    >
                      <DropZone.FileUpload actionTitle="Add file" actionHint={`Drag and drop your songs, podcasts, or any audio file here`} />
                    </DropZone>
                  )}

                  {!uploading && data.blob && (
                    <ResourceList
                      resourceName={{ singular: 'file', plural: 'files' }}
                      items={[data.blob]}
                      renderItem={(item) => {
                        const { filename, human_size, cover_art, artist, title } = item
                        const media = (
                          <Thumbnail
                            source={cover_art || NoteIcon}
                            alt={filename}
                            size="medium"
                          />
                        )

                        return (
                          <ResourceItem
                            id={filename}
                            media={media}
                            align="center"
                            verticalAlignment='center'
                            persistActions
                            accessibilityLabel={`View details for ${filename}`}
                            shortcutActions={[
                              {
                                content: 'Remove',
                                icon: DeleteIcon,
                                onAction: handleRemoveFile,
                              },
                            ]}
                          >
                            <Text variant="bodyMd" fontWeight="bold" as="h3">
                              {filename}
                            </Text>
                            {artist && title && <Text variant="bodyxs" as="p">{artist} - {title}</Text>}
                            <Text variant="bodyXs" as="p" tone="subdued">
                              {human_size}
                            </Text>
                          </ResourceItem>
                        )
                      }}
                    />
                  )}

                  <ProductField />
                </FormLayout>
              </form>
            </Card>
          </Layout.Section>

          {data.blob && (
            <Layout.Section>
              <Card>
                <BlockStack gap="400">
                  <Text variant="headingMd" as="h2">Upload Response</Text>
                  <pre style={{
                    background: '#f6f6f7',
                    padding: '16px',
                    borderRadius: '8px',
                    overflow: 'auto',
                    fontSize: '12px'
                  }}>
                    {JSON.stringify(data.blob, null, 2)}
                  </pre>
                </BlockStack>
              </Card>
            </Layout.Section>
          )}
        </Layout>

        <SaveBar id="recording-save-bar">
          <button variant="primary" onClick={handleSubmit} disabled={processing}></button>
          <button onClick={handleDiscard}></button>
        </SaveBar>
      </Page>
    </AppProvider>
  )
}

export default function RecordingsNew(props) {
  return (
    <RecordingsNewProvider>
      <RecordingsNewPage {...props} />
    </RecordingsNewProvider>
  )
}
