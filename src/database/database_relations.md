# 資料庫關聯圖

根據 `supabase_schema.sql` 生成的資料庫關聯圖

```mermaid
erDiagram
    %% ============================================================================
    %% Supabase 內建表
    %% ============================================================================
    auth_users {
        uuid id PK
        string email
        timestamp created_at
    }

    %% ============================================================================
    %% 系統參數與選項表
    %% ============================================================================
    product_categories {
        bigserial id PK
        varchar code UK
        varchar name
        varchar name_cn
        integer level
        bigint parent_id FK
        varchar main_category_code
        integer display_order
        boolean is_active
        text description
        timestamp created_at
        timestamp updated_at
    }

    suppliers {
        bigserial id PK
        varchar code UK
        varchar name
        varchar contact_person
        varchar email
        varchar phone
        text address
        varchar country
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    packaging_categories {
        bigserial id PK
        varchar code UK
        varchar name
        varchar name_cn
        integer display_order
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    packaging_options {
        bigserial id PK
        bigint category_id FK
        varchar code
        varchar name
        text description
        integer display_order
        boolean is_active
        timestamp created_at
        timestamp updated_at
    }

    category_packaging_defaults {
        bigserial id PK
        varchar main_category_code
        bigint packaging_category_id FK
        bigint packaging_option_id FK
        integer display_order
        timestamp created_at
        timestamp updated_at
    }

    system_options {
        bigserial id PK
        varchar module
        varchar cate
        varchar parent_key
        varchar key
        text value
        varchar label
        text desc
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% 使用者與認證表
    %% ============================================================================
    user_profiles {
        uuid id PK
        varchar username UK
        varchar role
        varchar department
        varchar position
        varchar phone
        varchar avatar_url
        boolean is_active
        timestamp created_at
        timestamp updated_at
        timestamp last_login
        varchar last_login_ip
    }

    %% ============================================================================
    %% 申請與表單記錄表
    %% ============================================================================
    applications {
        bigserial id PK
        varchar item_code UK
        bigint main_category_id FK
        bigint sub_category_id FK
        bigint spec_category_id FK
        varchar item_name_cn
        varchar item_name_en
        varchar material
        varchar surface_finish
        jsonb dimensions
        integer moq
        varchar unit
        varchar customer_ref
        bigint supplier_id FK
        text notes
        text internal_notes
        timestamp submit_date
        varchar status
        uuid applicant_id FK
        varchar priority
        integer approval_level
        varchar approval_status
        timestamp approval_date
        timestamp reject_date
        text reject_reason
        uuid approver_id FK
        uuid next_approver_id FK
        decimal unit_price
        decimal cost
        varchar currency
        integer safety_stock
        integer reorder_point
        varchar storage_location
        text_array tags
        varchar project_code
        varchar barcode
        varchar qr_code
        date estimated_delivery_date
        integer lead_time
        integer version
        timestamp created_at
        timestamp updated_at
        uuid updated_by_id FK
    }

    application_packaging {
        bigserial id PK
        bigint application_id FK
        bigint packaging_category_id FK
        bigint packaging_option_id FK
        text description
        integer display_order
        timestamp created_at
    }

    attachments {
        bigserial id PK
        bigint application_id FK
        varchar file_name
        varchar original_file_name
        varchar file_type
        bigint file_size
        varchar mime_type
        varchar file_url
        varchar thumbnail_url
        uuid uploaded_by_id FK
        timestamp uploaded_at
        text description
    }

    approval_logs {
        bigserial id PK
        bigint application_id FK
        varchar action
        uuid approver_id FK
        varchar approver_name
        varchar approver_role
        integer level
        text reason
        text comment
        timestamp timestamp
        varchar ip_address
        text user_agent
    }

    code_counters {
        bigserial id PK
        varchar key UK
        integer counter
        timestamp last_used_date
        uuid last_used_by_id FK
        timestamp created_at
        timestamp updated_at
    }

    export_logs {
        bigserial id PK
        varchar category
        varchar status
        date start_date
        date end_date
        integer record_count
        varchar file_name
        varchar file_path
        bigint file_size
        varchar format
        uuid exported_by_id FK
        timestamp exported_at
        integer download_count
    }

    drafts {
        bigserial id PK
        jsonb application_data
        uuid saved_by_id FK
        timestamp saved_at
        timestamp last_modified_at
    }

    system_settings {
        bigserial id PK
        varchar setting_key UK
        text setting_value
        varchar setting_type
        text description
        uuid updated_by_id FK
        timestamp created_at
        timestamp updated_at
    }

    %% ============================================================================
    %% 關聯關係
    %% ============================================================================

    %% 產品分類自關聯（階層結構）
    product_categories ||--o{ product_categories : "parent_id (自關聯)"

    %% 包裝系統關聯
    packaging_categories ||--o{ packaging_options : "category_id"
    packaging_categories ||--o{ category_packaging_defaults : "packaging_category_id"
    packaging_options ||--o{ category_packaging_defaults : "packaging_option_id"

    %% 使用者關聯
    auth_users ||--|| user_profiles : "id (1:1)"

    %% 申請表關聯
    product_categories ||--o{ applications : "main_category_id"
    product_categories ||--o{ applications : "sub_category_id"
    product_categories ||--o{ applications : "spec_category_id"
    suppliers ||--o{ applications : "supplier_id"
    user_profiles ||--o{ applications : "applicant_id"
    user_profiles ||--o{ applications : "approver_id"
    user_profiles ||--o{ applications : "next_approver_id"
    user_profiles ||--o{ applications : "updated_by_id"

    %% 申請包裝關聯
    applications ||--o{ application_packaging : "application_id (CASCADE)"
    packaging_categories ||--o{ application_packaging : "packaging_category_id"
    packaging_options ||--o{ application_packaging : "packaging_option_id"

    %% 附件關聯
    applications ||--o{ attachments : "application_id (CASCADE)"
    user_profiles ||--o{ attachments : "uploaded_by_id"

    %% 審核記錄關聯
    applications ||--o{ approval_logs : "application_id (CASCADE)"
    user_profiles ||--o{ approval_logs : "approver_id"

    %% 編碼計數器關聯
    user_profiles ||--o{ code_counters : "last_used_by_id"

    %% 匯出記錄關聯
    user_profiles ||--o{ export_logs : "exported_by_id"

    %% 草稿關聯
    user_profiles ||--o{ drafts : "saved_by_id"

    %% 系統設定關聯
    user_profiles ||--o{ system_settings : "updated_by_id"
```

