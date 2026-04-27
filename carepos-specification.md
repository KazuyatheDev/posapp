# CarePOS - Carenderia POS System
## Complete Specification & Implementation Guide

---

## 🎯 Project Overview

A **minimalist, square-design POS system** for carenderia (Filipino eateries) with offline capability, Supabase backend, and clean modern UI.

### Core Design Principles
- **Minimalist**: Clean white/black/gray color scheme
- **Square & Modern**: Sharp corners, geometric layouts
- **Offline-First**: Works without internet, syncs when available
- **Single-Page**: No routing, pure JavaScript state management

---

## 📊 System Features

### 1. Dashboard
**Purpose**: Overview of business performance

**Features**:
- Sales graph (daily trend)
- Most sold items (top 5)
- Total items sold today
- Total revenue today
- Recent transactions list (last 10)
- Each transaction clickable → view full receipt

**Data Sources**:
- `invoices` table (transactions)
- `invoice_items` table (item details)
- `menu_items` table (product info)

---

### 2. Cashier (Main POS)
**Purpose**: Primary selling interface

**Layout**:
- **Left Side (60%)**: Menu items grid
  - Food items displayed as cards
  - Items pulled from Inventory (where `is_available_in_cashier = true`)
  - Click to add to cart
  - Search/filter functionality
  
- **Right Side (40%)**: Order cart
  - Selected items with quantities
  - Subtotal calculation
  - VAT (12%) calculation
  - **Total Amount**
  - "Pay Now" button

**Payment Flow**:
1. Click "Pay Now" → Modal opens
2. Modal shows:
   - Total Amount (large, prominent)
   - Two payment options with icons:
     - 💳 **GCash** (with image/logo)
     - 💵 **Cash** (with image/logo)
3. Cashier selects payment method
4. Cashier confirms amount received
5. System saves invoice to Supabase:
   - Order details
   - Payment type
   - Timestamp
   - All items and amounts
6. Success message → Cart clears

---

### 3. Inventory
**Purpose**: Manage menu items

**Features**:
- **CRUD Operations**:
  - Create new menu item
  - Read/List all items
  - Update item details
  - Delete item
  
- **Item Fields**:
  - Name
  - Price
  - Category (optional)
  - Image URL (optional)
  - `is_available_in_cashier` (boolean toggle)
  
- **Cashier Visibility Toggle**:
  - When enabled → item appears in Cashier menu
  - When disabled → item hidden from Cashier (but not deleted)

- **UI Components**:
  - Table/Grid view of all items
  - "Add New Item" button
  - Edit/Delete buttons per item
  - Toggle switch for cashier visibility

---

### 4. Reports
**Purpose**: Sales analytics

**Views**:
- **Daily Report**:
  - Today's total sales
  - Transaction count
  - Items sold breakdown
  - Sales by hour graph
  
- **Monthly Report**:
  - Current month overview
  - Day-by-day graph
  - Top selling items
  - Revenue trends
  
- **Yearly Report**:
  - Month-by-month graph
  - Annual totals
  - Growth percentages
  - Comparative analysis

**Filters**:
- Date range picker
- Export to PDF/CSV (optional)

---

### 5. Settings
**Purpose**: System configuration

**Features** (TBD - To Be Determined):
- Store information
- Tax rate configuration
- Receipt customization
- User management
- Backup settings

---

### 6. Authentication
**Purpose**: Secure access

**Features**:
- Login page (initial screen)
- Logout button (in sidebar)
- Session management
- Role-based access (optional future)

---

## 🗄️ Supabase Database Schema

### Table 1: `menu_items`
Stores all menu items (inventory)

```sql
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  category VARCHAR(100),
  image_url TEXT,
  is_available_in_cashier BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for cashier queries
CREATE INDEX idx_menu_items_available ON menu_items(is_available_in_cashier) WHERE is_available_in_cashier = true;
```

**Sample Data**:
```sql
INSERT INTO menu_items (name, price, category, is_available_in_cashier) VALUES
('Chicken Adobo', 85.00, 'Main Dish', true),
('Pork Sinigang', 95.00, 'Main Dish', true),
('Beef Caldereta', 110.00, 'Main Dish', true),
('Fried Tilapia', 90.00, 'Main Dish', true),
('Menudo', 80.00, 'Main Dish', true),
('Pinakbet', 75.00, 'Vegetable', true);
```

---

### Table 2: `invoices`
Stores transaction headers

