import type { Metadata } from 'next'
import { Analytics } from '@vercel/analytics/next'
import './globals.css'
import { SmoothScroll } from '@/components/smooth-scroll';

export const metadata: Metadata = {
  title: 'OSMO — Stellar Ecosystem Folio',
  description:
    'One deposit, the whole Stellar basket. A diversified token folio (DTF) on Stellar testnet — five ecosystem assets, one token: SEF.',
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="font-sans">
      <body className="font-sans antialiased">
         <SmoothScroll>
          {children}
         </SmoothScroll>
        <Analytics />
      </body>
    </html>
  )
}
