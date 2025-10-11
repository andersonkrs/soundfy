import { Head, router } from "@inertiajs/react";
import { AppProvider, Page, Card, Text, BlockStack } from "@shopify/polaris";
import enTranslations from "@shopify/polaris/locales/en.json";

export default function Home() {
  return (
    <AppProvider i18n={enTranslations}>
      <Head title="Soundfy - Home" />
      <Page
        title="Welcome to Soundfy"
        primaryAction={{
          target: "_top",
          content: "Test",
          onAction: () => router.visit("/shopify/recordings")
        }}
      >
        <BlockStack gap="500">
          <Card>
            <BlockStack gap="300">
              <Text variant="headingMd" as="h2">
                Get Started
              </Text>
              <Text variant="bodyMd" as="p">
                Welcome to your Shopify app! This is your home page built with
                Shopify Polaris components.
              </Text>
            </BlockStack>
          </Card>
        </BlockStack>
      </Page>
    </AppProvider>
  );
}
