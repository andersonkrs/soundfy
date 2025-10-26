import { useCallback, useEffect, useRef } from 'react'
import { useRecordingsNewContext } from './Context'
import { useDebouncedCallback } from 'use-debounce'

export function ProductField() {
  const { uploading, form } = useRecordingsNewContext()
  const { data, setData } = form
  const searchFieldRef = useRef(null)

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
  }, [setData])

  const handleSearchChange = useCallback((e) => {
    const value = e.target.value
    setData((prevData) => ({
      ...prevData,
      product_query: value,
    }))

    debouncedSearch?.cancel()
    debouncedSearch(value)
  }, [setData, debouncedSearch])

  const handleBrowseClick = useCallback(() => {
    handleVariantSelection()
    debouncedSearch.cancel()
  }, [handleVariantSelection, debouncedSearch])

  return (
    <s-stack vertical gap="200">
      <s-text variant="heading-md">Product</s-text>

      <s-stack gap="0">
        <s-search-field
          ref={searchFieldRef}
          placeholder="Search products"
          value={data.product_query || ''}
          onInput={handleSearchChange}
          style={{ flex: 1 }}
        />
        <s-button
          icon="search"
          onClick={handleBrowseClick}
        >
          Browse
        </s-button>
      </s-stack>

      {data.recordable?.variant_gid && (
        <s-box
          border-width="025"
          border-radius="200"
          padding="300"
        >
          <s-stack gap="200" align="center">
            <s-icon source="product" />
            <s-text variant="body-md">
              {data.recordable.title || 'Selected variant'}
            </s-text>
          </s-stack>
        </s-box>
      )}
    </s-stack>
  )
}
