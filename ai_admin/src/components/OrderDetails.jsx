import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Package, Truck, CheckCircle, XCircle } from 'react-feather';
import { supabase } from '../supabaseClient';
import { toast } from 'react-toastify';

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
    return <div className="loading">Loading order details...</div>;
  }

  if (!order) {
    return <div className="error">Order not found</div>;
  }

  return (
    <div className="order-details-page">
      <div className="page-header">
        <button className="back-button" onClick={() => navigate(-1)}>
          <ArrowLeft size={20} /> Back to Orders
        </button>
        <h2>Order #{order.order_number}</h2>
      </div>

      <div className="order-details-grid">
        {/* Order Summary */}
        <div className="details-card">
          <h3>Order Summary</h3>
          <div className="order-summary">
            <div className="summary-row">
              <span>Order Date:</span>
              <span>{new Date(order.created_at).toLocaleString()}</span>
            </div>
            <div className="summary-row">
              <span>Status:</span>
              <select
                value={order.status}
                onChange={(e) => updateOrderStatus(e.target.value)}
                className={`status-select ${order.status}`}
              >
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="shipped">Shipped</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
            <div className="summary-row">
              <span>Payment Status:</span>
              <span className={`payment-status ${order.payment_status}`}>
                {order.payment_status}
              </span>
            </div>
            <div className="summary-row">
              <span>Payment Method:</span>
              <span>{order.payment_method}</span>
            </div>
            <div className="summary-row">
              <span>Total Amount:</span>
              <span className="total-amount">${order.total_amount}</span>
            </div>
          </div>
        </div>

        {/* Customer Information */}
        <div className="details-card">
          <h3>Customer Information</h3>
          <div className="customer-details">
            <div className="detail-row">
              <span>Name:</span>
              <span>{order.customer.first_name} {order.customer.last_name}</span>
            </div>
            <div className="detail-row">
              <span>Email:</span>
              <span>{order.customer.email}</span>
            </div>
            <div className="detail-row">
              <span>Phone:</span>
              <span>{order.customer.phone || 'N/A'}</span>
            </div>
          </div>

          <h4>Shipping Address</h4>
          <div className="address-details">
            <p>{order.shipping_address.street}</p>
            <p>{order.shipping_address.city}, {order.shipping_address.state}</p>
            <p>{order.shipping_address.postal_code}</p>
            <p>{order.shipping_address.country}</p>
          </div>

          <h4>Billing Address</h4>
          <div className="address-details">
            <p>{order.billing_address.street}</p>
            <p>{order.billing_address.city}, {order.billing_address.state}</p>
            <p>{order.billing_address.postal_code}</p>
            <p>{order.billing_address.country}</p>
          </div>
        </div>

        {/* Order Items */}
        <div className="details-card full-width">
          <h3>Order Items</h3>
          <div className="order-items-table">
            <table>
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
                        <div>
                          <div className="product-name">{item.product.name}</div>
                          <div className="product-sku">SKU: {item.product.id}</div>
                        </div>
                      </div>
                    </td>
                    <td>{item.quantity}</td>
                    <td>${item.unit_price}</td>
                    <td>${item.total_price}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr>
                  <td colSpan="3" align="right">Total:</td>
                  <td>${order.total_amount}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </div>

        {/* Order Timeline */}
        <div className="details-card">
          <h3>Order Timeline</h3>
          <div className="order-timeline">
            <div className={`timeline-item ${order.status === 'pending' ? 'active' : ''}`}>
              <Package size={20} />
              <div>
                <h4>Order Placed</h4>
                <p>Order has been placed</p>
              </div>
            </div>
            <div className={`timeline-item ${order.status === 'processing' ? 'active' : ''}`}>
              <Package size={20} />
              <div>
                <h4>Processing</h4>
                <p>Order is being processed</p>
              </div>
            </div>
            <div className={`timeline-item ${order.status === 'shipped' ? 'active' : ''}`}>
              <Truck size={20} />
              <div>
                <h4>Shipped</h4>
                <p>Order has been shipped</p>
              </div>
            </div>
            <div className={`timeline-item ${order.status === 'delivered' ? 'active' : ''}`}>
              <CheckCircle size={20} />
              <div>
                <h4>Delivered</h4>
                <p>Order has been delivered</p>
              </div>
            </div>
            {order.status === 'cancelled' && (
              <div className="timeline-item active cancelled">
                <XCircle size={20} />
                <div>
                  <h4>Cancelled</h4>
                  <p>Order has been cancelled</p>
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
