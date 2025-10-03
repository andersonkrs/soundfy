import React from 'react'
import { Head } from '@inertiajs/react'
import {
  AppProvider,
  Page,
  Layout,
  Card,
  Text,
  BlockStack,
  InlineGrid,
  Box,
  Button,
  Badge
} from '@shopify/polaris'
import enTranslations from '@shopify/polaris/locales/en.json'

export default function Admin ({ currentTime }) {
  return (
    <AppProvider i18n={enTranslations}>
      <Head title='Admin Dashboard' />
      <Page
        title='Admin Dashboard'
        subtitle='Manage your application settings and monitor activity'
        primaryAction={{
          content: 'Settings',
          onAction: () => console.log('Settings clicked')
        }}
      >
        <Layout>
          <Layout.Section>
            <Card>
              <BlockStack gap='400'>
                <Text variant='headingMd' as='h2'>
                  System Overview
                </Text>
                <InlineGrid columns={3} gap='400'>
                  <Box>
                    <BlockStack gap='200'>
                      <Text variant='bodyMd' tone='subdued'>
                        Total Shops
                      </Text>
                      <Text variant='heading2xl' as='p'>
                        42
                      </Text>
                    </BlockStack>
                  </Box>
                  <Box>
                    <BlockStack gap='200'>
                      <Text variant='bodyMd' tone='subdued'>
                        Active Users
                      </Text>
                      <Text variant='heading2xl' as='p'>
                        128
                      </Text>
                    </BlockStack>
                  </Box>
                  <Box>
                    <BlockStack gap='200'>
                      <Text variant='bodyMd' tone='subdued'>
                        API Calls Today
                      </Text>
                      <Text variant='heading2xl' as='p'>
                        1,492
                      </Text>
                    </BlockStack>
                  </Box>
                </InlineGrid>
              </BlockStack>
            </Card>
          </Layout.Section>

          <Layout.Section>
            <Card>
              <BlockStack gap='400'>
                <Text variant='headingMd' as='h2'>
                  Quick Actions
                </Text>
                <InlineGrid columns={4} gap='400'>
                  <Button fullWidth>View Logs</Button>
                  <Button fullWidth>Manage Shops</Button>
                  <Button fullWidth>API Settings</Button>
                  <Button fullWidth variant='primary'>
                    Run Reports
                  </Button>
                </InlineGrid>
              </BlockStack>
            </Card>
          </Layout.Section>

          <Layout.Section variant='oneThird'>
            <Card>
              <BlockStack gap='400'>
                <Text variant='headingMd' as='h2'>
                  System Status
                </Text>
                <BlockStack gap='200'>
                  <InlineGrid columns={2} gap='400'>
                    <Text variant='bodyMd'>API</Text>
                    <Badge tone='success'>Operational</Badge>
                  </InlineGrid>
                  <InlineGrid columns={2} gap='400'>
                    <Text variant='bodyMd'>Database</Text>
                    <Badge tone='success'>Healthy</Badge>
                  </InlineGrid>
                  <InlineGrid columns={2} gap='400'>
                    <Text variant='bodyMd'>Queue</Text>
                    <Badge tone='warning'>Delayed</Badge>
                  </InlineGrid>
                </BlockStack>
              </BlockStack>
            </Card>
          </Layout.Section>

          <Layout.Section variant='twoThirds'>
            <Card>
              <BlockStack gap='400'>
                <Text variant='headingMd' as='h2'>
                  Recent Activity
                </Text>
                <BlockStack gap='200'>
                  <Text variant='bodyMd'>
                    • New shop installed: example-store.myshopify.com
                  </Text>
                  <Text variant='bodyMd'>
                    • Webhook processed: orders/create
                  </Text>
                  <Text variant='bodyMd'>
                    • Configuration updated: API rate limits
                  </Text>
                  <Text variant='bodyMd'>
                    • Scheduled job completed: Daily metrics
                  </Text>
                </BlockStack>
                <Text variant='bodySm' tone='subdued'>
                  Last updated: {currentTime}
                </Text>
              </BlockStack>
            </Card>
          </Layout.Section>
        </Layout>
      </Page>
    </AppProvider>
  )
}
