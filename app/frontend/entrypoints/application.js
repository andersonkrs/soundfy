// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

import "@shopify/polaris/build/esm/styles.css";

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

import { router } from "@inertiajs/react";

// Listen for Inertia requests and attach sessionToken to Authorization header
router.on("before", (event) => {
  // Add Authorization header with JWT session token
  // The token contains shop domain, so query params are not needed
  event.detail.visit.headers = {
    ...event.detail.visit.headers,
    Authorization: `Bearer ${window.sessionToken}`,
  };
});

const SESSION_TOKEN_REFRESH_INTERVAL = 2000; // Request a new token every 2s

async function retrieveToken() {
  window.sessionToken = await window.shopify.idToken();
}

function keepRetrievingToken() {
  setInterval(() => {
    retrieveToken();
  }, SESSION_TOKEN_REFRESH_INTERVAL);
}

document.addEventListener("DOMContentLoaded", async () => {
  // Admin pages do not initialize shopify
  if (!window.shopify) return;

  // Wait for a session token before trying to load an authenticated page
  await retrieveToken();

  // Keep retrieving a session token periodically
  keepRetrievingToken();
});
