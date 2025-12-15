        // 設定管理（續）
        function saveSettings() {
            settings = {
                serialDigits: document.getElementById('serialDigits').value,
                serialStart: document.getElementById('serialStart').value,
                autoApprove: document.getElementById('autoApprove').value,
                emailNotify: document.getElementById('emailNotify').value,
                approvalLevel: document.getElementById('approvalLevel').value
            };
            
            localStorage.setItem('settings_v35', JSON.stringify(settings));
            alert('設定已儲存成功！');
        }
        
        function resetSettings() {
            if (confirm('確定要恢復預設設定嗎？')) {
                settings = {
                    serialDigits: '5',
                    serialStart: '1',
                    autoApprove: 'false',
                    emailNotify: 'true',
                    approvalLevel: '1'
                };
                
                document.getElementById('serialDigits').value = settings.serialDigits;
                document.getElementById('serialStart').value = settings.serialStart;
                document.getElementById('autoApprove').value = settings.autoApprove;
                document.getElementById('emailNotify').value = settings.emailNotify;
                document.getElementById('approvalLevel').value = settings.approvalLevel;
                
                localStorage.setItem('settings_v35', JSON.stringify(settings));
                alert('已恢復預設設定！');
            }
        }
        
        function loadDefaultPackaging() {
            const category = document.getElementById('defaultCategory').value;
            const container = document.getElementById('defaultPackagingSettings');
            
            if (!category) {
                container.style.display = 'none';
                return;
            }
            
            container.style.display = 'block';
            
            // 載入該類別的預設包裝設定
            let html = '<div class="checkbox-grid">';
            
            const defaults = {
                'H': {
                    '產品包裝': ['塑膠袋', '產品標籤'],
                    '配件內容': ['螺絲'],
                    '內盒': ['印製ITEM NO.', '印製數量'],
                    '外箱': ['瓦楞紙箱', '側嘜']
                },
                'S': {
                    '產品包裝': ['氣泡袋', 'PE/PP材質'],
                    '配件內容': ['螺絲', '說明書'],
                    '內盒': ['印製ITEM NO.', '條碼'],
                    '外箱': ['瓦楞紙箱', '易碎標誌']
                },
                'M': {
                    '產品包裝': ['彩盒包裝'],
                    '配件內容': ['螺絲', '支架', '說明書'],
                    '內盒': ['印製ITEM NO.', '客戶Logo'],
                    '外箱': ['瓦楞紙箱', '向上標誌']
                }
            };
            
            const categoryDefaults = defaults[category] || {};
            
            for (let section in categoryDefaults) {
                html += `<h4>${section}</h4>`;
                categoryDefaults[section].forEach(item => {
                    html += `
                        <div class="checkbox-item">
                            <input type="checkbox" id="default_${section}_${item}" checked>
                            <label for="default_${section}_${item}">${item}</label>
                        </div>
                    `;
                });
            }
            
            html += '</div>';
            container.innerHTML = html;
        }
        
        // 初始化
        document.addEventListener('DOMContentLoaded', function() {
            // 載入設定
            if (settings.serialDigits) {
                document.getElementById('serialDigits').value = settings.serialDigits;
            }
            if (settings.autoApprove) {
                document.getElementById('autoApprove').value = settings.autoApprove;
            }
            if (settings.emailNotify) {
                document.getElementById('emailNotify').value = settings.emailNotify;
            }
            if (settings.approvalLevel) {
                document.getElementById('approvalLevel').value = settings.approvalLevel;
            }
            
            // 設定今天日期
            const today = new Date().toISOString().split('T')[0];
            document.getElementById('exportEndDate').value = today;
            
            // 設定30天前為開始日期
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
            document.getElementById('exportStartDate').value = thirtyDaysAgo.toISOString().split('T')[0];
            
            // 更新待審核數量
            updatePendingCount();
            
            // 設定使用者名稱
            const username = localStorage.getItem('username') || 'Guest User';
            document.getElementById('username').textContent = username;
            
            // 檢查草稿
            const draft = localStorage.getItem('draft_v35');
            if (draft) {
                const loadDraft = confirm('發現未完成的草稿，是否載入？');
                if (loadDraft) {
                    loadDraftData(JSON.parse(draft));
                }
            }
            
            // 為checkbox添加互動效果
            document.querySelectorAll('.checkbox-item').forEach(item => {
                item.addEventListener('click', function(e) {
                    if (e.target.tagName !== 'INPUT') {
                        const checkbox = this.querySelector('input[type="checkbox"]');
                        checkbox.checked = !checkbox.checked;
                    }
                    this.classList.toggle('checked', this.querySelector('input[type="checkbox"]').checked);
                });
                
                // 初始化checked狀態
                const checkbox = item.querySelector('input[type="checkbox"]');
                if (checkbox && checkbox.checked) {
                    item.classList.add('checked');
                }
            });
        });
        
        function loadDraftData(draft) {
            if (draft.mainCategory) document.getElementById('mainCategory').value = draft.mainCategory;
            if (draft.subCategory) {
                updateSubCategories();
                document.getElementById('subCategory').value = draft.subCategory;
            }
            if (draft.specCategory) {
                updateSpecCategories();
                document.getElementById('specCategory').value = draft.specCategory;
            }
            if (draft.itemCode) document.getElementById('itemCode').value = draft.itemCode;
            if (draft.itemNameCN) document.getElementById('itemNameCN').value = draft.itemNameCN;
            if (draft.itemNameEN) document.getElementById('itemNameEN').value = draft.itemNameEN;
            // ... 載入其他欄位
        }
        
        // 快捷鍵支援
        document.addEventListener('keydown', function(e) {
            // Alt + N: 新增申請
            if (e.altKey && e.key === 'n') {
                switchTab('apply');
                e.preventDefault();
            }
            // Alt + R: 審核管理
            if (e.altKey && e.key === 'r') {
                switchTab('review');
                e.preventDefault();
            }
            // Alt + E: 匯出
            if (e.altKey && e.key === 'e') {
                switchTab('export');
                e.preventDefault();
            }
            // Alt + Q: 查詢
            if (e.altKey && e.key === 'q') {
                switchTab('query');
                e.preventDefault();
            }
            // Escape: 關閉彈窗
            if (e.key === 'Escape') {
                closeModal();
            }
        });
        
        // 自動儲存草稿
        let autoSaveTimer;
        document.querySelectorAll('input, select, textarea').forEach(field => {
            field.addEventListener('input', function() {
                clearTimeout(autoSaveTimer);
                autoSaveTimer = setTimeout(() => {
                    saveAsDraft();
                    console.log('自動儲存草稿');
                }, 30000); // 30秒自動儲存
            });
        });
        
        // 防止資料遺失
        window.addEventListener('beforeunload', function(e) {
            const hasUnsaved = document.querySelector('input[value]:not([readonly]), textarea:not(:empty)');
            if (hasUnsaved) {
                e.preventDefault();
                e.returnValue = '您有未儲存的資料，確定要離開嗎？';
            }
        });
        
        // 顯示載入中
        function showLoading() {
            const loading = document.createElement('div');
            loading.className = 'loading';
            loading.id = 'globalLoading';
            document.body.appendChild(loading);
        }
        
        function hideLoading() {
            const loading = document.getElementById('globalLoading');
            if (loading) {
                loading.remove();
            }
        }
        
        // 模擬載入測試資料（開發用）
        function loadTestData() {
            const testApplications = [
                {
                    id: '1700000001',
                    submitDate: new Date(Date.now() - 86400000).toISOString(),
                    status: 'PENDING',
                    itemCode: 'H01.C.00001',
                    mainCategory: 'H',
                    subCategory: '01',
                    specCategory: 'C',
                    itemNameCN: '鍍鉻把手 160mm',
                    itemNameEN: 'Chrome Handle 160mm',
                    customerRef: 'CUST-001',
                    supplier: 'SUP001',
                    material: 'Zinc Alloy',
                    surfaceFinish: 'Chrome',
                    dimensions: { length: 160, width: 25, height: 35, weight: 120 },
                    moq: 500,
                    unit: 'PCS',
                    packaging: {
                        '產品包裝': { options: ['塑膠袋', '產品標籤'], description: '1PC/塑膠袋，印刷回收標誌' },
                        '配件內容': { options: ['螺絲'], description: 'M4x25mm螺絲2顆' },
                        '配件': { options: [], description: '' },
                        '內盒': { options: ['印製ITEM NO.'], description: '' },
                        '外箱': { options: ['瓦楞紙箱'], description: '5層瓦楞紙箱' },
                        '運輸與托盤要求': { options: [], description: '' },
                        '裝櫃要求': { options: [], description: '' },
                        '其他說明': { options: [], description: '' }
                    },
                    applicant: 'Test User'
                },
                {
                    id: '1700000002',
                    submitDate: new Date(Date.now() - 172800000).toISOString(),
                    status: 'APPROVED',
                    itemCode: 'S01.B.00001',
                    mainCategory: 'S',
                    subCategory: '01',
                    specCategory: 'B',
                    itemNameCN: '滾珠滑軌 350mm',
                    itemNameEN: 'Ball Bearing Slide 350mm',
                    customerRef: 'CUST-002',
                    supplier: 'SUP002',
                    material: 'Steel',
                    surfaceFinish: 'Zinc',
                    dimensions: { length: 350, width: 45, height: 45, weight: 680 },
                    moq: 100,
                    unit: 'PAIR',
                    packaging: {
                        '產品包裝': { options: ['氣泡袋'], description: '左右滑軌分別包裝' },
                        '配件內容': { options: ['螺絲', '說明書'], description: '安裝螺絲整套' },
                        '配件': { options: [], description: '' },
                        '內盒': { options: ['印製ITEM NO.', '條碼'], description: '' },
                        '外箱': { options: ['瓦楞紙箱', '易碎標誌'], description: '' },
                        '運輸與托盤要求': { options: ['托盤/Pallet'], description: '' },
                        '裝櫃要求': { options: [], description: '' },
                        '其他說明': { options: [], description: '' }
                    },
                    applicant: 'Test User',
                    approvalDate: new Date(Date.now() - 86400000).toISOString()
                },
                {
                    id: '1700000003',
                    submitDate: new Date(Date.now() - 259200000).toISOString(),
                    status: 'REJECTED',
                    itemCode: 'M01.D.00001',
                    mainCategory: 'M',
                    subCategory: '01',
                    specCategory: 'D',
                    itemNameCN: '抽屜系統',
                    itemNameEN: 'Drawer System',
                    customerRef: 'CUST-003',
                    supplier: 'SUP003',
                    material: 'Steel',
                    surfaceFinish: 'Powder',
                    dimensions: { length: 500, width: 400, height: 150, weight: 2500 },
                    moq: 50,
                    unit: 'SET',
                    packaging: {
                        '產品包裝': { options: ['彩盒包裝'], description: '' },
                        '配件內容': { options: ['螺絲', '支架'], description: '' },
                        '配件': { options: [], description: '' },
                        '內盒': { options: ['客戶Logo'], description: '' },
                        '外箱': { options: ['瓦楞紙箱'], description: '' },
                        '運輸與托盤要求': { options: [], description: '' },
                        '裝櫃要求': { options: [], description: '' },
                        '其他說明': { options: [], description: '' }
                    },
                    applicant: 'Test User',
                    rejectDate: new Date(Date.now() - 172800000).toISOString(),
                    rejectReason: '材質規格不符'
                }
            ];
            
            applications = [...applications, ...testApplications];
            localStorage.setItem('applications_v35', JSON.stringify(applications));
            updatePendingCount();
            alert('已載入測試資料！');
        }
        
        // 清除所有資料（開發用）
        function clearAllData() {
            if (confirm('確定要清除所有資料嗎？此操作無法復原！')) {
                localStorage.removeItem('applications_v35');
                localStorage.removeItem('codeCounter_v35');
                localStorage.removeItem('settings_v35');
                localStorage.removeItem('draft_v35');
                applications = [];
                codeCounter = {};
                settings = {};
                updatePendingCount();
                alert('所有資料已清除！');
                location.reload();
            }
        }
        
        // 開發者控制台命令
        window.dev = {
            loadTestData,
            clearAllData,
            showApplications: () => console.table(applications),
            showSettings: () => console.log(settings),
            showCodeCounter: () => console.log(codeCounter)
        };
        
        console.log('%c物料編碼申請管理系統 V3.5 優化版', 'color: #2563eb; font-size: 20px; font-weight: bold;');
        console.log('%c開發者命令：', 'color: #10b981; font-size: 14px;');
        console.log('dev.loadTestData() - 載入測試資料');
        console.log('dev.clearAllData() - 清除所有資料');
        console.log('dev.showApplications() - 顯示所有申請');
        console.log('dev.showSettings() - 顯示系統設定');
        console.log('dev.showCodeCounter() - 顯示編碼計數器');
    </script>
</body>
</html>