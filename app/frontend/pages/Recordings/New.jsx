import { Head, useForm, router } from '@inertiajs/react'
import {
  AppProvider,
  Page,
  Layout,
  Card,
  FormLayout,
  TextField,
  Banner,
  Button,
  Text,
  BlockStack,
  InlineStack,
} from '@shopify/polaris'
import { SaveBar, useAppBridge } from '@shopify/app-bridge-react'
import enTranslations from '@shopify/polaris/locales/en.json'

export default function RecordingsNew() {
  const shopify = useAppBridge()

  const { data, setData, post, processing, errors } = useForm({
    recordable: {
      title: '',
      variant_gid: null,
    },
    // UI-only fields (not sent to backend)
    variant_title: '',
    product_title: '',
  })

  const handleVariantSelection = async () => {
    const selected = await shopify.resourcePicker({
      type: 'variant',
      multiple: false,
    })

    if (selected && selected.length > 0) {
      const variant = selected[0]
      setData({
        ...data,
        recordable: {
          ...data.recordable,
          variant_gid: variant.id,
          title: data.recordable.title || variant.title,
        },
        variant_title: variant.title,
        product_title: variant.productTitle,
      })
      shopify.saveBar.show('recording-save-bar')
    }
  }

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

  return (
    <AppProvider i18n={enTranslations}>
      <Head title='New Recording' />
      <Page
        title='Create Recording'
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

            <Card>
              <form onSubmit={handleSubmit} onChange={() => shopify.saveBar.show('recording-save-bar')}>
                <FormLayout>
                  <BlockStack gap="400">
                    <Text variant="headingMd" as="h2">Product Variant</Text>

                    {data.recordable.variant_gid ? (
                      <BlockStack gap="200">
                        <InlineStack align="space-between" blockAlign="center">
                          <BlockStack gap="100">
                            <Text variant="bodyMd" as="p" fontWeight="semibold">
                              {data.product_title}
                            </Text>
                            <Text variant="bodySm" as="p" tone="subdued">
                              {data.variant_title}
                            </Text>
                          </BlockStack>
                          <Button onClick={handleVariantSelection}>
                            Change variant
                          </Button>
                        </InlineStack>
                      </BlockStack>
                    ) : (
                      <Button onClick={handleVariantSelection}>
                        Select product variant
                      </Button>
                    )}
                  </BlockStack>

                  <TextField
                    label="Title"
                    value={data.recordable.title}
                    onChange={(value) => setData('recordable', { ...data.recordable, title: value })}
                    error={errors['recordable.title']}
                    autoComplete="off"
                    helpText="Enter a title for your recording (defaults to variant title)"
                  />
                </FormLayout>
              </form>
            </Card>
          </Layout.Section>
        </Layout>

        <SaveBar id="recording-save-bar">
          <button variant="primary" onClick={handleSubmit} disabled={processing}></button>
          <button onClick={handleDiscard}></button>
        </SaveBar>
      </Page>
    </AppProvider>
  )
}
