import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Package, Truck, CheckCircle, XCircle, Calendar, CreditCard, User, MapPin } from 'react-feather';
import { supabase } from '../supabaseClient';
import { toast } from 'react-toastify';
import './OrderDetails.css';

const OrderDetails = () => {
  const { orderId } = useParams();
  const navigate = useNavigate();
  const [order, setOrder] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadOrderDetails();
  }, [orderId]);

  const loadOrderDetails = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('orders')
        .select(`
          *,
          customer:customers(*),
          items:order_items(
            *,
            product:products(*)
          )
        `)
        .eq('id', orderId)
        .single();

      if (error) throw error;
      setOrder(data);
    } catch (error) {
      console.error('Error loading order details:', error);
      toast.error('Failed to load order details');
    } finally {
      setLoading(false);
    }
  };

  const updateOrderStatus = async (newStatus) => {
    try {
      const { error } = await supabase
        .from('orders')
        .update({ status: newStatus })
        .eq('id', orderId);

      if (error) throw error;
      toast.success('Order status updated successfully');
      loadOrderDetails();
    } catch (error) {
      console.error('Error updating order status:', error);
      toast.error('Failed to update order status');
    }
  };

  if (loading) {
    return (
      <div className="order-details-page">
        <div className="loading-container">
          <div className="loading-text">Loading order details...</div>
        </div>
      </div>
    );
  }

  if (!order) {
    return (
      <div className="order-details-page">
        <div className="error-container">
          <div className="error-text">Order not found</div>
        </div>
      </div>
    );
  }

  return (
    <div className="order-details-page">
      <div className="order-details-container">
        {/* Header Section */}
        <div className="order-header">
          <div className="header-top">
            <button className="back-button" onClick={() => navigate(-1)}>
              <ArrowLeft size={18} />
              Back to Orders
            </button>
            <h1 className="order-title">Order #{order.order_number}</h1>
          </div>
          
          <div className="order-meta">
            <div className="meta-item">
              <Calendar size={16} />
              <span className="meta-label">Order Date:</span>
              <span className="meta-value">{new Date(order.created_at).toLocaleDateString()}</span>
            </div>
            
            <div className="meta-item">
              <Package size={16} />
              <span className="meta-label">Status:</span>
              <span className={`status-badge ${order.status}`}>
                {order.status}
              </span>
            </div>
            
            <div className="meta-item">
              <CreditCard size={16} />
              <span className="meta-label">Payment:</span>
              <span className={`payment-status ${order.payment_status}`}>
                {order.payment_status}
              </span>
            </div>
            
            <div className="meta-item">
              <span className="meta-label">Total:</span>
              <span className="total-amount">${order.total_amount}</span>
            </div>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="order-content-grid">
          {/* Order Management Card */}
          <div className="details-card">
            <div className="card-header">
              <h3 className="card-title">Order Management</h3>
              <div className="card-action">
                <Package size={18} />
              </div>
            </div>
            
            <div className="order-summary">
              <div className="summary-row">
                <span className="summary-label">Order Status</span>
                <select
                  value={order.status}
                  onChange={(e) => updateOrderStatus(e.target.value)}
                  className="status-select"
                >
                  <option value="pending">Pending</option>
                  <option value="processing">Processing</option>
                  <option value="shipped">Shipped</option>
                  <option value="delivered">Delivered</option>
                  <option value="cancelled">Cancelled</option>
                </select>
              </div>
              
              <div className="summary-row">
                <span className="summary-label">Payment Status</span>
                <span className={`payment-status ${order.payment_status}`}>
                  {order.payment_status}
                </span>
              </div>
              
              <div className="summary-row">
                <span className="summary-label">Payment Method</span>
                <span className="summary-value">{order.payment_method}</span>
              </div>
              
              <div className="summary-row">
                <span className="summary-label">Order Date</span>
                <span className="summary-value">
                  {new Date(order.created_at).toLocaleDateString()} at {new Date(order.created_at).toLocaleTimeString()}
                </span>
              </div>
              
              <div className="summary-row">
                <span className="summary-label">Total Amount</span>
                <span className="total-amount">${order.total_amount}</span>
              </div>
            </div>
          </div>

          {/* Customer Information Card */}
          <div className="details-card">
            <div className="card-header">
              <h3 className="card-title">Customer Information</h3>
              <div className="card-action">
                <User size={18} />
              </div>
            </div>
            
            <div className="customer-section">
              <div className="customer-details">
                <div className="detail-row">
                  <span className="detail-label">Name:</span>
                  <span className="detail-value">
                    {order.customer.first_name} {order.customer.last_name}
                  </span>
                </div>
                
                <div className="detail-row">
                  <span className="detail-label">Email:</span>
                  <span className="detail-value">{order.customer.email}</span>
                </div>
                
                <div className="detail-row">
                  <span className="detail-label">Phone:</span>
                  <span className="detail-value">{order.customer.phone || 'Not provided'}</span>
                </div>
              </div>

              <div className="address-section">
                <div className="address-header">
                  <MapPin size={16} style={{ display: 'inline', marginRight: '8px' }} />
                  Shipping Address
                </div>
                <div className="address-details">
                  <p>{order.shipping_address.street}</p>
                  <p>{order.shipping_address.city}, {order.shipping_address.state}</p>
                  <p>{order.shipping_address.postal_code}</p>
                  <p>{order.shipping_address.country}</p>
                </div>
              </div>

              <div className="address-section">
                <div className="address-header">
                  <CreditCard size={16} style={{ display: 'inline', marginRight: '8px' }} />
                  Billing Address
                </div>
                <div className="address-details">
                  <p>{order.billing_address.street}</p>
                  <p>{order.billing_address.city}, {order.billing_address.state}</p>
                  <p>{order.billing_address.postal_code}</p>
                  <p>{order.billing_address.country}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Order Items Section */}
        <div className="details-card order-content-full">
          <div className="card-header">
            <h3 className="card-title">Order Items</h3>
            <div className="card-action">
              <Package size={18} />
              <span style={{ fontSize: '14px', color: '#64748b' }}>
                {order.items.length} item{order.items.length !== 1 ? 's' : ''}
              </span>
            </div>
          </div>
          
          <div className="order-items-container">
            <table className="order-items-table">
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Quantity</th>
                  <th>Unit Price</th>
                  <th>Total</th>
                </tr>
              </thead>
              <tbody>
                {order.items.map((item) => (
                  <tr key={item.id}>
                    <td>
                      <div className="product-info">
                        {item.product.thumbnail_image && (
                          <img 
                            src={item.product.thumbnail_image} 
                            alt={item.product.name}
                            className="product-thumbnail"
                          />
                        )}
                        <div className="product-details">
                          <div className="product-name">{item.product.name}</div>
                          <div className="product-sku">SKU: {item.product.id}</div>
                        </div>
                      </div>
                    </td>
                    <td className="quantity-cell">{item.quantity}</td>
                    <td className="price-cell">${item.unit_price}</td>
                    <td className="price-cell">${item.total_price}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="total-row">
                  <td colSpan="3" className="total-label">Order Total:</td>
                  <td className="total-value">${order.total_amount}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        {/* Order Timeline Section */}
        <div className="details-card order-content-full">
          <div className="card-header">
            <h3 className="card-title">Order Timeline</h3>
            <div className="card-action">
              <Truck size={18} />
            </div>
          </div>
          
          <div className="order-timeline">
            <div className={`timeline-item ${['pending', 'processing', 'shipped', 'delivered'].includes(order.status) ? 'completed' : ''}`}>
              <div className="timeline-icon">
                <Package size={20} />
              </div>
              <div className="timeline-content">
                <h4 className="timeline-title">Order Placed</h4>
                <p className="timeline-description">
                  Your order has been placed and is being prepared for processing.
                </p>
              </div>
            </div>

            <div className={`timeline-item ${['processing', 'shipped', 'delivered'].includes(order.status) ? 'completed' : order.status === 'processing' ? 'active' : ''}`}>
              <div className="timeline-icon">
                <Package size={20} />
              </div>
              <div className="timeline-content">
                <h4 className="timeline-title">Processing</h4>
                <p className="timeline-description">
                  Your order is being processed and prepared for shipment.
                </p>
              </div>
            </div>

            <div className={`timeline-item ${['shipped', 'delivered'].includes(order.status) ? 'completed' : order.status === 'shipped' ? 'active' : ''}`}>
              <div className="timeline-icon">
                <Truck size={20} />
              </div>
              <div className="timeline-content">
                <h4 className="timeline-title">Shipped</h4>
                <p className="timeline-description">
                  Your order has been shipped and is on its way to you.
                </p>
              </div>
            </div>

            <div className={`timeline-item ${order.status === 'delivered' ? 'completed active' : ''}`}>
              <div className="timeline-icon">
                <CheckCircle size={20} />
              </div>
              <div className="timeline-content">
                <h4 className="timeline-title">Delivered</h4>
                <p className="timeline-description">
                  Your order has been successfully delivered.
                </p>
              </div>
            </div>

            {order.status === 'cancelled' && (
              <div className="timeline-item cancelled active">
                <div className="timeline-icon">
                  <XCircle size={20} />
                </div>
                <div className="timeline-content">
                  <h4 className="timeline-title">Cancelled</h4>
                  <p className="timeline-description">
                    This order has been cancelled and will not be processed.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default OrderDetails;
