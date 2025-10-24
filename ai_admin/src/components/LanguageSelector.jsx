import { Globe } from 'lucide-react'
import { useLanguage } from '../contexts/LanguageContext'
import './LanguageSelector.css'

const LanguageSelector = () => {
  const { language, toggleLanguage } = useLanguage()

  return (
    <div className="language-selector">
      <button 
        className="language-toggle"
        onClick={toggleLanguage}
        title={language === 'en' ? 'Switch to Arabic' : 'التبديل إلى الإنجليزية'}
      >
        <Globe size={18} />
        <span className="language-text">
          {language === 'en' ? 'العربية' : 'English'}
        </span>
      </button>
    </div>
  )
}

export default LanguageSelector