```sql
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  vat_amount DECIMAL(10, 2) NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash', 'gcash')),
  payment_status VARCHAR(20) DEFAULT 'completed' CHECK (payment_status IN ('completed', 'pending', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  synced_at TIMESTAMP WITH TIME ZONE
);

-- Function to generate invoice numbers
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TEXT AS $$
DECLARE
  next_num INTEGER;
  invoice_num TEXT;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 5) AS INTEGER)), 0) + 1
  INTO next_num
  FROM invoices
  WHERE invoice_number LIKE 'INV-%';
  
  invoice_num := 'INV-' || LPAD(next_num::TEXT, 6, '0');
  RETURN invoice_num;
END;
$$ LANGUAGE plpgsql;

-- Index for queries
CREATE INDEX idx_invoices_created_at ON invoices(created_at DESC);
CREATE INDEX idx_invoices_payment_method ON invoices(payment_method);
```

---

### Table 3: `invoice_items`
Stores line items for each transaction

```sql
CREATE TABLE invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  menu_item_id UUID NOT NULL REFERENCES menu_items(id),
  item_name VARCHAR(255) NOT NULL, -- Snapshot of name at time of sale
  item_price DECIMAL(10, 2) NOT NULL, -- Snapshot of price at time of sale
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  line_total DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_invoice_items_invoice ON invoice_items(invoice_id);
CREATE INDEX idx_invoice_items_menu ON invoice_items(menu_item_id);
```

---

### Table 4: `users` (Optional - for authentication)
If using custom auth instead of Supabase Auth

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'cashier' CHECK (role IN ('admin', 'cashier', 'manager')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE
);
```

---

## 🔐 Row Level Security (RLS)

Enable RLS and create policies:

```sql
-- Enable RLS
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

-- Policies for menu_items (read all, authenticated can modify)
CREATE POLICY "Allow public read access to menu_items"
ON menu_items FOR SELECT
TO public
USING (true);

CREATE POLICY "Allow authenticated users to manage menu_items"
ON menu_items FOR ALL
TO authenticated
USING (true);

-- Policies for invoices
CREATE POLICY "Allow authenticated users to manage invoices"
ON invoices FOR ALL
TO authenticated
USING (true);

-- Policies for invoice_items
CREATE POLICY "Allow authenticated users to manage invoice_items"
ON invoice_items FOR ALL
TO authenticated
USING (true);
```

---

## 📱 UI/UX Specifications

### Design System

**Colors**:
- **Background**: `#ffffff` (white)
- **Surface**: `#fafafa` (light gray)
- **Border**: `#e5e5e5` (gray border)
- **Text Primary**: `#171717` (almost black)
- **Text Secondary**: `#737373` (gray)
- **Accent**: `#171717` (black for buttons/active states)

**Typography**:
- Font: Inter (Google Fonts)
- Sizes: 
  - Large: 24px (headings)
  - Medium: 16px (body)
  - Small: 13px (labels)

**Spacing**:
- Card padding: 24px
- Grid gap: 16px
- Button padding: 16px

**Borders**:
- Default: `1px solid #e5e5e5`
- Radius: 12px (cards), 8px (buttons/inputs)

---

### Layout Structure

```
┌─────────────────────────────────────────────────────┐
│  STATUS BAR (Connection indicator)                  │
├──────────┬──────────────────────────────────────────┤
│          │                                          │
│          │                                          │
│ SIDEBAR  │         MAIN CONTENT AREA               │
│  260px   │                                          │
│          │    (Dashboard/Cashier/Inventory/etc)     │
│          │                                          │
│          │                                          │
└──────────┴──────────────────────────────────────────┘
```

### Cashier Layout (Specific)

```
┌──────────────────────────┬─────────────────────┐
│                          │   ORDER CART        │
│   MENU ITEMS GRID        │   ─────────────     │
│                          │   Item 1   ₱85      │
│   [🍗]  [🍲]  [🥘]       │   Item 2   ₱95      │
│                          │   ─────────────     │
│   [🐟]  [🍖]  [🥗]       │   Subtotal: ₱180    │
│                          │   VAT 12%:  ₱21.60  │
│                          │   ─────────────     │
│                          │   TOTAL:   ₱201.60  │
│                          │                     │
│                          │   [PAY NOW]         │
└──────────────────────────┴─────────────────────┘
```

---

## 💻 Technical Implementation