## 資料表說明

### 核心業務表

1. **applications** - 申請資料表（核心表）
   - 關聯到：product_categories (3個), suppliers, user_profiles (4個)
   - 包含完整的申請資訊

2. **application_packaging** - 申請包裝資料表
   - 關聯到：applications, packaging_categories, packaging_options
   - 儲存申請的包裝選項和說明

3. **attachments** - 附件表
   - 關聯到：applications, user_profiles
   - 儲存申請的附件檔案

4. **approval_logs** - 審核記錄表
   - 關聯到：applications, user_profiles
   - 記錄所有審核動作

### 系統參數表

5. **product_categories** - 產品分類系統
   - 自關聯：parent_id（階層結構）
   - 三層結構：大類 → 中類 → 小類

6. **suppliers** - 供應商表
   - 獨立表，被 applications 引用

7. **packaging_categories** - 包裝類別表
   - 8個包裝類別

8. **packaging_options** - 包裝選項表
   - 關聯到：packaging_categories
   - 各類別下的具體選項

9. **category_packaging_defaults** - 類別預設包裝表
   - 關聯到：packaging_categories, packaging_options
   - 各產品大類的預設包裝選項

10. **system_options** - 系統參數資料表
    - 獨立表，儲存系統設定類的選項

### 使用者與認證表

11. **auth.users** - Supabase 內建使用者表
    - 用於身份驗證

12. **user_profiles** - 使用者資料表
    - 關聯到：auth.users (1:1)
    - 儲存應用程式特定的使用者資料

### 輔助表

13. **code_counters** - 編碼計數器表
    - 關聯到：user_profiles
    - 用於產生料號的流水號計數器

14. **export_logs** - 匯出記錄表
    - 關聯到：user_profiles
    - 記錄 Excel 匯出操作

15. **drafts** - 草稿表
    - 關聯到：user_profiles
    - 儲存未提交的申請草稿

16. **system_settings** - 系統設定表
    - 關聯到：user_profiles
    - 儲存系統設定值

## 關聯關係說明

### 一對多關係 (1:N)
- `product_categories` → `applications` (3個外鍵：main_category_id, sub_category_id, spec_category_id)
- `suppliers` → `applications`
- `user_profiles` → `applications` (4個外鍵：applicant_id, approver_id, next_approver_id, updated_by_id)
- `applications` → `application_packaging` (CASCADE DELETE)
- `applications` → `attachments` (CASCADE DELETE)
- `applications` → `approval_logs` (CASCADE DELETE)
- `packaging_categories` → `packaging_options`
- `packaging_categories` → `category_packaging_defaults`
- `packaging_options` → `category_packaging_defaults`
- `user_profiles` → `attachments`, `approval_logs`, `code_counters`, `export_logs`, `drafts`, `system_settings`

### 一對一關係 (1:1)
- `auth.users` → `user_profiles`

### 自關聯關係
- `product_categories` → `product_categories` (parent_id，階層結構)

## 重要特性

1. **CASCADE DELETE**：刪除申請時自動刪除相關的包裝、附件、審核記錄
2. **UUID 外鍵**：所有使用者相關的外鍵使用 UUID（對應 auth.users.id）
3. **JSONB 欄位**：applications.dimensions 使用 JSONB 儲存複雜結構
4. **階層結構**：product_categories 使用自關聯實現三層階層
5. **唯一約束**：多個表使用複合唯一約束確保資料完整性

