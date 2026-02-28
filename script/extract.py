import pandas as pd

#file location
file_path = "C:/Users/geeth/Downloads/archive (1)/online_retail_II.xlsx"

df = pd.read_excel(file_path)

# # Basic Info
# print("Shape of dataset:", df.shape)
# print("\nColumns:")
# print(df.columns)

# print("\nData Types:")
# print(df.dtypes)

# print("\nMissing Values:")
# print(df.isnull().sum())

# print("\nDuplicate Rows:", df.duplicated().sum())

# print(df.head())

#negative quantity
print("negative quantity:", (df['Quantity'] < 0).sum())


# # Check zero price
# print("Zero Price:", (df['Price'] == 0).sum())

# # Check cancelled invoices
# print("Cancelled Invoices:", df['Invoice'].str.startswith('C').sum())

# Check if negative invoices also have positive rows in same invoice
# neg_invoices = df[df['Quantity'] < 0]['Invoice'].unique()

# mixed_invoices = df[df['Invoice'].isin(neg_invoices)]

# print(mixed_invoices.groupby('Invoice')['Quantity'].sum().head())


print("Original rows:", len(df))

# ==============================
# 2. REMOVE DUPLICATES
# ==============================

df = df.drop_duplicates()
print("After removing duplicates:", len(df))

# ==============================
# 3. CREATE REVENUE COLUMN
# ==============================

df['Revenue'] = df['Quantity'] * df['Price']

# ==============================
# 4. CREATE SALES DATASET
#    (Only Valid Transactions)
# ==============================

sales_df = df[
    (df['Quantity'] > 0) &
    (df['Price'] > 0) &
    (df['Customer ID'].notnull())
].copy()   # <-- important to avoid warning

print("Sales rows:", len(sales_df))

# ==============================
# 5. CREATE RETURNS DATASET
# ==============================

returns_df = df[df['Quantity'] < 0].copy()
print("Return rows:", len(returns_df))

# ==============================
# 6. REORDER COLUMNS EXACTLY
#    AS PostgreSQL TABLE
# # ==============================

# sales_df = sales_df[[
#     'Invoice',
#     'StockCode',
#     'Description',
#     'Quantity',
#     'Price',
#     'Revenue',
#     'Customer ID',
#     'Country',
#     'InvoiceDate'
# ]]

# # ==============================
# # 7. RENAME COLUMNS TO MATCH DB
# # ==============================

# sales_df.columns = [
#     'invoice',
#     'stock_code',
#     'description',
#     'quantity',
#     'price',
#     'revenue',
#     'customer_id',
#     'country',
#     'invoice_date'
# ]

# # ==============================
# # 8. FIX DATA TYPES
# # ==============================

# # Convert customer_id to integer (remove .0 issue)
# sales_df['customer_id'] = sales_df['customer_id'].astype(int)

# # Ensure invoice_date is datetime
# sales_df['invoice_date'] = pd.to_datetime(sales_df['invoice_date'])

# ==============================
# 9. SAVE CLEAN CSV
# ==============================

sales_df.to_csv("clean_sales_data.csv", index=False)
returns_df = df[df['Quantity'] < 0].copy()

returns_df = returns_df[[
    'Invoice',
    'StockCode',
    'Description',
    'Quantity',
    'Price',
    'Revenue',
    'Customer ID',
    'Country',
    'InvoiceDate'
]]

returns_df.columns = [
    'invoice',
    'stock_code',
    'description',
    'quantity',
    'price',
    'revenue',
    'customer_id',
    'country',
    'invoice_date'
]

returns_df['customer_id'] = returns_df['customer_id'].astype(int)

returns_df.to_csv("clean_returns_data.csv", index=False)

print("Clean CSV created successfully ✅")