### Tech Stack
- **Frontend**: Pure HTML, CSS, JavaScript (no frameworks)
- **Backend**: Supabase (PostgreSQL + Auth)
- **Storage**: localStorage (offline cache)
- **Deployment**: GitHub Pages / Netlify / Vercel

### Key Libraries
- **Supabase JS Client**: Database operations
- **Chart.js**: Graphs in Dashboard/Reports
- None else (keep it simple)

### File Structure
```
carepos/
├── index.html           # Main app file
├── styles.css           # Optional: extracted styles
├── app.js               # Optional: extracted JavaScript
├── assets/
│   ├── gcash-logo.png
│   └── cash-icon.png
└── README.md
```

---

## 🚀 Implementation Workflow

### Phase 1: Setup & Authentication
1. Create Supabase project
2. Run database schema (all CREATE TABLE statements)
3. Configure RLS policies
4. Build login page
5. Implement authentication flow

### Phase 2: Core POS (Cashier)
1. Build sidebar navigation
2. Create Cashier menu items grid (left)
3. Create order cart (right)
4. Implement add-to-cart functionality
5. Implement payment modal
6. Connect payment flow to Supabase

### Phase 3: Inventory Management
1. Build CRUD interface
2. Create add/edit item forms
3. Implement cashier visibility toggle
4. Connect to Supabase

### Phase 4: Dashboard
1. Fetch invoice data
2. Build sales graph
3. Display top items
4. Show recent transactions
5. Make transactions clickable

### Phase 5: Reports
1. Create date filter UI
2. Fetch data by date ranges
3. Build daily/monthly/yearly views
4. Implement graphs (Chart.js)

### Phase 6: Offline Functionality
1. Implement localStorage caching
2. Add Service Worker (optional)
3. Build sync mechanism
4. Add connection status indicator

---

## 📝 Complete Prompt for Claude

Use this prompt when you're ready to build:

---

**PROMPT START**

Build a complete carenderia POS system with the following specifications:

## Design Requirements
- **Minimalist design**: White, black, and gray color scheme only
- **Square/geometric UI**: Sharp corners, clean lines, modern feel
- **Single HTML file**: No frameworks, pure JavaScript
- **Responsive**: Works on desktop (primary)

## Core Features

### 1. Sidebar Navigation (Left, 260px wide)
- Logo: "CarePOS"
- Menu items:
  - 📊 Dashboard
  - 🛒 Cashier (default active)
  - 📦 Inventory
  - 📈 Reports
  - ⚙️ Settings
  - 🚪 Logout

### 2. Dashboard Page
- Today's sales graph (simple line chart)
- Metric cards:
  - Total sales amount
  - Total transactions
  - Items sold count
- Most sold items (top 5, with quantities)
- Recent transactions table (last 10):
  - Invoice number
  - Time
  - Total amount
  - Payment method
  - Each row clickable → shows full receipt modal

### 3. Cashier Page (Main POS)
**Left side (60% width):**
- Grid of menu items (from `menu_items` where `is_available_in_cashier = true`)
- Each item card shows:
  - Emoji/icon
  - Name
  - Price
- Search bar at top
- Click item → adds to cart

**Right side (40% width):**
- Order cart showing:
  - Each item with quantity controls (+/-)
  - Line totals
  - Subtotal
  - VAT (12%)
  - **TOTAL** (large, bold)
- "Pay Now" button (black, prominent)

**Payment Modal:**
When "Pay Now" clicked, show modal with:
- Total Amount (very large, centered at top)
- Two payment options (buttons with icons):
  - 💳 GCash (with image if available)
  - 💵 Cash (with image if available)
- After selection, "Confirm Payment" button
- On confirm:
  - Save invoice to Supabase `invoices` table
  - Save all items to `invoice_items` table
  - Clear cart
  - Show success message

### 4. Inventory Page
- Table view of all `menu_items`
- Columns:
  - Name
  - Price
  - Category
  - Available in Cashier (toggle switch)
  - Actions (Edit/Delete buttons)
- "Add New Item" button at top
- Add/Edit modal with form:
  - Name (required)
  - Price (required)
  - Category (optional)
  - Image URL (optional)
  - Available in Cashier (checkbox, default true)

### 5. Reports Page
- Date range selector
- Three tabs: Daily, Monthly, Yearly
- **Daily tab:**
  - Sales by hour graph
  - Total for selected day
  - Transaction count
- **Monthly tab:**
  - Daily sales bar chart
  - Month total
  - Top items
- **Yearly tab:**
  - Monthly sales line chart
  - Year total
  - Growth stats

