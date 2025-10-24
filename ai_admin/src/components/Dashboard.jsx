import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { db, supabase } from '../lib/supabase'
import { toast } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'
import { useLanguage } from '../contexts/LanguageContext'
import LanguageSelector from './LanguageSelector'
import { 
  BarChart3, 
  Folder, 
  FolderOpen, 
  Package, 
  Users, 
  Megaphone, 
  Plus, 
  Eye, 
  Edit, 
  Trash2, 
  Sun, 
  Moon,
  Clipboard,
  User,
  Settings,
  ShoppingCart,
  TrendingUp
} from 'lucide-react'
import './Dashboard.css'

const Dashboard = () => {
  const { t } = useLanguage()
  const [userEmail, setUserEmail] = useState('')
  const [activeSection, setActiveSection] = useState('dashboard')
  const [isDarkMode, setIsDarkMode] = useState(false)
  const [showModal, setShowModal] = useState(false)
  const [modalType, setModalType] = useState('') // 'add', 'edit', 'view', 'delete'
  const [selectedItem, setSelectedItem] = useState(null)
  const [formData, setFormData] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [uploadingMedia, setUploadingMedia] = useState(false)
  const [schemaWarning, setSchemaWarning] = useState(false)
  
  // Real data from Supabase
  const [dashboardStats, setDashboardStats] = useState({
    total_users: 0,
    total_books: 0,
    total_orders: 0,
    total_revenue: 0,
    total_categories: 0,
    active_banners: 0
  })
  const [categories, setCategories] = useState([])
  const [subcategories, setSubcategories] = useState([])
  const [products, setProducts] = useState([])
  const [users, setUsers] = useState([])
  const [banners, setBanners] = useState([])
  const [orders, setOrders] = useState([])
  const [orderPage, setOrderPage] = useState(1)
  const [ordersPerPage] = useState(10)
  const [orderStatusFilter, setOrderStatusFilter] = useState('all')
  const [orderSearchQuery, setOrderSearchQuery] = useState('')
  const [loadingOrders, setLoadingOrders] = useState(false)

  const [customers, setCustomers] = useState([])
  const [customerPage, setCustomerPage] = useState(1)
  const [customersPerPage] = useState(10)
  const [customerStatusFilter, setCustomerStatusFilter] = useState('all')
  const [customerSearchQuery, setCustomerSearchQuery] = useState('')
  const [loadingCustomers, setLoadingCustomers] = useState(false)

  const navigate = useNavigate()

  useEffect(() => {
    // Check if user is authenticated
    const isAuthenticated = localStorage.getItem('isAuthenticated')
    const email = localStorage.getItem('userEmail')
    
    if (!isAuthenticated) {
      navigate('/login')
      return
    }
    
    setUserEmail(email)

    // Check for saved theme preference
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme === 'dark') {
      setIsDarkMode(true)
      document.body.classList.add('dark-mode')
    }

    // Load data from Supabase
    loadData()
  }, [navigate])

  // Effect hooks for orders and customers
  useEffect(() => {
    loadOrders()
  }, [orderPage, orderStatusFilter, orderSearchQuery])

  useEffect(() => {
    loadCustomers()
  }, [customerPage, customerStatusFilter, customerSearchQuery])

  const loadOrders = async () => {
    try {
      setLoadingOrders(true)
      let query = supabase
        .from('orders')
        .select(`
          *,
          customer:customers(first_name, last_name, email)
        `)
        .range((orderPage - 1) * ordersPerPage, orderPage * ordersPerPage - 1)
        .order('created_at', { ascending: false })

      if (orderStatusFilter !== 'all') {
        query = query.eq('status', orderStatusFilter)
      }

      if (orderSearchQuery) {
        query = query.or(`order_number.ilike.%${orderSearchQuery}%,customer.first_name.ilike.%${orderSearchQuery}%,customer.last_name.ilike.%${orderSearchQuery}%`)
      }

      const { data, error } = await query
      
      if (error) throw error
      setOrders(data || [])
    } catch (error) {
      console.error('Error loading orders:', error)
      toast.error('Failed to load orders')
    } finally {
      setLoadingOrders(false)
    }
  }

  const loadCustomers = async () => {
    try {
      setLoadingCustomers(true)
      let query = supabase
        .from('customers')
        .select('*')
        .range((customerPage - 1) * customersPerPage, customerPage * customersPerPage - 1)
        .order('created_at', { ascending: false })

      if (customerStatusFilter !== 'all') {
        query = query.eq('status', customerStatusFilter)
      }

      if (customerSearchQuery) {
        query = query.or(`first_name.ilike.%${customerSearchQuery}%,last_name.ilike.%${customerSearchQuery}%,email.ilike.%${customerSearchQuery}%`)
      }

      const { data, error } = await query
      
      if (error) throw error
      setCustomers(data || [])
    } catch (error) {
      console.error('Error loading customers:', error)
      toast.error('Failed to load customers')
    } finally {
      setLoadingCustomers(false)
    }
  }

  const loadData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      // Load dashboard stats
      try {
        const stats = await db.getDashboardStats()
        setDashboardStats(stats)
      } catch (err) {
        console.log('Dashboard stats not available yet:', err.message)
      }

      // Load categories
      try {
        const categoriesData = await db.getCategories()
        setCategories(categoriesData?.map(category => ({
          ...category,
          count: category.count || 0 // Fallback if count is not available
        })) || [])
      } catch (err) {
        console.log('Categories not available yet:', err.message)
      }

      // Load subcategories
      try {
        const subcategoriesData = await db.getSubcategories()
        setSubcategories(subcategoriesData?.map(subcategory => ({
          ...subcategory,
          count: subcategory.count || 0 // Fallback if count is not available
        })) || [])
      } catch (err) {
        console.log('Subcategories not available yet:', err.message)
      }

      // Load books/products
      try {
        const booksData = await db.getBooks()
        setProducts(booksData?.map(book => ({
          id: book.id,
          name: book.title,
          description: book.description || '',
          price: book.price,
          category: book.category,
          status: book.is_active ? 'active' : 'inactive',
          stock: book.stock_quantity || 0,
          thumbnail_image: book.thumbnail_image || '',
          images: book.images || [],
          videos: book.videos || [],
          preview_video: book.preview_video || '',
          ideal_for: book.ideal_for || '',
          age_range: book.age_range || '',
          characters: book.characters || [],
          genre: book.genre || ''
        })) || [])
      } catch (err) {
        console.log('Books not available yet:', err.message)
        // If error is about missing columns, show helpful message
        if (err.message.includes('column') && err.message.includes('does not exist')) {
          setSchemaWarning(true)
          setError('Database schema needs to be updated. Please run the database migration script in Supabase.')
        }
      }

      // Load app users
      try {
        const usersData = await db.getAppUsers()
        setUsers(usersData?.map(user => ({
          id: user.id,
          name: user.full_name || 'N/A',
          email: user.email,
          role: 'user',
          status: user.is_active ? 'active' : 'inactive',
          joinDate: user.created_at ? new Date(user.created_at).toISOString().split('T')[0] : 'N/A'
        })) || [])
      } catch (err) {
        console.log('Users not available yet:', err.message)
      }

      // Load banners
      try {
        const bannersData = await db.getBanners()
        setBanners(bannersData?.map(banner => ({
          id: banner.id,
          title: banner.title,
          description: banner.description,
          status: banner.is_active ? 'active' : 'inactive',
          startDate: banner.start_date ? new Date(banner.start_date).toISOString().split('T')[0] : 'N/A',
          endDate: banner.end_date ? new Date(banner.end_date).toISOString().split('T')[0] : 'N/A'
        })) || [])
      } catch (err) {
        console.log('Banners not available yet:', err.message)
      }

      // Load initial orders
      try {
        await loadOrders()
      } catch (err) {
        console.log('Orders not available yet:', err.message)
      }

      // Load initial customers
      try {
        await loadCustomers()
      } catch (err) {
        console.log('Customers not available yet:', err.message)
      }

    } catch (err) {
      console.error('Error loading data:', err)
      setError('Failed to load data. Please check your Supabase configuration.')
    } finally {
      setLoading(false)
    }
  }

  const toggleTheme = () => {
    setIsDarkMode(!isDarkMode)
    if (!isDarkMode) {
      document.body.classList.add('dark-mode')
      localStorage.setItem('theme', 'dark')
    } else {
      document.body.classList.remove('dark-mode')
      localStorage.setItem('theme', 'light')
    }
  }

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated')
    localStorage.removeItem('userEmail')
    navigate('/login')
  }

  const sidebarItems = [
    { id: 'dashboard', label: t('nav.dashboard'), icon: BarChart3 },
    { id: 'orders', label: t('nav.orders'), icon: ShoppingCart },
    { id: 'customers', label: t('nav.customers'), icon: Users },
    { id: 'categories', label: t('nav.categories'), icon: Folder },
    { id: 'subcategories', label: t('nav.subcategories'), icon: FolderOpen },
    { id: 'products', label: t('nav.products'), icon: Package },
    { id: 'users', label: t('nav.users'), icon: Users },
    { id: 'banners', label: t('nav.banners'), icon: Megaphone }
  ]

  const openModal = (type, item = null) => {
    setModalType(type)
    setSelectedItem(item)
    
    // Initialize form data based on modal type and item
    if (type === 'add') {
      setFormData({})
    } else if (type === 'edit' && item) {
      // Pre-populate form data for editing
      if (item.type === 'category') {
        setFormData({
          name: item.name || '',
          description: item.description || ''
        })
      } else if (item.type === 'subcategory') {
        setFormData({
          name: item.name || '',
          description: item.description || '',
          category_id: item.category_id || '',
          category_name: item.category_name || ''
        })
      } else if (item.type === 'product') {
        setFormData({
          name: item.name || '',
          description: item.description || '',
          price: item.price || '',
          category: item.category || '',
          subcategory_id: item.subcategory_id || '',
          stock: item.stock || '',
          status: item.status || 'active',
          thumbnail_image: item.thumbnail_image || '',
          images: item.images || [],
          videos: item.videos || [],
          preview_video: item.preview_video || '',
          ideal_for: item.ideal_for || '',
          age_range: item.age_range || '',
          characters: item.characters || [],
          genre: item.genre || ''
        })
      } else if (item.type === 'user') {
        setFormData({
          name: item.name || '',
          email: item.email || '',
          role: item.role || 'user',
          status: item.status || 'active'
        })
      } else if (item.type === 'banner') {
        setFormData({
          title: item.title || '',
          description: item.description || '',
          startDate: item.startDate || '',
          endDate: item.endDate || '',
          status: item.status || 'active'
        })
      }
    }
    
    setShowModal(true)
  }

  const closeModal = () => {
    setShowModal(false)
    setModalType('')
    setSelectedItem(null)
    setFormData({})
  }

  const handleDelete = async (type, id) => {
    if (window.confirm('Are you sure you want to delete this item?')) {
      try {
        if (type === 'category') {
          await db.deleteCategory(id)
          setCategories(categories.filter(cat => cat.id !== id))
        } else if (type === 'subcategory') {
          await db.deleteSubcategory(id)
          setSubcategories(subcategories.filter(subcat => subcat.id !== id))
        } else if (type === 'product') {
          await db.deleteBook(id)
          setProducts(products.filter(prod => prod.id !== id))
        } else if (type === 'user') {
          await db.deleteAppUser(id)
          setUsers(users.filter(user => user.id !== id))
        } else if (type === 'banner') {
          await db.deleteBanner(id)
          setBanners(banners.filter(banner => banner.id !== id))
        }
        closeModal()
        // Reload data to ensure consistency
        await loadData()
      } catch (error) {
        console.error('Delete failed:', error)
        alert('Failed to delete item. Please try again.')
      }
    }
  }

  // Form input handler
  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
  }

  // Media handling functions
  const handleFileUpload = async (event, mediaType) => {
    const files = Array.from(event.target.files)
    if (!files.length) return

    setUploadingMedia(true)
    try {
      const uploadedUrls = []
      
      for (const file of files) {
        // Validate file size (max 50MB)
        if (file.size > 50 * 1024 * 1024) {
          alert(`File ${file.name} is too large. Maximum size is 50MB.`)
          continue
        }

        // Validate file type
        const isImage = file.type.startsWith('image/')
        const isVideo = file.type.startsWith('video/')
        
        if (mediaType.includes('image') && !isImage) {
          alert(`File ${file.name} is not a valid image format.`)
          continue
        }
        
        if (mediaType.includes('video') && !isVideo) {
          alert(`File ${file.name} is not a valid video format.`)
          continue
        }
        
        const fileName = `${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`
        const filePath = `products/${selectedItem?.id || 'new'}/${fileName}`
        
        try {
          const { data, error } = await db.uploadMedia(file, filePath)
          if (error) throw error
          
          const publicUrl = db.getMediaUrl(data.path)
          uploadedUrls.push(publicUrl)
        } catch (uploadError) {
          console.error('Upload error for file:', file.name, uploadError)
          
          // Handle specific upload errors
          if (uploadError.message.includes('storage bucket')) {
            alert('Storage bucket not found. Please ensure the "product-media" bucket exists in Supabase Storage.')
          } else if (uploadError.message.includes('policy')) {
            alert('Upload permission denied. Please check Supabase storage policies.')
          } else {
            alert(`Failed to upload ${file.name}. Error: ${uploadError.message}`)
          }
          continue
        }
      }

      if (uploadedUrls.length === 0) {
        setUploadingMedia(false)
        return
      }

      // Update formData based on media type
      if (mediaType === 'thumbnail_image' || mediaType === 'preview_video') {
        handleInputChange(mediaType, uploadedUrls[0])
      } else {
        // For images and videos arrays
        const currentMedia = formData[mediaType] || []
        handleInputChange(mediaType, [...currentMedia, ...uploadedUrls])
      }
      
      if (uploadedUrls.length > 0) {
        alert(`Successfully uploaded ${uploadedUrls.length} file(s)`)
      }
    } catch (error) {
      console.error('Upload failed:', error)
      
      // Provide specific error messages
      if (error.message.includes('bucket')) {
        alert('Storage bucket configuration error. Please ensure the "product-media" bucket exists and is properly configured in Supabase.')
      } else if (error.message.includes('authentication')) {
        alert('Authentication error. Please login again.')
      } else {
        alert(`Failed to upload media. Error: ${error.message}`)
      }
    } finally {
      setUploadingMedia(false)
    }
  }

  const removeMedia = (mediaType, index) => {
    if (formData[mediaType] && Array.isArray(formData[mediaType])) {
      const updatedMedia = formData[mediaType].filter((_, i) => i !== index)
      handleInputChange(mediaType, updatedMedia)
    }
  }

  // Save functions for different types
  const handleSave = async () => {
    try {
      if (!selectedItem?.type) return
      
      const { type } = selectedItem
      
      // Show loading state
      setUploadingMedia(true)
      
      if (modalType === 'add') {
        if (type === 'category') {
          if (!formData.name?.trim()) {
            alert('Please enter a category name')
            setUploadingMedia(false)
            return
          }
          await db.addCategory({
            name: formData.name.trim(),
            description: formData.description?.trim() || '',
            is_active: true,
            sort_order: categories.length + 1
          })
        } else if (type === 'subcategory') {
          if (!formData.name?.trim() || !formData.category_id) {
            alert('Please enter subcategory name and select a category')
            setUploadingMedia(false)
            return
          }
          await db.addSubcategory({
            name: formData.name.trim(),
            description: formData.description?.trim() || '',
            category_id: parseInt(formData.category_id),
            is_active: true,
            sort_order: subcategories.filter(s => s.category_id === parseInt(formData.category_id)).length + 1
          })
        } else if (type === 'product') {
          if (!formData.name?.trim() || !formData.price || !formData.category) {
            alert('Please fill in all required fields (name, price, category)')
            setUploadingMedia(false)
            return
          }
          
          // Prepare book data with fallback for missing schema columns
          const bookData = {
            title: formData.name.trim(),
            description: formData.description?.trim() || '',
            price: parseFloat(formData.price) || 0,
            category: formData.category,
            stock_quantity: parseInt(formData.stock) || 0,
            is_active: formData.status === 'active',
            ideal_for: formData.ideal_for?.trim() || null,
            age_range: formData.age_range?.trim() || null,
            characters: formData.characters || [],
            genre: formData.genre?.trim() || null
          }
          
          // Only add media fields if they exist (to handle schema migration)
          try {
            bookData.thumbnail_image = formData.thumbnail_image || null
            bookData.images = formData.images || []
            bookData.videos = formData.videos || []
            bookData.preview_video = formData.preview_video || null
          } catch (e) {
            console.log('Media fields not available in schema yet')
          }
          
          await db.addBook(bookData)
        } else if (type === 'user') {
          if (!formData.name?.trim() || !formData.email?.trim()) {
            alert('Please enter both name and email')
            setUploadingMedia(false)
            return
          }
          await db.addAppUser({
            full_name: formData.name.trim(),
            email: formData.email.trim(),
            role: formData.role || 'user',
            is_active: formData.status === 'active'
          })
        } else if (type === 'banner') {
          if (!formData.title?.trim()) {
            alert('Please enter a banner title')
            setUploadingMedia(false)
            return
          }
          await db.addBanner({
            title: formData.title.trim(),
            description: formData.description?.trim() || '',
            start_date: formData.startDate || null,
            end_date: formData.endDate || null,
            is_active: formData.status === 'active',
            priority: banners.length + 1
          })
        }
      } else if (modalType === 'edit') {
        if (type === 'category') {
          if (!formData.name?.trim()) {
            alert('Please enter a category name')
            setUploadingMedia(false)
            return
          }
          await db.updateCategory(selectedItem.id, {
            name: formData.name.trim(),
            description: formData.description?.trim() || ''
          })
        } else if (type === 'subcategory') {
          if (!formData.name?.trim()) {
            alert('Please enter a subcategory name')
            setUploadingMedia(false)
            return
          }
          await db.updateSubcategory(selectedItem.id, {
            name: formData.name.trim(),
            description: formData.description?.trim() || ''
          })
        } else if (type === 'product') {
          if (!formData.name?.trim() || !formData.price || !formData.category) {
            alert('Please fill in all required fields (name, price, category)')
            setUploadingMedia(false)
            return
          }
          
          // Prepare book data with fallback for missing schema columns
          const bookData = {
            title: formData.name.trim(),
            description: formData.description?.trim() || '',
            price: parseFloat(formData.price) || 0,
            category: formData.category,
            stock_quantity: parseInt(formData.stock) || 0,
            is_active: formData.status === 'active',
            ideal_for: formData.ideal_for?.trim() || null,
            age_range: formData.age_range?.trim() || null,
            characters: formData.characters || [],
            genre: formData.genre?.trim() || null
          }
          
          // Only add media fields if they exist (to handle schema migration)
          try {
            bookData.thumbnail_image = formData.thumbnail_image || null
            bookData.images = formData.images || []
            bookData.videos = formData.videos || []
            bookData.preview_video = formData.preview_video || null
          } catch (e) {
            console.log('Media fields not available in schema yet')
          }
          
          await db.updateBook(selectedItem.id, bookData)
        } else if (type === 'user') {
          if (!formData.name?.trim() || !formData.email?.trim()) {
            alert('Please enter both name and email')
            setUploadingMedia(false)
            return
          }
          await db.updateAppUser(selectedItem.id, {
            full_name: formData.name.trim(),
            email: formData.email.trim(),
            role: formData.role || 'user',
            is_active: formData.status === 'active'
          })
        } else if (type === 'banner') {
          if (!formData.title?.trim()) {
            alert('Please enter a banner title')
            setUploadingMedia(false)
            return
          }
          await db.updateBanner(selectedItem.id, {
            title: formData.title.trim(),
            description: formData.description?.trim() || '',
            start_date: formData.startDate || null,
            end_date: formData.endDate || null,
            is_active: formData.status === 'active'
          })
        }
      }
      
      // Reload data after successful save
      await loadData()
      closeModal()
      alert(`${type.charAt(0).toUpperCase() + type.slice(1)} ${modalType === 'add' ? 'added' : 'updated'} successfully!`)
    } catch (error) {
      console.error('Save failed:', error)
      
      // Provide specific error messages based on error type
      let errorMessage = `Failed to ${modalType} ${selectedItem?.type}.`
      
      if (error.message.includes('column') && (error.message.includes('images') || error.message.includes('videos'))) {
        errorMessage = 'Database schema needs to be updated with media columns. Please run the database migration script in Supabase SQL editor. For now, the product was saved without media fields.'
      } else if (error.message.includes('schema cache')) {
        errorMessage = 'Database schema is outdated. Please run the database migration script in Supabase to add media support.'
      } else if (error.message.includes('foreign key')) {
        errorMessage = 'Invalid category selected. Please choose a valid category.'
      } else if (error.message.includes('duplicate')) {
        errorMessage = 'A record with this name already exists. Please use a different name.'
      } else if (error.message.includes('permission')) {
        errorMessage = 'Permission denied. Please check your access rights.'
      } else {
        errorMessage += ` Error: ${error.message}`
      }
      
      alert(errorMessage)
    } finally {
      setUploadingMedia(false)
    }
  }

  const renderContent = () => {
    switch (activeSection) {
      case 'orders':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Orders</h3>
                  <div className="filter-section">
                    <select 
                      value={orderStatusFilter} 
                      onChange={(e) => setOrderStatusFilter(e.target.value)}
                      className="filter-select"
                    >
                      <option value="all">All Status</option>
                      <option value="pending">Pending</option>
                      <option value="processing">Processing</option>
                      <option value="shipped">Shipped</option>
                      <option value="delivered">Delivered</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Search by order number or customer"
                      value={orderSearchQuery}
                      onChange={(e) => setOrderSearchQuery(e.target.value)}
                      className="search-input"
                    />
                  </div>
                </div>
                {loadingOrders ? (
                  <div className="loading-message">
                    <p>Loading orders...</p>
                  </div>
                ) : (
                  <>
                    <div className="orders-table-container">
                      <table className="orders-table">
                        <thead>
                          <tr>
                            <th>Order #</th>
                            <th>Customer</th>
                            <th>Date</th>
                            <th>Total</th>
                            <th>Status</th>
                            <th>Payment</th>
                            <th>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {orders.map((order) => (
                            <tr key={order.id}>
                              <td>{order.order_number}</td>
                              <td>
                                <div className="customer-info">
                                  <span>{order.customer?.first_name} {order.customer?.last_name}</span>
                                  <small>{order.customer?.email}</small>
                                </div>
                              </td>
                              <td>{new Date(order.created_at).toLocaleDateString()}</td>
                              <td>${order.total_amount}</td>
                              <td>
                                <span className={`status-badge ${order.status}`}>
                                  {order.status}
                                </span>
                              </td>
                              <td>
                                <span className={`payment-status ${order.payment_status}`}>
                                  {order.payment_status}
                                </span>
                              </td>
                              <td>
                                <button
                                  className="action-btn view"
                                  onClick={() => navigateToOrderDetails(order.id)}
                                >
                                  <Eye size={16} /> View Details
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                    <div className="pagination">
                      <button 
                        onClick={() => setOrderPage(prev => Math.max(1, prev - 1))}
                        disabled={orderPage === 1}
                      >
                        Previous
                      </button>
                      <span>Page {orderPage}</span>
                      <button 
                        onClick={() => setOrderPage(prev => prev + 1)}
                        disabled={orders.length < ordersPerPage}
                      >
                        Next
                      </button>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        )

      case 'customers':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Customers</h3>
                  <div className="filter-section">
                    <select 
                      value={customerStatusFilter} 
                      onChange={(e) => setCustomerStatusFilter(e.target.value)}
                      className="filter-select"
                    >
                      <option value="all">All Status</option>
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                      <option value="blocked">Blocked</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Search by name or email"
                      value={customerSearchQuery}
                      onChange={(e) => setCustomerSearchQuery(e.target.value)}
                      className="search-input"
                    />
                  </div>
                </div>
                {loadingCustomers ? (
                  <div className="loading-message">
                    <p>Loading customers...</p>
                  </div>
                ) : (
                  <>
                    <div className="customers-table-container">
                      <table className="customers-table">
                        <thead>
                          <tr>
                            <th>Customer</th>
                            <th>Contact</th>
                            <th>Joined</th>
                            <th>Orders</th>
                            <th>Total Spent</th>
                            <th>Status</th>
                            <th>Actions</th>
                          </tr>
                        </thead>
                        <tbody>
                          {customers.map((customer) => (
                            <tr key={customer.id}>
                              <td>
                                <div className="customer-info">
                                  <span>{customer.first_name} {customer.last_name}</span>
                                  <small>{customer.email}</small>
                                </div>
                              </td>
                              <td>{customer.phone || 'N/A'}</td>
                              <td>{new Date(customer.created_at).toLocaleDateString()}</td>
                              <td>{customer.total_orders}</td>
                              <td>${customer.total_spent}</td>
                              <td>
                                <span className={`status-badge ${customer.status}`}>
                                  {customer.status}
                                </span>
                              </td>
                              <td>
                                <button
                                  className="action-btn view"
                                  onClick={() => navigateToCustomerDetails(customer.id)}
                                >
                                  <Eye size={16} /> View Details
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                    <div className="pagination">
                      <button 
                        onClick={() => setCustomerPage(prev => Math.max(1, prev - 1))}
                        disabled={customerPage === 1}
                      >
                        Previous
                      </button>
                      <span>Page {customerPage}</span>
                      <button 
                        onClick={() => setCustomerPage(prev => prev + 1)}
                        disabled={customers.length < customersPerPage}
                      >
                        Next
                      </button>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        )

      case 'categories':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Categories ({categories.length})</h3>
                  <button 
                    className="header-button"
                    onClick={() => openModal('add', { type: 'category' })}
                  >
                    <Plus size={16} />
                    Add Category
                  </button>
                </div>
                <div className="items-list">
                  {categories.map((category) => (
                    <div key={category.id} className="list-item">
                      <div className="item-info">
                        <div className="item-main">
                          <span className="item-name">{category.name}</span>
                          <span className="item-description">{category.description}</span>
                        </div>
                        <div className="item-meta">
                          <span className="item-count">{category.count} products</span>
                        </div>
                      </div>
                      <div className="item-actions">
                        <button 
                          className="action-btn view"
                          onClick={() => openModal('view', { ...category, type: 'category' })}
                        >
                          <Eye size={16} /> View
                        </button>
                        <button 
                          className="action-btn edit"
                          onClick={() => openModal('edit', { ...category, type: 'category' })}
                        >
                          <Edit size={16} /> Edit
                        </button>
                        <button 
                          className="action-btn delete"
                          onClick={() => openModal('delete', { ...category, type: 'category' })}
                        >
                          <Trash2 size={16} /> Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )
      case 'subcategories':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Subcategories ({subcategories.length})</h3>
                  <button 
                    className="header-button"
                    onClick={() => openModal('add', { type: 'subcategory' })}
                  >
                    <Plus size={16} />
                    Add Subcategory
                  </button>
                </div>
                <div className="items-list">
                  {subcategories.map((subcategory) => (
                    <div key={subcategory.id} className="list-item">
                      <div className="item-info">
                        <div className="item-main">
                          <span className="item-name">{subcategory.name}</span>
                          <span className="item-description">{subcategory.description}</span>
                        </div>
                        <div className="item-meta">
                          <span className="item-category">Category: {subcategory.category_name}</span>
                          <span className="item-count">{subcategory.count} products</span>
                        </div>
                      </div>
                      <div className="item-actions">
                        <button 
                          className="action-btn view"
                          onClick={() => openModal('view', { ...subcategory, type: 'subcategory' })}
                        >
                          <Eye size={16} /> View
                        </button>
                        <button 
                          className="action-btn edit"
                          onClick={() => openModal('edit', { ...subcategory, type: 'subcategory' })}
                        >
                          <Edit size={16} /> Edit
                        </button>
                        <button 
                          className="action-btn delete"
                          onClick={() => openModal('delete', { ...subcategory, type: 'subcategory' })}
                        >
                          <Trash2 size={16} /> Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )
      case 'products':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Products ({products.length})</h3>
                  <button 
                    className="header-button"
                    onClick={() => openModal('add', { type: 'product' })}
                  >
                    <Plus size={16} />
                    Add Product
                  </button>
                </div>
                <div className="items-list">
                  {products.map((product) => (
                    <div key={product.id} className="list-item">
                      <div className="item-info">
                        <div className="item-main">
                          <span className="item-name">{product.name}</span>
                          <span className="item-description">Category: {product.category}</span>
                        </div>
                        <div className="item-meta">
                          <span className="item-price">${product.price}</span>
                          <span className={`item-status ${product.status}`}>
                            {product.status}
                          </span>
                          <span className="item-stock">Stock: {product.stock}</span>
                        </div>
                      </div>
                      <div className="item-actions">
                        <button 
                          className="action-btn view"
                          onClick={() => openModal('view', { ...product, type: 'product' })}
                        >
                          <Eye size={16} /> View
                        </button>
                        <button 
                          className="action-btn edit"
                          onClick={() => openModal('edit', { ...product, type: 'product' })}
                        >
                          <Edit size={16} /> Edit
                        </button>
                        <button 
                          className="action-btn delete"
                          onClick={() => openModal('delete', { ...product, type: 'product' })}
                        >
                          <Trash2 size={16} /> Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )
      case 'users':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Users ({users.length})</h3>
                  <button 
                    className="header-button"
                    onClick={() => openModal('add', { type: 'user' })}
                  >
                    <Plus size={16} />
                    Add User
                  </button>
                </div>
                <div className="items-list">
                  {users.map((user) => (
                    <div key={user.id} className="list-item">
                      <div className="item-info">
                        <div className="item-main">
                          <span className="item-name">{user.name}</span>
                          <span className="item-description">{user.email}</span>
                        </div>
                        <div className="item-meta">
                          <span className={`item-role ${user.role}`}>{user.role}</span>
                          <span className={`item-status ${user.status}`}>{user.status}</span>
                          <span className="item-date">Joined: {user.joinDate}</span>
                        </div>
                      </div>
                      <div className="item-actions">
                        <button 
                          className="action-btn view"
                          onClick={() => openModal('view', { ...user, type: 'user' })}
                        >
                          <Eye size={16} /> View
                        </button>
                        <button 
                          className="action-btn edit"
                          onClick={() => openModal('edit', { ...user, type: 'user' })}
                        >
                          <Edit size={16} /> Edit
                        </button>
                        <button 
                          className="action-btn delete"
                          onClick={() => openModal('delete', { ...user, type: 'user' })}
                        >
                          <Trash2 size={16} /> Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )
      case 'orders':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Orders</h3>
                  <div className="filter-section">
                    <select 
                      value={orderStatusFilter} 
                      onChange={(e) => setOrderStatusFilter(e.target.value)}
                      className="filter-select"
                    >
                      <option value="all">All Status</option>
                      <option value="pending">Pending</option>
                      <option value="processing">Processing</option>
                      <option value="shipped">Shipped</option>
                      <option value="delivered">Delivered</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Search by order number or customer"
                      value={orderSearchQuery}
                      onChange={(e) => setOrderSearchQuery(e.target.value)}
                      className="search-input"
                    />
                  </div>
                </div>
                <div className="orders-table-container">
                  <table className="orders-table">
                    <thead>
                      <tr>
                        <th>Order #</th>
                        <th>Customer</th>
                        <th>Date</th>
                        <th>Total</th>
                        <th>Status</th>
                        <th>Payment</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {orders.map((order) => (
                        <tr key={order.id}>
                          <td>{order.order_number}</td>
                          <td>
                            <div className="customer-info">
                              <span>{order.customer.first_name} {order.customer.last_name}</span>
                              <small>{order.customer.email}</small>
                            </div>
                          </td>
                          <td>{new Date(order.created_at).toLocaleDateString()}</td>
                          <td>${order.total_amount}</td>
                          <td>
                            <select
                              value={order.status}
                              onChange={(e) => updateOrderStatus(order.id, e.target.value)}
                              className={`status-select ${order.status}`}
                            >
                              <option value="pending">Pending</option>
                              <option value="processing">Processing</option>
                              <option value="shipped">Shipped</option>
                              <option value="delivered">Delivered</option>
                              <option value="cancelled">Cancelled</option>
                            </select>
                          </td>
                          <td>
                            <span className={`payment-status ${order.payment_status}`}>
                              {order.payment_status}
                            </span>
                          </td>
                          <td>
                            <button
                              className="action-btn view"
                              onClick={() => navigateToOrderDetails(order.id)}
                            >
                              <Eye size={16} /> View Details
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="pagination">
                  <button 
                    onClick={() => setOrderPage(prev => Math.max(1, prev - 1))}
                    disabled={orderPage === 1}
                  >
                    Previous
                  </button>
                  <span>Page {orderPage}</span>
                  <button 
                    onClick={() => setOrderPage(prev => prev + 1)}
                    disabled={orders.length < ordersPerPage}
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>
        )

      case 'customers':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Customers</h3>
                  <div className="filter-section">
                    <select 
                      value={customerStatusFilter} 
                      onChange={(e) => setCustomerStatusFilter(e.target.value)}
                      className="filter-select"
                    >
                      <option value="all">All Status</option>
                      <option value="active">Active</option>
                      <option value="inactive">Inactive</option>
                      <option value="blocked">Blocked</option>
                    </select>
                    <input
                      type="text"
                      placeholder="Search by name or email"
                      value={customerSearchQuery}
                      onChange={(e) => setCustomerSearchQuery(e.target.value)}
                      className="search-input"
                    />
                  </div>
                </div>
                <div className="customers-table-container">
                  <table className="customers-table">
                    <thead>
                      <tr>
                        <th>Customer</th>
                        <th>Contact</th>
                        <th>Joined</th>
                        <th>Orders</th>
                        <th>Total Spent</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {customers.map((customer) => (
                        <tr key={customer.id}>
                          <td>
                            <div className="customer-info">
                              <span>{customer.first_name} {customer.last_name}</span>
                              <small>{customer.email}</small>
                            </div>
                          </td>
                          <td>{customer.phone || 'N/A'}</td>
                          <td>{new Date(customer.created_at).toLocaleDateString()}</td>
                          <td>{customer.total_orders}</td>
                          <td>${customer.total_spent}</td>
                          <td>
                            <select
                              value={customer.status}
                              onChange={(e) => updateCustomerStatus(customer.id, e.target.value)}
                              className={`status-select ${customer.status}`}
                            >
                              <option value="active">Active</option>
                              <option value="inactive">Inactive</option>
                              <option value="blocked">Blocked</option>
                            </select>
                          </td>
                          <td>
                            <button
                              className="action-btn view"
                              onClick={() => navigateToCustomerDetails(customer.id)}
                            >
                              <Eye size={16} /> View Details
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="pagination">
                  <button 
                    onClick={() => setCustomerPage(prev => Math.max(1, prev - 1))}
                    disabled={customerPage === 1}
                  >
                    Previous
                  </button>
                  <span>Page {customerPage}</span>
                  <button 
                    onClick={() => setCustomerPage(prev => prev + 1)}
                    disabled={customers.length < customersPerPage}
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          </div>
        )

      case 'banners':
        return (
          <div className="section-content">
            <div className="content-grid">
              <div className="content-card full-width">
                <div className="card-header">
                  <h3>All Banners ({banners.length})</h3>
                  <button 
                    className="header-button"
                    onClick={() => openModal('add', { type: 'banner' })}
                  >
                    <Plus size={16} />
                    Add Banner
                  </button>
                </div>
                <div className="items-list">
                  {banners.map((banner) => (
                    <div key={banner.id} className="list-item">
                      <div className="item-info">
                        <div className="item-main">
                          <span className="item-name">{banner.title}</span>
                          <span className="item-description">{banner.description}</span>
                        </div>
                        <div className="item-meta">
                          <span className={`item-status ${banner.status}`}>{banner.status}</span>
                          <span className="item-date">Start: {banner.startDate}</span>
                          <span className="item-date">End: {banner.endDate}</span>
                        </div>
                      </div>
                      <div className="item-actions">
                        <button 
                          className="action-btn view"
                          onClick={() => openModal('view', { ...banner, type: 'banner' })}
                        >
                          <Eye size={16} /> View
                        </button>
                        <button 
                          className="action-btn edit"
                          onClick={() => openModal('edit', { ...banner, type: 'banner' })}
                        >
                          <Edit size={16} /> Edit
                        </button>
                        <button 
                          className="action-btn delete"
                          onClick={() => openModal('delete', { ...banner, type: 'banner' })}
                        >
                          <Trash2 size={16} /> Delete
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )
      default:
        return (
          <div className="section-content">
            {loading && (
              <div className="loading-message">
                <p>Loading dashboard data...</p>
              </div>
            )}
            
            {error && (
              <div className="error-message">
                <p>{error}</p>
                <button onClick={loadData} className="retry-button">Retry</button>
              </div>
            )}
            
            <div className="stats-grid">
              {stats.map((stat, index) => (
                <div key={index} className="stat-card">
                  <div className="stat-icon" style={{ backgroundColor: stat.color }}>
                    <BarChart3 size={24} color="white" />
                  </div>
                  <div className="stat-content">
                    <h3>{stat.value}</h3>
                    <p>{stat.title}</p>
                    <span className="stat-change" style={{ color: stat.color }}>
                      {stat.change}
                    </span>
                  </div>
                </div>
              ))}
            </div>

            <div className="dashboard-grid">
              <div className="dashboard-card">
                <h2>Recent Activities</h2>
                <div className="activities-list">
                  {recentActivities.map((activity, index) => (
                    <div key={index} className="activity-item">
                      <div className={`activity-icon activity-${activity.type}`}>
                        {activity.type === 'user' && <User size={16} />}
                        {activity.type === 'project' && <Folder size={16} />}
                        {activity.type === 'system' && <Settings size={16} />}
                        {activity.type === 'order' && <ShoppingCart size={16} />}
                      </div>
                      <div className="activity-content">
                        <p>{activity.action}</p>
                        <span>{activity.time}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="dashboard-card">
                <h2>Quick Actions</h2>
                <div className="quick-actions">
                  <button className="action-button primary">
                    <Plus size={16} />
                    Create New Project
                  </button>
                  <button className="action-button secondary">
                    <Users size={16} />
                    Manage Users
                  </button>
                  <button className="action-button tertiary">
                    <TrendingUp size={16} />
                    View Analytics
                  </button>
                  <button className="action-button quaternary">
                    <Settings size={16} />
                    System Settings
                  </button>
                </div>
              </div>

              <div className="dashboard-card">
                <h2>System Status</h2>
                <div className="system-status">
                  <div className="status-item">
                    <div className="status-indicator online"></div>
                    <span>API Server</span>
                    <span className="status-text">Online</span>
                  </div>
                  <div className="status-item">
                    <div className="status-indicator online"></div>
                    <span>Database</span>
                    <span className="status-text">Online</span>
                  </div>
                  <div className="status-item">
                    <div className="status-indicator warning"></div>
                    <span>Cache Server</span>
                    <span className="status-text">Warning</span>
                  </div>
                  <div className="status-item">
                    <div className="status-indicator online"></div>
                    <span>File Storage</span>
                    <span className="status-text">Online</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )
    }
  }

  const renderModal = () => {
    if (!showModal || !selectedItem) return null

    const { type } = selectedItem

    return (
      <div className="modal-overlay" onClick={closeModal}>
        <div className="modal-content" onClick={(e) => e.stopPropagation()}>
          <div className="modal-header">
            <h3>
              {modalType === 'add' && `Add New ${type.charAt(0).toUpperCase() + type.slice(1)}`}
              {modalType === 'edit' && `Edit ${type.charAt(0).toUpperCase() + type.slice(1)}`}
              {modalType === 'view' && `View ${type.charAt(0).toUpperCase() + type.slice(1)}`}
              {modalType === 'delete' && `Delete ${type.charAt(0).toUpperCase() + type.slice(1)}`}
            </h3>
            <button className="modal-close" onClick={closeModal}>✕</button>
          </div>
          
          <div className="modal-body">
            {modalType === 'delete' ? (
              <div className="delete-confirmation">
                <p>Are you sure you want to delete this {type}?</p>
                <p><strong>{selectedItem.name}</strong></p>
                <div className="delete-actions">
                  <button className="btn btn-danger" onClick={() => handleDelete(type, selectedItem.id)}>
                    Delete
                  </button>
                  <button className="btn btn-secondary" onClick={closeModal}>
                    Cancel
                  </button>
                </div>
              </div>
            ) : modalType === 'view' ? (
              <div className="view-details">
                {type === 'category' && (
                  <>
                    <div className="detail-item">
                      <label>Name:</label>
                      <span>{selectedItem.name}</span>
                    </div>
                    <div className="detail-item">
                      <label>Description:</label>
                      <span>{selectedItem.description}</span>
                    </div>
                    <div className="detail-item">
                      <label>Product Count:</label>
                      <span>{selectedItem.count} products</span>
                    </div>
                  </>
                )}
                {type === 'subcategory' && (
                  <>
                    <div className="detail-item">
                      <label>Name:</label>
                      <span>{selectedItem.name}</span>
                    </div>
                    <div className="detail-item">
                      <label>Description:</label>
                      <span>{selectedItem.description}</span>
                    </div>
                    <div className="detail-item">
                      <label>Category:</label>
                      <span>{selectedItem.category_name}</span>
                    </div>
                    <div className="detail-item">
                      <label>Product Count:</label>
                      <span>{selectedItem.count} products</span>
                    </div>
                  </>
                )}
                {type === 'product' && (
                  <>
                    <div className="detail-item">
                      <label>Name:</label>
                      <span>{selectedItem.name}</span>
                    </div>
                    <div className="detail-item">
                      <label>Description:</label>
                      <span>{selectedItem.description}</span>
                    </div>
                    <div className="detail-item">
                      <label>Price:</label>
                      <span>${selectedItem.price}</span>
                    </div>
                    <div className="detail-item">
                      <label>Category:</label>
                      <span>{selectedItem.category}</span>
                    </div>
                    <div className="detail-item">
                      <label>Status:</label>
                      <span className={`status-badge ${selectedItem.status}`}>
                        {selectedItem.status}
                      </span>
                    </div>
                    <div className="detail-item">
                      <label>Stock:</label>
                      <span>{selectedItem.stock} units</span>
                    </div>
                    
                    {/* New Metadata Fields */}
                    {selectedItem.ideal_for && (
                      <div className="detail-item">
                        <label>Ideal For:</label>
                        <span>{selectedItem.ideal_for}</span>
                      </div>
                    )}
                    
                    {selectedItem.age_range && (
                      <div className="detail-item">
                        <label>Age Range:</label>
                        <span>{selectedItem.age_range}</span>
                      </div>
                    )}
                    
                    {selectedItem.characters && selectedItem.characters.length > 0 && (
                      <div className="detail-item">
                        <label>Characters:</label>
                        <span>{selectedItem.characters.join(', ')}</span>
                      </div>
                    )}
                    
                    {selectedItem.genre && (
                      <div className="detail-item">
                        <label>Genre:</label>
                        <span>{selectedItem.genre}</span>
                      </div>
                    )}
                    
                    {/* Media Display */}
                    {selectedItem.thumbnail_image && (
                      <div className="detail-item">
                        <label>Thumbnail:</label>
                        <div className="media-display">
                          <img src={selectedItem.thumbnail_image} alt="Thumbnail" style={{width: '150px', height: '150px', objectFit: 'cover'}} />
                        </div>
                      </div>
                    )}
                    
                    {selectedItem.images && selectedItem.images.length > 0 && (
                      <div className="detail-item">
                        <label>Images ({selectedItem.images.length}):</label>
                        <div className="media-gallery">
                          {selectedItem.images.map((img, index) => (
                            <img key={index} src={img} alt={`Product ${index + 1}`} style={{width: '100px', height: '100px', objectFit: 'cover', margin: '5px'}} />
                          ))}
                        </div>
                      </div>
                    )}
                    
                    {selectedItem.videos && selectedItem.videos.length > 0 && (
                      <div className="detail-item">
                        <label>Videos ({selectedItem.videos.length}):</label>
                        <div className="media-gallery">
                          {selectedItem.videos.map((video, index) => (
                            <video key={index} width="120" height="80" controls style={{margin: '5px'}}>
                              <source src={video} type="video/mp4" />
                              Your browser does not support the video tag.
                            </video>
                          ))}
                        </div>
                      </div>
                    )}
                    
                    {selectedItem.preview_video && (
                      <div className="detail-item">
                        <label>Preview Video:</label>
                        <div className="media-display">
                          <video width="250" height="150" controls>
                            <source src={selectedItem.preview_video} type="video/mp4" />
                            Your browser does not support the video tag.
                          </video>
                        </div>
                      </div>
                    )}
                  </>
                )}
                {type === 'user' && (
                  <>
                    <div className="detail-item">
                      <label>Name:</label>
                      <span>{selectedItem.name}</span>
                    </div>
                    <div className="detail-item">
                      <label>Email:</label>
                      <span>{selectedItem.email}</span>
                    </div>
                    <div className="detail-item">
                      <label>Role:</label>
                      <span className={`role-badge ${selectedItem.role}`}>
                        {selectedItem.role}
                      </span>
                    </div>
                    <div className="detail-item">
                      <label>Status:</label>
                      <span className={`status-badge ${selectedItem.status}`}>
                        {selectedItem.status}
                      </span>
                    </div>
                    <div className="detail-item">
                      <label>Join Date:</label>
                      <span>{selectedItem.joinDate}</span>
                    </div>
                  </>
                )}
                {type === 'banner' && (
                  <>
                    <div className="detail-item">
                      <label>Title:</label>
                      <span>{selectedItem.title}</span>
                    </div>
                    <div className="detail-item">
                      <label>Description:</label>
                      <span>{selectedItem.description}</span>
                    </div>
                    <div className="detail-item">
                      <label>Status:</label>
                      <span className={`status-badge ${selectedItem.status}`}>
                        {selectedItem.status}
                      </span>
                    </div>
                    <div className="detail-item">
                      <label>Start Date:</label>
                      <span>{selectedItem.startDate}</span>
                    </div>
                    <div className="detail-item">
                      <label>End Date:</label>
                      <span>{selectedItem.endDate}</span>
                    </div>
                  </>
                )}
              </div>
            ) : (
              <form className="modal-form" onSubmit={(e) => e.preventDefault()}>
                {type === 'category' && (
                  <>
                    <div className="form-group">
                      <label>Category Name</label>
                      <input 
                        type="text" 
                        value={formData.name || ''}
                        onChange={(e) => handleInputChange('name', e.target.value)}
                        placeholder="Enter category name"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <textarea 
                        value={formData.description || ''}
                        onChange={(e) => handleInputChange('description', e.target.value)}
                        placeholder="Enter category description"
                        rows="3"
                      />
                    </div>
                  </>
                )}
                {type === 'subcategory' && (
                  <>
                    <div className="form-group">
                      <label>Subcategory Name</label>
                      <input 
                        type="text" 
                        value={formData.name || ''}
                        onChange={(e) => handleInputChange('name', e.target.value)}
                        placeholder="Enter subcategory name"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <textarea 
                        value={formData.description || ''}
                        onChange={(e) => handleInputChange('description', e.target.value)}
                        placeholder="Enter subcategory description"
                        rows="3"
                      />
                    </div>
                    {modalType === 'add' && (
                      <div className="form-group">
                        <label>Category</label>
                        <select 
                          value={formData.category_id || ''}
                          onChange={(e) => handleInputChange('category_id', e.target.value)}
                          required
                        >
                          <option value="">Select category</option>
                          {categories.map(cat => (
                            <option key={cat.id} value={cat.id}>{cat.name}</option>
                          ))}
                        </select>
                      </div>
                    )}
                    {modalType === 'edit' && (
                      <div className="form-group">
                        <label>Category</label>
                        <input 
                          type="text" 
                          value={formData.category_name || ''}
                          disabled
                          style={{ backgroundColor: '#f5f5f5', cursor: 'not-allowed' }}
                        />
                        <small style={{ color: '#666', fontSize: '12px' }}>
                          Category cannot be changed when editing
                        </small>
                      </div>
                    )}
                  </>
                )}
                {type === 'product' && (
                  <>
                    <div className="form-group">
                      <label>Product Name</label>
                      <input 
                        type="text" 
                        value={formData.name || ''}
                        onChange={(e) => handleInputChange('name', e.target.value)}
                        placeholder="Enter product name"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <textarea 
                        value={formData.description || ''}
                        onChange={(e) => handleInputChange('description', e.target.value)}
                        placeholder="Enter product description"
                        rows="3"
                      />
                    </div>
                    <div className="form-group">
                      <label>Price</label>
                      <input 
                        type="number" 
                        step="0.01"
                        value={formData.price || ''}
                        onChange={(e) => handleInputChange('price', e.target.value)}
                        placeholder="Enter price"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Category</label>
                      <select 
                        value={formData.category || ''}
                        onChange={(e) => {
                          handleInputChange('category', e.target.value)
                          // Reset subcategory when category changes
                          handleInputChange('subcategory_id', '')
                        }}
                        required
                      >
                        <option value="">Select category</option>
                        {categories.map(cat => (
                          <option key={cat.id} value={cat.name}>{cat.name}</option>
                        ))}
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Subcategory (Optional)</label>
                      <select 
                        value={formData.subcategory_id || ''}
                        onChange={(e) => handleInputChange('subcategory_id', e.target.value)}
                        disabled={!formData.category}
                      >
                        <option value="">Select subcategory</option>
                        {formData.category && subcategories
                          .filter(subcat => {
                            const selectedCategory = categories.find(cat => cat.name === formData.category)
                            return selectedCategory && subcat.category_id === selectedCategory.id
                          })
                          .map(subcat => (
                            <option key={subcat.id} value={subcat.id}>{subcat.name}</option>
                          ))
                        }
                      </select>
                      {!formData.category && (
                        <small style={{ color: '#666', fontSize: '12px' }}>
                          Please select a category first
                        </small>
                      )}
                    </div>
                    <div className="form-group">
                      <label>Stock</label>
                      <input 
                        type="number" 
                        value={formData.stock || ''}
                        onChange={(e) => handleInputChange('stock', e.target.value)}
                        placeholder="Enter stock quantity"
                      />
                    </div>
                    
                    {/* New Product Metadata Fields */}
                    <div className="form-group">
                      <label>Ideal For</label>
                      <input 
                        type="text" 
                        value={formData.ideal_for || ''}
                        onChange={(e) => handleInputChange('ideal_for', e.target.value)}
                        placeholder="e.g., Boys, Girls, Kids, Toddlers, Teens, Everyone"
                      />
                      <small style={{ color: '#666', fontSize: '12px' }}>
                        Enter target audience (e.g., Boys, Girls, Kids, Everyone)
                      </small>
                    </div>
                    
                    <div className="form-group">
                      <label>Age Range</label>
                      <select 
                        value={formData.age_range || ''}
                        onChange={(e) => handleInputChange('age_range', e.target.value)}
                      >
                        <option value="">Select age range</option>
                        <option value="0-2 years old">0-2 years old</option>
                        <option value="3-5 years old">3-5 years old</option>
                        <option value="6-8 years old">6-8 years old</option>
                        <option value="9-12 years old">9-12 years old</option>
                        <option value="13+ years old">13+ years old</option>
                        <option value="All ages">All ages</option>
                      </select>
                    </div>
                    
                    <div className="form-group">
                      <label>Characters (comma-separated)</label>
                      <input 
                        type="text" 
                        value={Array.isArray(formData.characters) ? formData.characters.join(', ') : ''}
                        onChange={(e) => {
                          const chars = e.target.value.split(',').map(c => c.trim()).filter(c => c)
                          handleInputChange('characters', chars)
                        }}
                        placeholder="e.g., Hero, Villain, Sidekick"
                      />
                      <small style={{ color: '#666', fontSize: '12px' }}>
                        Enter character names separated by commas
                      </small>
                    </div>
                    
                    <div className="form-group">
                      <label>Genre</label>
                      <input 
                        type="text" 
                        value={formData.genre || ''}
                        onChange={(e) => handleInputChange('genre', e.target.value)}
                        placeholder="e.g., Adventure, Fantasy, Educational, Mystery"
                      />
                      <small style={{ color: '#666', fontSize: '12px' }}>
                        Enter book genre (e.g., Adventure & Exploration, Fantasy, Educational)
                      </small>
                    </div>
                    
                    {/* Media Upload Section */}
                    <div className="media-section">
                      <h4>Product Media</h4>
                      
                      <div className="form-group">
                        <label>Thumbnail Image</label>
                        <input 
                          type="file" 
                          accept="image/*"
                          onChange={(e) => handleFileUpload(e, 'thumbnail_image')}
                          disabled={uploadingMedia}
                        />
                        {formData.thumbnail_image && (
                          <div className="media-preview">
                            <img src={formData.thumbnail_image} alt="Thumbnail" style={{width: '100px', height: '100px', objectFit: 'cover'}} />
                            <button 
                              type="button" 
                              className="remove-media-btn"
                              onClick={() => handleInputChange('thumbnail_image', '')}
                            >
                              ❌
                            </button>
                          </div>
                        )}
                      </div>
                      
                      <div className="form-group">
                        <label>Product Images</label>
                        <input 
                          type="file" 
                          accept="image/*"
                          multiple
                          onChange={(e) => handleFileUpload(e, 'images')}
                          disabled={uploadingMedia}
                        />
                        {formData.images && formData.images.length > 0 && (
                          <div className="media-preview">
                            {formData.images.map((img, index) => (
                              <div key={index} className="image-preview-item">
                                <img src={img} alt={`Product ${index + 1}`} style={{width: '80px', height: '80px', objectFit: 'cover', margin: '5px'}} />
                                <button 
                                  type="button" 
                                  className="remove-media-btn"
                                  onClick={() => removeMedia('images', index)}
                                >
                                  ❌
                                </button>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                      
                      <div className="form-group">
                        <label>Product Videos</label>
                        <input 
                          type="file" 
                          accept="video/*"
                          multiple
                          onChange={(e) => handleFileUpload(e, 'videos')}
                          disabled={uploadingMedia}
                        />
                        {formData.videos && formData.videos.length > 0 && (
                          <div className="media-preview">
                            {formData.videos.map((video, index) => (
                              <div key={index} className="video-preview-item">
                                <video width="120" height="80" controls>
                                  <source src={video} type="video/mp4" />
                                  Your browser does not support the video tag.
                                </video>
                                <button 
                                  type="button" 
                                  className="remove-media-btn"
                                  onClick={() => removeMedia('videos', index)}
                                >
                                  ❌
                                </button>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                      
                      <div className="form-group">
                        <label>Preview Video (Main)</label>
                        <input 
                          type="file" 
                          accept="video/*"
                          onChange={(e) => handleFileUpload(e, 'preview_video')}
                          disabled={uploadingMedia}
                        />
                        {formData.preview_video && (
                          <div className="media-preview">
                            <video width="200" height="120" controls>
                              <source src={formData.preview_video} type="video/mp4" />
                              Your browser does not support the video tag.
                            </video>
                            <button 
                              type="button" 
                              className="remove-media-btn"
                              onClick={() => handleInputChange('preview_video', '')}
                            >
                              ❌
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                    
                    <div className="form-group">
                      <label>Status</label>
                      <select 
                        value={formData.status || 'active'}
                        onChange={(e) => handleInputChange('status', e.target.value)}
                      >
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                  </>
                )}
                {type === 'user' && (
                  <>
                    <div className="form-group">
                      <label>Full Name</label>
                      <input 
                        type="text" 
                        value={formData.name || ''}
                        onChange={(e) => handleInputChange('name', e.target.value)}
                        placeholder="Enter full name"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Email</label>
                      <input 
                        type="email" 
                        value={formData.email || ''}
                        onChange={(e) => handleInputChange('email', e.target.value)}
                        placeholder="Enter email address"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Role</label>
                      <select 
                        value={formData.role || 'user'}
                        onChange={(e) => handleInputChange('role', e.target.value)}
                      >
                        <option value="user">User</option>
                        <option value="moderator">Moderator</option>
                        <option value="admin">Admin</option>
                      </select>
                    </div>
                    <div className="form-group">
                      <label>Status</label>
                      <select 
                        value={formData.status || 'active'}
                        onChange={(e) => handleInputChange('status', e.target.value)}
                      >
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                  </>
                )}
                {type === 'banner' && (
                  <>
                    <div className="form-group">
                      <label>Banner Title</label>
                      <input 
                        type="text" 
                        value={formData.title || ''}
                        onChange={(e) => handleInputChange('title', e.target.value)}
                        placeholder="Enter banner title"
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Description</label>
                      <textarea 
                        value={formData.description || ''}
                        onChange={(e) => handleInputChange('description', e.target.value)}
                        placeholder="Enter banner description"
                        rows="3"
                      />
                    </div>
                    <div className="form-group">
                      <label>Start Date</label>
                      <input 
                        type="date" 
                        value={formData.startDate || ''}
                        onChange={(e) => handleInputChange('startDate', e.target.value)}
                      />
                    </div>
                    <div className="form-group">
                      <label>End Date</label>
                      <input 
                        type="date" 
                        value={formData.endDate || ''}
                        onChange={(e) => handleInputChange('endDate', e.target.value)}
                      />
                    </div>
                    <div className="form-group">
                      <label>Status</label>
                      <select 
                        value={formData.status || 'active'}
                        onChange={(e) => handleInputChange('status', e.target.value)}
                      >
                        <option value="active">Active</option>
                        <option value="inactive">Inactive</option>
                      </select>
                    </div>
                  </>
                )}
                <div className="form-actions">
                  <button 
                    type="button" 
                    className="btn btn-primary" 
                    onClick={handleSave}
                    disabled={uploadingMedia}
                  >
                    {uploadingMedia ? 'Uploading...' : (modalType === 'add' ? 'Add' : 'Save Changes')}
                  </button>
                  <button type="button" className="btn btn-secondary" onClick={closeModal}>
                    Cancel
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      </div>
    )
  }

  const stats = [
    { 
      title: t('dashboard.totalUsers'), 
      value: dashboardStats.total_users?.toString() || '0', 
      change: '+12%', 
      color: '#4f46e5' 
    },
    { 
      title: t('dashboard.totalBooks'), 
      value: dashboardStats.total_books?.toString() || '0', 
      change: '+8%', 
      color: '#059669' 
    },
    { 
      title: t('dashboard.totalOrders'), 
      value: dashboardStats.total_orders?.toString() || '0', 
      change: '+23%', 
      color: '#dc2626' 
    },
    { 
      title: t('dashboard.totalRevenue'), 
      value: `$${dashboardStats.total_revenue ? parseFloat(dashboardStats.total_revenue).toFixed(2) : '0.00'}`, 
      change: '+15%', 
      color: '#7c3aed' 
    }
  ]

  const recentActivities = [
    { action: 'New user registered', time: '2 minutes ago', type: 'user' },
    { action: 'Project "AI Analytics" completed', time: '1 hour ago', type: 'project' },
    { action: 'System backup completed', time: '3 hours ago', type: 'system' },
    { action: 'New order received', time: '5 hours ago', type: 'order' },
    { action: 'Database optimization completed', time: '1 day ago', type: 'system' }
  ]

  return (
    <div className="dashboard-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <h2>AI Project</h2>
        </div>
        
        <nav className="sidebar-nav">
          {sidebarItems.map((item) => (
            <button
              key={item.id}
              className={`nav-item ${activeSection === item.id ? 'active' : ''}`}
              onClick={() => setActiveSection(item.id)}
            >
              <span className="nav-icon">
                <item.icon size={20} />
              </span>
              <span className="nav-label">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <LanguageSelector />
          <div className="theme-toggle">
            <span className="theme-label">{t('nav.theme')}</span>
            <button 
              className={`toggle-switch ${isDarkMode ? 'dark' : 'light'}`}
              onClick={toggleTheme}
            >
              <span className="toggle-slider">
                {isDarkMode ? <Moon size={16} /> : <Sun size={16} />}
              </span>
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <div className="main-content">
        <header className="dashboard-header">
          <div className="header-content">
            <h1>
              {activeSection.charAt(0).toUpperCase() + activeSection.slice(1)}
            </h1>
            <div className="user-info">
              <span>{t('common.welcome')}, {userEmail}</span>
              <button onClick={handleLogout} className="logout-button">
                {t('common.logout')}
              </button>
            </div>
          </div>
        </header>

        <main className="dashboard-main">
          {schemaWarning && (
            <div className="schema-warning-banner" style={{
              background: 'linear-gradient(90deg, #f59e0b, #f97316)',
              color: 'white',
              padding: '12px 20px',
              margin: '0 0 20px 0',
              borderRadius: '8px',
              fontWeight: '500',
              boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
            }}>
              <Clipboard size={16} style={{ display: 'inline', marginRight: '8px' }} />
              <strong>Database Update Required:</strong> To use media features (images/videos), please run the database migration script in your Supabase SQL editor. 
              <a 
                href="#" 
                onClick={() => setSchemaWarning(false)}
                style={{ 
                  color: 'white', 
                  textDecoration: 'underline', 
                  marginLeft: '10px',
                  fontSize: '14px'
                }}
              >
                Dismiss
              </a>
            </div>
          )}
          {renderContent()}
        </main>
      </div>

      {/* Modal */}
      {renderModal()}
    </div>
  )
}

export default Dashboard
