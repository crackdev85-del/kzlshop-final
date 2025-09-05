// src/App.jsx
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { initializeApp } from 'firebase/app';

import {
  getFirestore,
  collection,
  onSnapshot,
  doc,
  addDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  getDocs,
  getDoc,
  runTransaction
} from 'firebase/firestore';
import {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  GoogleAuthProvider,
  signInWithPopup,
  signOut,
  onAuthStateChanged
} from 'firebase/auth';
import './app.css';

// --- Config ---
const appId = import.meta.env.VITE_APP_ID ?? (typeof __app_id !== 'undefined' ? __app_id : 'default-app-id');
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY ?? "",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN ?? "",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID ?? "",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ?? "",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID ?? "",
  appId: import.meta.env.VITE_FIREBASE_APP_ID ?? ""
};

const PRODUCTS_COLLECTION_PATH = `artifacts/${appId}/public/data/products`;
const CATEGORIES_COLLECTION_PATH = `artifacts/${appId}/public/data/categories`;
const TOWNSHIPS_COLLECTION_PATH = `artifacts/${appId}/public/data/townships`;
const ANNOUNCEMENTS_COLLECTION_PATH = `artifacts/${appId}/public/data/announcements`;
const USERS_COLLECTION_PATH = `artifacts/${appId}/public/data/users`;

// SETTINGS: single doc to hold shop name, logo and splash
const SETTINGS_COLLECTION_PATH = `artifacts/${appId}/public/data/settings`;
const SETTINGS_DOC_ID = 'meta';

/* -------------------------
   Helpers
   ------------------------- */
const formatDate = (iso) => {
  try {
    if (!iso) return 'Unknown';
    const d = new Date(iso);
    if (isNaN(d.getTime())) return 'Unknown';
    return d.toISOString().slice(0, 10);
  } catch { return 'Unknown'; }
};
const fileToDataUrl = (file) => new Promise((resolve, reject) => {
  const reader = new FileReader();
  reader.onload = () => resolve(reader.result);
  reader.onerror = reject;
  reader.readAsDataURL(file);
});

/* -------------------------
   Small UI components (LOGIN / SIGNUP updated for Email/Google auth)
   ------------------------- */

const LoginForm = ({ onLogin, onGoogleLogin, switchToSignup }) => {
  const [identifier, setIdentifier] = useState(''); // email or username
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const ok = await onLogin(identifier.trim(), password);
      if (!ok) setError('Email/username သို့မဟုတ် password မမှန်ပါ။');
    } catch (err) {
      console.error(err);
      setError('Login မအောင်မြင်ပါ');
    } finally { setLoading(false); }
  };

  return (
    <div className="auth-card" style={{ maxWidth: 420 }}>
      <h2 className="auth-title">Login</h2>
      {error && <div className="error-box">{error}</div>}
      <form onSubmit={submit} className="auth-form">
        <label className="label">Email or Username</label>
        <input className="input" value={identifier} onChange={(e) => setIdentifier(e.target.value)} required />
        <label className="label">Password</label>
        <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          <button className="btn btn-primary" type="submit" disabled={loading}>{loading ? 'Signing in...' : 'Sign in'}</button>
          <button type="button" className="btn btn-secondary" onClick={switchToSignup}>Create account</button>
        </div>
      </form>

      <div style={{ marginTop: 12 }}>
        <div style={{ marginBottom: 8 }} className="muted">Or sign in with</div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary" onClick={onGoogleLogin}>Sign in with Google</button>
        </div>
      </div>
    </div>
  );
};

/* Updated SignupForm: accepts townships prop and stores township on create */
const SignupForm = ({ onSubmit, switchToLogin, submitLabel = 'Sign up', defaultRole = 'user', info, townships = [] }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [username, setUsername] = useState('');
  const [shopName, setShopName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [address, setAddress] = useState('');
  const [location, setLocation] = useState(''); // can be address or "lat,lng"
  const [township, setTownship] = useState(''); // NEW: township selection
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const [gpsLoading, setGpsLoading] = useState(false);

  useEffect(() => {
    // If townships prop has entries and no township selected yet, optionally set default
    if (!township && townships && townships.length > 0) {
      // leave blank to force user to choose, do not auto-select
    }
  }, [townships]);

  const requestCurrentLocation = () => {
    if (!navigator.geolocation) return setError('Geolocation မရရှိနိုင်ပါ။');
    setError('');
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition((pos) => {
      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const coords = `${lat.toFixed(6)},${lng.toFixed(6)}`;
      setLocation(coords);
      setGpsLoading(false);
    }, (err) => {
      console.error('Geolocation error', err);
      setError('GPS ရယူမရပါ (permission denied သို့မဟုတ် error)။');
      setGpsLoading(false);
    }, { enableHighAccuracy: true, timeout: 10000 });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!email || !password) return setError('Email နှင့် password ထည့်ပါ။');
    if (password.length < 6) return setError('Password သည် အနည်းဆုံး 6 အက္ခရာ ဖြစ်ရမည်။');

    if (!shopName.trim()) return setError('ဆိုင်အမည် ထည့်ရန်လိုအပ်သည် (required)');
    if (!phoneNumber.trim()) return setError('ဖုန်းနံပါတ် ထည့်ရန်လိုအပ်သည် (required)');
    if (!address.trim()) return setError('လိပ်စာ ထည့်ရန်လိုအပ်သည် (required)');
    if (!location.trim()) return setError('Location / Map address ထည့်ရန်လိုအပ်သည် (required)');
    if (!township || township.trim() === '') return setError('မြို့နယ် (Township) ကိုရွေးချယ်ပါ။'); // NEW validation

    setLoading(true);
    try {
      const success = await onSubmit({
        email: email.trim(),
        password,
        username: username.trim(),
        role: defaultRole,
        shopName: shopName.trim(),
        phoneNumber: phoneNumber.trim(),
        address: address.trim(),
        location: location.trim(),
        township: township.trim() // NEW: include township
      });
      if (!success) setError('Account ဖန်တီး၍ မရပါ — email ရှိပြီးသားဖြစ်နိုင်သည်။');
    } catch (err) {
      console.error(err);
      setError('Signup failed');
    } finally { setLoading(false); }
  };

  return (
    <div className="auth-card" style={{ maxWidth: 520 }}>
      <h2 className="auth-title">{submitLabel}</h2>
      {info && <p className="brand-sub">{info}</p>}
      {error && <div className="error-box">{error}</div>}
      <form onSubmit={handleSubmit} className="auth-form">
        <label className="label">Email</label>
        <input className="input" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <label className="label">Password</label>
        <input className="input" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
        <label className="label">Username (display name)</label>
        <input className="input" value={username} onChange={(e) => setUsername(e.target.value)} />

        <label className="label">ဆိုင်အမည် (required)</label>
        <input className="input" value={shopName} onChange={(e) => setShopName(e.target.value)} required />

        <label className="label">ဖုန်းနံပါတ် (required)</label>
        <input className="input" value={phoneNumber} onChange={(e) => setPhoneNumber(e.target.value)} required />

        <label className="label">လိပ်စာ (required)</label>
        <textarea className="input textarea" rows={2} value={address} onChange={(e) => setAddress(e.target.value)} required />

        <label className="label">Location / Map address (required)</label>
        <input className="input" placeholder="e.g. 16.813100,96.149500 OR No.123, Yangon" value={location} onChange={(e) => setLocation(e.target.value)} required />

        <label className="label">မြို့နယ်ရွေးရန် (Township)</label>
        <select className="input" value={township} onChange={(e) => setTownship(e.target.value)} required>
          <option value="">-- မြို့နယ်ရွေးရန် --</option>
          {townships && townships.map(t => (
            <option key={t.id || t.name} value={t.name || t.id}>{t.name}</option>
          ))}
        </select>

        <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 8 }}>
          <button type="button" className="btn btn-secondary" onClick={requestCurrentLocation} disabled={gpsLoading}>
            {gpsLoading ? 'Getting location...' : 'Use my current location'}
          </button>
          <div className="muted" style={{ fontSize: 13 }}>
            Sign up အချိန် GPS သုံးလိုပါက "Use my current location" ကို နှိပ်ပါ — browser permission လိုအပ်သည်။
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
          <button className="btn btn-success" type="submit" disabled={loading}>{loading ? 'Creating...' : submitLabel}</button>
          <button type="button" className="btn btn-secondary" onClick={switchToLogin}>Back to login</button>
        </div>
      </form>
    </div>
  );
};

/* -------------------------
   AuthWrapper (updated: only show admin-create when no admin exists)
   ------------------------- */

const AuthWrapper = ({ hasUsers, hasAdmin, onCreateUser, onLogin, onGoogleLogin, townships }) => {
  // Default to login mode; do NOT force create-admin even when no admin exists
  const [mode, setMode] = useState('login');

  const handleSignupAuth = async (payload) => onCreateUser(payload);

  useEffect(() => {
    // If no admin exists, force the create-admin UI.
    if (!hasAdmin) setMode('create-admin');
    else setMode('login');
  }, [hasAdmin]);

  const handleSignup = async (payload) => onCreateUser(payload);

  // When there is no admin, only show the Create Admin form.
 if (!hasAdmin) {
    return (
      <div style={{ padding: 24, display: 'flex', gap: 20, justifyContent: 'center' }}>
        <SignupForm
          onSubmit={async (payload) => {
            payload.role = 'admin';
            return onCreateUser(payload);
          }}
          switchToLogin={() => setMode('login')}
          submitLabel="Create admin account"
          townships={townships}
        />
      </div>
    );
  }

   // Admin exists -> show normal login / signup experience for users.
  return (
    <div style={{ padding: 24, display: 'flex', gap: 20, flexWrap: 'wrap', justifyContent: 'center' }}>
      {mode === 'login'
        ? <LoginForm onLogin={onLogin} onGoogleLogin={onGoogleLogin} switchToSignup={() => setMode('signup')} />
        : <SignupForm onSubmit={onCreateUser} switchToLogin={() => setMode('login')} townships={townships} />}
    </div>
  );
};
/* -------------------------
   OrderReports component
   - Includes phone & location next to username with Google Maps link.
   ------------------------- */