### 6. Settings Page
- Placeholder for now with "Coming Soon" message

## Supabase Connection

Use these tables (I've already created them):

**menu_items:**
- id (uuid, pk)
- name (varchar)
- price (decimal)
- category (varchar)
- image_url (text)
- is_available_in_cashier (boolean)
- created_at, updated_at (timestamp)

**invoices:**
- id (uuid, pk)
- invoice_number (varchar, unique)
- subtotal (decimal)
- vat_amount (decimal)
- total_amount (decimal)
- payment_method (varchar: 'cash' or 'gcash')
- payment_status (varchar: 'completed')
- created_at (timestamp)

**invoice_items:**
- id (uuid, pk)
- invoice_id (uuid, fk to invoices)
- menu_item_id (uuid, fk to menu_items)
- item_name (varchar, snapshot)
- item_price (decimal, snapshot)
- quantity (integer)
- line_total (decimal)
- created_at (timestamp)

## Supabase Configuration
```javascript
const SUPABASE_URL = '[MY_PROJECT_URL]';
const SUPABASE_ANON_KEY = '[MY_ANON_KEY]';
```

## Additional Requirements
- Use Chart.js for graphs
- Include connection status indicator at top (online/offline)
- Store cart in localStorage (for offline resilience)
- Invoice numbers auto-generate as "INV-000001", "INV-000002", etc.
- All monetary amounts in Philippine Peso (₱)
- VAT rate hardcoded at 12%
- Clean console (no errors)
- Commented code sections

## UI Guidelines
- White backgrounds
- Black text (#171717)
- Gray borders (#e5e5e5)
- 12px border radius on cards
- 8px border radius on buttons
- Inter font (Google Fonts)
- Hover states on all interactive elements
- Smooth transitions (0.2s)

Generate the complete single-file HTML application with all features functional.

**PROMPT END**

---

## 🎨 Visual References

### Color Palette
```css
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #fafafa;
  --border-color: #e5e5e5;
  --text-primary: #171717;
  --text-secondary: #737373;
  --accent: #171717;
}
```

### Payment Modal Layout
```
┌────────────────────────────────┐
│     CONFIRM PAYMENT            │
│                                │
│    Total Amount                │
│    ₱ 296.80                    │
│      (large, bold)             │
│                                │
│  ┌─────────┐   ┌─────────┐    │
│  │  💳     │   │  💵     │    │
│  │ GCash   │   │  Cash   │    │
│  └─────────┘   └─────────┘    │
│                                │
│    [CONFIRM PAYMENT]           │
│                                │
└────────────────────────────────┘
```

---

## ✅ Testing Checklist

- [ ] Login/logout works
- [ ] Sidebar navigation switches views
- [ ] Dashboard loads with sample data
- [ ] Cashier adds items to cart
- [ ] Quantity controls work
- [ ] Calculations correct (subtotal, VAT, total)
- [ ] Payment modal opens
- [ ] Payment methods selectable
- [ ] Invoice saves to Supabase
- [ ] Invoice items save correctly
- [ ] Cart clears after payment
- [ ] Inventory CRUD operations work
- [ ] Toggle visibility updates cashier menu
- [ ] Reports load data
- [ ] Graphs render correctly
- [ ] Offline detection works
- [ ] No console errors

---

## 📚 Additional Notes

### Invoice Number Generation
- Format: `INV-XXXXXX` (6 digits, zero-padded)
- Use Supabase function `generate_invoice_number()`
- Increments automatically

### VAT Calculation
```javascript
const subtotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
const vat = subtotal * 0.12;
const total = subtotal + vat;
```

### Offline Strategy
1. Save cart to localStorage on every change
2. Detect online/offline with `navigator.onLine`
3. Queue transactions when offline
4. Sync to Supabase when connection returns
5. Show status indicator at top

---

## 🔧 Environment Variables

Create a `.env` or config in HTML:
```javascript
const CONFIG = {
  SUPABASE_URL: 'https://your-project.supabase.co',
  SUPABASE_ANON_KEY: 'your-anon-key-here',
  VAT_RATE: 0.12,
  CURRENCY: '₱'
};
```

---

## 📞 Support & Resources

- Supabase Docs: https://supabase.com/docs
- Chart.js Docs: https://www.chartjs.org/docs/
- Inter Font: https://fonts.google.com/specimen/Inter

---

**End of Specification Document**

Review this document before prompting Claude to ensure all requirements are clear!