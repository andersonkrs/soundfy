import { useCallback } from 'react'
import { BlockStack, Text, TextField, Button, Icon } from '@shopify/polaris'
import { SearchIcon } from '@shopify/polaris-icons'
import { useRecordingsNewContext } from './Context'
import { useDebouncedCallback } from 'use-debounce'

export function ProductField() {
  const { uploading, form } = useRecordingsNewContext()

  const { data, setData } = form

  console.log(data)

  if (uploading || !data.blob) {
    return null
  }

  const debouncedSearch = useDebouncedCallback((query) => handleVariantSelection(query), 500)

  const handleVariantSelection = useCallback(async (query = '') => {
    const selected = await shopify.resourcePicker({
      action: 'select',
      type: 'variant',
      multiple: false,
      query: query,
    })

    setData((prevData) => ({
      ...prevData,
      product_query: '',
    }))

    if (selected && selected.length > 0) {
      const variant = selected[0]
      setData((prevData) => ({
        ...prevData,
        recordable: {
          ...prevData.recordable,
          variant_gid: variant.id,
          title: variant.title,
        },
      }))
      shopify.saveBar.show('recording-save-bar')
    }
  }, [shopify, setData])


  return (
    <BlockStack gap="200">
      <Text variant="headingMd" as="h2">
        Product
      </Text>

      <TextField
        type="text"
        prefix={<Icon source={SearchIcon} tone="base" />}
        placeholder="Search products"
        value={data.product_query}
        onChange={(value) => {
          setData((prevData) => ({
            ...prevData,
            product_query: value,
          }))

          debouncedSearch?.cancel()
          debouncedSearch(value)
        }}
        connectedRight={
          <Button
            icon={<SearchIcon />}
            onClick={() => {
              handleVariantSelection()
              debouncedSearch.cancel()
            }}
          >
            Browse
          </Button>
        }
      />
    </BlockStack>
  )
}
