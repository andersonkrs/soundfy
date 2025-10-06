import { Link } from "@inertiajs/react";
import { NavMenu } from "@shopify/app-bridge-react";

function Layout({ children }) {
  return (
    <main role="main">
      <NavMenu>
        <Link href="/shopify/home" rel="home" target="_top">
          Home
        </Link>
        <Link href="/shopify/recordings" target="_top">
          Recordings
        </Link>
      </NavMenu>
      {children}
    </main>
  );
}

export default Layout;
