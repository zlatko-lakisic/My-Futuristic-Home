import { Route, Routes } from 'react-router-dom'
import { ScrollManager } from './components/ScrollManager'
import { HomePage } from './pages/HomePage'
import { NotFoundPage } from './pages/NotFoundPage'
import { SystemDetailPage } from './pages/SystemDetailPage'

export default function App() {
  return (
    <div className="min-h-svh bg-night">
      <ScrollManager />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/systems/:slug" element={<SystemDetailPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </div>
  )
}