// ... (OrderReports code unchanged, omitted here for brevity in this snippet)
// For full file, original OrderReports implementation continues exactly as before.
function OrderReports({ orders = [], users = [], products = [], onViewUserProfile, viewMode = 'user', fromDate = null, toDate = null, specificUserId = null }) {
  const userMap = React.useMemo(() => {
    const m = new Map(); (users || []).forEach(u => m.set(u.id, u)); return m;
  }, [users]);

  const filteredOrders = React.useMemo(() => {
    const from = fromDate ? new Date(fromDate + 'T00:00:00Z') : null;
    const to = toDate ? new Date(toDate + 'T23:59:59Z') : null;
    // Only include orders that were confirmed/received by admin
    return (orders || []).filter(o => {
      if (!o) return false;
      if ((o.status || '') !== 'Order Received') return false;
      if (specificUserId && o.userId !== specificUserId) return false;
      if (!o.createdAt) return true;
      const d = new Date(o.createdAt);
      if (isNaN(d.getTime())) return true;
      if (from && d < from) return false;
      if (to && d > to) return false;
      return true;
    });
  }, [orders, fromDate, toDate, specificUserId]);

  const groupedByUser = React.useMemo(() => {
    const out = new Map();
    filteredOrders.forEach((o) => {
      const uid = o.userId || 'unknown_user';
      const dateKey = o.createdAt ? (new Date(o.createdAt)).toISOString().slice(0,10) : 'unknown';
      if (!out.has(uid)) out.set(uid, new Map());
      const byDate = out.get(uid);
      if (!byDate.has(dateKey)) byDate.set(dateKey, []);
      byDate.get(dateKey).push(o);
    });
    return out;
  }, [filteredOrders]);

  const groupedByDate = React.useMemo(() => {
    const out = new Map();
    filteredOrders.forEach((o) => {
      const dateKey = o.createdAt ? (new Date(o.createdAt)).toISOString().slice(0,10) : 'unknown';
      if (!out.has(dateKey)) out.set(dateKey, new Map());
      const byUser = out.get(dateKey);
      const uid = o.userId || 'unknown_user';
      if (!byUser.has(uid)) byUser.set(uid, []);
      byUser.get(uid).push(o);
    });
    return out;
  }, [filteredOrders]);

  const totals = React.useMemo(() => {
    let overallOrders = 0; let overallAmount = 0;
    filteredOrders.forEach(o => { overallOrders++; overallAmount += Number(o.price || 0) * Number(o.quantity || 1); });
    return { overallOrders, overallAmount };
  }, [filteredOrders]);

  const exportCsv = () => {
    const rows = [];
    rows.push(['userId', 'username', 'phone', 'location', 'date', 'orderId', 'productId', 'productName', 'qty', 'price', 'total', 'status', 'createdAt']);
    filteredOrders.forEach(o => {
      const dateKey = o.createdAt ? (new Date(o.createdAt)).toISOString().slice(0,10) : '';
      const user = userMap.get(o.userId) || {};
      const username = user.username || o.userName || o.userId || '';
      const phone = user.phoneNumber || user.phone || '';
      const location = user.location || '';
      const total = (Number(o.price || 0) * Number(o.quantity || 1)).toFixed(2);
      rows.push([o.userId || '', username, phone, location, dateKey, o.id || '', o.productId || '', o.productName || '', o.quantity || '', o.price || '', total, o.status || '', o.createdAt || '']);
    });
    const csvContent = rows.map(r => r.map(c => { if (c === null || c === undefined) return ''; const s = String(c).replace(/"/g, '""'); return `"${s}"`; }).join(',')).join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a'); a.href = url; a.setAttribute('download', `order-reports-${new Date().toISOString().slice(0,10)}.csv`); document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  };

  if (!filteredOrders || filteredOrders.length === 0) return <div className="empty-note">No confirmed orders (Order Received) for the selected filters.</div>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
        <h3 className="section-title">Orders Report — confirmed sales (Order Received)</h3>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="btn btn-secondary" onClick={exportCsv}>Export CSV</button>
        </div>
      </div>

      <div style={{ marginTop: 8 }} className="muted">
        This report shows only orders with status "Order Received" — i.e. admin-confirmed sales.
      </div>

      <div style={{ marginTop: 12 }}>
        <div style={{ marginBottom: 8 }} className="muted">
          Showing: <strong>{filteredOrders.length}</strong> confirmed orders • Total amount: <strong>{Number(totals.overallAmount).toLocaleString()} ကျပ်</strong>
        </div>

        {viewMode === 'user' ? (
          [...groupedByUser.entries()].map(([uid, byDate]) => {
            const user = userMap.get(uid) || {};
            const username = user.username || (byDate && [...byDate.values()].flat()[0]?.userName) || uid;

            // New: phone & location display
            const phone = user.phoneNumber || user.phone || '';
            const location = user.location || '';
            const locationLink = location ? `https://www.google.com/maps?q=${encodeURIComponent(location)}` : '';

            let userTotalAmount = 0; let userOrderCount = 0;
            byDate.forEach(arr => arr.forEach(o => { userOrderCount++; userTotalAmount += Number(o.price || 0) * Number(o.quantity || 1); }));
            return (
              <div key={uid} style={{ marginTop: 18, borderRadius: 10, padding: 12, background: 'linear-gradient(180deg, rgba(255,255,255,0.98), rgba(255,255,255,0.95))', border: '1px solid rgba(11,27,43,0.03)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
                  <div>
                    <div style={{ fontWeight: 900 }}>
                      {onViewUserProfile ? (
                        <button className="category-link" onClick={() => onViewUserProfile(uid)} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', fontWeight: 900 }}>
                          {username}
                        </button>
                      ) : username}
                      {/* phone & location in parentheses next to username */}
                      {(phone || location) ? (
                        <span className="muted" style={{ fontWeight: 600, marginLeft: 8, fontSize: 13 }}>
                          (
                          {phone ? <span>{phone}</span> : null}
                          {phone && location ? <span> • </span> : null}
                          {location ? (
                            <a href={locationLink} target="_blank" rel="noreferrer" style={{ color: 'inherit', textDecoration: 'underline' }}>{location}</a>
                          ) : null}
                          )
                        </span>
                      ) : null}
                    </div>
                    <div className="muted">User ID: {uid} • Orders: {userOrderCount} • Total: {Number(userTotalAmount).toLocaleString()} ကျပ်</div>
                  </div>
                </div>

                {[...byDate.entries()].sort((a,b) => b[0].localeCompare(a[0])).map(([dateKey, ordersArr]) => {
                  const dayTotal = ordersArr.reduce((s, o) => s + (Number(o.price || 0) * Number(o.quantity || 1)), 0);
                  return (
                    <div key={dateKey} style={{ marginTop: 12 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <strong>{dateKey}</strong>
                        <span className="muted">Orders: {ordersArr.length} • Total: {Number(dayTotal).toLocaleString()} ကျပ်</span>
                      </div>
                      <div style={{ marginTop: 8 }}>
                        {ordersArr.map(o => (
                          <div key={o.id} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderTop: '1px solid rgba(11,27,43,0.03)' }}>
                            <div style={{ minWidth: 0 }}>
                              <div style={{ fontWeight: 800 }}>{o.productName || o.productId}</div>
                              <div className="muted">Qty: {o.quantity} • Price: {Number(o.price).toLocaleString()} ကျပ် • Status: {o.status}</div>
                            </div>
                            <div style={{ textAlign: 'right' }}>
                              <div className="mono">{Number((o.price || 0) * (o.quantity || 1)).toLocaleString()} ကျပ်</div>
                              <div className="muted" style={{ fontSize: 12 }}>{o.id}</div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })
        ) : (
          [...groupedByDate.entries()].sort((a,b) => b[0].localeCompare(a[0])).map(([dateKey, byUser]) => {
            const dayTotal = [...byUser.values()].flat().reduce((s,o) => s + (Number(o.price || 0) * Number(o.quantity || 1)), 0);
            const totalOrders = [...byUser.values()].flat().length;
            return (
              <div key={dateKey} style={{ marginTop: 18, borderRadius: 10, padding: 12, background: 'linear-gradient(180deg, rgba(255,255,255,0.98), rgba(255,255,255,0.95))', border: '1px solid rgba(11,27,43,0.03)' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
                  <div>
                    <div style={{ fontWeight: 900 }}>{dateKey}</div>
                    <div className="muted">Orders: {totalOrders} • Total: {Number(dayTotal).toLocaleString()} ကျပ်</div>
                  </div>
                </div>

                {[...byUser.entries()].map(([uid, ordersArr]) => {
                  const user = userMap.get(uid) || {};
                  const username = user.username || ordersArr[0]?.userName || uid;

                  // phone & location for date grouping too
                  const phone = user.phoneNumber || user.phone || '';
                  const location = user.location || '';
                  const locationLink = location ? `https://www.google.com/maps?q=${encodeURIComponent(location)}` : '';

                  const userTotal = ordersArr.reduce((s,o) => s + (Number(o.price || 0) * Number(o.quantity || 1)), 0);
                  return (
                    <div key={uid} style={{ marginTop: 10, paddingTop: 8, borderTop: '1px dashed rgba(11,27,43,0.04)' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <div style={{ fontWeight: 800 }}>
                            {onViewUserProfile ? (
                              <button className="category-link" onClick={() => onViewUserProfile(uid)} style={{ background: 'transparent', border: 'none', padding: 0, cursor: 'pointer', fontWeight: 800 }}>
                                {username}
                              </button>
                            ) : username}
                            {(phone || location) ? (
                              <span className="muted" style={{ fontWeight: 600, marginLeft: 8, fontSize: 13 }}>
                                (
                                {phone ? <span>{phone}</span> : null}
                                {phone && location ? <span> • </span> : null}
                                {location ? (
                                  <a href={locationLink} target="_blank" rel="noreferrer" style={{ color: 'inherit', textDecoration: 'underline' }}>{location}</a>
                                ) : null}
                                )
                              </span>
                            ) : null}
                          </div>
                          <div className="muted">Orders: {ordersArr.length} • Total: {Number(userTotal).toLocaleString()} ကျပ်</div>
                        </div>
                        <div>
                          <div className="muted">{ordersArr.map(o => o.productName || o.productId).join(', ')}</div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

/* -------------------------
   Announcement components
   ------------------------- */
const AnnouncementModal = ({ announcements = [], onClose }) => {
  return (
    <div className="modal-backdrop">
      <div className="modal">
        <button className="btn-close" onClick={onClose}>×</button>
        <h2>New Announcements</h2>
        <div style={{ maxHeight: '60vh', overflow: 'auto' }}>
          {announcements.map(a => (
            <div key={a.id} style={{ marginBottom: 12, paddingBottom: 8, borderBottom: '1px solid rgba(11,27,43,0.06)' }}>
              <div style={{ fontWeight: 900 }}>{a.title || 'Announcement'}</div>
              <div className="muted" style={{ fontSize: 13 }}>{formatDate(a.createdAt)}</div>
              <div style={{ marginTop: 8 }}>{a.text}</div>
              {a.imageUrl ? <img src={a.imageUrl} alt="announcement" style={{ width: '100%', maxHeight: 200, objectFit: 'cover', marginTop: 8, borderRadius: 8 }} /> : null}
            </div>
          ))}
        </div>
        <div style={{ marginTop: 12, textAlign: 'right' }}>
          <button className="btn btn-primary" onClick={onClose}>Mark as read</button>
        </div>
      </div>
    </div>
  );
};
const AnnouncementsPage = ({ announcements = [] }) => {
  const sorted = (announcements || []).slice().sort((a, b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
  return (
    <div className="panel">
      <h2>Announcements</h2>
      {sorted.length === 0 ? <div className="empty-note">No announcements yet.</div> : sorted.map(a => (
        <div key={a.id} style={{ marginTop: 12, padding: 12, borderRadius: 10, border: '1px solid rgba(11,27,43,0.03)', background: 'var(--card)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontWeight: 900 }}>{a.title || 'Announcement'}</div>
            <div className="muted">{formatDate(a.createdAt)}</div>
          </div>
          <div style={{ marginTop: 8 }}>{a.text}</div>
          {a.imageUrl ? <img src={a.imageUrl} alt="announcement" style={{ width: '100%', maxHeight: 300, objectFit: 'cover', marginTop: 10, borderRadius: 8 }} /> : null}
        </div>
      ))}
    </div>
  );
};

/* -------------------------
   ProfileView (with township added)
   ------------------------- */
const ProfileView = ({ user, updateUser, userOrders, deleteOrder, onBack, isViewingOther, townships = [] }) => {
  const [editing, setEditing] = useState(false);
  const [username, setUsername] = useState(user?.username || user?.email || '');
  const [shopName, setShopName] = useState(user?.shopName || '');
  const [phoneNumber, setPhoneNumber] = useState(user?.phoneNumber || '');
  const [address, setAddress] = useState(user?.address || '');
  const [location, setLocation] = useState(user?.location || '');
  const [township, setTownship] = useState(user?.township || ''); // NEW
  const [profileFile, setProfileFile] = useState(null);
  const [preview, setPreview] = useState(user?.profileImage || '');

  useEffect(() => {
    setUsername(user?.username || user?.email || '');
    setShopName(user?.shopName || '');
    setPhoneNumber(user?.phoneNumber || '');
    setAddress(user?.address || '');
    setLocation(user?.location || '');
    setTownship(user?.township || '');
    setPreview(user?.profileImage || '');
  }, [user]);

  useEffect(() => {
    if (!profileFile) return;
    const fr = new FileReader();
    fr.onload = () => setPreview(fr.result);
    fr.readAsDataURL(profileFile);
  }, [profileFile]);

  const handleSave = async () => {
    const updates = {
      username: username.trim(),
      shopName: shopName.trim(),
      phoneNumber: phoneNumber.trim(),
      address: address.trim(),
      location: location.trim(),
      township: township || ''   // NEW: include township in updates
    };
    if (profileFile) {
      try {
        const dataUrl = await fileToDataUrl(profileFile);
        updates.profileImage = dataUrl;
      } catch (e) {
        console.error('Profile image read failed', e);
      }
    }
    const ok = await updateUser(updates);
    if (ok) { alert('Profile updated'); setEditing(false); }
  };

  const handleDeleteOrder = async (orderId) => {
    if (!confirm('Delete this order?')) return;
    const res = await deleteOrder(orderId);
    if (res.success) alert('Order ပယ်ဖျတ်လိုက်ပါပြီ'); else alert('ပယ်ဖျတ်မရတော့ပါ');
  };

  const grouped = (userOrders || []).reduce((acc, o) => {
    const d = formatDate(o.createdAt);
    acc[d] = acc[d] || [];
    acc[d].push(o);
    return acc;
  }, {});
  const dates = Object.keys(grouped).sort((a, b) => b.localeCompare(a));
  const mapSrc = (loc) => loc ? `https://www.google.com/maps?q=${encodeURIComponent(loc)}&output=embed` : '';

  return (
    <>
      <div className="profile-top" style={{ justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div className="profile-avatar">
            <img className="profile-image" src={preview || `https://placehold.co/120x120/cccccc/ffffff?text=${(user?.username?.[0] ?? 'U')}`} alt="avatar" />
          </div>
          <div>
            <h2 className="profile-title">{isViewingOther ? `Profile: ${user?.username || user?.email}` : 'Profile'}</h2>
            <div className="muted">Username: {user?.username || user?.email}</div>
          </div>
        </div>
        <div>
          {isViewingOther && <button className="btn btn-secondary" onClick={onBack}>Back to admin</button>}
        </div>
      </div>

      {!editing ? (
        <div style={{ display: 'grid', gap: 8 }}>
          <div><strong>Username:</strong> {user?.username || user?.email}</div>
          <div><strong>Shop:</strong> {user?.shopName || '-'}</div>
          <div><strong>Phone:</strong> {user?.phoneNumber || '-'}</div>
          <div><strong>Address:</strong> {user?.address || '-'}</div>
          <div><strong>Location:</strong> {user?.location || '-'}</div>
          <div><strong>မြို့နယ် (Township):</strong> {user?.township || '-'}</div>
          <div style={{ marginTop: 12 }}>
            <button className="btn btn-primary" onClick={() => setEditing(true)}>Edit profile</button>
          </div>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 8 }}>
          <label className="label">Username</label>
          <input className="input" value={username} onChange={(e) => setUsername(e.target.value)} />
          <label className="label">Shop name</label>
          <input className="input" value={shopName} onChange={(e) => setShopName(e.target.value)} />
          <label className="label">Phone</label>
          <input className="input" value={phoneNumber} onChange={(e) => setPhoneNumber(e.target.value)} />
          <label className="label">Address</label>
          <textarea className="input textarea" rows={2} value={address} onChange={(e) => setAddress(e.target.value)} />
          <label className="label">Location (for map)</label>
          <input className="input" placeholder="e.g. No. 123, Example St, Yangon OR 16.8,96.15" value={location} onChange={(e) => setLocation(e.target.value)} />

          <label className="label">မြို့နယ် (Township)</label>
          <select className="input" value={township} onChange={(e) => setTownship(e.target.value)}>
            <option value="">-- Choose township --</option>
            {townships && townships.map(t => (
              <option key={t.id || t.name} value={t.name}>{t.name}</option>
            ))}
          </select>

          <label className="label">Profile image</label>
          <div className="upload-row">
            <input type="file" accept="image/*" id="profile-upload" onChange={(e) => setProfileFile(e.target.files?.[0] || null)} />
            <div className="upload-help muted">Choose an image — it will be saved to this profile (demo: saved as data URL).</div>
            {preview && <img src={preview} alt="preview" className="upload-preview" />}
          </div>

          <div style={{ marginTop: 12, display: 'flex', gap: 8 }}>
            <button className="btn btn-success" onClick={handleSave}>Save</button>
            <button className="btn btn-secondary" onClick={() => setEditing(false)}>Cancel</button>
          </div>
        </div>
      )}

      {user?.location ? (
        <div style={{ marginTop: 18 }}>
          <h3 className="section-title">Location map</h3>
          <div className="map-wrap">
            <iframe title="shop-location" src={mapSrc(user.location)} className="map-frame" loading="lazy" referrerPolicy="no-referrer-when-downgrade" />
          </div>
        </div>
      ) : null}

      <div style={{ marginTop: 20 }}>
        <h3>သင်မှာယူထားသောပစ္စည်းများ (Your Orders)</h3>
        {dates.length === 0 ? <div className="empty-note">No orders yet.</div> : dates.map(date => (
          <div key={date} className="order-day-block">
            <div className="order-day-header">
              <strong>{date}</strong>
              <span className="muted"> — {grouped[date].length} orders</span>
            </div>
            {grouped[date].map(o => (
              <div key={o.id} className="order-item">
                <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
                  <div>
                    <div style={{ fontWeight: 800 }}>{o.productName}</div>
                    <div className="muted">Qty: {o.quantity} • {o.status}</div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div className="mono">{Number(o.price).toLocaleString()} ကျပ်</div>
                    <button className="btn btn-danger" style={{ marginTop: 8 }} onClick={() => handleDeleteOrder(o.id)}>Delete</button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        ))}
      </div>
    </>
  );
};

/* -------------------------
   AdminPanel (full implementation + Settings tab)
   ------------------------- */
const AdminPanel = ({ db, products, categories, announcements = [], orders, users, refreshCollections, addUser, updateUserByAdmin, deleteUser, updateOrderQuantity, deleteOrder, updateOrderStatus, addAnnouncement, updateAnnouncement, deleteAnnouncement, onViewUserProfile }) => {
  const [tab, setTab] = useState('products');

  // report controls
  const [reportMode, setReportMode] = useState('user'); // 'user' or 'date'
  const [reportFrom, setReportFrom] = useState('');
  const [reportTo, setReportTo] = useState('');
  const [reportUserId, setReportUserId] = useState('');

  // product add/edit states
  const [prodName, setProdName] = useState('');
  const [prodPrice, setProdPrice] = useState('');
  const [prodQty, setProdQty] = useState('');
  const [prodImageUrl, setProdImageUrl] = useState('');
  const [prodImageFile, setProdImageFile] = useState(null);
  const [prodCategory, setProdCategory] = useState('');
  const [prodTownship, setProdTownship] = useState('');

  // user add/edit states
  const [newUsername, setNewUsername] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [newRole, setNewRole] = useState('user');
  const [newShopName, setNewShopName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newAddress, setNewAddress] = useState('');
  const [newLocation, setNewLocation] = useState('');

  // taxonomy (new tab) states
  const [newCategoryName, setNewCategoryName] = useState('');
  const [newTownshipName, setNewTownshipName] = useState('');
  const [townshipsList, setTownshipsList] = useState([]);
  const [loadingTownshipsError, setLoadingTownshipsError] = useState(null);

  // NEW: Category image file state for admin creation
  const [newCategoryImageFile, setNewCategoryImageFile] = useState(null);
  const [newCategoryPreview, setNewCategoryPreview] = useState('');

  // announcements states (new)
  const [announceTitle, setAnnounceTitle] = useState('');
  const [announceText, setAnnounceText] = useState('');
  const [announceFile, setAnnounceFile] = useState(null);

  useEffect(() => {
    if (!db) return;
    try {
      const unsub = onSnapshot(collection(db, TOWNSHIPS_COLLECTION_PATH), (snap) => {
        setTownshipsList(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }, (err) => {
        console.error('Townships listener error', err);
        setTownshipsList([]);
        setLoadingTownshipsError(err?.message || String(err));
      });
      return () => unsub();
    } catch (e) {
      console.error('Townships setup failed', e);
      setLoadingTownshipsError(e?.message || String(e));
    }
  }, [db]);

  useEffect(() => {
    if (!newCategoryImageFile) { setNewCategoryPreview(''); return; }
    const fr = new FileReader();
    fr.onload = () => setNewCategoryPreview(fr.result);
    fr.readAsDataURL(newCategoryImageFile);
  }, [newCategoryImageFile]);

  // ---- Settings-related state + handlers ----
  const [shopNameSetting, setShopNameSetting] = useState('');
  const [logoFile, setLogoFile] = useState(null);
  const [logoPreview, setLogoPreview] = useState('');
  const [splashFile, setSplashFile] = useState(null);
  const [splashPreview, setSplashPreview] = useState('');
  const [settingsLoading, setSettingsLoading] = useState(false);

  // load settings on mount (one-time read)
  useEffect(() => {
    if (!db) return;
    let mounted = true;
    const loadSettings = async () => {
      try {
        setSettingsLoading(true);
        const sRef = doc(db, SETTINGS_COLLECTION_PATH, SETTINGS_DOC_ID);
        const snap = await getDoc(sRef);
        if (!mounted) return;
        if (snap.exists()) {
          const data = snap.data();
          setShopNameSetting(data.shopName || '');
          setLogoPreview(data.logoUrl || '');
          setSplashPreview(data.splashUrl || '');
        } else {
          setShopNameSetting('');
          setLogoPreview('');
          setSplashPreview('');
        }
      } catch (e) {
        console.error('Load settings failed', e);
      } finally { if (mounted) setSettingsLoading(false); }
    };
    loadSettings();
    return () => { mounted = false; };
  }, [db]);

  // update previews when files selected
  useEffect(() => {
    if (!logoFile) return;
    const fr = new FileReader();
    fr.onload = () => setLogoPreview(fr.result);
    fr.readAsDataURL(logoFile);
  }, [logoFile]);

  useEffect(() => {
    if (!splashFile) return;
    const fr = new FileReader();
    fr.onload = () => setSplashPreview(fr.result);
    fr.readAsDataURL(splashFile);
  }, [splashFile]);

  const saveSettings = async (e) => {
    e?.preventDefault?.();
    if (!db) return alert('DB not ready');
    try {
      setSettingsLoading(true);
      const sRef = doc(db, SETTINGS_COLLECTION_PATH, SETTINGS_DOC_ID);
      const payload = {
        shopName: (shopNameSetting || '').trim(),
        logoUrl: logoPreview || '',
        splashUrl: splashPreview || '',
        updatedAt: new Date().toISOString()
      };
      // For demo we store data URLs directly. For production use Firebase Storage and save URL here.
      await setDoc(sRef, payload, { merge: true });
      alert('Settings saved');
      if (refreshCollections) refreshCollections();
    } catch (err) {
      console.error('Save settings failed', err);
      alert('Failed to save settings');
    } finally { setSettingsLoading(false); }
  };

  // Add product
  const addProduct = async (e) => {
    e?.preventDefault();
    if (!db) return alert('DB not ready');
    if (!prodName || !prodPrice) return alert('Provide name and price');
    try {
      const payload = {
        name: prodName,
        price: Number(prodPrice),
        quantity: Number(prodQty) || 0,
        imageUrl: prodImageUrl || '',
        category: prodCategory || '',
        township: prodTownship || ''
      };
      if (prodImageFile) {
        try {
          const dataUrl = await fileToDataUrl(prodImageFile);
          payload.imageUrl = dataUrl;
        } catch (e) {
          console.error('Image read failed', e);
        }
      }
      await addDoc(collection(db, PRODUCTS_COLLECTION_PATH), payload);
      setProdName(''); setProdPrice(''); setProdQty(''); setProdImageUrl(''); setProdImageFile(null); setProdCategory(''); setProdTownship('');
      if (refreshCollections) refreshCollections();
    } catch (err) {
      console.error(err); alert('Failed to add product');
    }
  };

  const updateProductField = async (id, field, value) => {
    if (!db) return alert('DB not ready');
    try { await updateDoc(doc(db, PRODUCTS_COLLECTION_PATH, id), { [field]: value }); if (refreshCollections) refreshCollections(); }
    catch (err) { console.error(err); alert('Update failed'); }
  };

  const deleteProduct = async (id) => {
    if (!confirm('Delete product?')) return;
    try { await deleteDoc(doc(db, PRODUCTS_COLLECTION_PATH, id)); if (refreshCollections) refreshCollections(); }
    catch (err) { console.error(err); alert('Delete failed'); }
  };

  const handleReplaceProductImage = async (productId) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.onchange = async () => {
      const f = input.files?.[0];
      if (!f) return;
      try {
        const dataUrl = await fileToDataUrl(f);
        await updateProductField(productId, 'imageUrl', dataUrl);
      } catch (e) {
        console.error(e); alert('Image upload failed');
      }
    };
    input.click();
  };

  // edit product (prompt)
  const handleEditProduct = async (p) => {
    if (!p) return;
    const name = prompt('Name', p.name || '') || p.name;
    const priceStr = prompt('Price', String(p.price || 0));
    if (priceStr === null) return;
    const price = Number(priceStr);
    if (isNaN(price)) return alert('Invalid price');
    const qtyStr = prompt('Quantity', String(p.quantity || 0));
    if (qtyStr === null) return;
    const qty = Number(qtyStr);
    if (isNaN(qty)) return alert('Invalid quantity');
    const category = prompt('Category', p.category || '') || p.category || '';
    const township = prompt('Township', p.township || '') || p.township || '';
    const imageUrl = prompt('Image URL (leave blank to keep current)', p.imageUrl || '') || p.imageUrl || '';
    try {
      await updateProductField(p.id, 'name', name.trim());
      await updateProductField(p.id, 'price', price);
      await updateProductField(p.id, 'quantity', qty);
      await updateProductField(p.id, 'category', category.trim());
      await updateProductField(p.id, 'township', township.trim());
      if (imageUrl !== p.imageUrl) await updateProductField(p.id, 'imageUrl', imageUrl);
      if (refreshCollections) refreshCollections();
      alert('Product updated');
    } catch (e) {
      console.error(e);
      alert('Product update failed');
    }
  };

  // Add user (admin)
  const handleAddUserFromAdmin = async (ev) => {
    ev?.preventDefault();
    if (!db) return alert('DB not ready');
    if (!newUsername || !newPassword) return alert('Provide username & password');
    const payload = {
      username: newUsername.trim(),
      password: newPassword,
      role: newRole || 'user',
      shopName: newShopName.trim(),
      phoneNumber: newPhone.trim(),
      address: newAddress.trim(),
      location: newLocation.trim()
    };
    try {
      const res = await addUser(payload);
      if (!res || !res.success) return alert('Failed to add user — username may exist');
      setNewUsername(''); setNewPassword(''); setNewRole('user'); setNewShopName(''); setNewPhone(''); setNewAddress(''); setNewLocation('');
      if (refreshCollections) refreshCollections();
      alert('User added');
    } catch (e) {
      console.error(e);
      alert('Add user failed');
    }
  };

  // edit user
  const handleEditUser = async (u) => {
    if (!u) return;
    try {
      const username = prompt('Username', u.username || '') || u.username;
      const role = prompt('Role (admin/user)', u.role || 'user') || u.role;
      const shopName = prompt('Shop name (optional)', u.shopName || '') || u.shopName || '';
      const phone = prompt('Phone (optional)', u.phoneNumber || '') || u.phoneNumber || '';
      const address = prompt('Address (optional)', u.address || '') || u.address || '';
      const location = prompt('Location for map (optional)', u.location || '') || u.location || '';
      const pwd = prompt('Password (leave empty to keep existing)', '') || '';
      const updates = {
        username: username.trim(),
        role: role.trim() || 'user',
        shopName: shopName.trim(),
        phoneNumber: phone.trim(),
        address: address.trim(),
        location: location.trim()
      };
      if (pwd) updates.password = pwd;
      const res = await updateUserByAdmin(u.id, updates);
      if (!res || !res.success) return alert('Update failed');
      if (refreshCollections) refreshCollections();
      alert('User updated');
    } catch (e) {
      console.error(e); alert('Update failed');
    }
  };

  const handleDeleteUser = async (u) => {
    if (!confirm(`Delete user ${u.username || u.id}?`)) return;
    const res = await deleteUser(u.id);
    if (!res || !res.success) return alert('Delete failed');
    if (refreshCollections) refreshCollections();
    alert('User deleted');
  };

  // taxonomy functions (new tab)
  const addCategoryAdmin = async (ev) => {
    ev?.preventDefault();
    if (!db) return alert('DB not ready');
    const name = (newCategoryName || '').trim();
    if (!name) return alert('Provide category name');
    try {
      const q = query(collection(db, CATEGORIES_COLLECTION_PATH), where('name', '==', name));
      const exists = await getDocs(q);
      if (!exists.empty) return alert('Category already exists');
      const payload = { name, imageUrl: '' };
      if (newCategoryImageFile) {
        try {
          const dataUrl = await fileToDataUrl(newCategoryImageFile);
          payload.imageUrl = dataUrl;
        } catch (e) {
          console.error('Category image read failed', e);
        }
      }
      await addDoc(collection(db, CATEGORIES_COLLECTION_PATH), payload);
      setNewCategoryName('');
      setNewCategoryImageFile(null);
      setNewCategoryPreview('');
      if (refreshCollections) refreshCollections();
      alert('Category added');
    } catch (e) {
      console.error('Add category failed', e);
      alert('Add category failed');
    }
  };

  const deleteCategoryAdmin = async (catId, catName) => {
    if (!confirm(`Delete category "${catName}"?`)) return;
    try {
      await deleteDoc(doc(db, CATEGORIES_COLLECTION_PATH, catId));
      if (refreshCollections) refreshCollections();
      alert('Category deleted');
    } catch (e) {
      console.error('Delete category failed', e);
      alert('Delete failed');
    }
  };

  const addTownshipAdmin = async (ev) => {
    ev?.preventDefault();
    if (!db) return alert('DB not ready');
    const name = (newTownshipName || '').trim();
    if (!name) return alert('Provide township name');
    try {
      const q = query(collection(db, TOWNSHIPS_COLLECTION_PATH), where('name', '==', name));
      const exists = await getDocs(q);
      if (!exists.empty) return alert('Township already exists');
      await addDoc(collection(db, TOWNSHIPS_COLLECTION_PATH), { name });
      setNewTownshipName('');
      alert('Township added');
    } catch (e) {
      console.error('Add township failed', e);
      alert('Add township failed');
    }
  };

  const deleteTownshipAdmin = async (id, name) => {
    if (!confirm(`Delete township "${name}"?`)) return;
    try {
      await deleteDoc(doc(db, TOWNSHIPS_COLLECTION_PATH, id));
      alert('Township deleted');
    } catch (e) {
      console.error('Delete township failed', e);
      alert('Delete failed');
    }
  };

  // ANNOUNCEMENTS: create, edit, delete
  const handleAddAnnouncement = async (ev) => {
    ev?.preventDefault();
    if (!db) return alert('DB not ready');
    if (!announceText && !announceTitle) return alert('Provide text or title for the announcement');
    try {
      const payload = {
        title: announceTitle.trim(),
        text: announceText.trim(),
        imageUrl: '',
        createdAt: new Date().toISOString()
      };
      if (announceFile) {
        try {
          const dataUrl = await fileToDataUrl(announceFile);
          payload.imageUrl = dataUrl;
        } catch (e) { console.error('Announcement image read failed', e); }
      }
      await addDoc(collection(db, ANNOUNCEMENTS_COLLECTION_PATH), payload);
      setAnnounceTitle(''); setAnnounceText(''); setAnnounceFile(null);
      if (refreshCollections) refreshCollections();
      alert('Announcement created');
    } catch (e) {
      console.error('Add announcement failed', e);
      alert('Failed to create announcement');
    }
  };

  const handleEditAnnouncement = async (a) => {
    if (!a) return;
    try {
      const title = prompt('Title', a.title || '') || a.title;
      const text = prompt('Text', a.text || '') || a.text;
      const changeImage = confirm('Replace image? (Cancel to keep current)');
      let imageUrl = a.imageUrl || '';
      if (changeImage) {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.onchange = async () => {
          const f = input.files?.[0];
          if (f) {
            try {
              const dataUrl = await fileToDataUrl(f);
              imageUrl = dataUrl;
              await updateAnnouncement(a.id, { title: title.trim(), text: text.trim(), imageUrl });
              if (refreshCollections) refreshCollections();
              alert('Announcement updated');
            } catch (e) { console.error(e); alert('Image upload failed'); }
          } else {
            await updateAnnouncement(a.id, { title: title.trim(), text: text.trim() });
            if (refreshCollections) refreshCollections();
            alert('Announcement updated');
          }
        };
        input.click();
      } else {
        await updateAnnouncement(a.id, { title: title.trim(), text: text.trim() });
        if (refreshCollections) refreshCollections();
        alert('Announcement updated');
      }
    } catch (e) {
      console.error('Edit announcement failed', e);
      alert('Edit failed');
    }
  };

  const handleDeleteAnnouncement = async (a) => {
    if (!a) return;
    if (!confirm(`Delete announcement "${a.title || a.id}"?`)) return;
    try {
      await deleteAnnouncement(a.id);
      if (refreshCollections) refreshCollections();
      alert('Announcement deleted');
    } catch (e) {
      console.error('Delete announcement failed', e);
      alert('Delete failed');
    }
  };

  // Reports controls - refresh calls are handled via props passed to OrderReports component
  return (
    <div className="panel">
      <h2 className="panel-title">Admin Panel</h2>
      <div className="panel-nav" role="tablist" aria-label="Admin sections">
        <button className={`btn ${tab === 'products' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('products')}>Products</button>
        <button className={`btn ${tab === 'orders' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('orders')}>Orders</button>
        <button className={`btn ${tab === 'users' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('users')}>Users</button>
        <button className={`btn ${tab === 'reports' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('reports')}>Reports</button>
        <button className={`btn ${tab === 'taxonomy' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('taxonomy')}>Categories & Townships</button>
        <button className={`btn ${tab === 'announcements' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('announcements')}>Announcements</button>
        <button className={`btn ${tab === 'settings' ? 'btn-primary' : 'btn-secondary'}`} onClick={() => setTab('settings')}>Settings</button>
      </div>

      <div style={{ marginTop: 12 }}>
        {tab === 'products' && (
          <>
            <form className="form-grid" onSubmit={addProduct}>
              <input className="input" placeholder="Name" value={prodName} onChange={(e) => setProdName(e.target.value)} />
              <input className="input" placeholder="Price" value={prodPrice} onChange={(e) => setProdPrice(e.target.value)} />
              <input className="input" placeholder="Quantity" value={prodQty} onChange={(e) => setProdQty(e.target.value)} />
              <input className="input" placeholder="Image URL (or choose file below)" value={prodImageUrl} onChange={(e) => setProdImageUrl(e.target.value)} />
              <div className="upload-row">
                <input type="file" accept="image/*" onChange={(e) => setProdImageFile(e.target.files?.[0] || null)} />
                
              </div>
              <select className="input" value={prodCategory} onChange={(e) => setProdCategory(e.target.value)}>
                <option value="">-- Category --</option>
                {(categories || []).map(c => <option key={c.id} value={c.name}>{c.name}</option>)}
              </select>
              <input className="input" placeholder="Township" value={prodTownship} onChange={(e) => setProdTownship(e.target.value)} />
              <div className="form-actions">
                <button className="btn btn-success" type="submit">Add Product</button>
              </div>
            </form>

            <div style={{ marginTop: 16 }}>
              {(products || []).map(p => (
                <div key={p.id} className="list-item">
                  <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                    <img src={p.imageUrl || 'https://placehold.co/80x60'} alt={p.name} style={{ width: 80, height: 60, objectFit: 'cover', borderRadius: 8 }} />
                    <div>
                      <div style={{ fontWeight: 800 }}>{p.name}</div>
                      <div className="muted">{p.category} • {p.township || '-'} • {Number(p.price).toLocaleString()} ကျပ်</div>
                    </div>
                  </div>
                  <div className="list-actions">
                    <button className="btn btn-secondary" onClick={() => handleEditProduct(p)}>Edit</button>
                    <button className="btn btn-secondary" onClick={() => handleReplaceProductImage(p.id)}>Replace Image</button>
                    <button className="btn btn-danger" onClick={() => deleteProduct(p.id)}>Delete</button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {tab === 'orders' && (
          <>
            <h3>Orders</h3>
            <div className="table-wrap">
              <table className="orders-table">
                <thead>
                  <tr><th>User</th><th>Product</th><th>Qty</th><th>Total</th><th>Status</th><th>Action</th></tr>
                </thead>
                <tbody>
                  {(orders || []).map(o => (
                    <tr key={o.id}>
                      
                      <td>{o.userName}</td>
                      <td>{o.productName}</td>
                      <td>{o.quantity}</td>
                      <td>{Number(o.price * (o.quantity || 1)).toLocaleString()} ကျပ်</td>
                      <td>{o.status}</td>
                      <td>
                        <select className="input" value={o.status} onChange={async (e) => {
                          const res = await updateOrderStatus(o.id, e.target.value);
                          if (!res.success) alert('Failed: ' + res.message);
                          else if (refreshCollections) refreshCollections();
                        }}>
                          <option>Order Placed</option>
                          <option>Order Received</option>
                          <option>Processing</option>
                          <option>Shipping</option>
                          <option>Delivered</option>
                          <option>Cancelled</option>
                        </select>

                        <button className="btn btn-secondary" style={{ marginLeft: 8 }} onClick={async () => {
                          const newQtyStr = prompt('New order quantity', String(o.quantity || 1));
                          if (newQtyStr === null) return;
                          const newQty = Number(newQtyStr);
                          if (isNaN(newQty) || newQty < 1) return alert('Invalid');
                          const res = await updateOrderQuantity(o.id, newQty);
                          if (!res.success) alert('Failed: ' + res.message);
                          else if (refreshCollections) refreshCollections();
                        }}>Edit Qty</button>

                        <button className="btn btn-danger" style={{ marginLeft: 8 }} onClick={async () => {
                          if (!confirm('Delete order?')) return;
                          const res = await deleteOrder(o.id);
                          if (!res.success) alert('Delete failed');
                          else if (refreshCollections) refreshCollections();
                        }}>Delete</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}

        {tab === 'users' && (
          <>
            <h3>Users</h3>

            <form className="form-grid" onSubmit={handleAddUserFromAdmin} style={{ marginBottom: 12 }}>
              <input className="input" placeholder="Username" value={newUsername} onChange={(e) => setNewUsername(e.target.value)} />
              <input className="input" placeholder="Password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} />
              <select className="input" value={newRole} onChange={(e) => setNewRole(e.target.value)}>
                <option value="user">User</option>
                <option value="admin">Admin</option>
              </select>
              <input className="input" placeholder="Shop name" value={newShopName} onChange={(e) => setNewShopName(e.target.value)} />
              <input className="input" placeholder="Phone" value={newPhone} onChange={(e) => setNewPhone(e.target.value)} />
              <input className="input" placeholder="Address" value={newAddress} onChange={(e) => setNewAddress(e.target.value)} />
              <input className="input" placeholder="Location (map)" value={newLocation} onChange={(e) => setNewLocation(e.target.value)} />
              <div className="form-actions">
                <button className="btn btn-success" type="submit">Add user</button>
              </div>
            </form>

            <div style={{ marginTop: 8 }}>
              {(users || []).map(u => (
                <div key={u.id} className="list-item">
                  <div>
                    <div style={{ fontWeight: 900 }}>{u.username}</div>
                    <div className="muted">role: {u.role || 'user'} • id: {u.id}</div>
                  </div>
                  <div className="list-actions">
                    <button className="btn btn-secondary" onClick={() => handleEditUser(u)}>Edit</button>
                    <button className="btn btn-secondary" onClick={() => onViewUserProfile && onViewUserProfile(u.id)}>View profile</button>
                    <button className="btn btn-danger" onClick={() => handleDeleteUser(u)}>Delete</button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}

        {tab === 'reports' && (
          <div style={{ marginTop: 12 }}>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center', marginBottom: 12 }}>
              <div>
                <label className="label">Group by</label>
                <div>
                  <select className="input" value={reportMode} onChange={(e) => setReportMode(e.target.value)}>
                    <option value="user">User (user → date)</option>
                    <option value="date">Date (date → user)</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="label">From</label>
                <input className="input" type="date" value={reportFrom} onChange={(e) => setReportFrom(e.target.value)} />
              </div>

              <div>
                <label className="label">To</label>
                <input className="input" type="date" value={reportTo} onChange={(e) => setReportTo(e.target.value)} />
              </div>

              <div>
                <label className="label">User</label>
                <select className="input" value={reportUserId} onChange={(e) => setReportUserId(e.target.value)}>
                  <option value="">All users</option>
                  {(users || []).map(u => <option key={u.id} value={u.id}>{u.username}</option>)}
                </select>
              </div>

              <div style={{ alignSelf: 'end' }}>
                <button className="btn btn-secondary" onClick={() => { if (refreshCollections) refreshCollections(); }}>Refresh</button>
              </div>
            </div>

            <OrderReports
              orders={orders}
              users={users}
              products={products}
              onViewUserProfile={onViewUserProfile}
              viewMode={reportMode}
              fromDate={reportFrom || null}
              toDate={reportTo || null}
              specificUserId={reportUserId || null}
            />
          </div>
        )}

        {tab === 'taxonomy' && (
          <div style={{ marginTop: 12 }}>
            <h3>Categories</h3>
            <form style={{ display: 'flex', gap: 8, marginBottom: 12, alignItems: 'center' }} onSubmit={addCategoryAdmin}>
              <input className="input" placeholder="New category name" value={newCategoryName} onChange={(e) => setNewCategoryName(e.target.value)} />
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                <input type="file" accept="image/*" onChange={(e) => setNewCategoryImageFile(e.target.files?.[0] || null)} />
                <div className="upload-help muted">Optional: upload a category image (will be saved as data URL for demo).</div>
                {newCategoryPreview ? <img src={newCategoryPreview} alt="preview" style={{ width: 80, height: 80, objectFit: 'cover', borderRadius: 8 }} /> : null}
              </div>
              <button className="btn btn-success" type="submit">Add Category</button>
            </form>

            <div style={{ marginBottom: 18 }}>
              {(categories || []).length === 0 ? <div className="muted">No categories yet.</div> : (
                (categories || []).map(c => (
                  <div key={c.id} className="list-item" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div>
                      {c.imageUrl ? (
                        <img src={c.imageUrl} alt={c.name} style={{ width: 72, height: 72, objectFit: 'cover', borderRadius: 10 }} />
                      ) : (
                        <div className="category-placeholder" style={{ width: 72, height: 72 }}>{(c.name || '').slice(0,1).toUpperCase()}</div>
                      )}
                    </div>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 800 }}>{c.name}</div>
                      <div className="muted">id: {c.id}</div>
                    </div>
                    <div className="list-actions">
                      <button className="btn btn-danger" onClick={() => deleteCategoryAdmin(c.id, c.name)}>Delete</button>
                    </div>
                  </div>
                ))
              )}
            </div>

            <h3>Townships</h3>
            <form style={{ display: 'flex', gap: 8, marginBottom: 12 }} onSubmit={addTownshipAdmin}>
              <input className="input" placeholder="New township name" value={newTownshipName} onChange={(e) => setNewTownshipName(e.target.value)} />
              <button className="btn btn-success" type="submit">Add Township</button>
            </form>

            <div>
              {loadingTownshipsError && <div className="muted">Townships load error: {loadingTownshipsError}</div>}
              {(!townshipsList || townshipsList.length === 0) ? <div className="muted">No townships yet.</div> : (
                townshipsList.map(t => (
                  <div key={t.id} className="list-item">
                    <div>
                      <div style={{ fontWeight: 800 }}>{t.name}</div>
                      <div className="muted">id: {t.id}</div>
                    </div>
                    <div className="list-actions">
                      <button className="btn btn-danger" onClick={() => deleteTownshipAdmin(t.id, t.name)}>Delete</button>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {tab === 'announcements' && (
          <div style={{ marginTop: 12 }}>
            <h3>Create Announcement</h3>
            <form style={{ display: 'grid', gap: 8, marginBottom: 12 }} onSubmit={handleAddAnnouncement}>
              <input className="input" placeholder="Title (optional)" value={announceTitle} onChange={(e) => setAnnounceTitle(e.target.value)} />
              <textarea className="input textarea" placeholder="Announcement text" value={announceText} onChange={(e) => setAnnounceText(e.target.value)} />
              <div className="upload-row">
                <input type="file" accept="image/*" onChange={(e) => setAnnounceFile(e.target.files?.[0] || null)} />
                <div className="upload-help muted">Optional: upload an image to show with the announcement.</div>
              </div>
              <div>
                <button className="btn btn-success" type="submit">Publish Announcement</button>
              </div>
            </form>

            <h3 style={{ marginTop: 18 }}>Existing Announcements</h3>
            {(announcements || []).slice().sort((a,b) => (b.createdAt || '').localeCompare(a.createdAt || '')).map(a => (
              <div key={a.id} className="list-item" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontWeight: 800 }}>{a.title || '(no title)'}</div>
                  <div className="muted">{formatDate(a.createdAt)} • {a.text?.slice(0,80)}{a.text && a.text.length>80 ? '…' : ''}</div>
                </div>
                <div className="list-actions">
                  <button className="btn btn-secondary" onClick={() => handleEditAnnouncement(a)}>Edit</button>
                  <button className="btn btn-danger" onClick={() => handleDeleteAnnouncement(a)}>Delete</button>
                </div>
              </div>
            ))}
            {(announcements || []).length === 0 && <div className="muted" style={{ marginTop: 8 }}>No announcements yet.</div>}
          </div>
        )}

        {tab === 'settings' && (
          <div style={{ marginTop: 12 }}>
            <h3>Shop Settings</h3>
            <form style={{ display: 'grid', gap: 12, maxWidth: 720 }} onSubmit={saveSettings}>
              <div>
                <label className="label">Shop name</label>
                <input className="input" value={shopNameSetting} onChange={(e) => setShopNameSetting(e.target.value)} placeholder="e.g. MG Shop" />
              </div>

              <div>
                <label className="label">Logo (upload)</label>
                <div className="upload-row">
                  <input type="file" accept="image/*" onChange={(e) => setLogoFile(e.target.files?.[0] || null)} />
                  <div className="upload-help muted">1MB ကျော်လျှင်မတင်ရ</div>
                </div>
                {logoPreview ? <div style={{ marginTop: 8 }}><img src={logoPreview} alt="logo preview" style={{ height: 80, objectFit: 'contain', borderRadius: 8 }} /></div> : null}
              </div>

              <div>
                <label className="label">Splash / Launch image (upload)</label>
                <div className="upload-row">
                  <input type="file" accept="image/*" onChange={(e) => setSplashFile(e.target.files?.[0] || null)} />
                  <div className="upload-help muted">1MB ကျော်လျှင်မတင်ရ</div>
                </div>
                {splashPreview ? <div style={{ marginTop: 8 }}><img src={splashPreview} alt="splash preview" style={{ width: '100%', maxHeight: 240, objectFit: 'cover', borderRadius: 8 }} /></div> : null}
              </div>

              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-success" type="submit" disabled={settingsLoading}>{settingsLoading ? 'Saving...' : 'Save settings'}</button>
                <button className="btn btn-secondary" type="button" onClick={() => {
                  if (db) {
                    (async () => {
                      try {
                        setSettingsLoading(true);
                        const sRef = doc(db, SETTINGS_COLLECTION_PATH, SETTINGS_DOC_ID);
                        const snap = await getDoc(sRef);
                        if (snap.exists()) {
                          const data = snap.data();
                          setShopNameSetting(data.shopName || '');
                          setLogoPreview(data.logoUrl || '');
                          setSplashPreview(data.splashUrl || '');
                          setLogoFile(null);
                          setSplashFile(null);
                        } else {
                          setShopNameSetting('');
                          setLogoPreview('');
                          setSplashPreview('');
                        }
                      } catch (e) { console.error(e); alert('Reload failed'); }
                      finally { setSettingsLoading(false); }
                    })();
                  }
                }}>Reload</button>
              </div>
            </form>
          </div>
        )}
      </div>
    </div>
  );
};

/* -------------------------
   AppMenu (inline)
   ------------------------- */
// ------------------ Replace AppMenu definition with this simplified version ------------------
function AppMenu({
  isAdmin,
  hasAdmin,
  unseenCount = 0,
  setView = () => {},
  onLogout = () => {},
  openCreateAdminPrompt = () => {},
  setSelectedProfileUserId = () => {},
  defaultOpen = false,
  isLoggedIn = true
}) {
  // If user is not logged in, do not render the menu at all
  if (!isLoggedIn) return null;

  const [open, setOpen] = useState(!!defaultOpen);
  const ref = useRef(null);

  useEffect(() => {
    const onDocClick = (e) => {
      if (!ref.current) return;
      if (!ref.current.contains(e.target)) setOpen(false);
    };
    document.addEventListener('click', onDocClick);
    return () => document.removeEventListener('click', onDocClick);
  }, []);

  const closeAnd = (fn) => {
    setOpen(false);
    if (typeof fn === 'function') fn();
  };

  return (
    <div className="app-menu" ref={ref}>
      <button aria-haspopup="true" aria-expanded={open} className="menu-btn btn btn-secondary" onClick={() => setOpen(!open)} title="Menu">
        <span className="hamburger">☰</span>
      </button>

      {open && (
        <div className="menu-dropdown" role="menu" aria-label="App menu">
          <button role="menuitem" className="menu-item" onClick={() => closeAnd(() => setView('announcements'))}>
            <div className="left"><span className="label">Announcements</span></div>
            {unseenCount > 0 && <div className="badge-count" aria-hidden>{unseenCount}</div>}
          </button>

          <button role="menuitem" className="menu-item" onClick={() => closeAnd(() => { setSelectedProfileUserId(null); setView('profile'); })}>
            <div className="left"><span className="label">Profile</span></div>
          </button>

          {isAdmin && (
            <button role="menuitem" className="menu-item" onClick={() => closeAnd(() => setView('admin'))}>
              <div className="left"><span className="label">Admin Panel</span></div>
            </button>
          )}

          {!hasAdmin && (
            <button role="menuitem" className="menu-item" onClick={() => closeAnd(openCreateAdminPrompt)}>
              <div className="left"><span className="label">Create Admin</span></div>
            </button>
          )}

          <button role="menuitem" className="menu-item" onClick={() => closeAnd(onLogout)}>
            <div className="left"><span className="label">Logout</span></div>
          </button>
        </div>
      )}
    </div>
  );
}
/* -------------------------
   Cart Modal component
   ------------------------- */
// ... (CartModal and rest of file remain unchanged)
// For brevity, the rest of the original file content (CartModal, MAIN APP, etc.) remains the same as your original App.jsx,
// except we add an App-level listener for settings so the header will show logo & shopName when available.

const CartModal = ({ open, onClose, items = [], onUpdateQuantity, onRemoveItem, onConfirm, total }) => {
  if (!open) return null;
  return (
    <div className="modal-backdrop">
      <div className="modal" style={{ maxWidth: 720 }}>
        <button className="btn-close" onClick={onClose}>×</button>
        <h2>သင့် စျေးခြင်း</h2>

        {items.length === 0 ? (
          <div className="empty-note">Your cart is empty.</div>
        ) : (
          <>
            <div style={{ maxHeight: '50vh', overflow: 'auto' }}>
              {items.map((it, idx) => (
                <div key={it.productId || idx} style={{ display: 'flex', gap: 12, alignItems: 'center', padding: 8, borderBottom: '1px solid rgba(11,27,43,0.04)' }}>
                  <div style={{ flex: '0 0 80px' }}>
                    <img src={it.imageUrl || 'https://placehold.co/80x60'} alt={it.name} style={{ width: 80, height: 60, objectFit: 'cover', borderRadius: 8 }} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 800 }}>{it.name}</div>
                    <div className="muted">Date: {it.date}</div>
                    <div className="muted">Price: {Number(it.price).toLocaleString()} ကျပ်</div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end' }}>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      <button className="btn btn-secondary" onClick={() => onUpdateQuantity(it.productId, Math.max(1, Number(it.quantity) - 1))}>−</button>
                      <input className="input" type="number" style={{ width: 68, textAlign: 'center' }} min={1} value={it.quantity} onChange={(e) => onUpdateQuantity(it.productId, Number(e.target.value) || 1)} />
                      <button className="btn btn-secondary" onClick={() => onUpdateQuantity(it.productId, Number(it.quantity) + 1)}>+</button>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontWeight: 900 }}>{Number((it.price || 0) * (it.quantity || 1)).toLocaleString()} ကျပ်</div>
                      <button className="btn btn-danger" style={{ marginTop: 6 }} onClick={() => onRemoveItem(it.productId)}>Remove</button>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            <div style={{ marginTop: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div className="muted">Total</div>
                <div style={{ fontWeight: 900, fontSize: 18 }}>{Number(total).toLocaleString()} ကျပ်</div>
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button className="btn btn-secondary" onClick={onClose}>Continue shopping</button>
                <button className="btn btn-primary" onClick={onConfirm}>Confirm Order</button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

/* -------------------------
   MAIN APP
   - Integrates townships listener and passes townships into Signup and Profile.
   ------------------------- */
export default function App() {
  const [view, setView] = useState('shop');
  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [announcements, setAnnouncements] = useState([]);
  const [orders, setOrders] = useState([]);
  const [users, setUsers] = useState([]);
  const [hasUsers, setHasUsers] = useState(false);
  const [hasAdmin, setHasAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [db, setDb] = useState(null);
  const [userId, setUserId] = useState(null);
  const [isAuthReady, setIsAuthReady] = useState(false);
  
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loggedInUserData, setLoggedInUserData] = useState(null);

  const [showOrderModal, setShowOrderModal] = useState(false);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [orderQuantity, setOrderQuantity] = useState('');
  const [userOrders, setUserOrders] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [searchTerm, setSearchTerm] = useState('');
  const [loadingError, setLoadingError] = useState(null);
  const seededRef = useRef(false);
  const [usersLoaded, setUsersLoaded] = useState(false);

  // CART state: local until confirmed
  const [cartItems, setCartItems] = useState([]);
  const [isCartOpen, setIsCartOpen] = useState(false);

  // NEW: quantity prompt modal state (for adding to cart)
  const [showQtyPrompt, setShowQtyPrompt] = useState(false);

  // profile selection for admin -> view other user's profile
  const [selectedProfileUserId, setSelectedProfileUserId] = useState(null);

  // townships state (realtime listener)
  const [townships, setTownships] = useState([]);

  // header
  const headerRef = useRef(null);
  const lastScrollY = useRef(0);
  const ticking = useRef(false);
  const [headerHidden, setHeaderHidden] = useState(false);

  // announcements notification modal
  const [showAnnouncementNotifyModal, setShowAnnouncementNotifyModal] = useState(false);
  const [unseenAnnouncements, setUnseenAnnouncements] = useState([]);

  // localStorage key helper
  const cartStorageKey = React.useMemo(() => `kzl_cart_${appId}_${(loggedInUserData && loggedInUserData.id) ? loggedInUserData.id : 'anon'}`, [loggedInUserData]);

  // APP-LEVEL settings state so header can reflect saved shopName/logo/splash
  const [appSettings, setAppSettings] = useState({ shopName: '', logoUrl: '', splashUrl: '' });

  useEffect(() => {
    const setHeaderHeight = () => {
      if (headerRef.current) {
        const h = headerRef.current.getBoundingClientRect().height;
        document.documentElement.style.setProperty('--header-height', `${h}px`);
      }
    };
    setHeaderHeight();
    window.addEventListener('resize', setHeaderHeight);
    return () => window.removeEventListener('resize', setHeaderHeight);
  }, []);

  useEffect(() => {
    const onScroll = () => {
      const currentY = window.scrollY || window.pageYOffset;
      if (!ticking.current) {
        window.requestAnimationFrame(() => {
          const delta = currentY - lastScrollY.current;
          if (currentY < 60) setHeaderHidden(false);
          else if (delta > 10) setHeaderHidden(true);
          else if (delta < -10) setHeaderHidden(false);
          lastScrollY.current = currentY;
          ticking.current = false;
        });
        ticking.current = true;
      }
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  // Firebase init (no anonymous sign-in)
  useEffect(() => {
    try {
      const app = initializeApp(firebaseConfig);
      const firestoreDb = getFirestore(app);
      setDb(firestoreDb);
      const auth = getAuth(app);

      const unsubscribe = onAuthStateChanged(auth, async (user) => {
        try {
          if (user) {
            setUserId(user.uid);
            // ensure a Firestore user doc exists for this auth user
            try {
              const userDocRef = doc(firestoreDb, USERS_COLLECTION_PATH, user.uid);
              const snap = await getDoc(userDocRef);
              if (snap.exists()) {
                setLoggedInUserData({ id: user.uid, ...snap.data() });
              } else {
                const profile = {
                  username: user.displayName || user.email || 'user',
                  email: user.email || '',
                  role: 'user',
                  shopName: '',
                  phoneNumber: '',
                  address: '',
                  location: '',
                  township: '',
                  createdAt: new Date().toISOString()
                };
                await setDoc(userDocRef, profile);
                setLoggedInUserData({ id: user.uid, ...profile });
              }
            } catch (e) {
              console.error('Failed ensuring user doc', e);
            }
            setIsLoggedIn(true);
          } else {
            setIsLoggedIn(false);
            setLoggedInUserData(null);
          }
        } catch (err) {
          console.error('Auth state handling failed', err);
          setLoadingError(`Auth state failed: ${err?.message || String(err)}`);
        } finally {
          setIsAuthReady(true);
          setIsLoading(false);
        }
      });
      return () => unsubscribe();
    } catch (err) {
      console.error('Firebase init failed', err);
      setLoadingError(`Firebase init failed: ${err?.message || String(err)}`);
      setIsAuthReady(true);
      setIsLoading(false);
    }
  }, []);

  // settings listener for header & app-level usage
  useEffect(() => {
    if (!db) return;
    try {
      const sRef = doc(db, SETTINGS_COLLECTION_PATH, SETTINGS_DOC_ID);
      const unsub = onSnapshot(sRef, (snap) => {
        if (!snap.exists()) return setAppSettings({ shopName: '', logoUrl: '', splashUrl: '' });
        const data = snap.data() || {};
        setAppSettings({
          shopName: data.shopName || '',
          logoUrl: data.logoUrl || '',
          splashUrl: data.splashUrl || ''
        });
      }, (err) => {
        console.error('Settings listener error', err);
      });
      return () => unsub();
    } catch (e) {
      console.error('Settings realtime setup failed', e);
    }
  }, [db]);

  // seed sample data (minimal)
  useEffect(() => {
    if (!db || seededRef.current) return;
    const seed = async () => {
      try {
        const pRef = collection(db, PRODUCTS_COLLECTION_PATH);
        const snap = await getDocs(pRef);
        if (snap.empty) {
          await setDoc(doc(db, PRODUCTS_COLLECTION_PATH, 'prod-001'), {
            name: 'MacBook Air M3', category: 'Electronics', township: 'Bahan', price: 1899000, quantity: 15, imageUrl: 'https://placehold.co/600x400/0891b2/ffffff?text=MacBook+Air'
          });
          await setDoc(doc(db, PRODUCTS_COLLECTION_PATH, 'prod-002'), {
            name: 'iPhone 15 Pro', category: 'Smartphones', township: 'Kamayut', price: 3500000, quantity: 25, imageUrl: 'https://placehold.co/600x400/8b5cf6/ffffff?text=iPhone+15'
          });
        }
        const cRef = collection(db, CATEGORIES_COLLECTION_PATH);
        const cs = await getDocs(cRef);
        if (cs.empty) {
          await setDoc(doc(db, CATEGORIES_COLLECTION_PATH, 'cat-001'), { name: 'Electronics', imageUrl: 'https://placehold.co/120x120/0891b2/ffffff?text=E' });
          await setDoc(doc(db, CATEGORIES_COLLECTION_PATH, 'cat-002'), { name: 'Smartphones', imageUrl: 'https://placehold.co/120x120/8b5cf6/ffffff?text=S' });
        }
        const tRef = collection(db, TOWNSHIPS_COLLECTION_PATH);
        const ts = await getDocs(tRef);
        if (ts.empty) {
          await setDoc(doc(db, TOWNSHIPS_COLLECTION_PATH, 'town-001'), { name: 'Bahan' });
          await setDoc(doc(db, TOWNSHIPS_COLLECTION_PATH, 'town-002'), { name: 'Kamayut' });
        }
        const aRef = collection(db, ANNOUNCEMENTS_COLLECTION_PATH);
        const as = await getDocs(aRef);
        if (as.empty) {
          await setDoc(doc(db, ANNOUNCEMENTS_COLLECTION_PATH, 'ann-001'), {
            title: 'Welcome to MG မုန့်မျိုးစုံထုတ်လုပ်ဖြန့်ချီရေး',
            text: 'Welcome — this is a sample announcement. Admins can create announcements with text and images.',
            imageUrl: '',
            createdAt: new Date().toISOString()
          });
        }
        seededRef.current = true;
      } catch (err) {
        console.error('Seeding error', err);
        setLoadingError(`Seeding error: ${err?.message || String(err)}`);
        setIsLoading(false);
      }
    };
    seed();
  }, [db]);

  // refresh helper
  const refreshCollections = useCallback(async () => {
    if (!db) { setLoadingError('DB not ready'); setIsLoading(false); return; }
    try {
      const prodSnap = await getDocs(collection(db, PRODUCTS_COLLECTION_PATH));
      setProducts(prodSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      const catSnap = await getDocs(collection(db, CATEGORIES_COLLECTION_PATH));
      setCategories(catSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      const annSnap = await getDocs(collection(db, ANNOUNCEMENTS_COLLECTION_PATH));
      setAnnouncements(annSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      const ordSnap = await getDocs(collection(db, `artifacts/${appId}/public/data/orders`));
      setOrders(ordSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      const usersSnap = await getDocs(collection(db, USERS_COLLECTION_PATH));
      const usersData = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));
      setUsers(usersData);
      setHasUsers(usersData.length > 0);
      setHasAdmin(usersData.some(u => u.role === 'admin'));
      // townships refresh too
      const tSnap = await getDocs(collection(db, TOWNSHIPS_COLLECTION_PATH));
      setTownships(tSnap.docs.map(d => ({ id: d.id, ...d.data() })));
      setIsLoading(false);
    } catch (err) {
      console.error('Refresh error', err);
      setLoadingError(`Refresh error: ${err?.message || String(err)}`);
      setIsLoading(false);
    }
  }, [db]);

  // realtime listeners
  useEffect(() => {
    if (!db || !isAuthReady) return;
    try {
      const unsubProds = onSnapshot(collection(db, PRODUCTS_COLLECTION_PATH), (snap) => {
        const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        setProducts(data.length > 0 ? data : []);
        setIsLoading(false);
      }, (err) => { console.error(err); setProducts([]); setLoadingError(`Products listener: ${err?.message}`); setIsLoading(false); });

      const unsubCats = onSnapshot(collection(db, CATEGORIES_COLLECTION_PATH), (snap) => {
        const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        setCategories(data.length > 0 ? data : []);
      }, (err) => { console.error(err); setCategories([]); setLoadingError(`Categories listener: ${err?.message}`); });

      const unsubOrders = onSnapshot(collection(db, `artifacts/${appId}/public/data/orders`), (snap) => {
        setOrders(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }, (err) => { console.error(err); setOrders([]); setLoadingError(`Orders listener: ${err?.message}`); });

      // inside the useEffect that sets up realtime listeners
const unsubUsers = onSnapshot(collection(db, USERS_COLLECTION_PATH), (snap) => {
  const data = snap.docs.map(d => ({ id: d.id, ...d.data() }));
  setUsers(data);
  setHasUsers(data.length > 0);
  setHasAdmin(data.some(u => u.role === 'admin'));
  // mark that users have been loaded at least once (prevents create-admin flash)
  setUsersLoaded(true);
}, (err) => {
  console.error(err);
  setUsers([]);
  setHasUsers(false);
  setHasAdmin(false);
  // still mark loaded so the UI won't hang forever if listener errors
  setUsersLoaded(true);
  setLoadingError(`Users listener: ${err?.message}`);
});

      const unsubAnnouncements = onSnapshot(collection(db, ANNOUNCEMENTS_COLLECTION_PATH), (snap) => {
        setAnnouncements(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }, (err) => { console.error(err); setAnnouncements([]); setLoadingError(`Announcements listener: ${err?.message}`); });

      const unsubTownships = onSnapshot(collection(db, TOWNSHIPS_COLLECTION_PATH), (snap) => {
        setTownships(snap.docs.map(d => ({ id: d.id, ...d.data() })));
      }, (err) => { console.error(err); setTownships([]); setLoadingError(`Townships listener: ${err?.message}`); });

      return () => { try { unsubProds(); unsubCats(); unsubOrders(); unsubUsers(); unsubAnnouncements(); unsubTownships(); } catch (e) { } };
    } catch (err) {
      console.error('Realtime setup failed', err);
      setLoadingError(`Realtime setup failed: ${err?.message || String(err)}`);
      setIsLoading(false);
    }
  }, [db, isAuthReady]);

  // keep userOrders in sync
  useEffect(() => {
    if (isLoggedIn && loggedInUserData && orders) setUserOrders(orders.filter(o => o.userId === loggedInUserData.id));
    else setUserOrders([]);
  }, [orders, isLoggedIn, loggedInUserData]);

  // CART persistence: load from localStorage on mount / user change
  useEffect(() => {
    try {
      const raw = localStorage.getItem(cartStorageKey);
      if (raw) {
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed)) setCartItems(parsed);
      }
    } catch (e) {
      console.warn('Failed to load cart from storage', e);
    }
  }, [cartStorageKey]);

  useEffect(() => {
    try {
      localStorage.setItem(cartStorageKey, JSON.stringify(cartItems || []));
    } catch (e) {
      console.warn('Failed to persist cart', e);
    }
  }, [cartItems, cartStorageKey]);

  // addUser helper (used by admin and signup)
  const addUser = async (user) => {
    if (!db) return false;
    try {
      const usersRef = collection(db, USERS_COLLECTION_PATH);
      const q = query(usersRef, where('username', '==', user.username));
      const snap = await getDocs(q);
      if (!snap.empty) return false;
      const docRef = await addDoc(usersRef, user);
      return { success: true, id: docRef.id };
    } catch (err) {
      console.error('Add user error', err);
      setLoadingError(`Add user failed: ${err?.message || String(err)}`);
      return false;
    }
  };

  // update any user (admin)
  const updateUserByAdmin = async (userIdToUpdate, updates) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      await updateDoc(doc(db, USERS_COLLECTION_PATH, userIdToUpdate), updates);
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (err) {
      console.error('Update user (admin) error', err);
      return { success: false, message: 'UPDATE_FAILED' };
    }
  };

  // delete user (admin)
  const deleteUser = async (userIdToDelete) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      await deleteDoc(doc(db, USERS_COLLECTION_PATH, userIdToDelete));
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (err) {
      console.error('Delete user error', err);
      return { success: false, message: 'DELETE_FAILED' };
    }
  };

 // Replace your existing handleCreateUser and openCreateAdminPrompt with these variants.

// Create Auth user (Email/Password) and Firestore user doc
// Accepts an options object { keepSignedIn: true } default true.
// If keepSignedIn is false, we sign out immediately so the app remains not-logged-in.
const handleCreateUser = async (payload, { keepSignedIn = true } = {}) => {
  try {
    const auth = getAuth();
    const userCred = await createUserWithEmailAndPassword(auth, payload.email, payload.password);
    const uid = userCred.user.uid;
    const profile = {
      username: payload.username || payload.email,
      email: payload.email,
      role: payload.role || 'user',
      shopName: payload.shopName || '',
      phoneNumber: payload.phoneNumber || '',
      address: payload.address || '',
      location: payload.location || '',
      township: payload.township || '',
      createdAt: new Date().toISOString()
    };
    await setDoc(doc(db, USERS_COLLECTION_PATH, uid), profile);

    if (keepSignedIn) {
      setLoggedInUserData({ id: uid, ...profile });
      setIsLoggedIn(true);
    } else {
      // Immediately sign out so the client is not left logged in as the newly created admin
      try { await signOut(auth); } catch (e) { console.warn('SignOut after create failed', e); }
      setLoggedInUserData(null);
      setIsLoggedIn(false);
    }

    return { success: true };
  } catch (err) {
    console.error('handleCreateUser failed', err);
    setLoadingError(`Create user failed: ${err?.message || String(err)}`);
    return false;
  }
};


  // Email/password login and Google sign-in
  const handleGoogleLogin = async () => {
    try {
      const auth = getAuth();
      const provider = new GoogleAuthProvider();
      const result = await signInWithPopup(auth, provider);
      const user = result.user;
      const uid = user.uid;
      const userDocRef = doc(db, USERS_COLLECTION_PATH, uid);
      const snap = await getDoc(userDocRef);
      if (!snap.exists()) {
        const profile = {
          username: user.displayName || user.email || 'user',
          email: user.email || '',
          role: 'user',
          shopName: '',
          phoneNumber: '',
          address: '',
          location: '',
          township: '',
          createdAt: new Date().toISOString()
        };
        await setDoc(userDocRef, profile);
        setLoggedInUserData({ id: uid, ...profile });
      } else {
        setLoggedInUserData({ id: uid, ...snap.data() });
      }
      setIsLoggedIn(true);
      return true;
    } catch (err) {
      console.error('Google sign-in failed', err);
      setLoadingError(`Google sign-in failed: ${err?.message || String(err)}`);
      return false;
    }
  };

  const handleLogout = async () => {
    try {
      const auth = getAuth();
      await signOut(auth);
    } catch (e) {
      console.warn('Sign out error', e);
    }
    setIsLoggedIn(false);
    setLoggedInUserData(null);
    setView('shop');
    setSelectedProfileUserId(null);
  };

  // addOrderToFirestore and transactional helpers (same as earlier)
  const addOrderToFirestore = async (orderData) => {
    if (!db || !loggedInUserData) return { success: false };
    try {
      await addDoc(collection(db, `artifacts/${appId}/public/data/orders`), {
        productId: orderData.productId,
        productName: orderData.productName || '',
        price: orderData.price || 0,
        quantity: orderData.quantity || 1,
        userId: loggedInUserData.id,
        userName: loggedInUserData.username || loggedInUserData.email,
        status: 'Order Placed',
        createdAt: new Date().toISOString()
      });
      return { success: true };
    } catch (err) {
      console.error('Add order failed', err);
      setLoadingError(`Add order failed: ${err?.message || String(err)}`);
      return { success: false };
    }
  };

  const handlePlaceOrder = async (orderData) => {
    const res = await addOrderToFirestore(orderData);
    if (!res.success) { alert('Order မအောင်မြင်ပါ'); return; }
    setShowOrderModal(false); setSelectedProduct(null); setOrderQuantity(1);
    alert('Order တင်လိုက်ပါပြီ');
  };

  const updateOrderStatus = async (orderId, newStatus) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      const orderRef = doc(db, `artifacts/${appId}/public/data/orders`, orderId);
      await runTransaction(db, async (tx) => {
        const orderSnap = await tx.get(orderRef);
        if (!orderSnap.exists()) throw new Error('ORDER_NOT_FOUND');
        const orderData = orderSnap.data();
        const prevStatus = orderData.status || '';
        const willBeConfirm = prevStatus !== 'Order Received' && newStatus === 'Order Received';
        const willBeUnconfirm = prevStatus === 'Order Received' && newStatus !== 'Order Received';
        if ((willBeConfirm || willBeUnconfirm) && orderData.productId) {
          const productRef = doc(db, PRODUCTS_COLLECTION_PATH, orderData.productId);
          const prodSnap = await tx.get(productRef);
          if (!prodSnap.exists()) {
            if (willBeConfirm) throw new Error('PRODUCT_NOT_FOUND');
          } else {
            const currentStock = prodSnap.data().quantity || 0;
            const qty = orderData.quantity || 0;
            if (willBeConfirm) {
              if (currentStock < qty) throw new Error('INSUFFICIENT_STOCK');
              tx.update(productRef, { quantity: currentStock - qty });
            } else if (willBeUnconfirm) {
              tx.update(productRef, { quantity: currentStock + qty });
            }
          }
        }
        tx.update(orderRef, { status: newStatus, updatedAt: new Date().toISOString() });
      });
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (e) {
      console.error('updateOrderStatus err', e);
      if (e.message === 'INSUFFICIENT_STOCK') return { success: false, message: 'INSUFFICIENT_STOCK' };
      if (e.message === 'PRODUCT_NOT_FOUND') return { success: false, message: 'PRODUCT_NOT_FOUND' };
      if (e.message === 'ORDER_NOT_FOUND') return { success: false, message: 'ORDER_NOT_FOUND' };
      return { success: false, message: 'UNKNOWN_ERROR' };
    }
  };

  const updateOrderQuantity = async (orderId, newQuantity) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      const ordersRef = doc(db, `artifacts/${appId}/public/data/orders`, orderId);
      await runTransaction(db, async (tx) => {
        const orderSnap = await tx.get(ordersRef);
        if (!orderSnap.exists()) throw new Error('ORDER_NOT_FOUND');
        const orderData = orderSnap.data();
        const oldQuantity = orderData.quantity || 0;
        const productId = orderData.productId;
        if (!productId) throw new Error('ORDER_MISSING_PRODUCT');
        const productRef = doc(db, PRODUCTS_COLLECTION_PATH, productId);
        const prodSnap = await tx.get(productRef);
        if (!prodSnap.exists()) throw new Error('PRODUCT_NOT_FOUND');
        const currentStock = prodSnap.data().quantity || 0;
        const delta = newQuantity - oldQuantity;
        if (orderData.status === 'Order Received') {
          if (delta > 0) {
            if (currentStock < delta) throw new Error('INSUFFICIENT_STOCK');
            tx.update(productRef, { quantity: currentStock - delta });
          } else if (delta < 0) {
            tx.update(productRef, { quantity: currentStock + Math.abs(delta) });
          }
        }
        tx.update(ordersRef, { quantity: newQuantity, updatedAt: new Date().toISOString() });
      });
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (e) {
      console.error('updateOrderQuantity err', e);
      if (e.message === 'INSUFFICIENT_STOCK') return { success: false, message: 'INSUFFICIENT_STOCK' };
      if (e.message === 'ORDER_NOT_FOUND') return { success: false, message: 'ORDER_NOT_FOUND' };
      if (e.message === 'PRODUCT_NOT_FOUND') return { success: false, message: 'PRODUCT_NOT_FOUND' };
      return { success: false, message: 'UNKNOWN_ERROR' };
    }
  };

  const deleteOrder = async (orderId) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      const ordersRef = doc(db, `artifacts/${appId}/public/data/orders`, orderId);
      await runTransaction(db, async (tx) => {
        const orderSnap = await tx.get(ordersRef);
        if (!orderSnap.exists()) throw new Error('ORDER_NOT_FOUND');
        const orderData = orderSnap.data();
        const productId = orderData.productId;
        const qty = orderData.quantity || 0;
        if (orderData.status === 'Order Received' && productId && qty > 0) {
          const productRef = doc(db, PRODUCTS_COLLECTION_PATH, productId);
          const prodSnap = await tx.get(productRef);
          if (prodSnap.exists()) {
            const currentStock = prodSnap.data().quantity || 0;
            tx.update(productRef, { quantity: currentStock + qty });
          }
        }
        tx.delete(ordersRef);
      });
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (e) {
      console.error('deleteOrder err', e);
      if (e.message === 'ORDER_NOT_FOUND') return { success: false, message: 'ORDER_NOT_FOUND' };
      return { success: false, message: 'UNKNOWN_ERROR' };
    }
  };

  // ANNOUNCEMENTS CRUD wrappers used by AdminPanel
  const addAnnouncement = async (payload) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      const docRef = await addDoc(collection(db, ANNOUNCEMENTS_COLLECTION_PATH), payload);
      if (refreshCollections) refreshCollections();
      return { success: true, id: docRef.id };
    } catch (e) {
      console.error('addAnnouncement err', e);
      return { success: false, message: 'ADD_FAILED' };
    }
  };
  const updateAnnouncement = async (id, updates) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      await updateDoc(doc(db, ANNOUNCEMENTS_COLLECTION_PATH, id), updates);
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (e) {
      console.error('updateAnnouncement err', e);
      return { success: false, message: 'UPDATE_FAILED' };
    }
  };
  const deleteAnnouncement = async (id) => {
    if (!db) return { success: false, message: 'DB not ready' };
    try {
      await deleteDoc(doc(db, ANNOUNCEMENTS_COLLECTION_PATH, id));
      if (refreshCollections) refreshCollections();
      return { success: true };
    } catch (e) {
      console.error('deleteAnnouncement err', e);
      return { success: false, message: 'DELETE_FAILED' };
    }
  };

  // header/profile helpers
  const handleViewUserProfile = (userIdToView) => {
    setSelectedProfileUserId(userIdToView);
    setView('profile');
  };

  // profileUser selection for ProfileView
  const profileUser = selectedProfileUserId ? users.find(u => u.id === selectedProfileUserId) : loggedInUserData;
  const profileUpdateHandler = async (updates) => {
    if (!profileUser) return false;
    if (profileUser.id === loggedInUserData?.id) {
      return updateLoggedInUser(updates);
    } else {
      const res = await updateUserByAdmin(profileUser.id, updates);
      return res.success;
    }
  };
  const profileOnBack = () => {
    setSelectedProfileUserId(null);
    setView('admin');
  };

  // shop filters used elsewhere (defaults kept)
  const townshipsFromProducts = React.useMemo(() => {
    const s = new Set();
    (products || []).forEach(p => { if (p && p.township) s.add(p.township); });
    return Array.from(s).sort();
  }, [products]);

  const displayedProducts = React.useMemo(() => {
    const term = (searchTerm || '').trim().toLowerCase();
    let filtered = products || [];
    if (selectedCategory && selectedCategory !== 'All') filtered = filtered.filter(p => String(p.category || '').toLowerCase() === selectedCategory.toLowerCase());
    if (term.length > 0) {
      filtered = filtered.filter(p => {
        const name = String(p.name || '').toLowerCase();
        const cat = String(p.category || '').toLowerCase();
        const id = String(p.id || '').toLowerCase();
        const town = String(p.township || '').toLowerCase();
        return name.includes(term) || cat.includes(term) || id.includes(term) || town.includes(term);
      });
    }
    return filtered;
  }, [products, selectedCategory, searchTerm]);

  // Announcements notification logic:
  useEffect(() => {
    if (!isLoggedIn || !loggedInUserData || !announcements) {
      setUnseenAnnouncements([]);
      setShowAnnouncementNotifyModal(false);
      return;
    }
    const lastSeen = loggedInUserData.lastSeenAnnouncements ? new Date(loggedInUserData.lastSeenAnnouncements) : new Date(0);
    const unseen = (announcements || []).filter(a => {
      const created = a.createdAt ? new Date(a.createdAt) : new Date(0);
      return created > lastSeen;
    }).sort((a,b) => (b.createdAt || '').localeCompare(a.createdAt || ''));
    setUnseenAnnouncements(unseen);
    if (unseen.length > 0) {
      setShowAnnouncementNotifyModal(true);
    } else {
      setShowAnnouncementNotifyModal(false);
    }
  }, [announcements, isLoggedIn, loggedInUserData]);

  const markAnnouncementsAsRead = async () => {
    if (!loggedInUserData) { setShowAnnouncementNotifyModal(false); return; }
    const now = new Date().toISOString();
    const ok = await updateLoggedInUser({ lastSeenAnnouncements: now });
    setShowAnnouncementNotifyModal(false);
    return ok;
  };

  const updateLoggedInUser = async (updates) => {
    if (!db || !loggedInUserData) { alert('DB or user not ready'); return false; }
    try {
      await updateDoc(doc(db, USERS_COLLECTION_PATH, loggedInUserData.id), updates);
      setLoggedInUserData(prev => ({ ...prev, ...updates }));
      if (refreshCollections) refreshCollections();
      return true;
    } catch (err) {
      console.error('Update user error', err);
      alert('Failed to update profile');
      return false;
    }
  };

  const handleRetry = () => { setLoadingError(null); setIsLoading(true); if (db) refreshCollections(); else window.location.reload(); };
  const clearSearch = () => setSearchTerm('');

  // Add item to cart (local only)
  const addToCart = (product, qty = 1) => {
    if (!product) return;
    const pid = product.id;
    setCartItems(prev => {
      const existing = prev.find(it => it.productId === pid);
      if (existing) {
        return prev.map(it => it.productId === pid ? { ...it, quantity: Number(it.quantity || 0) + Number(qty || 1) } : it);
      }
      const date = new Date().toISOString().slice(0,10);
      return [...prev, { productId: pid, name: product.name, price: Number(product.price || 0), quantity: Number(qty || 1), date, imageUrl: product.imageUrl || '' }];
    });
    // DO NOT auto-open cart after adding — user asked: only show when they click
    try {
      const live = document.getElementById('kzl-live-announce');
      if (live) live.textContent = `${product.name} added to cart (Qty: ${qty})`;
    } catch (e) {}
  };

  const updateCartQuantity = (productId, newQty) => {
    setCartItems(prev => prev.map(it => it.productId === productId ? { ...it, quantity: Number(newQty || 1) } : it));
  };
  const removeCartItem = (productId) => {
    setCartItems(prev => prev.filter(it => it.productId !== productId));
  };

  const cartTotal = React.useMemo(() => {
    return (cartItems || []).reduce((s, it) => s + (Number(it.price || 0) * Number(it.quantity || 1)), 0);
  }, [cartItems]);

  // IMPORTANT: define openCreateAdminPrompt here so AppMenu usage won't ReferenceError
 const openCreateAdminPrompt = async () => {
  try {
    const email = prompt('Create admin email (required)');
    if (!email) return alert('Email required');

    const pwd = prompt('Create admin password (required, min 6 chars)');
    if (!pwd) return alert('Password required');
    if (pwd.length < 6) return alert('Password must be at least 6 characters');

    const res = await handleCreateUser({
      email: email.trim(),
      password: pwd,
      username: email.split('@')[0],
      role: 'admin',
      shopName: '',
      phoneNumber: '',
      address: '',
      location: '',
      township: ''
    }, { keepSignedIn: false }); // <-- do NOT remain signed in as the new admin

    if (res && (res.success || res === true)) {
      alert('Admin created. You are not signed in as that admin.');
      setView('admin'); // optional: move to admin view or to login screen
    } else {
      alert('Failed to create admin — maybe the email already exists.');
    }
  } catch (e) {
    console.error('openCreateAdminPrompt failed', e);
    alert('Failed to create admin: ' + (e?.message || e));
  }
};

  // HANDLE LOGIN (email OR username)
  const handleLogin = async (identifier, password) => {
    if (!db) { console.warn('DB not ready'); return false; }
    try {
      const auth = getAuth();
      if (identifier.includes('@')) {
        try {
          const cred = await signInWithEmailAndPassword(auth, identifier, password);
          const uid = cred.user.uid;
          const userDocRef = doc(db, USERS_COLLECTION_PATH, uid);
          const snap = await getDoc(userDocRef);
          if (snap.exists()) {
            setLoggedInUserData({ id: uid, ...snap.data() });
          } else {
            const profile = {
              username: cred.user.email || 'user',
              email: cred.user.email || '',
              role: 'user',
              createdAt: new Date().toISOString()
            };
            await setDoc(userDocRef, profile);
            setLoggedInUserData({ id: uid, ...profile });
          }
          setIsLoggedIn(true);
          return true;
        } catch (err) {
          console.error('Email sign-in failed', err);
          return false;
        }
      }

      const usersRef = collection(db, USERS_COLLECTION_PATH);
      const q = query(usersRef, where('username', '==', identifier));
      const snap = await getDocs(q);
      if (snap.empty) {
        return false;
      }
      const udoc = snap.docs[0];
      const udata = udoc.data();

      if (udata.email) {
        try {
          const cred = await signInWithEmailAndPassword(auth, udata.email, password);
          const uid = cred.user.uid;
          const userDocRef = doc(db, USERS_COLLECTION_PATH, uid);
          const s2 = await getDoc(userDocRef);
          if (!s2.exists()) {
            await setDoc(userDocRef, udata, { merge: true });
          }
          setLoggedInUserData({ id: uid, ...udata });
          setIsLoggedIn(true);
          return true;
        } catch (err) {
          console.warn('Sign-in with stored email failed, falling back to plaintext-password migration check', err);
        }
      }

      if (udata.password && udata.password === password) {
        const syntheticEmail = udata.email || `${identifier.replace(/\s+/g,'_')}@migration.local`;
        try {
          const cred = await createUserWithEmailAndPassword(auth, syntheticEmail, password);
          const uid = cred.user.uid;
          const profile = {
            ...udata,
            email: syntheticEmail,
            username: identifier,
            migratedFrom: udoc.id,
            createdAt: udata.createdAt || new Date().toISOString()
          };
          await setDoc(doc(db, USERS_COLLECTION_PATH, uid), profile, { merge: true });
          try {
            await updateDoc(doc(db, USERS_COLLECTION_PATH, udoc.id), { migratedUid: uid, migratedAt: new Date().toISOString() });
          } catch (e) {
            console.warn('Could not mark original doc as migrated', e);
          }
          setLoggedInUserData({ id: uid, ...profile });
          setIsLoggedIn(true);
          return true;
        } catch (e) {
          console.error('Failed to create Auth user during username-login migration', e);
          return false;
        }
      }

      return false;
    } catch (err) {
      console.error('handleLogin error', err);
      return false;
    }
  };

  const isAdmin = loggedInUserData && loggedInUserData.role === 'admin';
  const unseenCount = (unseenAnnouncements || []).length;

  if (loadingError) {
    return (
      <div style={{ minHeight: '100vh' }}>
        <header className="header" ref={headerRef}>
          <div className="header-inner container">
            <div className="brand-center">
              <div className="brand-block">
                <div className="brand-logo">MG</div>
                <div>
                  <h1 className="brand-title">MG</h1>
                  <p className="brand-sub">မုန့်မျိုးစုံထုတ်လုပ်ဖြန့်ချီရေး</p>
                </div>
              </div>
            </div>
          </div>
        </header>
        <div className="header-spacer" />
        <main className="main container"><div className="panel"><h2>Loading error</h2><pre>{String(loadingError)}</pre><div style={{ marginTop: 12 }}><button className="btn btn-primary" onClick={handleRetry}>Retry</button></div></div></main>
      </div>
    );
  }

  if (isLoading || !isAuthReady) {
    return (<div className="center-screen"><div className="loader-wrap"><div className="spinner" /><p className="muted">Loading shop data...</p></div></div>);
  }

  if (!isLoggedIn) {
    return (
      <div style={{ minHeight: '100vh' }}>
        <header className={`header ${headerHidden ? 'header-hidden' : ''}`} ref={headerRef}>
  <div className="header-inner container">
    {/* AppMenu removed for not-logged-in view */}
    <div className="brand-center">
      <div className="brand-block">
        <div className="brand-logo">
          {appSettings.logoUrl ? (
            <img src={appSettings.logoUrl} alt="logo" style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 10 }} />
          ) : 'KZ'}
        </div>
        <div>
          <h1 className="brand-title">{appSettings.shopName || 'MG'}</h1>
          <p className="brand-sub">မုန့်မျိုးစုံထုတ်လုပ်ဖြန့်ချီရေး</p>
        </div>
      </div>
    </div>

    <div style={{ display: 'flex', gap: 8, marginLeft: 'auto', alignItems: 'center' }}>
      

    </div>
  </div>
</header>
        <div className="header-spacer" />
        
        <main className="main container">
  {!usersLoaded ? (
    <div style={{ padding: 24, display: 'flex', gap: 20, justifyContent: 'center' }}>


<div className="loading-accounts" role="status" aria-live="polite" aria-label="Loading accounts">
  <div className="runner" aria-hidden>🏃‍♂️</div>
  <div style={{ display: 'flex', flexDirection: 'column' }}>
    <div className="loading-dots" aria-hidden>
      <span className="dot" /><span className="dot" /><span className="dot" />
    </div>
    <div className="muted">Loading accounts…</div>
  </div>
</div>
    </div>
  ) : (
    <AuthWrapper
      hasUsers={hasUsers}
      hasAdmin={hasAdmin}
      usersLoaded={usersLoaded}
      onCreateUser={handleCreateUser}
      onLogin={handleLogin}
      onGoogleLogin={handleGoogleLogin}
      townships={townships}
    />
  )}
</main>

<CartModal
  open={isCartOpen}
  onClose={() => setIsCartOpen(false)}
  items={cartItems}
  onUpdateQuantity={(pid, q) => updateCartQuantity(pid, q)}
  onRemoveItem={(pid) => removeCartItem(pid)}
  onConfirm={() => { alert('Please login to confirm order'); }}
  total={cartTotal}
/>

<div id="kzl-live-announce" aria-live="polite" style={{ position: 'absolute', left: -9999, top: 'auto', width: 1, height: 1, overflow: 'hidden' }} />

      </div>
    );
  }

  // Open quantity prompt for product (instead of directly adding and opening cart)
  const openQtyPrompt = (product) => {
    setSelectedProduct(product);
    setOrderQuantity('');
    setShowQtyPrompt(true);
  };

  const closeQtyPrompt = () => {
    setShowQtyPrompt(false);
    setSelectedProduct(null);
    setOrderQuantity(1);
  };

  const confirmQtyAddToCart = () => {
  if (!selectedProduct) return;
  // parse the entered value; allow empty => default 1
  const parsed = Number(orderQuantity);
  const qty = (orderQuantity === '' || isNaN(parsed) || parsed < 1) ? 1 : Math.floor(parsed);
  addToCart(selectedProduct, qty);
  // keep previous behavior: do not auto-open cart
  setShowQtyPrompt(false);
  setSelectedProduct(null);
  setOrderQuantity(''); // reset to empty for next time
};

  // NEW: when user confirms cart, create order documents in Firestore for each cart item.
  // Orders are created with status 'Order Placed' and will appear under user's profile and in Admin -> Orders.
  // When admin later changes status to 'Order Received', those orders will be included into Reports (OrderReports filters by 'Order Received').
  const confirmCartToOrders = async () => {
    if (!isLoggedIn || !loggedInUserData) {
      alert('Please login to confirm order');
      setIsCartOpen(false);
      return;
    }
    if (!db) {
      alert('Database not ready');
      return;
    }
    if (!cartItems || cartItems.length === 0) {
      alert('Cart is empty');
      setIsCartOpen(false);
      return;
    }

    setIsCartOpen(false);
    try {
      // Create orders sequentially to avoid overwhelming transaction logic — could be parallel if desired
      for (const it of cartItems) {
        await addOrderToFirestore({
          productId: it.productId,
          productName: it.name,
          price: it.price,
          quantity: it.quantity
        });
      }
      // clear local cart
      setCartItems([]);
      // refresh collections so profile/admin see new orders quickly
      if (refreshCollections) await refreshCollections();
      alert('သင် မှာယူပြီးပါပြီ ကျွန်တော်တို့လက်ခံပေးပါမယ် ခေတ္တစောင့်ဆိုင်းပေးပါနော်');
    } catch (e) {
      console.error('confirmCartToOrders failed', e);
      alert('တစ်ခုခုမှားယွင်းနေသောကြောင့်မှာယူမရနိုင်ပါ');
    }
  };

  return (
    <div className="app-root">
      <header ref={headerRef} className={`header ${headerHidden ? 'header-hidden' : ''}`}>
        <div className="header-inner container" style={{ alignItems: 'center' }}>

<AppMenu

  hasAdmin={hasAdmin}
  unseenCount={0}
  setView={() => {}}
  onLogout={() => {}}
  openCreateAdminPrompt={openCreateAdminPrompt}
  setSelectedProfileUserId={() => {}}
  defaultOpen={true}
  isAdmin={isAdmin}
  unseenCount={unseenCount}
  setView={(v) => setView(v)}
  onLogout={handleLogout}
  openCreateAdminPrompt={openCreateAdminPrompt}
  setSelectedProfileUserId={setSelectedProfileUserId}
  isLoggedIn={isLoggedIn} // normal behaviour: show full menu when true
/>

          <div className="brand-center" aria-hidden>
            <div className="brand-block" onClick={() => { setView('shop'); setSelectedCategory('All'); setSearchTerm(''); }}>
              <div className="brand-logo" title="MG">
                {appSettings.logoUrl ? <img src={appSettings.logoUrl} alt="logo" style={{ width: 48, height: 48, objectFit: 'cover', borderRadius: 10 }} /> : 'MG'}
              </div>
              <div style={{ textAlign: 'center' }}>
                <h1 className="brand-title" style={{ cursor: 'pointer' }}>{appSettings.shopName || 'MG'}</h1>
                <p className="brand-sub">မုန့်မျိုးစုံထုတ်လုပ်ဖြန့်ချီရေး</p>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', gap: 8, marginLeft: 'auto', alignItems: 'center' }}>
           
<button className="btn btn-secondary" onClick={() => { setIsCartOpen(true); }} aria-label="Open cart">
 
  <svg className="cart-icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
    <path d="M7 4h-2l-1 2h2l3.6 7.59-1.35 2.45A1 1 0 0 0 8.9 17h7.45a1 1 0 0 0 .92-.62l1.72-4.28A1 1 0 0 0 18.9 10H6.21" />
    <circle cx="10" cy="20" r="1.5" />
    <circle cx="17" cy="20" r="1.5" />
  </svg>
 
  {cartItems.length > 0 && <span className="badge-count" style={{ marginLeft: 8 }}>{cartItems.length}</span>}
</button>
          </div>
        </div>
      </header>

      <div className="header-spacer" />

      <main className="main container">
        {view === 'shop' ? (
          <div className="shop-page">
            <div className="search-bar" style={{ marginBottom: 8 }}>
              <input className="input search-input" placeholder="Search name, category or id..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} />
              {searchTerm && <button className="btn btn-secondary" onClick={clearSearch}>Clear</button>}
            </div>

            <div className="categories-region" style={{ marginBottom: 12 }}>
              <div className="categories-strip">
                <div
                  key="all"
                  className={`category-card ${selectedCategory === 'All' ? 'active' : ''}`}
                  onClick={() => { setSelectedCategory('All'); setSearchTerm(''); }}
                  role="button"
                >
                  <div className="category-placeholder" style={{ width: 64, height: 64, borderRadius: 10 }}>All</div>
                  <div className="category-name">All</div>
                </div>

                {(categories || []).map(c => (
                  <div
                    key={c.id}
                    className={`category-card ${selectedCategory === c.name ? 'active' : ''}`}
                    onClick={() => { setSelectedCategory(c.name); setSearchTerm(''); }}
                    role="button"
                  >
                    {c.imageUrl ? (
                      <img src={c.imageUrl} alt={c.name} style={{ width: 64, height: 64, borderRadius: 10, objectFit: 'cover' }} />
                    ) : (
                      <div className="category-placeholder">{(c.name || '').slice(0,1).toUpperCase()}</div>
                    )}
                    <div className="category-name">{c.name}</div>
                  </div>
                ))}
              </div>
              <div className="muted" style={{ textAlign: 'center', marginTop: 8 }}>Filter by category</div>
            </div>

            {/* Products grid: clicking a card opens quantity prompt modal */}
            <div className="products-grid" aria-live="polite">
              {displayedProducts.length === 0 ? (
                <div className="empty-note">{searchTerm ? `No products match "${searchTerm}"` : 'No products'}</div>
              ) : displayedProducts.map(p => (
                <div
                  key={p.id}
                  className="product-card"
                  role="button"
                  tabIndex={0}
                  onClick={() => { openQtyPrompt(p); }}
                  onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openQtyPrompt(p); } }}
                  title="Click to add to cart"
                  aria-label={`Add ${p.name} to cart`}
                >
                  <div className="product-card-media" aria-hidden>
                    <img className="product-card-image" src={p.imageUrl || 'https://placehold.co/400x300'} alt={p.name} />
                  </div>
                  <div className="product-card-body">
                    <div className="product-card-title">{p.name}</div>
                    <div className="muted" style={{ fontSize: 13 }}>{p.category || ''}</div>

                    <div className="product-card-meta" style={{ marginTop: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div className="price">{Number(p.price).toLocaleString()} ကျပ်</div>
                      <div className="badge">Stock: {p.quantity || 0}</div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ) : view === 'admin' ? (
          <AdminPanel
            db={db}
            products={products}
            categories={categories}
            announcements={announcements}
            orders={orders}
            users={users}
            refreshCollections={refreshCollections}
            addUser={addUser}
            updateUserByAdmin={updateUserByAdmin}
            deleteUser={deleteUser}
            updateOrderQuantity={updateOrderQuantity}
            deleteOrder={deleteOrder}
            updateOrderStatus={updateOrderStatus}
            addAnnouncement={addAnnouncement}
            updateAnnouncement={updateAnnouncement}
            deleteAnnouncement={deleteAnnouncement}
            onViewUserProfile={handleViewUserProfile}
          />
        ) : view === 'announcements' ? (
          <AnnouncementsPage announcements={announcements} />
        ) : (
          <div className="profile-card" role="region" aria-label="User profile">
            {profileUser ? (
              <ProfileView
                user={profileUser}
                updateUser={profileUpdateHandler}
                userOrders={orders.filter(o => o.userId === profileUser.id)}
                deleteOrder={deleteOrder}
                onBack={profileOnBack}
                isViewingOther={!!selectedProfileUserId}
                townships={townships}
              />
            ) : (
              <div className="panel">No profile selected.</div>
            )}
          </div>
        )}
      </main>

      <footer className="footer"><div className="footer-inner"><p>&copy; 2025 MG Shop</p></div></footer>

      <CartModal
        open={isCartOpen}
        onClose={() => setIsCartOpen(false)}
        items={cartItems}
        onUpdateQuantity={(pid, q) => updateCartQuantity(pid, q)}
        onRemoveItem={(pid) => removeCartItem(pid)}
        onConfirm={() => confirmCartToOrders()}
        total={cartTotal}
      />

      {/* Quantity prompt modal (NEW): show when user clicks a product card.
          User enters amount and clicks "Add to cart" — cart will be updated but NOT opened. */}
      {showQtyPrompt && selectedProduct && (
        <div className="modal-backdrop">
          <div className="modal" style={{ maxWidth: 420 }}>
            <button className="btn-close" onClick={closeQtyPrompt}>×</button>
            <h2 style={{ marginTop: 0 }}> စျေး ခြင်းထဲထည့်မယ်</h2>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
              <div style={{ flex: '0 0 84px' }}>
                <img src={selectedProduct.imageUrl || 'https://placehold.co/120x90'} alt={selectedProduct.name} style={{ width: 84, height: 84, objectFit: 'cover', borderRadius: 8 }} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 900 }}>{selectedProduct.name}</div>
                <div className="muted" style={{ marginTop: 6 }}>{Number(selectedProduct.price).toLocaleString()} ကျပ် • Stock: {selectedProduct.quantity || 0}</div>

                <div style={{ marginTop: 10 }}>
                  <label className="label">Quantity</label>
                  <input className="input" type="number" min={''} max={selectedProduct.quantity || 9999} value={orderQuantity} onChange={e => setOrderQuantity(Number(e.target.value) || 0)} placeholder="အရေအတွက် (e.g. 1)" />
                </div>
              </div>
            </div>

            <div style={{ marginTop: 14, display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
              <button className="btn btn-secondary" onClick={closeQtyPrompt}>Cancel</button>
              <button className="btn btn-primary" onClick={confirmQtyAddToCart}>Add to cart</button>
            </div>
          </div>
        </div>
      )}

      {showOrderModal && selectedProduct && (
        <div className="modal-backdrop">
          <div className="modal">
            <button className="btn-close" onClick={() => { setShowOrderModal(false); setSelectedProduct(null); setOrderQuantity( ); }}>×</button>
            <h2>Confirm Order</h2>
            <div className="modal-product">
              <img src={selectedProduct.imageUrl} className="modal-product-image" alt={selectedProduct.name} />
              <div>
                <div style={{ fontWeight: 800 }}>{selectedProduct.name}</div>
                <div className="muted">Available: {selectedProduct.quantity}</div>
                <div style={{ marginTop: 8 }}>
                  <label className="label">Quantity</label>
                  <input className="input" type="number" min={1} max={selectedProduct.quantity || 9999} value={orderQuantity} onChange={e => setOrderQuantity(Number(e.target.value) || 1)} />
                </div>
              </div>
            </div>
            <div className="modal-actions">
              <button className="btn btn-success" onClick={() => handlePlaceOrder({ productId: selectedProduct.id, productName: selectedProduct.name, price: selectedProduct.price, quantity: orderQuantity })}>Place order</button>
              <button className="btn btn-secondary" onClick={() => { setShowOrderModal(false); setSelectedProduct(null); setOrderQuantity(1); }}>Cancel</button>
            </div>
          </div>
        </div>
      )}

      {showAnnouncementNotifyModal && unseenAnnouncements && unseenAnnouncements.length > 0 && (
        <AnnouncementModal announcements={unseenAnnouncements} onClose={markAnnouncementsAsRead} />
      )}

      <div id="kzl-live-announce" aria-live="polite" style={{ position: 'absolute', left: -9999, top: 'auto', width: 1, height: 1, overflow: 'hidden' }} />


    </div>
  );
}
