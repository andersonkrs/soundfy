import { Head, router } from '@inertiajs/react'
import {
  AppProvider,
  Page,
  Layout,
  Card,
  IndexTable,
  Badge,
  Text,
  EmptyState,
  useIndexResourceState,
  Thumbnail,
  Pagination,
  BlockStack,
  InlineStack
} from '@shopify/polaris'
import { ImageIcon } from '@shopify/polaris-icons'
import enTranslations from '@shopify/polaris/locales/en.json'

export default function RecordingsIndex({ recordings, pagy }) {
  const resourceName = {
    singular: 'recording',
    plural: 'recordings'
  }

  const { selectedResources, allResourcesSelected, handleSelectionChange } =
    useIndexResourceState(recordings)

  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  const getRecordableTypeBadge = (type) => {
    const badgeConfig = {
      'SingleTrack': { tone: 'info', text: 'Single' },
      'Album': { tone: 'success', text: 'Album' },
      'AlbumTrack': { tone: 'attention', text: 'Album Track' }
    }
    
    const config = badgeConfig[type] || { tone: 'default', text: type }
    return <Badge tone={config.tone} size="small">{config.text}</Badge>
  }

  const rowMarkup = recordings.map((recording, index) => (
    <IndexTable.Row
      id={recording.id}
      key={recording.id}
      selected={selectedResources.includes(recording.id)}
      position={index}
    >
      <IndexTable.Cell>
        <InlineStack gap="300" blockAlign="center">
          {recording.product?.image_url ? (
            <Thumbnail
              source={recording.product.image_url}
              alt={recording.product.title || 'Product image'}
              size="small"
            />
          ) : (
            <Thumbnail source={ImageIcon} alt="" size="small" />
          )}
          <Text variant="bodyMd" as="span">
            {recording.product?.title || 'N/A'}
          </Text>
        </InlineStack>
      </IndexTable.Cell>
      <IndexTable.Cell>{getRecordableTypeBadge(recording.recordable_type)}</IndexTable.Cell>
      <IndexTable.Cell>
        {recording.archived ? (
          <Badge tone="warning" size="small">Archived</Badge>
        ) : (
          <Badge tone="success" size="small">Active</Badge>
        )}
      </IndexTable.Cell>
      <IndexTable.Cell>{formatDate(recording.created_at)}</IndexTable.Cell>
    </IndexTable.Row>
  ))

  const emptyState = (
    <EmptyState
      heading="No recordings found"
      image="https://cdn.shopify.com/s/files/1/0262/4071/2726/files/emptystate-files.png"
    >
      <p>There are no recordings available at the moment.</p>
    </EmptyState>
  )

  return (
    <AppProvider i18n={enTranslations}>
      <Head title='Recordings' />
      <Page
        title='Recordings'
        subtitle='Manage your audio products'
      >
        <Layout>
          <Layout.Section>
            {recordings.length === 0 ? (
              <Card>
                {emptyState}
              </Card>
            ) : (
               <Card padding="0">
                <IndexTable
                  resourceName={resourceName}
                  itemCount={recordings.length}
                  selectedItemsCount={
                    allResourcesSelected ? 'All' : selectedResources.length
                  }
                  onSelectionChange={handleSelectionChange}
                  headings={[
                    { title: 'Recording' },
                    { title: 'Type' },
                    { title: 'Status' },
                    { title: 'Created At' }
                  ]}
                >
                  {rowMarkup}
                </IndexTable>
              </Card>
            )}
          </Layout.Section>
          
          {recordings.length > 0 && (
            <Layout.Section>
              <BlockStack gap="400">
                {pagy.pages > 1 && (
                  <Pagination
                    label={`Page ${pagy.page} of ${pagy.pages}`}
                    hasPrevious={pagy.prev !== null}
                    onPrevious={() => {
                      router.visit(`?page=${pagy.prev}`, { preserveState: true })
                    }}
                    hasNext={pagy.next !== null}
                    onNext={() => {
                      router.visit(`?page=${pagy.next}`, { preserveState: true })
                    }}
                  />
                )}
              </BlockStack>
            </Layout.Section>
          )}
        </Layout>
      </Page>
    </AppProvider>
  )
}
