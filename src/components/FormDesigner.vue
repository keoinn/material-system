<template>
  <v-card>
    <v-card-title class="system-header d-flex align-center">
      <h2 class="ma-0">{{ isEditMode ? '編輯表單' : '建立新表單' }}</h2>
      <v-spacer />
      <div class="d-flex align-center" style="gap: 8px;">
        <v-btn
          v-if="isEditMode"
          color="primary"
          size="small"
          variant="outlined"
          @click="loadForm"
        >
          <v-icon start>mdi-refresh</v-icon>
          重新載入
        </v-btn>
        <v-btn
          color="grey-darken-1"
          size="small"
          variant="outlined"
          @click="handleCancel"
        >
          <v-icon start>mdi-close</v-icon>
          關閉
        </v-btn>
      </div>
    </v-card-title>

    <v-card-text class="pt-6">
      <!-- 儲存進度條 -->
      <v-progress-linear
        v-if="saving"
        class="mb-4"
        color="primary"
        height="24"
        :model-value="saveProgress"
      >
        <template #default="{ value }">
          <strong :class="value < 50 ? 'text-grey-darken-3' : 'text-white'">
            {{ Math.ceil(value) }}%
          </strong>
        </template>
      </v-progress-linear>

      <v-tabs v-model="activeTab" class="mb-4">
        <v-tab value="basic">
          <v-icon start>mdi-information</v-icon>
          基本資訊
        </v-tab>
        <v-tab value="fields">
          <v-icon start>mdi-form-select</v-icon>
          欄位設定
          <v-badge
            v-if="fields.length > 0"
            class="ml-2"
            color="primary"
            :content="fields.length"
            inline
          />
        </v-tab>
        <v-tab value="preview">
          <v-icon start>mdi-eye</v-icon>
          預覽
        </v-tab>
      </v-tabs>

      <v-window v-model="activeTab">
        <!-- 基本資訊 -->
        <v-window-item value="basic">
          <v-form ref="basicFormRef" v-model="basicFormValid">
            <v-row>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="formData.form_code"
                  :disabled="isEditMode"
                  hint="唯一識別碼，例如：material_application"
                  label="表單代碼 *"
                  :rules="[rules.required, rules.formCode]"
                  variant="outlined"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-switch
                  v-model="formData.is_active"
                  color="primary"
                  hide-details
                  label="啟用"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="formData.form_name"
                  label="表單名稱（中文） *"
                  :rules="[rules.required]"
                  variant="outlined"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-text-field
                  v-model="formData.form_name_en"
                  label="表單名稱（英文）"
                  variant="outlined"
                />
              </v-col>
              <v-col cols="12">
                <v-textarea
                  v-model="formData.description"
                  label="表單說明"
                  rows="3"
                  variant="outlined"
                />
              </v-col>
              <v-col cols="12" md="6">
                <v-switch
                  v-model="formData.is_default"
                  color="primary"
                  hide-details
                  label="設為預設表單"
                />
              </v-col>
            </v-row>
          </v-form>
        </v-window-item>

        <!-- 欄位設定 -->
        <v-window-item ref="fieldsTabRef" value="fields">
          <div ref="fieldsHeaderRef" class="d-flex justify-space-between align-center mb-4">
            <div class="d-flex align-center" style="gap: 8px;">
              <h3 class="mb-0">表單欄位</h3>
              <v-btn
                color="primary"
                :disabled="!canSave"
                :loading="saving"
                @click="saveForm"
              >
                <v-icon start>mdi-content-save</v-icon>
                儲存表單
              </v-btn>
              <v-btn
                color="grey"
                variant="outlined"
                @click="handleCancel"
              >
                取消
              </v-btn>
            </div>
            <div class="d-flex align-center" style="gap: 8px;">
              <v-btn
                color="info"
                variant="outlined"
                @click="openGroupOrderDialog"
              >
                <v-icon start>mdi-sort</v-icon>
                群組管理
              </v-btn>
              <v-btn
                color="primary"
                @click="openFieldDialog(null)"
              >
                <v-icon start>mdi-plus</v-icon>
                新增欄位
              </v-btn>
              <v-btn
                color="secondary"
                variant="outlined"
                @click="toggleAllGroups"
              >
                <v-icon start>{{ allGroupsExpanded ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
                折疊/展開全部
              </v-btn>
              <v-btn
                :color="floatingWindowVisible ? 'primary' : 'default'"
                icon
                variant="text"
                @click="toggleFloatingWindow"
              >
                <v-icon>{{ floatingWindowVisible ? 'mdi-close' : 'mdi-window-restore' }}</v-icon>
              </v-btn>
            </div>
          </div>

          <!-- 懸浮視窗：表單欄位功能按鈕 -->
          <v-card
            v-if="floatingWindowVisible"
            class="fields-floating-window"
            elevation="8"
          >
            <v-card-text class="pa-3">
              <div class="d-flex align-center justify-space-between mb-3">
                <h3 class="mb-0 text-h6">表單欄位功能</h3>
                <v-btn
                  icon
                  size="small"
                  variant="text"
                  @click="toggleFloatingWindow"
                >
                  <v-icon>mdi-close</v-icon>
                </v-btn>
              </div>
              <v-divider class="mb-3" />
              <div class="d-flex align-center" style="gap: 8px; flex-wrap: wrap;">
                <v-btn
                  color="primary"
                  :disabled="!canSave"
                  :loading="saving"
                  size="small"
                  @click="saveForm"
                >
                  <v-icon start>mdi-content-save</v-icon>
                  儲存表單
                </v-btn>
                <v-btn
                  color="grey"
                  size="small"
                  variant="outlined"
                  @click="handleCancel"
                >
                  取消
                </v-btn>
                <v-divider vertical />
                <v-btn
                  color="info"
                  size="small"
                  variant="outlined"
                  @click="openGroupOrderDialog"
                >
                  <v-icon start>mdi-sort</v-icon>
                  群組管理
                </v-btn>
                <v-btn
                  color="primary"
                  size="small"
                  @click="openFieldDialog(null)"
                >
                  <v-icon start>mdi-plus</v-icon>
                  新增欄位
                </v-btn>
                <v-btn
                  color="secondary"
                  size="small"
                  variant="outlined"
                  @click="toggleAllGroups"
                >
                  <v-icon start>{{ allGroupsExpanded ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
                  折疊/展開全部
                </v-btn>
              </div>
            </v-card-text>
          </v-card>

          <!-- 按群組顯示欄位 -->
          <div>
            <template v-for="(group, groupName) in groupedFieldsForDesign" :key="groupName">
              <!-- 群組標題 -->
              <v-card
                v-if="groupName === '未分組欄位' || groupOrder.includes(groupName) || (group && ((group.subGroups && Object.keys(group.subGroups).length > 0) || (group.ungrouped && group.ungrouped.length > 0)))"
                class="mb-4 group-card"
                :class="{ 'drag-target': dragOverGroup === groupName && !draggedFromGroup }"
                variant="outlined"
              >
                <v-card-title
                  class="d-flex align-center bg-primary text-white py-2"
                  style="cursor: pointer;"
                  @click="toggleGroup(groupName)"
                >
                  <v-icon class="mr-2">{{ isGroupExpanded(groupName) ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
                  <v-icon class="mr-2">mdi-folder</v-icon>
                  <span>{{ groupName || '未分組欄位' }}</span>
                  <v-spacer />
                  <v-chip color="white" size="small" variant="flat">
                    {{ getGroupFieldCount(group) }} 個欄位
                  </v-chip>
                  <v-btn
                    v-if="groupName && groupName !== '未分組欄位'"
                    class="ml-2"
                    icon
                    size="small"
                    variant="text"
                    @click.stop="openGroupDialog(groupName)"
                  >
                    <v-icon>mdi-pencil</v-icon>
                  </v-btn>
                </v-card-title>

                <v-card-text v-show="isGroupExpanded(groupName)" class="pa-0">
                  <!-- 按子群組分組顯示欄位 -->
                  <template v-for="(subGroup, subGroupName) in getSubGroupsForDisplay(groupName, group)" :key="subGroupName">
                    <!-- 子群組容器（用方框包圍） -->
                    <div v-if="subGroupName" class="subgroup-container">
                      <div class="subgroup-header">
                        <v-icon class="mr-2" size="small">mdi-view-grid</v-icon>
                        <span class="subgroup-title">{{ subGroupName }}</span>
                      </div>
                      <div class="subgroup-content pl-4 pr-4">
                        <v-list
                          :class="`subgroup-field-list-${subGroupName}`"
                          @dragenter.prevent="handleDragEnter($event, groupName, subGroupName)"
                          @dragleave="handleDragLeave($event, groupName, subGroupName)"
                          @dragover.prevent="handleDragOver($event, groupName, subGroupName)"
                          @drop="handleDrop($event, groupName, subGroupName)"
                        >
                          <!-- 空子群組提示 -->
                          <div v-if="!subGroup || subGroup.length === 0" class="text-center pa-8 text-grey">
                            <v-icon color="grey-lighten-1" size="48">mdi-drag-horizontal</v-icon>
                            <div class="text-body-2 mt-2">拖曳欄位到此子群組</div>
                          </div>
                          <template v-for="(field, index) in subGroup" :key="field.id || field.field_key || `temp-${index}`">
                            <div
                              v-if="dragOverGroup === groupName && dragOverSubGroup === subGroupName && dragOverIndex === index && draggedField"
                              class="drop-indicator"
                            >
                              <v-divider class="border-opacity-100" style="border-width: 2px; border-color: #1976d2;" />
                              <div class="text-caption text-center pa-2 text-primary">
                                放置在此處
                              </div>
                            </div>

                            <v-list-item
                              class="border-bottom draggable-field"
                              :class="{
                                'dragging': draggedField && draggedFromGroup === groupName && draggedFromSubGroup === subGroupName && draggedFromIndex === index,
                                'drag-over': dragOverIndex === index && dragOverGroup === groupName && dragOverSubGroup === subGroupName
                              }"
                              draggable="true"
                              @dragend="handleDragEnd"
                              @dragover.prevent="handleItemDragOver($event, groupName, index, subGroupName)"
                              @dragstart="handleDragStart($event, field, groupName, index, subGroupName)"
                            >
                              <template #prepend>
                                <div class="d-flex flex-column mr-2">
                                  <v-btn
                                    :disabled="index === 0"
                                    icon
                                    size="x-small"
                                    variant="text"
                                    @click.stop="moveFieldUpInSubGroup(groupName, subGroupName, index)"
                                  >
                                    <v-icon>mdi-chevron-up</v-icon>
                                  </v-btn>
                                  <v-btn
                                    :disabled="index === subGroup.length - 1"
                                    icon
                                    size="x-small"
                                    variant="text"
                                    @click.stop="moveFieldDownInSubGroup(groupName, subGroupName, index)"
                                  >
                                    <v-icon>mdi-chevron-down</v-icon>
                                  </v-btn>
                                </div>
                              </template>

                              <v-list-item-title>
                                <div class="d-flex align-center">
                                  <span class="font-weight-bold">{{ getFieldDisplayLabel(field) }}</span>
                                  <v-chip
                                    class="ml-2"
                                    :color="getFieldTypeColor(field.field_type)"
                                    size="small"
                                  >
                                    {{ getFieldTypeLabel(field.field_type) }}
                                  </v-chip>
                                  <v-chip
                                    v-if="field.is_required"
                                    class="ml-2"
                                    color="error"
                                    size="small"
                                  >
                                    必填
                                  </v-chip>
                                </div>
                              </v-list-item-title>

                              <v-list-item-subtitle>
                                <div class="d-flex align-center mt-1">
                                  <span v-if="shouldShowFieldKey(field)" class="text-caption">鍵值：{{ getFieldDisplayKey(field) }}</span>
                                  <span class="text-caption" :class="shouldShowFieldKey(field) ? 'ml-4' : ''">
                                    寬度：{{ getFieldTotalWidth(field) }}/12
                                  </span>
                                  <span class="text-caption ml-4">
                                    順序：{{ field.display_order || index + 1 }}
                                  </span>
                                </div>
                              </v-list-item-subtitle>

                              <template #append>
                                <div class="d-flex">
                                  <v-btn
                                    icon
                                    size="small"
                                    variant="text"
                                    @click="openFieldDialog(field, getFieldIndexInAllFields(field))"
                                  >
                                    <v-icon>mdi-pencil</v-icon>
                                  </v-btn>
                                  <v-btn
                                    color="error"
                                    icon
                                    size="small"
                                    variant="text"
                                    @click="deleteField(getFieldIndexInAllFields(field))"
                                  >
                                    <v-icon>mdi-delete</v-icon>
                                  </v-btn>
                                </div>
                              </template>
                            </v-list-item>
                          </template>
                        </v-list>
                      </div>
                    </div>

                    <!-- 未分組到子群組的欄位 -->
                    <v-list
                      v-else
                      :class="`field-list-${groupName}`"
                      @dragenter.prevent="handleDragEnter($event, groupName)"
                      @dragleave="handleDragLeave($event, groupName)"
                      @dragover.prevent="handleDragOver($event, groupName)"
                      @drop="handleDrop($event, groupName)"
                    >
                      <!-- 空群組提示（當沒有欄位時顯示） -->
                      <div v-if="!subGroup || subGroup.length === 0" class="text-center pa-8 text-grey">
                        <v-icon color="grey-lighten-1" size="48">mdi-drag-horizontal</v-icon>
                        <div class="text-body-2 mt-2">拖曳欄位到此群組</div>
                      </div>
                      <template v-for="(field, index) in subGroup" :key="field.id || field.field_key || `temp-${index}`">
                        <div
                          v-if="dragOverGroup === groupName && dragOverIndex === index && draggedField"
                          class="drop-indicator"
                        >
                          <v-divider class="border-opacity-100" style="border-width: 2px; border-color: #1976d2;" />
                          <div class="text-caption text-center pa-2 text-primary">
                            放置在此處
                          </div>
                        </div>

                        <v-list-item
                          class="border-bottom draggable-field"
                          :class="{
                            'dragging': draggedField && draggedFromGroup === groupName && draggedFromIndex === index,
                            'drag-over': dragOverIndex === index && dragOverGroup === groupName
                          }"
                          draggable="true"
                          @dragend="handleDragEnd"
                          @dragover.prevent="handleItemDragOver($event, groupName, index)"
                          @dragstart="handleDragStart($event, field, groupName, index)"
                        >
                          <template #prepend>
                            <div class="d-flex flex-column mr-2">
                              <v-btn
                                :disabled="index === 0"
                                icon
                                size="x-small"
                                variant="text"
                                @click.stop="moveFieldUpInGroup(groupName, index)"
                              >
                                <v-icon>mdi-chevron-up</v-icon>
                              </v-btn>
                              <v-btn
                                :disabled="index === subGroup.length - 1"
                                icon
                                size="x-small"
                                variant="text"
                                @click.stop="moveFieldDownInGroup(groupName, index)"
                              >
                                <v-icon>mdi-chevron-down</v-icon>
                              </v-btn>
                            </div>
                          </template>

                          <v-list-item-title>
                            <div class="d-flex align-center">
                              <span class="font-weight-bold">{{ getFieldDisplayLabel(field) }}</span>
                              <v-chip
                                class="ml-2"
                                :color="getFieldTypeColor(field.field_type)"
                                size="small"
                              >
                                {{ getFieldTypeLabel(field.field_type) }}
                              </v-chip>
                              <v-chip
                                v-if="field.is_required"
                                class="ml-2"
                                color="error"
                                size="small"
                              >
                                必填
                              </v-chip>
                            </div>
                          </v-list-item-title>

                          <v-list-item-subtitle>
                            <div class="d-flex align-center mt-1">
                              <span v-if="shouldShowFieldKey(field)" class="text-caption">鍵值：{{ getFieldDisplayKey(field) }}</span>
                              <span class="text-caption" :class="shouldShowFieldKey(field) ? 'ml-4' : ''">
                                寬度：{{ getFieldTotalWidth(field) }}/12
                              </span>
                              <span class="text-caption ml-4">
                                順序：{{ field.display_order || index + 1 }}
                              </span>
                            </div>
                          </v-list-item-subtitle>

                          <template #append>
                            <div class="d-flex">
                              <v-btn
                                icon
                                size="small"
                                variant="text"
                                @click="openFieldDialog(field, getFieldIndexInAllFields(field))"
                              >
                                <v-icon>mdi-pencil</v-icon>
                              </v-btn>
                              <v-btn
                                color="error"
                                icon
                                size="small"
                                variant="text"
                                @click="deleteField(getFieldIndexInAllFields(field))"
                              >
                                <v-icon>mdi-delete</v-icon>
                              </v-btn>
                            </div>
                          </template>
                        </v-list-item>
                      </template>
                    </v-list>
                  </template>

                  <!-- 空群組提示（當群組沒有任何子群組和未分組欄位時顯示） -->
                  <div
                    v-if="(group.subGroups && Object.keys(group.subGroups).length === 0 && (!group.ungrouped || group.ungrouped.length === 0))"
                    class="text-center pa-8 text-grey"
                    style="min-height: 100px;"
                    @dragenter.prevent="handleDragEnter($event, groupName)"
                    @dragleave="handleDragLeave($event, groupName)"
                    @dragover.prevent="handleDragOver($event, groupName)"
                    @drop="handleDrop($event, groupName)"
                  >
                    <v-icon color="grey-lighten-1" size="48">mdi-drag-horizontal</v-icon>
                    <div class="text-body-2 mt-2">拖曳欄位到此群組</div>
                  </div>
                </v-card-text>
              </v-card>
            </template>

            <!-- 當沒有任何群組和欄位時顯示提示 -->
            <v-card v-if="fields.length === 0 && groupOrder.length === 0" class="text-center pa-8">
              <v-icon color="grey" size="64">mdi-form-select</v-icon>
              <div class="text-h6 mt-4 text-grey">尚未新增任何欄位</div>
              <div class="text-body-2 text-grey mt-2">點擊「新增欄位」開始建立表單欄位</div>
            </v-card>
          </div>

          <!-- 返回頂部按鈕 -->
          <div class="text-center mt-6 mb-4">
            <v-btn
              color="primary"
              variant="outlined"
              @click="scrollToFieldsTop"
            >
              <v-icon start>mdi-arrow-up</v-icon>
              返回頂部
            </v-btn>
          </div>
        </v-window-item>

        <!-- 預覽 -->
        <v-window-item value="preview">
          <v-alert
            v-if="fields.length === 0"
            class="mb-4"
            type="info"
            variant="tonal"
          >
            請先新增欄位才能預覽表單
          </v-alert>
          <v-card v-else class="preview-form">
            <v-card-text class="pt-6">
              <v-form>
                <template v-for="(group, groupName) in previewGroupedFields" :key="groupName">
                  <div v-if="(group.subGroups && Object.keys(group.subGroups).length > 0) || (group.ungrouped && group.ungrouped.length > 0) && groupName !== '_ungrouped'" class="form-section">
                    <h3>{{ groupName }}</h3>
                    <!-- 按子群組分組顯示 -->
                    <template v-for="(subGroup, subGroupName) in getSubGroupsForDisplay(groupName, group)" :key="subGroupName">
                      <!-- 子群組容器（用方框包圍） -->
                      <div v-if="subGroupName" class="subgroup-container">
                        <div class="subgroup-header">
                          <v-icon class="mr-2" size="small">mdi-view-grid</v-icon>
                          <span class="subgroup-title">{{ subGroupName }}</span>
                        </div>
                        <div class="subgroup-content pl-4 pr-4">
                          <v-row>
                            <template v-for="field in subGroup" :key="field.id || field.field_key">
                              <v-col
                                :cols="getFieldCols(field)"
                                :md="getFieldMd(field)"
                              >
                                <component
                                  :is="getFieldComponent(field.field_type)"
                                  :field="field"
                                  :model-value="previewValues[field.field_key]"
                                  :options="getFieldOptions(field)"
                                  :use-chip-style="field.field_type === 'checkbox'"
                                  @update:model-value="previewValues[field.field_key] = $event"
                                />
                              </v-col>
                            </template>
                          </v-row>
                        </div>
                      </div>

                      <!-- 未分組到子群組的欄位 -->
                      <v-row v-else>
                        <template v-for="field in subGroup" :key="field.id || field.field_key">
                          <v-col
                            :cols="getFieldCols(field)"
                            :md="getFieldMd(field)"
                          >
                            <component
                              :is="getFieldComponent(field.field_type)"
                              :field="field"
                              :model-value="previewValues[field.field_key]"
                              :options="getFieldOptions(field)"
                              :use-chip-style="field.field_type === 'checkbox'"
                              @update:model-value="previewValues[field.field_key] = $event"
                            />
                          </v-col>
                        </template>
                      </v-row>
                    </template>
                  </div>
                </template>
                <div v-if="previewUngroupedFields.length > 0" class="form-section">
                  <h3>未分組欄位</h3>
                  <v-row>
                    <template v-for="field in previewUngroupedFields" :key="field.id || field.field_key">
                      <v-col
                        :cols="getFieldCols(field)"
                        :md="getFieldMd(field)"
                      >
                        <component
                          :is="getFieldComponent(field.field_type)"
                          :field="field"
                          :model-value="previewValues[field.field_key]"
                          :options="getFieldOptions(field)"
                          @update:model-value="previewValues[field.field_key] = $event"
                        />
                      </v-col>
                    </template>
                  </v-row>
                </div>
              </v-form>
            </v-card-text>
          </v-card>
        </v-window-item>
      </v-window>

      <v-divider class="my-4" />

    </v-card-text>

    <!-- 欄位編輯對話框 -->
    <v-dialog
      v-model="fieldDialog"
      max-width="800"
      persistent
      scrollable
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary text-white">
          <v-icon class="mr-2">{{ editingFieldIndex !== null ? 'mdi-pencil' : 'mdi-plus' }}</v-icon>
          <span>{{ editingFieldIndex !== null ? '編輯欄位' : '新增欄位' }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeFieldDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-form ref="fieldFormRef" v-model="fieldFormValid">
            <v-row>
              <!-- 非多層選單類型的通用設定 -->
              <template v-if="!needsCascadingLevels">
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="fieldData.field_key"
                    :disabled="editingFieldIndex !== null"
                    hint="唯一識別碼，例如：item_name_cn"
                    label="欄位鍵值 *"
                    :rules="[rules.required, rules.fieldKey]"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-select
                    v-model="fieldData.field_type"
                    :items="fieldTypeOptions"
                    label="欄位類型 *"
                    :rules="[rules.required]"
                    variant="outlined"
                    @update:model-value="handleFieldTypeChange"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="fieldData.field_label"
                    label="欄位標籤（中文） *"
                    :rules="[rules.required]"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-text-field
                    v-model="fieldData.field_label_en"
                    label="欄位標籤（英文）"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12" md="4">
                  <v-select
                    v-model="fieldData.columnSize"
                    hint="用於 RWD 響應式佈局（12 = 全寬，6 = 半寬，4 = 1/3 寬）"
                    :items="columnSizeOptions"
                    label="欄位寬度（占行數）"
                    persistent-hint
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12" md="4">
                  <v-text-field
                    v-model.number="fieldData.display_order"
                    label="顯示順序"
                    type="number"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-combobox
                    v-model="fieldData.field_group"
                    clearable
                    hint="選擇現有群組或輸入新群組名稱，用於分組顯示"
                    item-title="title"
                    item-value="value"
                    :items="availableGroups"
                    label="群組名稱"
                    :menu-props="{ maxHeight: 200 }"
                    variant="outlined"
                    @update:model-value="handleFieldGroupChange"
                  >
                    <template #append-item>
                      <v-list-item @click="openGroupDialog(null)">
                        <v-list-item-title class="text-primary">
                          <v-icon start>mdi-folder-plus</v-icon>
                          管理群組
                        </v-list-item-title>
                      </v-list-item>
                    </template>
                  </v-combobox>
                </v-col>
                <v-col cols="12" md="6">
                  <v-combobox
                    v-model="fieldData.sub_group"
                    clearable
                    :disabled="!fieldData.field_group"
                    hint="選擇現有子群組或輸入新子群組名稱，用於排版顯示"
                    item-title="title"
                    item-value="value"
                    :items="availableSubGroups"
                    label="子群組名稱"
                    :menu-props="{ maxHeight: 200 }"
                    variant="outlined"
                    @update:model-value="handleFieldSubGroupChange"
                  >
                    <template #append-item>
                      <v-list-item
                        v-if="fieldData.field_group"
                        @click="openSubGroupDialog(fieldData.field_group, null)"
                      >
                        <v-list-item-title class="text-primary">
                          <v-icon start>mdi-view-grid-plus</v-icon>
                          管理子群組
                        </v-list-item-title>
                      </v-list-item>
                    </template>
                  </v-combobox>
                </v-col>
                <v-col cols="12" md="6">
                  <v-switch
                    v-model="fieldData.is_required"
                    color="primary"
                    hide-details
                    label="必填"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-switch
                    v-model="fieldData.is_visible"
                    color="primary"
                    hide-details
                    label="顯示"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-switch
                    v-model="fieldData.is_readonly"
                    color="primary"
                    hide-details
                    label="唯讀"
                  />
                </v-col>
                <v-col cols="12" md="6">
                  <v-switch
                    v-model="fieldData.is_in_template"
                    color="primary"
                    hide-details
                    label="加入模板"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model="fieldData.placeholder"
                    label="提示文字"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12">
                  <v-textarea
                    v-model="fieldData.help_text"
                    label="說明文字"
                    rows="2"
                    variant="outlined"
                  />
                </v-col>
                <v-col cols="12">
                  <v-text-field
                    v-model="fieldData.default_value"
                    label="預設值"
                    variant="outlined"
                  />
                </v-col>
              </template>

              <!-- 欄位類型特定設定 -->
              <v-col v-if="needsOptions" cols="12">
                <v-card class="pa-4" variant="outlined">
                  <v-card-title class="text-subtitle-1 d-flex align-center">
                    <span>選項設定</span>
                    <v-spacer />
                    <v-btn
                      color="primary"
                      size="small"
                      @click="addOption"
                    >
                      <v-icon start>mdi-plus</v-icon>
                      新增選項
                    </v-btn>
                    <v-btn
                      v-if="fieldData.field_type === 'select' || fieldData.field_type === 'multiselect'"
                      class="ml-2"
                      color="info"
                      size="small"
                      variant="outlined"
                      @click="loadExampleOptions"
                    >
                      <v-icon start>mdi-lightbulb</v-icon>
                      載入範例
                    </v-btn>
                  </v-card-title>
                  <v-card-text>
                    <v-alert
                      v-if="fieldOptions.length === 0"
                      class="mb-4"
                      type="info"
                      variant="tonal"
                    >
                      <div class="text-body-2">
                        <strong>提示：</strong>
                        <ul class="mt-2">
                          <li v-if="fieldData.field_type === 'select'">下拉選單需要至少一個選項</li>
                          <li v-if="fieldData.field_type === 'multiselect'">多選下拉需要至少一個選項</li>
                          <li v-if="fieldData.field_type === 'checkbox'">複選框需要至少一個選項</li>
                          <li v-if="fieldData.field_type === 'radio'">單選框需要至少一個選項</li>
                        </ul>
                      </div>
                    </v-alert>
                    <v-list v-if="fieldOptions.length > 0">
                      <v-list-item
                        v-for="(option, index) in fieldOptions"
                        :key="index"
                        class="mb-2 border"
                      >
                        <v-row>
                          <v-col cols="12" md="5">
                            <v-text-field
                              v-model="option.value"
                              density="compact"
                              label="值 *"
                              :rules="[v => !!v || '值為必填']"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="5">
                            <v-text-field
                              v-model="option.label"
                              density="compact"
                              label="標籤 *"
                              :rules="[v => !!v || '標籤為必填']"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col class="d-flex align-center" cols="12" md="2">
                            <v-btn
                              color="error"
                              icon
                              size="small"
                              @click="removeOption(index)"
                            >
                              <v-icon>mdi-delete</v-icon>
                            </v-btn>
                          </v-col>
                        </v-row>
                      </v-list-item>
                    </v-list>
                    <v-alert
                      v-if="fieldData.field_type === 'multiselect' && fieldOptions.length > 0"
                      class="mt-4"
                      type="info"
                      variant="tonal"
                    >
                      <div class="text-body-2">
                        <strong>多選下拉說明：</strong>
                        <br>
                        使用者可以選擇多個選項，值會以陣列形式儲存，例如：["tag1", "tag2"]
                      </div>
                    </v-alert>
                  </v-card-text>
                </v-card>
              </v-col>

              <!-- 聚合資料模板設定 -->
              <v-col v-if="needsAggregatedTemplate" cols="12">
                <v-card class="pa-4" variant="outlined">
                  <v-card-title class="text-subtitle-1 d-flex align-center">
                    <v-icon class="mr-2">mdi-code-braces</v-icon>
                    <span>聚合模板設定</span>
                  </v-card-title>
                  <v-card-text>
                    <v-textarea
                      v-model="fieldData.field_config.template"
                      hint="使用 {#欄位鍵值} 引用其他欄位的值，使用 {@sn#位數} 表示系統計數序號。例如：{#type}.{#subtype}.{#detail}.{@sn#5}"
                      label="聚合模板 *"
                      persistent-hint
                      rows="3"
                      :rules="[rules.required]"
                      variant="outlined"
                    />
                    <v-alert
                      class="mt-4"
                      type="info"
                      variant="tonal"
                    >
                      <div class="text-body-2">
                        <strong>模板語法說明：</strong>
                        <ul class="mt-2">
                          <li><code>{#欄位鍵值}</code>：引用其他欄位的值，例如 <code>{#type}</code> 會取得欄位鍵值為 "type" 的值</li>
                          <li><code>{@sn#位數}</code>：系統計數序號，例如 <code>{@sn#5}</code> 會產生 5 位數的序號（不足補零），如 00005</li>
                        </ul>
                        <div class="mt-2">
                          <strong>範例：</strong>
                          <br>
                          模板：<code>{#type}.{#subtype}.{#detail}.{@sn#5}</code>
                          <br>
                          當 type = "D", subtype = "S", detail = "A", 系統計數器 = 5 時
                          <br>
                          結果：<code>D.S.A.00005</code>
                        </div>
                      </div>
                    </v-alert>
                    <v-text-field
                      v-model.number="fieldData.field_config.counterValue"
                      class="mt-4"
                      hint="用於測試，實際使用時會從系統獲取"
                      label="系統計數器值"
                      min="0"
                      persistent-hint
                      type="number"
                      variant="outlined"
                    />
                  </v-card-text>
                </v-card>
              </v-col>

              <!-- 多層選單配置 -->
              <template v-if="needsCascadingLevels">
                <!-- 區塊 1: 共通設定 -->
                <v-col cols="12">
                  <v-card class="pa-4" variant="outlined">
                    <v-card-title class="text-subtitle-1">
                      <v-icon class="mr-2">mdi-cog</v-icon>
                      共通設定
                    </v-card-title>
                    <v-card-text>
                      <v-row>
                        <v-col cols="12" md="6">
                          <v-select
                            v-model="fieldData.field_type"
                            disabled
                            :items="fieldTypeOptions"
                            label="欄位類型 *"
                            :rules="[rules.required]"
                            variant="outlined"
                          />
                        </v-col>
                        <v-col cols="12" md="6">
                          <v-text-field
                            v-model.number="cascadingLevelCount"
                            hint="設定下拉選單的層級數量（1-10）"
                            label="層次數量 *"
                            max="10"
                            min="1"
                            persistent-hint
                            type="number"
                            variant="outlined"
                            @update:model-value="updateCascadingLevelCount"
                          />
                        </v-col>
                        <v-col cols="12" md="6">
                          <v-combobox
                            v-model="fieldData.field_group"
                            clearable
                            hint="選擇現有群組或輸入新群組名稱"
                            item-title="title"
                            item-value="value"
                            :items="availableGroups"
                            label="群組名稱"
                            :menu-props="{ maxHeight: 200 }"
                            variant="outlined"
                            @update:model-value="handleFieldGroupChange"
                          >
                            <template #append-item>
                              <v-list-item @click="openGroupDialog(null)">
                                <v-list-item-title class="text-primary">
                                  <v-icon start>mdi-folder-plus</v-icon>
                                  管理群組
                                </v-list-item-title>
                              </v-list-item>
                            </template>
                          </v-combobox>
                        </v-col>
                        <v-col cols="12" md="6">
                          <v-combobox
                            v-model="fieldData.sub_group"
                            clearable
                            :disabled="!fieldData.field_group"
                            hint="選擇現有子群組或輸入新子群組名稱"
                            item-title="title"
                            item-value="value"
                            :items="availableSubGroups"
                            label="子群組名稱"
                            :menu-props="{ maxHeight: 200 }"
                            variant="outlined"
                            @update:model-value="handleFieldSubGroupChange"
                          >
                            <template #append-item>
                              <v-list-item
                                v-if="fieldData.field_group"
                                @click="openSubGroupDialog(fieldData.field_group, null)"
                              >
                                <v-list-item-title class="text-primary">
                                  <v-icon start>mdi-view-grid-plus</v-icon>
                                  管理子群組
                                </v-list-item-title>
                              </v-list-item>
                            </template>
                          </v-combobox>
                        </v-col>
                      </v-row>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 區塊 2: 多層式選單設定（根據層次數量動態生成） -->
                <v-col cols="12">
                  <v-card class="pa-4" variant="outlined">
                    <v-card-title class="text-subtitle-1 d-flex align-center">
                      <v-icon class="mr-2">mdi-menu</v-icon>
                      <span>多層式選單設定</span>
                      <v-spacer />
                      <v-chip color="primary" size="small" variant="flat">
                        {{ cascadingLevelCount }} 層
                      </v-chip>
                    </v-card-title>
                    <v-card-text>
                      <v-alert
                        v-if="cascadingLevels.length === 0"
                        class="mb-4"
                        type="info"
                        variant="tonal"
                      >
                        <div class="text-body-2">
                          <strong>提示：</strong>
                          請先在「共通設定」中設定層次數量，系統會自動生成對應的層級設定。
                        </div>
                      </v-alert>

                      <!-- 主欄位鍵值設定 -->
                      <v-row class="mb-4">
                        <v-col cols="12" md="6">
                          <v-text-field
                            v-model="fieldData.field_key"
                            hint="多層式選單的主欄位鍵值，用於資料庫儲存和程式碼識別"
                            label="欄位鍵值 *"
                            :rules="[rules.required, rules.fieldKey]"
                            persistent-hint
                            variant="outlined"
                          />
                        </v-col>
                      </v-row>

                      <!-- 根據層次數量動態生成設定 -->
                      <div v-for="(level, levelIndex) in cascadingLevels" :key="levelIndex" class="mb-6 border pa-4 rounded">
                        <div class="d-flex align-center mb-3">
                          <v-icon class="mr-2" color="primary">mdi-layers</v-icon>
                          <h3 class="text-h6">層級 {{ levelIndex + 1 }} 設定</h3>
                          <v-spacer />
                          <v-btn
                            :disabled="levelIndex === 0"
                            icon="mdi-arrow-up"
                            size="small"
                            variant="text"
                            @click="moveCascadingLevelUp(levelIndex)"
                          />
                          <v-btn
                            :disabled="levelIndex === cascadingLevels.length - 1"
                            icon="mdi-arrow-down"
                            size="small"
                            variant="text"
                            @click="moveCascadingLevelDown(levelIndex)"
                          />
                        </div>

                        <v-row>
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="level.field_key"
                              :disabled="editingFieldIndex !== null && levelIndex === 0"
                              :hint="levelIndex === 0 ? '唯一識別碼，例如：cascading_category_level_1' : '自動生成，可手動修改'"
                              :label="`層級 ${levelIndex + 1} 欄位鍵值 *`"
                              persistent-hint
                              :rules="[rules.required, rules.fieldKey]"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="level.field_label"
                              :label="`層級 ${levelIndex + 1} 欄位標籤（中文） *`"
                              :rules="[rules.required]"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="3">
                            <v-switch
                              v-model="level.is_required"
                              color="primary"
                              hide-details
                              :label="`必填（層級 ${levelIndex + 1}）`"
                            />
                          </v-col>
                          <v-col cols="12" md="3">
                            <v-switch
                              v-model="level.is_visible"
                              color="primary"
                              hide-details
                              :label="`顯示（層級 ${levelIndex + 1}）`"
                            />
                          </v-col>
                          <v-col cols="12" md="3">
                            <v-select
                              v-model="level.columnSize"
                              hint="用於 RWD 響應式佈局"
                              :items="columnSizeOptions"
                              :label="`欄寬（層級 ${levelIndex + 1}）`"
                              persistent-hint
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="3">
                            <v-text-field
                              v-model.number="level.display_order"
                              :label="`顯示順序（層級 ${levelIndex + 1}）`"
                              type="number"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="level.placeholder_text"
                              :label="`提示文字（層級 ${levelIndex + 1}）`"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="level.default_value"
                              :label="`預設值（層級 ${levelIndex + 1}）`"
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12">
                            <v-textarea
                              v-model="level.help_text"
                              :label="`說明文字（層級 ${levelIndex + 1}）`"
                              rows="2"
                              variant="outlined"
                            />
                          </v-col>
                        </v-row>
                      </div>
                    </v-card-text>
                  </v-card>
                </v-col>

                <!-- 區塊 3: 選項設定（動態依照層數產生） -->
                <v-col cols="12">
                  <v-card class="pa-4" variant="outlined">
                    <v-card-title class="text-subtitle-1 d-flex align-center">
                      <v-icon class="mr-2">mdi-format-list-bulleted</v-icon>
                      <span>選項設定</span>
                      <v-spacer />
                      <v-chip color="primary" size="small" variant="flat">
                        {{ cascadingLevelCount }} 層
                      </v-chip>
                    </v-card-title>
                    <v-card-text>
                      <v-alert
                        v-if="cascadingLevels.length === 0"
                        class="mb-4"
                        type="info"
                        variant="tonal"
                      >
                        <div class="text-body-2">
                          <strong>提示：</strong>
                          <ul class="mt-2">
                            <li>請先在「共通設定」中設定層次數量</li>
                            <li>每個層級可以有多個選項</li>
                            <li>每個選項可以包含子選項（下一層的選項）</li>
                            <li>選擇上一層的選項後，下一層才會顯示對應的子選項</li>
                          </ul>
                        </div>
                      </v-alert>

                      <!-- 層級一：只顯示選項列表（值、標籤） -->
                      <div v-if="cascadingLevels.length > 0" class="mb-6 border pa-4 rounded">
                        <div class="d-flex align-center mb-3">
                          <v-icon class="mr-2" color="primary">mdi-layers</v-icon>
                          <h3 class="text-h6">層級 1 - 選項設定</h3>
                        </div>

                        <v-row class="mb-3">
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="cascadingLevels[0].placeholder"
                              density="compact"
                              hint="下拉選單的提示文字"
                              label="提示文字"
                              persistent-hint
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field
                              density="compact"
                              disabled
                              hint="此標籤來自「多層式選單設定」中的層級 1 欄位標籤"
                              :label="`層級 1 標籤（唯讀）`"
                              :model-value="cascadingLevels[0]?.field_label || cascadingLevels[0]?.label || ''"
                              persistent-hint
                              variant="outlined"
                            />
                          </v-col>
                        </v-row>

                        <div class="d-flex align-center mb-2">
                          <v-icon class="mr-1" size="small">mdi-format-list-bulleted</v-icon>
                          <span class="text-subtitle-2">選項列表</span>
                          <v-spacer />
                          <v-btn
                            color="primary"
                            size="small"
                            variant="outlined"
                            @click="addCascadingOption(0)"
                          >
                            <v-icon start>mdi-plus</v-icon>
                            新增選項
                          </v-btn>
                        </div>

                        <div v-for="(option, optionIndex) in (cascadingLevels[0].options || [])" :key="optionIndex" class="mb-3 pa-3 border rounded" style="background: #f5f5f5;">
                          <v-row>
                            <v-col cols="12" md="5">
                              <v-text-field
                                v-model="option.value"
                                density="compact"
                                label="值 *"
                                :rules="[v => !!v || '值為必填']"
                                variant="outlined"
                              />
                            </v-col>
                            <v-col cols="12" md="5">
                              <v-text-field
                                v-model="option.label"
                                density="compact"
                                label="標籤 *"
                                :rules="[v => !!v || '標籤為必填']"
                                variant="outlined"
                              />
                            </v-col>
                            <v-col class="d-flex align-center" cols="12" md="2">
                              <v-btn
                                :disabled="optionIndex === 0"
                                icon
                                size="small"
                                variant="text"
                                @click="moveCascadingOptionUp(0, optionIndex)"
                              >
                                <v-icon>mdi-arrow-up</v-icon>
                              </v-btn>
                              <v-btn
                                :disabled="optionIndex === (cascadingLevels[0].options || []).length - 1"
                                icon
                                size="small"
                                variant="text"
                                @click="moveCascadingOptionDown(0, optionIndex)"
                              >
                                <v-icon>mdi-arrow-down</v-icon>
                              </v-btn>
                              <v-btn
                                color="error"
                                icon
                                size="small"
                                @click="removeCascadingOption(0, optionIndex)"
                              >
                                <v-icon>mdi-delete</v-icon>
                              </v-btn>
                            </v-col>
                          </v-row>
                        </div>
                      </div>

                      <!-- 層級二：讀取層級一的選項值，顯示子選項設定 -->
                      <div v-if="cascadingLevels.length > 1" class="mb-6 border pa-4 rounded">
                        <div class="d-flex align-center mb-3">
                          <v-icon class="mr-2" color="primary">mdi-layers</v-icon>
                          <h3 class="text-h6">層級 2 - 子選項設定</h3>
                        </div>

                        <v-row class="mb-3">
                          <v-col cols="12" md="6">
                            <v-text-field
                              v-model="cascadingLevels[1].placeholder"
                              density="compact"
                              hint="下拉選單的提示文字"
                              label="提示文字"
                              persistent-hint
                              variant="outlined"
                            />
                          </v-col>
                          <v-col cols="12" md="6">
                            <v-text-field
                              density="compact"
                              disabled
                              hint="此標籤來自「多層式選單設定」中的層級 2 欄位標籤"
                              label="層級 2 標籤（唯讀）"
                              :model-value="cascadingLevels[1]?.field_label || cascadingLevels[1]?.label || ''"
                              persistent-hint
                              variant="outlined"
                            />
                          </v-col>
                        </v-row>

                        <v-alert
                          v-if="!cascadingLevels[0] || !cascadingLevels[0].options || cascadingLevels[0].options.length === 0"
                          class="mb-4"
                          type="warning"
                          variant="tonal"
                        >
                          <div class="text-body-2">
                            請先在「層級 1」中新增選項，才能為層級 2 設定子選項。
                          </div>
                        </v-alert>

                        <!-- 根據層級一的選項顯示層級二的子選項設定 -->
                        <template v-if="cascadingLevels[0] && cascadingLevels[0].options && cascadingLevels[0].options.length > 0">
                          <div
                            v-for="(level1Option, level1OptionIndex) in cascadingLevels[0].options"
                            :key="level1OptionIndex"
                            class="mb-4 pa-3 border rounded"
                            style="background: #f8f9fa;"
                          >
                            <div class="d-flex align-center mb-3">
                              <v-icon class="mr-2" color="primary" size="small">mdi-menu-right</v-icon>
                              <span class="text-subtitle-2 font-weight-bold">
                                當選擇「{{ level1Option.label || level1Option.value }}」時的子選項
                              </span>
                              <v-spacer />
                              <v-chip color="primary" size="small" variant="flat">
                                {{ (level1Option.children || []).length }} 個子選項
                              </v-chip>
                            </div>

                            <div class="d-flex align-center mb-2">
                              <v-spacer />
                              <v-btn
                                color="primary"
                                size="small"
                                variant="outlined"
                                @click="addCascadingChildOption(0, level1OptionIndex)"
                              >
                                <v-icon start>mdi-plus</v-icon>
                                新增子選項
                              </v-btn>
                            </div>

                            <div v-for="(child, childIndex) in (level1Option.children || [])" :key="childIndex" class="mb-2">
                              <v-row>
                                <v-col cols="12" md="5">
                                  <v-text-field
                                    v-model="child.value"
                                    density="compact"
                                    label="值 *"
                                    :rules="[v => !!v || '值為必填']"
                                    variant="outlined"
                                  />
                                </v-col>
                                <v-col cols="12" md="5">
                                  <v-text-field
                                    v-model="child.label"
                                    density="compact"
                                    label="標籤 *"
                                    :rules="[v => !!v || '標籤為必填']"
                                    variant="outlined"
                                  />
                                </v-col>
                                <v-col class="d-flex align-center" cols="12" md="2">
                                  <v-btn
                                    :disabled="childIndex === 0"
                                    icon
                                    size="small"
                                    variant="text"
                                    @click="moveCascadingChildOptionUp(0, level1OptionIndex, childIndex)"
                                  >
                                    <v-icon>mdi-arrow-up</v-icon>
                                  </v-btn>
                                  <v-btn
                                    :disabled="childIndex === (level1Option.children || []).length - 1"
                                    icon
                                    size="small"
                                    variant="text"
                                    @click="moveCascadingChildOptionDown(0, level1OptionIndex, childIndex)"
                                  >
                                    <v-icon>mdi-arrow-down</v-icon>
                                  </v-btn>
                                  <v-btn
                                    color="error"
                                    icon
                                    size="small"
                                    @click="removeCascadingChildOption(0, level1OptionIndex, childIndex)"
                                  >
                                    <v-icon>mdi-delete</v-icon>
                                  </v-btn>
                                </v-col>
                              </v-row>
                            </div>
                          </div>
                        </template>
                      </div>

                      <!-- 層級三及以後：讀取層級一與層級二的選項組合，顯示子選項設定 -->
                      <template v-for="(level, levelIndex) in cascadingLevels" :key="levelIndex">
                        <div v-if="levelIndex > 1" class="mb-6 border pa-4 rounded">
                          <div class="d-flex align-center mb-3">
                            <v-icon class="mr-2" color="primary">mdi-layers</v-icon>
                            <h3 class="text-h6">層級 {{ levelIndex + 1 }} - 子選項設定</h3>
                          </div>

                          <v-row class="mb-3">
                            <v-col cols="12" md="6">
                              <v-text-field
                                v-model="level.placeholder"
                                density="compact"
                                hint="下拉選單的提示文字"
                                label="提示文字"
                                persistent-hint
                                variant="outlined"
                              />
                            </v-col>
                            <v-col cols="12" md="6">
                              <v-text-field
                                density="compact"
                                disabled
                                hint="此標籤來自「多層式選單設定」中的層級標籤"
                                :label="`層級 ${levelIndex + 1} 標籤（唯讀）`"
                                :model-value="level?.field_label || level?.label || ''"
                                persistent-hint
                                variant="outlined"
                              />
                            </v-col>
                          </v-row>

                          <v-alert
                            v-if="!cascadingLevels[0] || !cascadingLevels[0].options || cascadingLevels[0].options.length === 0"
                            class="mb-4"
                            type="warning"
                            variant="tonal"
                          >
                            <div class="text-body-2">
                              請先在「層級 1」中新增選項，才能為此層級設定子選項。
                            </div>
                          </v-alert>

                          <!-- 根據層級一與層級二的選項組合顯示子選項設定 -->
                          <template v-if="cascadingLevels[0] && cascadingLevels[0].options && cascadingLevels[0].options.length > 0">
                            <!-- 遍歷層級一的所有選項 -->
                            <div
                              v-for="(level1Option, level1OptionIndex) in cascadingLevels[0].options"
                              :key="level1OptionIndex"
                              class="mb-4"
                            >
                              <!-- 如果層級一的選項有子選項（層級二的選項），則顯示組合 -->
                              <template v-if="level1Option.children && level1Option.children.length > 0">
                                <div
                                  v-for="(level2Option, level2OptionIndex) in level1Option.children"
                                  :key="level2OptionIndex"
                                  class="mb-3 pa-3 border rounded"
                                  style="background: #f0f4f8;"
                                >
                                  <div class="d-flex align-center mb-3">
                                    <v-icon class="mr-2" color="primary" size="small">mdi-menu-right</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold">
                                      當選擇「{{ level1Option.label || level1Option.value }}」→「{{ level2Option.label || level2Option.value }}」時的子選項
                                    </span>
                                    <v-spacer />
                                    <v-chip color="primary" size="small" variant="flat">
                                      {{ (level2Option.children || []).length }} 個子選項
                                    </v-chip>
                                  </div>

                                  <div class="d-flex align-center mb-2">
                                    <v-spacer />
                                    <v-btn
                                      color="primary"
                                      size="small"
                                      variant="outlined"
                                      @click="addCascadingChildOption(levelIndex - 1, level2OptionIndex, level1OptionIndex)"
                                    >
                                      <v-icon start>mdi-plus</v-icon>
                                      新增子選項
                                    </v-btn>
                                  </div>

                                  <div v-for="(child, childIndex) in (level2Option.children || [])" :key="childIndex" class="mb-2">
                                    <v-row>
                                      <v-col cols="12" md="5">
                                        <v-text-field
                                          v-model="child.value"
                                          density="compact"
                                          label="值 *"
                                          :rules="[v => !!v || '值為必填']"
                                          variant="outlined"
                                        />
                                      </v-col>
                                      <v-col cols="12" md="5">
                                        <v-text-field
                                          v-model="child.label"
                                          density="compact"
                                          label="標籤 *"
                                          :rules="[v => !!v || '標籤為必填']"
                                          variant="outlined"
                                        />
                                      </v-col>
                                      <v-col class="d-flex align-center" cols="12" md="2">
                                        <v-btn
                                          :disabled="childIndex === 0"
                                          icon
                                          size="small"
                                          variant="text"
                                          @click="moveCascadingChildOptionUp(levelIndex - 1, level2OptionIndex, childIndex, level1OptionIndex)"
                                        >
                                          <v-icon>mdi-arrow-up</v-icon>
                                        </v-btn>
                                        <v-btn
                                          :disabled="childIndex === (level2Option.children || []).length - 1"
                                          icon
                                          size="small"
                                          variant="text"
                                          @click="moveCascadingChildOptionDown(levelIndex - 1, level2OptionIndex, childIndex, level1OptionIndex)"
                                        >
                                          <v-icon>mdi-arrow-down</v-icon>
                                        </v-btn>
                                        <v-btn
                                          color="error"
                                          icon
                                          size="small"
                                          @click="removeCascadingChildOption(levelIndex - 1, level2OptionIndex, childIndex, level1OptionIndex)"
                                        >
                                          <v-icon>mdi-delete</v-icon>
                                        </v-btn>
                                      </v-col>
                                    </v-row>
                                  </div>
                                </div>
                              </template>
                              <v-alert
                                v-else
                                class="mb-2"
                                type="info"
                                variant="tonal"
                              >
                                <div class="text-body-2">
                                  選項「{{ level1Option.label || level1Option.value }}」尚未設定層級 2 的子選項。
                                </div>
                              </v-alert>
                            </div>
                          </template>
                        </div>
                      </template>
                    </v-card-text>
                  </v-card>
                </v-col>
              </template>

              <!-- 欄位配置（JSON） -->
              <v-col cols="12">
                <v-card class="pa-4" variant="outlined">
                  <v-card-title class="text-subtitle-1">進階設定（JSON）</v-card-title>
                  <v-card-text>
                    <v-textarea
                      v-model="fieldConfigJson"
                      :error="jsonError"
                      :error-messages="jsonError ? 'JSON 格式錯誤，請檢查語法' : ''"
                      hint="JSON 格式的進階設定，會自動根據上方設定更新"
                      label="欄位配置（JSON）"
                      persistent-hint
                      rows="8"
                      variant="outlined"
                      @blur="updateFieldDataFromJson"
                    />
                    <v-alert
                      class="mt-4"
                      type="info"
                      variant="tonal"
                    >
                      <div class="text-body-2">
                        <strong>說明：</strong>
                        <ul class="mt-2">
                          <li>此 JSON 會自動根據上方的欄位設定更新</li>
                          <li>您也可以手動編輯 JSON 來設定進階參數</li>
                          <li>手動編輯後，請點擊其他區域或按 Tab 鍵來應用變更</li>
                          <li>JSON 格式錯誤時會顯示錯誤提示</li>
                        </ul>
                      </div>
                    </v-alert>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-form>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeFieldDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :disabled="!fieldFormValid"
            @click="saveField"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 群組管理對話框 -->
    <v-dialog
      v-model="groupDialog"
      max-width="500"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-info text-white">
          <v-icon class="mr-2">mdi-folder</v-icon>
          <span>{{ editingGroupName ? '編輯群組' : '新增群組' }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeGroupDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-text-field
            v-model="newGroupName"
            hint="例如：基本資訊、分類資訊、物料資訊等"
            label="群組名稱 *"
            persistent-hint
            :rules="[rules.required]"
            variant="outlined"
          />

          <v-alert
            v-if="editingGroupName"
            class="mt-4"
            type="info"
            variant="tonal"
          >
            <div class="text-body-2">
              <strong>提示：</strong>
              <ul class="mt-2">
                <li>修改群組名稱會更新所有屬於該群組的欄位</li>
                <li>刪除群組會將欄位的群組設定清空，欄位會移到「未分組欄位」</li>
              </ul>
            </div>
          </v-alert>

          <div v-if="editingGroupName" class="mt-4">
            <v-alert
              type="warning"
              variant="tonal"
            >
              <div class="text-body-2">
                屬於「{{ editingGroupName }}」群組的欄位：
                <ul class="mt-2">
                  <li
                    v-for="field in fields.filter(f => f.field_group === editingGroupName)"
                    :key="field.field_key"
                  >
                    {{ getFieldDisplayLabel(field) }}
                  </li>
                </ul>
              </div>
            </v-alert>
          </div>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            v-if="editingGroupName"
            color="error"
            variant="outlined"
            @click="deleteGroup"
          >
            <v-icon start>mdi-delete</v-icon>
            刪除群組
          </v-btn>
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeGroupDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :disabled="!newGroupName"
            @click="saveGroup"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 群組順序調整對話框 -->
    <v-dialog
      v-model="groupOrderDialog"
      max-width="600"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-info text-white">
          <v-icon class="mr-2">mdi-sort</v-icon>
          <span>調整群組順序</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeGroupOrderDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-alert
            class="mb-4"
            type="info"
            variant="tonal"
          >
            <div class="text-body-2">
              <strong>提示：</strong>
              <ul class="mt-2">
                <li>拖曳群組項目或使用上下按鈕調整順序</li>
                <li>群組將按照此順序顯示在表單中</li>
                <li>「未分組欄位」始終顯示在最後</li>
              </ul>
            </div>
          </v-alert>

          <v-list>
            <template v-for="(groupName, index) in groupOrderList" :key="groupName">
              <!-- 群組項目 -->
              <v-list-item
                :class="{ 'drag-over': draggedGroupIndex === index }"
                :draggable="true"
                @dragenter.prevent="handleGroupDragEnter($event, index)"
                @dragleave="handleGroupDragLeave($event, index)"
                @dragover.prevent="handleGroupDragOver($event, index)"
                @dragstart="handleGroupDragStart($event, index)"
                @drop="handleGroupDrop($event, index)"
              >
                <template #prepend>
                  <v-icon class="mr-2" color="grey">mdi-drag</v-icon>
                </template>
                <v-list-item-title>
                  <div class="d-flex align-center">
                    <v-icon class="mr-2" size="small">mdi-folder</v-icon>
                    <span>{{ groupName }}</span>
                  </div>
                </v-list-item-title>
                <template #append>
                  <div class="d-flex align-center">
                    <v-btn
                      icon
                      size="small"
                      variant="text"
                      @click="openSubGroupDialog(groupName, null)"
                    >
                      <v-icon size="small">mdi-view-grid-plus</v-icon>
                    </v-btn>
                    <v-btn
                      :disabled="index === 0"
                      icon
                      size="small"
                      variant="text"
                      @click="moveGroupUp(index)"
                    >
                      <v-icon>mdi-chevron-up</v-icon>
                    </v-btn>
                    <v-btn
                      :disabled="index === groupOrderList.length - 1"
                      icon
                      size="small"
                      variant="text"
                      @click="moveGroupDown(index)"
                    >
                      <v-icon>mdi-chevron-down</v-icon>
                    </v-btn>
                  </div>
                </template>
              </v-list-item>

              <!-- 子群組列表 -->
              <v-list-item
                v-if="getSubGroupsForGroup(groupName).length > 0"
                class="pl-8"
              >
                <v-list class="w-100" density="compact">
                  <template v-for="(subGroup, subIndex) in getSubGroupsForGroup(groupName)" :key="subGroup.name">
                    <v-list-item
                      :class="{ 'drag-over': draggedSubGroupIndex === subIndex && editingSubGroup.groupName === groupName }"
                      :draggable="true"
                      @dragenter.prevent="handleSubGroupDragEnter($event, groupName, subIndex)"
                      @dragleave="handleSubGroupDragLeave($event, groupName, subIndex)"
                      @dragover.prevent="handleSubGroupDragOver($event, groupName, subIndex)"
                      @dragstart="handleSubGroupDragStart($event, groupName, subIndex)"
                      @drop="handleSubGroupDrop($event, groupName, subIndex)"
                    >
                      <template #prepend>
                        <v-icon class="mr-2" color="grey" size="small">mdi-drag</v-icon>
                      </template>
                      <v-list-item-title>
                        <div class="d-flex align-center">
                          <v-icon class="mr-2" size="x-small">mdi-view-grid</v-icon>
                          <span class="text-body-2">{{ subGroup.name }}</span>
                        </div>
                      </v-list-item-title>
                      <template #append>
                        <div class="d-flex align-center">
                          <v-btn
                            icon
                            size="x-small"
                            variant="text"
                            @click="openSubGroupDialog(groupName, subGroup.name, subIndex)"
                          >
                            <v-icon size="small">mdi-pencil</v-icon>
                          </v-btn>
                          <v-btn
                            color="error"
                            icon
                            size="x-small"
                            variant="text"
                            @click="deleteSubGroup(groupName, subIndex)"
                          >
                            <v-icon size="small">mdi-delete</v-icon>
                          </v-btn>
                          <v-btn
                            :disabled="subIndex === 0"
                            icon
                            size="x-small"
                            variant="text"
                            @click="moveSubGroupUp(groupName, subIndex)"
                          >
                            <v-icon size="x-small">mdi-chevron-up</v-icon>
                          </v-btn>
                          <v-btn
                            :disabled="subIndex === getSubGroupsForGroup(groupName).length - 1"
                            icon
                            size="x-small"
                            variant="text"
                            @click="moveSubGroupDown(groupName, subIndex)"
                          >
                            <v-icon size="x-small">mdi-chevron-down</v-icon>
                          </v-btn>
                        </div>
                      </template>
                    </v-list-item>
                  </template>
                </v-list>
              </v-list-item>

              <v-divider v-if="index < groupOrderList.length - 1" />
            </template>
          </v-list>

          <v-alert
            v-if="groupOrderList.length === 0"
            class="mt-4"
            type="info"
            variant="tonal"
          >
            目前沒有群組，請點擊下方「新增群組」按鈕來建立新群組
          </v-alert>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-btn
            color="success"
            prepend-icon="mdi-folder-plus"
            variant="outlined"
            @click="openGroupDialog(null)"
          >
            新增群組
          </v-btn>
          <v-spacer />
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeGroupOrderDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            @click="saveGroupOrder"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- 子群組管理對話框 -->
    <v-dialog
      v-model="subGroupDialog"
      max-width="500"
      persistent
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-indigo text-white">
          <v-icon class="mr-2">mdi-view-grid</v-icon>
          <span>{{ editingSubGroup.subGroupName ? '編輯子群組' : '新增子群組' }}</span>
          <v-spacer />
          <v-btn
            icon
            variant="text"
            @click="closeSubGroupDialog"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>

        <v-card-text class="pa-4">
          <v-text-field
            v-model="newSubGroupName"
            hint="例如：基本資訊區塊、詳細資訊區塊等"
            label="子群組名稱 *"
            persistent-hint
            :rules="[rules.required]"
            variant="outlined"
          />

          <v-alert
            v-if="editingSubGroup.subGroupName"
            class="mt-4"
            type="info"
            variant="tonal"
          >
            <div class="text-body-2">
              重命名子群組會更新所有屬於此子群組的欄位設定。
            </div>
          </v-alert>

          <div v-if="editingSubGroup.subGroupName && editingSubGroup.groupName" class="mt-4">
            <v-divider class="mb-4" />
            <div class="text-subtitle-2 mb-2">
              屬於「{{ editingSubGroup.subGroupName }}」子群組的欄位：
            </div>
            <v-list density="compact" variant="outlined">
              <v-list-item
                v-for="field in fields.filter(f => f.sub_group === editingSubGroup.subGroupName && f.field_group === editingSubGroup.groupName)"
                :key="field.id || field.field_key"
              >
                <v-list-item-title>{{ getFieldDisplayLabel(field) }}</v-list-item-title>
              </v-list-item>
              <v-list-item v-if="fields.filter(f => f.sub_group === editingSubGroup.subGroupName && f.field_group === editingSubGroup.groupName).length === 0">
                <v-list-item-title class="text-grey">尚無欄位</v-list-item-title>
              </v-list-item>
            </v-list>
          </div>
        </v-card-text>

        <v-divider />

        <v-card-actions class="pa-4">
          <v-spacer />
          <v-btn
            v-if="editingSubGroup.subGroupName"
            color="error"
            variant="outlined"
            @click="deleteSubGroupFromDialog"
          >
            <v-icon start>mdi-delete</v-icon>
            刪除
          </v-btn>
          <v-btn
            color="grey"
            variant="outlined"
            @click="closeSubGroupDialog"
          >
            取消
          </v-btn>
          <v-btn
            color="primary"
            :disabled="!newSubGroupName"
            @click="saveSubGroup"
          >
            儲存
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
  import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
  import { formFieldsService } from '@/api/services/formFields'
  import { formsService } from '@/api/services/forms'
  import { useSwal } from '@/composables/useSwal'
  import AggregatedField from './form-fields/AggregatedField.vue'
  import CascadingSelectField from './form-fields/CascadingSelectField.vue'
  import CheckboxField from './form-fields/CheckboxField.vue'
  import DateField from './form-fields/DateField.vue'
  import DatetimeField from './form-fields/DatetimeField.vue'
  import FileField from './form-fields/FileField.vue'
  import JsonField from './form-fields/JsonField.vue'
  import MultiselectField from './form-fields/MultiselectField.vue'
  import NumberField from './form-fields/NumberField.vue'
  import RadioField from './form-fields/RadioField.vue'
  import SelectField from './form-fields/SelectField.vue'
  import TextareaField from './form-fields/TextareaField.vue'
  import TextField from './form-fields/TextField.vue'

  const props = defineProps({
    formId: {
      type: [String, Number],
      default: null,
    },
  })

  const emit = defineEmits(['saved', 'cancel'])

  const swal = useSwal()

  const activeTab = ref('basic')
  const basicFormRef = ref(null)
  const fieldFormRef = ref(null)
  const basicFormValid = ref(false)
  const fieldFormValid = ref(false)
  const saving = ref(false)
  const saveProgress = ref(0) // 儲存進度百分比
  const fieldsTabRef = ref(null) // 欄位設定分頁的引用
  const fieldDialog = ref(false)
  const editingFieldIndex = ref(null)
  const floatingWindowVisible = ref(false) // 懸浮視窗顯示狀態
  const fieldsHeaderRef = ref(null) // 原始功能列的引用
  const isAutoShowingFloatingWindow = ref(false) // 標記是否為自動顯示（避免與手動切換衝突）
  let scrollObserver = null // Intersection Observer 實例
  const previewValues = reactive({})

  const isEditMode = computed(() => !!props.formId)

  const formData = reactive({
    form_code: '',
    form_name: '',
    form_name_en: '',
    description: '',
    is_active: true,
    is_default: false,
    form_config: {},
  })

  const fields = ref([])

  // 欄位寬度選項（占行數）
  const columnSizeOptions = [
    { title: '全寬 (12)', value: 12 },
    { title: '2/3 寬 (8)', value: 8 },
    { title: '半寬 (6)', value: 6 },
    { title: '1/3 寬 (4)', value: 4 },
    { title: '1/4 寬 (3)', value: 3 },
  ]

  const fieldData = reactive({
    field_key: '',
    field_label: '',
    field_label_en: '',
    field_type: 'text',
    max_length: null,
    columnSize: 12, // 欄位寬度（占行數），預設為 12（全寬）
    is_required: false,
    field_group: '',
    sub_group: '', // 子群組名稱（用於排版）
    display_order: 0,
    field_config: {},
    default_value: '',
    placeholder: '',
    help_text: '',
    validation_rules: {},
    is_visible: true,
    is_readonly: false,
    is_in_template: false,
  })

  const fieldOptions = ref([])
  const cascadingLevels = ref([]) // 多層選單配置
  const cascadingLevelCount = ref(1) // 層次數量
  const fieldConfigJson = ref('{}')
  const isUpdatingJsonFromData = ref(false) // 標記是否正在從 fieldData 更新 JSON（避免循環更新）
  const jsonError = ref(false) // JSON 格式錯誤標記
  const groupDialog = ref(false)
  const editingGroupName = ref(null)
  const newGroupName = ref('')

  // 拖曳相關狀態
  const draggedField = ref(null)
  const draggedFromGroup = ref(null)
  const draggedFromSubGroup = ref(null)
  const draggedFromIndex = ref(null)
  const dragOverGroup = ref(null)
  const dragOverSubGroup = ref(null)
  const dragOverIndex = ref(null)

  // 所有群組列表（包括新增但尚未使用的群組）
  const allGroups = ref(new Set())

  // 群組摺疊/展開狀態
  const expandedGroups = ref(new Set())
  const allGroupsExpanded = ref(true) // 預設全部展開

  // 群組順序（用於控制群組顯示順序）
  const groupOrder = ref([])
  const groupOrderDialog = ref(false)
  const groupOrderList = ref([])
  const draggedGroupIndex = ref(null)

  // 子群組管理
  const subGroups = ref(new Map()) // Map<groupName, Array<{name: string, order: number}>>
  const editingSubGroup = ref({ groupName: null, subGroupName: null, index: null })
  const newSubGroupName = ref('')
  const subGroupDialog = ref(false)
  const draggedSubGroupIndex = ref(null)

  // 可用的群組選項（合併從欄位中提取的群組和手動新增的群組）
  const availableGroups = computed(() => {
    const groups = new Set(allGroups.value)

    // 從欄位中提取已使用的群組
    for (const field of fields.value) {
      if (field.field_group) {
        groups.add(field.field_group)
      }
    }

    return Array.from(groups).sort().map(g => ({ title: g, value: g }))
  })

  // 可用的子群組選項（根據當前選擇的群組）
  const availableSubGroups = computed(() => {
    if (!fieldData.field_group) {
      return []
    }

    const subGroups = getSubGroupsForGroup(fieldData.field_group)
    return subGroups.map(sg => ({ title: sg.name, value: sg.name }))
  })

  // 按群組和子群組分類欄位（用於設計器顯示）
  const groupedFieldsForDesign = computed(() => {
    const groups = {}
    const ungrouped = []

    for (const field of fields.value) {
      if (field.field_group) {
        if (!groups[field.field_group]) {
          groups[field.field_group] = {
            subGroups: {}, // Map<subGroupName, Array<field>>
            ungrouped: [], // 沒有子群組的欄位
          }
        }

        if (field.sub_group) {
          // 屬於子群組的欄位
          if (!groups[field.field_group].subGroups[field.sub_group]) {
            groups[field.field_group].subGroups[field.sub_group] = []
          }
          groups[field.field_group].subGroups[field.sub_group].push(field)
        } else {
          // 不屬於任何子群組的欄位
          groups[field.field_group].ungrouped.push(field)
        }
      } else {
        ungrouped.push(field)
      }
    }

    // 按 display_order 排序每個群組內的欄位
    for (const groupName of Object.keys(groups)) {
      // 排序子群組內的欄位
      for (const subGroupName of Object.keys(groups[groupName].subGroups)) {
        groups[groupName].subGroups[subGroupName].sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      }
      // 排序未分組到子群組的欄位
      groups[groupName].ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }

    ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))

    // 按照 groupOrder 排序群組
    const orderedGroups = {}

    // 先添加有順序的群組（包括空群組，以便用戶可以拖曳欄位到這些群組）
    for (const groupName of groupOrder.value) {
      if (groups[groupName]) {
        orderedGroups[groupName] = groups[groupName]
      } else {
        // 即使群組沒有欄位，也要創建空的群組結構，以便顯示和拖曳
        orderedGroups[groupName] = {
          subGroups: {},
          ungrouped: [],
        }
      }
    }

    // 再添加沒有順序的群組（新群組或未在順序列表中的群組）
    for (const groupName of Object.keys(groups)) {
      if (!groupOrder.value.includes(groupName)) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    // 最後添加未分組欄位
    if (ungrouped.length > 0) {
      orderedGroups['未分組欄位'] = {
        subGroups: {},
        ungrouped: ungrouped,
      }
    }

    console.log('groupedFieldsForDesign computed:', {
      groupOrder: groupOrder.value,
      orderedGroups: Object.keys(orderedGroups),
      fieldsCount: fields.value.length,
    })

    return orderedGroups
  })

  const rules = {
    required: v => !!v || '此欄位為必填',
    formCode: v => {
      if (!v) return true
      return /^[a-z][a-z0-9_]*$/.test(v) || '只能包含小寫字母、數字和底線，且必須以字母開頭'
    },
    fieldKey: v => {
      if (!v) return true
      return /^[a-z][a-z0-9_]*$/.test(v) || '只能包含小寫字母、數字和底線，且必須以字母開頭'
    },
  }

  const fieldTypeOptions = [
    { title: '文字', value: 'text' },
    { title: '多行文字', value: 'textarea' },
    { title: '數字', value: 'number' },
    { title: '下拉選單', value: 'select' },
    { title: '多選下拉', value: 'multiselect' },
    { title: '動態下拉選單', value: 'cascading_select' },
    { title: '複選框', value: 'checkbox' },
    { title: '單選框', value: 'radio' },
    { title: '日期', value: 'date' },
    { title: '日期時間', value: 'datetime' },
    { title: '檔案', value: 'file' },
    { title: 'JSON', value: 'json' },
    { title: '聚合資料', value: 'aggregated' },
  ]

  const needsOptions = computed(() => {
    return ['select', 'multiselect', 'checkbox', 'radio'].includes(fieldData.field_type)
  })

  const needsCascadingLevels = computed(() => {
    return fieldData.field_type === 'cascading_select'
  })

  const needsAggregatedTemplate = computed(() => {
    return fieldData.field_type === 'aggregated'
  })

  const canSave = computed(() => {
    return basicFormValid.value && formData.form_code && formData.form_name
  })

  // 載入表單
  async function loadForm () {
    if (!props.formId) return

    try {
      const form = await formsService.getForm(props.formId, true)
      if (form) {
        Object.assign(formData, {
          form_code: form.form_code,
          form_name: form.form_name,
          form_name_en: form.form_name_en || '',
          description: form.description || '',
          is_active: form.is_active !== false,
          is_default: form.is_default || false,
          form_config: form.form_config || {},
        })

        if (form.fields) {
          fields.value = form.fields.map(f => ({ ...f }))

          // 載入時，將所有已使用的群組添加到 allGroups
          for (const field of form.fields) {
            if (field.field_group) {
              allGroups.value.add(field.field_group)
            }
          }
        }

        // 載入群組順序（從 form_config 中）
        if (form.form_config && form.form_config.group_order && Array.isArray(form.form_config.group_order)) {
          groupOrder.value = [...form.form_config.group_order]
        } else {
          // 如果沒有順序設定，使用所有群組的預設順序（按字母排序）
          groupOrder.value = Array.from(allGroups.value).sort()
        }

        // 載入子群組資料（從 form_config 中）
        if (form.form_config && form.form_config.sub_groups && Object.keys(form.form_config.sub_groups).length > 0) {
          subGroups.value = new Map(Object.entries(form.form_config.sub_groups).map(([groupName, subGroupsList]) => {
            return [groupName, subGroupsList.map((sg, index) => ({
              name: typeof sg === 'string' ? sg : sg.name,
              order: typeof sg === 'string' ? index : (sg.order || index),
            }))]
          }))
          console.log('載入子群組資料:', subGroups.value)
        } else {
          // 從欄位中提取子群組
          const subGroupsMap = new Map()
          for (const field of form.fields) {
            if (field.field_group && field.sub_group) {
              if (!subGroupsMap.has(field.field_group)) {
                subGroupsMap.set(field.field_group, new Set())
              }
              subGroupsMap.get(field.field_group).add(field.sub_group)
            }
          }
          // 轉換為陣列格式
          subGroups.value = new Map(Array.from(subGroupsMap.entries()).map(([groupName, subGroupSet]) => {
            return [groupName, Array.from(subGroupSet).map((name, index) => ({ name, order: index }))]
          }))
          console.log('從欄位提取子群組資料:', subGroups.value)
        }

        // 確保 subGroups 初始化（即使沒有資料也要初始化為空 Map）
        if (!subGroups.value) {
          subGroups.value = new Map()
        }

        console.log('最終子群組資料:', subGroups.value)
      }
    } catch (error) {
      console.error('載入表單失敗', error)
      await swal.error('載入表單失敗')
    }
  }

  // 開啟欄位對話框
  function openFieldDialog (field, index) {
    editingFieldIndex.value = index === undefined ? null : index

    if (field) {
      const fieldConfig = field.field_config || {}
      Object.assign(fieldData, {
        field_key: field.field_key,
        field_label: field.field_label,
        field_label_en: field.field_label_en || '',
        field_type: field.field_type,
        max_length: field.max_length,
        columnSize: fieldConfig.cols || 12, // 從 field_config.cols 讀取欄位寬度
        is_required: field.is_required || false,
        field_group: field.field_group || '',
        sub_group: field.sub_group || '', // 子群組名稱
        display_order: field.display_order || 0,
        field_config: fieldConfig,
        default_value: field.default_value || '',
        placeholder: field.placeholder || '',
        help_text: field.help_text || '',
        validation_rules: field.validation_rules || {},
        is_visible: field.is_visible !== false,
        is_readonly: field.is_readonly || false,
        is_in_template: field.is_in_template || false,
      })

      // 載入選項
      if (needsOptions.value && fieldData.field_config.options) {
        fieldOptions.value = Array.isArray(fieldData.field_config.options)
          ? fieldData.field_config.options.map(opt => {
            if (typeof opt === 'string') {
              return { value: opt, label: opt }
            }
            return { value: opt.value, label: opt.label || opt.title || opt.value }
          })
          : []
      } else {
        fieldOptions.value = []
      }

      // 載入聚合資料模板
      if (needsAggregatedTemplate.value) {
      // 模板已經在 field_config.template 中
      }

      // 載入多層選單配置
      if (needsCascadingLevels.value && fieldData.field_config.levels) {
        cascadingLevels.value = Array.isArray(fieldData.field_config.levels)
          ? JSON.parse(JSON.stringify(fieldData.field_config.levels)).map((level, index) => {
            // 從獨立的 cascading_options 區塊讀取選項（僅第一層）
            let levelOptions = []
            if (index === 0 && fieldData.field_config.cascading_options) {
              // 第一層使用 cascading_options
              levelOptions = Array.isArray(fieldData.field_config.cascading_options)
                ? fieldData.field_config.cascading_options.map(opt => ({
                  value: opt.value || '',
                  label: opt.label || '',
                  children: opt.children || [],
                }))
                : []
            } else if (level.options) {
              // 兼容舊格式：如果層級中還有 options（向後兼容）
              levelOptions = Array.isArray(level.options)
                ? level.options.map(opt => ({
                  value: opt.value || '',
                  label: opt.label || '',
                  children: opt.children || [],
                }))
                : []
            }

            return {
              label: level.field_label || level.label || `第 ${index + 1} 層`,
              placeholder: level.placeholder || '請選擇',
              field_key: level.field_key || '',
              field_label: level.field_label || '',
              is_required: level.is_required === undefined ? false : level.is_required,
              is_visible: level.is_visible === undefined ? true : level.is_visible,
              columnSize: level.columnSize !== undefined && level.columnSize !== null ? Number(level.columnSize) : 12,
              display_order: level.display_order || 0,
              placeholder_text: level.placeholder_text || '',
              default_value: level.default_value || '',
              help_text: level.help_text || '',
              options: levelOptions,
            }
          })
          : []
        cascadingLevelCount.value = cascadingLevels.value.length || 1
      } else {
        cascadingLevels.value = []
        cascadingLevelCount.value = 1
        // 初始化第一層
        if (needsCascadingLevels.value) {
          updateCascadingLevelCount()
        }
      }

      // 載入配置 JSON（使用同步函數生成）
      updateJsonFromFieldData()
    } else {
      // 新增模式
      Object.assign(fieldData, {
        field_key: '',
        field_label: '',
        field_label_en: '',
        field_type: 'text',
        max_length: null,
        columnSize: 12, // 預設為全寬
        is_required: false,
        field_group: '',
        sub_group: '', // 子群組名稱
        display_order: fields.value.length + 1,
        field_config: {},
        default_value: '',
        placeholder: '',
        help_text: '',
        validation_rules: {},
        is_visible: true,
        is_readonly: false,
        is_in_template: false,
      })
      fieldOptions.value = []
      cascadingLevels.value = []
      cascadingLevelCount.value = 1
      fieldConfigJson.value = '{}'
    }

    // 如果是多層選單類型，初始化層級
    if (needsCascadingLevels.value && cascadingLevels.value.length === 0) {
      updateCascadingLevelCount()
    }

    // 初始化 JSON（在對話框打開後）
    fieldDialog.value = true
    // 使用 nextTick 確保所有響應式數據都已更新
    nextTick(() => {
      updateJsonFromFieldData()
    })
  }

  // 關閉欄位對話框
  function closeFieldDialog () {
    fieldDialog.value = false
    editingFieldIndex.value = null
  }

  // 處理群組名稱變更（確保始終是字符串）
  function handleFieldGroupChange (value) {
    if (value === null || value === undefined) {
      fieldData.field_group = ''
      fieldData.sub_group = '' // 清除子群組
    } else if (typeof value === 'string') {
      fieldData.field_group = value
    } else if (value && typeof value === 'object') {
      // 處理對象格式 { title: 'xxx', value: 'xxx' }
      fieldData.field_group = value.value || value.title || ''
    } else {
      fieldData.field_group = String(value || '')
    }

    // 如果群組改變，清除子群組（除非新群組中有相同的子群組名稱）
    if (fieldData.sub_group) {
      const subGroups = getSubGroupsForGroup(fieldData.field_group)
      if (!subGroups.find(sg => sg.name === fieldData.sub_group)) {
        fieldData.sub_group = ''
      }
    }
  }

  // 處理子群組名稱變更（確保始終是字符串）
  function handleFieldSubGroupChange (value) {
    if (value === null || value === undefined) {
      fieldData.sub_group = ''
    } else if (typeof value === 'string') {
      fieldData.sub_group = value
    } else if (value && typeof value === 'object') {
      // 處理對象格式 { title: 'xxx', value: 'xxx' }
      fieldData.sub_group = value.value || value.title || ''
    } else {
      fieldData.sub_group = String(value || '')
    }
  }

  // 開啟群組順序調整對話框
  function openGroupOrderDialog () {
    // 獲取所有有欄位的群組
    const groupsWithFields = new Set()
    for (const field of fields.value) {
      if (field.field_group) {
        groupsWithFields.add(field.field_group)
      }
    }

    // 建立順序列表：先使用已保存的順序，然後添加新群組
    const ordered = []
    for (const groupName of groupOrder.value) {
      if (groupsWithFields.has(groupName)) {
        ordered.push(groupName)
      }
    }

    // 添加不在順序列表中的群組
    for (const groupName of groupsWithFields) {
      if (!groupOrder.value.includes(groupName)) {
        ordered.push(groupName)
      }
    }

    groupOrderList.value = ordered
    groupOrderDialog.value = true
  }

  // 關閉群組順序調整對話框
  function closeGroupOrderDialog () {
    groupOrderDialog.value = false
    draggedGroupIndex.value = null
  }

  // 儲存群組順序
  async function saveGroupOrder () {
    const oldOrder = [...groupOrder.value]
    groupOrder.value = [...groupOrderList.value]

    // 重新計算欄位的 display_order，按照新的群組順序
    updateFieldOrdersByGroupOrder()

    closeGroupOrderDialog()
    await swal.success('群組順序已更新，欄位順序已自動調整')
  }

  // 根據群組順序更新欄位的 display_order
  function updateFieldOrdersByGroupOrder () {
    let orderCounter = 1

    // 按照群組順序處理每個群組的欄位
    for (const groupName of groupOrder.value) {
      const groupFields = fields.value.filter(f => f.field_group === groupName)
      // 按現有的 display_order 排序
      groupFields.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      // 重新分配順序號碼
      for (const field of groupFields) {
        field.display_order = orderCounter++
      }
    }

    // 處理未在群組順序列表中的群組（新群組）
    const processedGroups = new Set(groupOrder.value)
    const unprocessedGroups = new Set()
    for (const field of fields.value) {
      if (field.field_group && !processedGroups.has(field.field_group)) {
        unprocessedGroups.add(field.field_group)
      }
    }

    for (const groupName of unprocessedGroups) {
      const groupFields = fields.value.filter(f => f.field_group === groupName)
      groupFields.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      for (const field of groupFields) {
        field.display_order = orderCounter++
      }
    }

    // 處理未分組的欄位
    const ungroupedFields = fields.value.filter(f => !f.field_group)
    ungroupedFields.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    for (const field of ungroupedFields) {
      field.display_order = orderCounter++
    }
  }

  // 群組上移
  function moveGroupUp (index) {
    if (index > 0) {
      const temp = groupOrderList.value[index]
      groupOrderList.value[index] = groupOrderList.value[index - 1]
      groupOrderList.value[index - 1] = temp
    }
  }

  // 群組下移
  function moveGroupDown (index) {
    if (index < groupOrderList.value.length - 1) {
      const temp = groupOrderList.value[index]
      groupOrderList.value[index] = groupOrderList.value[index + 1]
      groupOrderList.value[index + 1] = temp
    }
  }

  // 群組拖曳處理
  function handleGroupDragStart (event, index) {
    draggedGroupIndex.value = index
    event.dataTransfer.effectAllowed = 'move'
  }

  function handleGroupDragOver (event, index) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  function handleGroupDrop (event, targetIndex) {
    event.preventDefault()
    if (draggedGroupIndex.value === null || draggedGroupIndex.value === targetIndex) {
      draggedGroupIndex.value = null
      return
    }

    const draggedItem = groupOrderList.value[draggedGroupIndex.value]
    groupOrderList.value.splice(draggedGroupIndex.value, 1)
    groupOrderList.value.splice(targetIndex, 0, draggedItem)
    draggedGroupIndex.value = null
  }

  function handleGroupDragEnter (event, index) {
    if (draggedGroupIndex.value !== null && draggedGroupIndex.value !== index) {
    // 可以添加視覺反饋
    }
  }

  function handleGroupDragLeave (event, index) {
  // 可以移除視覺反饋
  }

  // 取得群組的子群組列表
  function getSubGroupsForGroup (groupName) {
    if (!groupName || !subGroups.value || !subGroups.value.has(groupName)) {
      return []
    }
    const list = subGroups.value.get(groupName)
    return Array.isArray(list) ? list : []
  }

  // 取得用於顯示的子群組結構（包含子群組和未分組欄位）
  function getSubGroupsForDisplay (groupName, groupData) {
    const result = {}

    if (!groupData) {
      groupData = { subGroups: {}, ungrouped: [] }
    }

    // 確保 groupData.subGroups 存在
    if (!groupData.subGroups) {
      groupData.subGroups = {}
    }

    // 先添加有順序的子群組（即使沒有欄位也要顯示）
    const subGroupsList = getSubGroupsForGroup(groupName)
    if (subGroupsList && subGroupsList.length > 0) {
      for (const subGroup of subGroupsList) {
        // 即使子群組沒有欄位，也要顯示外框
        result[subGroup.name] = groupData.subGroups[subGroup.name] || []
      }
    }

    // 再添加沒有順序的子群組（新子群組或未在順序列表中的子群組）
    // 只添加有欄位的子群組（因為沒有順序的子群組通常是從欄位中提取的）
    if (groupData.subGroups) {
      for (const subGroupName of Object.keys(groupData.subGroups)) {
        // 如果子群組不在已處理的列表中，且有欄位，則添加
        if ((!subGroupsList || !subGroupsList.find(sg => sg.name === subGroupName)) && groupData.subGroups[subGroupName] && groupData.subGroups[subGroupName].length > 0) {
          result[subGroupName] = groupData.subGroups[subGroupName]
        }
      }
    }

    // 最後添加未分組到子群組的欄位
    if (groupData.ungrouped && groupData.ungrouped.length > 0) {
      result[''] = groupData.ungrouped // 空字符串表示未分組
    }

    return result
  }

  // 開啟子群組對話框
  function openSubGroupDialog (groupName, subGroupName, index = null) {
    editingSubGroup.value = {
      groupName,
      subGroupName: subGroupName || null,
      index: index === null ? null : index,
    }
    newSubGroupName.value = subGroupName || ''
    subGroupDialog.value = true
  }

  // 關閉子群組對話框
  function closeSubGroupDialog () {
    subGroupDialog.value = false
    editingSubGroup.value = { groupName: null, subGroupName: null, index: null }
    newSubGroupName.value = ''
  }

  // 儲存子群組
  async function saveSubGroup () {
    try {
      if (!newSubGroupName.value || !newSubGroupName.value.trim()) {
        await swal.warning('請輸入子群組名稱')
        return
      }

      if (!editingSubGroup.value.groupName) {
        await swal.warning('請選擇所屬群組')
        return
      }

      const trimmedName = newSubGroupName.value.trim()
      const groupName = editingSubGroup.value.groupName

      // 檢查子群組名稱是否已存在（排除當前編輯的子群組）
      const existingSubGroups = getSubGroupsForGroup(groupName)
      const existing = existingSubGroups.find(sg =>
        sg.name === trimmedName
        && (!editingSubGroup.value.subGroupName || sg.name !== editingSubGroup.value.subGroupName),
      )

      if (existing) {
        await swal.warning(`子群組「${trimmedName}」已存在於群組「${groupName}」中`)
        return
      }

      if (!subGroups.value.has(groupName)) {
        subGroups.value.set(groupName, [])
      }

      const subGroupsList = subGroups.value.get(groupName)

      if (editingSubGroup.value.subGroupName) {
        // 編輯模式：重命名子群組
        const oldName = editingSubGroup.value.subGroupName
        const subGroup = subGroupsList.find(sg => sg.name === oldName)
        if (subGroup) {
          subGroup.name = trimmedName
        }

        // 更新所有屬於該子群組的欄位
        for (const field of fields.value) {
          if (field.field_group === groupName && field.sub_group === oldName) {
            field.sub_group = trimmedName
          }
        }

        await swal.success(`子群組「${oldName}」已重命名為「${trimmedName}」`)
      } else {
        // 新增模式：添加子群組
        const maxOrder = subGroupsList.length > 0
          ? Math.max(...subGroupsList.map(sg => sg.order || 0))
          : -1
        subGroupsList.push({
          name: trimmedName,
          order: maxOrder + 1,
        })
        // 按 order 排序
        subGroupsList.sort((a, b) => (a.order || 0) - (b.order || 0))

        await swal.success(`子群組「${trimmedName}」已建立`)
      }

      closeSubGroupDialog()
    } catch (error) {
      console.error('儲存子群組時發生錯誤:', error)
      await swal.error('儲存子群組失敗：' + (error.message || '未知錯誤'))
    }
  }

  // 刪除子群組（從對話框）
  function deleteSubGroupFromDialog () {
    if (!editingSubGroup.value.subGroupName || !editingSubGroup.value.groupName) {
      return
    }
    deleteSubGroup(editingSubGroup.value.groupName, editingSubGroup.value.index)
    closeSubGroupDialog()
  }

  // 刪除子群組
  function deleteSubGroup (groupName, index) {
    if (!groupName || index === null) {
      return
    }

    const subGroupsList = subGroups.value.get(groupName)
    if (!subGroupsList || index >= subGroupsList.length) {
      return
    }

    const subGroupName = subGroupsList[index].name

    // 移除所有屬於該子群組的欄位的子群組設定
    for (const field of fields.value) {
      if (field.field_group === groupName && field.sub_group === subGroupName) {
        field.sub_group = ''
      }
    }

    // 從列表中移除
    subGroupsList.splice(index, 1)
    if (subGroupsList.length === 0) {
      subGroups.value.delete(groupName)
    }
  }

  // 子群組上移
  function moveSubGroupUp (groupName, index) {
    const subGroupsList = subGroups.value.get(groupName)
    if (!subGroupsList || index <= 0) return

    const temp = subGroupsList[index]
    subGroupsList[index] = subGroupsList[index - 1]
    subGroupsList[index - 1] = temp

    // 更新 order
    for (const [i, sg] of subGroupsList.entries()) {
      sg.order = i
    }
  }

  // 子群組下移
  function moveSubGroupDown (groupName, index) {
    const subGroupsList = subGroups.value.get(groupName)
    if (!subGroupsList || index >= subGroupsList.length - 1) return

    const temp = subGroupsList[index]
    subGroupsList[index] = subGroupsList[index + 1]
    subGroupsList[index + 1] = temp

    // 更新 order
    for (const [i, sg] of subGroupsList.entries()) {
      sg.order = i
    }
  }

  // 子群組拖曳處理
  function handleSubGroupDragStart (event, groupName, index) {
    editingSubGroup.value = { groupName, subGroupName: null, index }
    draggedSubGroupIndex.value = index
    event.dataTransfer.effectAllowed = 'move'
  }

  function handleSubGroupDragOver (event, groupName, index) {
    event.preventDefault()
    event.dataTransfer.dropEffect = 'move'
  }

  function handleSubGroupDrop (event, groupName, targetIndex) {
    event.preventDefault()
    if (editingSubGroup.value.index === null || editingSubGroup.value.index === targetIndex) {
      draggedSubGroupIndex.value = null
      editingSubGroup.value = { groupName: null, subGroupName: null, index: null }
      return
    }

    const subGroupsList = subGroups.value.get(groupName)
    if (!subGroupsList) return

    const draggedItem = subGroupsList[editingSubGroup.value.index]
    subGroupsList.splice(editingSubGroup.value.index, 1)
    subGroupsList.splice(targetIndex, 0, draggedItem)

    // 更新 order
    for (const [i, sg] of subGroupsList.entries()) {
      sg.order = i
    }

    draggedSubGroupIndex.value = null
    editingSubGroup.value = { groupName: null, subGroupName: null, index: null }
  }

  function handleSubGroupDragEnter (event, groupName, index) {
  // 可以添加視覺反饋
  }

  function handleSubGroupDragLeave (event, groupName, index) {
  // 可以移除視覺反饋
  }

  // 處理欄位類型變更
  function handleFieldTypeChange () {
    // 清除選項（如果不是需要選項的類型）
    if (!needsOptions.value) {
      fieldOptions.value = []
    }
    // 清除多層選單配置（如果不是多層選單類型）
    if (needsCascadingLevels.value) {
      // 如果是多層選單類型，初始化層級
      if (cascadingLevels.value.length === 0) {
        updateCascadingLevelCount()
      }
    } else {
      cascadingLevels.value = []
      cascadingLevelCount.value = 1
    }
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 新增選項
  function addOption () {
    fieldOptions.value.push({ value: '', label: '' })
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 載入範例選項
  function loadExampleOptions () {
    const examples = {
      select: [
        { value: 'option1', label: '選項 1' },
        { value: 'option2', label: '選項 2' },
        { value: 'option3', label: '選項 3' },
      ],
      multiselect: [
        { value: 'tag1', label: '標籤 1' },
        { value: 'tag2', label: '標籤 2' },
        { value: 'tag3', label: '標籤 3' },
        { value: 'tag4', label: '標籤 4' },
      ],
      checkbox: [
        { value: 'check1', label: '選項 A' },
        { value: 'check2', label: '選項 B' },
        { value: 'check3', label: '選項 C' },
      ],
      radio: [
        { value: 'yes', label: '是' },
        { value: 'no', label: '否' },
      ],
    }

    const example = examples[fieldData.field_type]
    if (example) {
      fieldOptions.value = [...example]
      swal.info('已載入範例選項，您可以修改或新增更多選項')
    }
  }

  // 開啟群組管理對話框
  function openGroupDialog (groupName) {
    // 確保 groupName 是字符串（處理 v-combobox 可能傳入對象的情況）
    const groupNameStr = typeof groupName === 'string'
      ? groupName
      : (groupName?.value || groupName?.title || groupName || '')

    editingGroupName.value = groupNameStr
    newGroupName.value = groupNameStr
    groupDialog.value = true
  }

  // 關閉群組管理對話框
  function closeGroupDialog () {
    groupDialog.value = false
    editingGroupName.value = null
    newGroupName.value = ''
  }

  // 儲存群組（新增或重命名）
  async function saveGroup () {
    try {
      console.log('saveGroup 被調用', { newGroupName: newGroupName.value, editingGroupName: editingGroupName.value })

      if (!newGroupName.value || !newGroupName.value.trim()) {
        await swal.warning('請輸入群組名稱')
        return
      }

      const trimmedGroupName = newGroupName.value.trim()
      console.log('群組名稱已修剪:', trimmedGroupName)

      // 檢查群組名稱是否已存在（排除當前編輯的群組）
      // 檢查 allGroups 和 fields 中的群組
      const existsInAllGroups = allGroups.value.has(trimmedGroupName)
        && (!editingGroupName.value || trimmedGroupName !== editingGroupName.value)

      const existsInFields = fields.value.some(field => {
        const fieldGroup = field.field_group || ''
        return fieldGroup === trimmedGroupName
          && (!editingGroupName.value || fieldGroup !== editingGroupName.value)
      })

      if (existsInAllGroups || existsInFields) {
        await swal.warning('群組名稱已存在，請使用其他名稱')
        return
      }

      if (editingGroupName.value) {
        // 編輯模式：重命名群組
        if (trimmedGroupName === editingGroupName.value) {
          closeGroupDialog()
          return
        }

        // 更新所有屬於該群組的欄位
        for (const field of fields.value) {
          if (field.field_group === editingGroupName.value) {
            field.field_group = trimmedGroupName
          }
        }

        // 更新 allGroups：移除舊名稱，添加新名稱
        allGroups.value.delete(editingGroupName.value)
        allGroups.value.add(trimmedGroupName)

        // 更新群組順序：如果群組順序調整對話框是開啟的，更新列表
        if (groupOrderDialog.value) {
          const index = groupOrderList.value.indexOf(editingGroupName.value)
          if (index !== -1) {
            groupOrderList.value[index] = trimmedGroupName
          }
        } else {
          // 更新群組順序
          const index = groupOrder.value.indexOf(editingGroupName.value)
          if (index !== -1) {
            groupOrder.value[index] = trimmedGroupName
          }
        }

        // 顯示成功訊息
        await swal.success(`群組「${editingGroupName.value}」已重命名為「${trimmedGroupName}」`)
      } else {
        // 新增模式：將群組添加到 allGroups，使其出現在下拉選單中
        allGroups.value.add(trimmedGroupName)
        console.log('新增群組模式，已添加到 allGroups:', Array.from(allGroups.value))

        // 如果群組順序調整對話框是開啟的，自動將新群組添加到群組順序列表
        if (groupOrderDialog.value) {
          if (!groupOrderList.value.includes(trimmedGroupName)) {
            groupOrderList.value.push(trimmedGroupName)
            console.log('群組順序調整對話框開啟，已添加到 groupOrderList:', groupOrderList.value)
          }
        } else {
          // 如果群組順序調整對話框未開啟，將新群組添加到群組順序
          if (!groupOrder.value.includes(trimmedGroupName)) {
            groupOrder.value.push(trimmedGroupName)
            console.log('群組順序調整對話框未開啟，已添加到 groupOrder:', groupOrder.value)
          }
        }

        // 顯示成功訊息
        await swal.success(`群組「${trimmedGroupName}」已建立，您可以在編輯欄位時選擇此群組`)
        console.log('成功訊息已顯示，當前 groupOrder:', groupOrder.value)
      }

      closeGroupDialog()
    } catch (error) {
      console.error('儲存群組時發生錯誤:', error)
      await swal.error('儲存群組失敗：' + (error.message || '未知錯誤'))
    }
  }

  // 刪除群組
  function deleteGroup () {
    if (!editingGroupName.value) {
      return
    }

    // 移除所有屬於該群組的欄位的群組設定
    for (const field of fields.value) {
      if (field.field_group === editingGroupName.value) {
        field.field_group = ''
      }
    }

    // 從 allGroups 中移除
    allGroups.value.delete(editingGroupName.value)

    closeGroupDialog()
  }

  // 移除選項
  function removeOption (index) {
    fieldOptions.value.splice(index, 1)
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 更新層次數量
  function updateCascadingLevelCount () {
    const currentCount = cascadingLevels.value.length
    const targetCount = cascadingLevelCount.value || 1

    if (targetCount > currentCount) {
      // 增加層級
      for (let i = currentCount; i < targetCount; i++) {
        const baseFieldKey = fieldData.field_key || 'cascading_field'
        cascadingLevels.value.push({
          label: `第 ${i + 1} 層`,
          placeholder: '請選擇',
          options: [],
          // 層級專屬設定
          field_key: `${baseFieldKey}_level_${i + 1}`,
          field_label: `層級 ${i + 1}`,
          is_required: i === 0 ? (fieldData.is_required || false) : false, // 只有第一層預設為必填
          is_visible: true,
          columnSize: fieldData.columnSize !== undefined && fieldData.columnSize !== null ? Number(fieldData.columnSize) : 12,
          display_order: (fieldData.display_order || 0) + i,
          placeholder_text: '請選擇',
          default_value: '',
          help_text: '',
        })
      }
    } else if (targetCount < currentCount) {
      // 減少層級
      cascadingLevels.value = cascadingLevels.value.slice(0, targetCount)
    }
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 添加多層選單層級
  function addCascadingLevel () {
    cascadingLevels.value.push({
      label: `第 ${cascadingLevels.value.length + 1} 層`,
      placeholder: '請選擇',
      options: [],
    })
    cascadingLevelCount.value = cascadingLevels.value.length
  }

  // 移除多層選單層級
  function removeCascadingLevel (index) {
    cascadingLevels.value.splice(index, 1)
    cascadingLevelCount.value = cascadingLevels.value.length
  }

  // 在指定層級添加選項
  function addCascadingOption (levelIndex) {
    if (!cascadingLevels.value[levelIndex]) {
      return
    }
    if (!cascadingLevels.value[levelIndex].options) {
      cascadingLevels.value[levelIndex].options = []
    }
    cascadingLevels.value[levelIndex].options.push({
      value: '',
      label: '',
      children: [],
    })
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 移除指定層級的選項
  function removeCascadingOption (levelIndex, optionIndex) {
    if (cascadingLevels.value[levelIndex] && cascadingLevels.value[levelIndex].options) {
      cascadingLevels.value[levelIndex].options.splice(optionIndex, 1)
    }
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 上移指定層級的選項
  function moveCascadingOptionUp (levelIndex, optionIndex) {
    if (optionIndex === 0) return
    if (!cascadingLevels.value[levelIndex] || !cascadingLevels.value[levelIndex].options) return

    const options = cascadingLevels.value[levelIndex].options
    const option = options[optionIndex]
    options.splice(optionIndex, 1)
    options.splice(optionIndex - 1, 0, option)
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 下移指定層級的選項
  function moveCascadingOptionDown (levelIndex, optionIndex) {
    if (!cascadingLevels.value[levelIndex] || !cascadingLevels.value[levelIndex].options) return
    const options = cascadingLevels.value[levelIndex].options
    if (optionIndex === options.length - 1) return

    const option = options[optionIndex]
    options.splice(optionIndex, 1)
    options.splice(optionIndex + 1, 0, option)
    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 上移指定選項的子選項
  function moveCascadingChildOptionUp (levelIndex, optionIndex, childIndex, level1OptionIndex = null) {
    let targetOption = null

    if (level1OptionIndex !== null && level1OptionIndex >= 0) {
      // 層級三及以後的情況
      const level1 = cascadingLevels.value[0]
      if (level1 && level1.options && level1.options[level1OptionIndex]) {
        const level1Option = level1.options[level1OptionIndex]
        if (level1Option.children && level1Option.children[optionIndex]) {
          targetOption = level1Option.children[optionIndex]
        }
      }
    } else {
      // 層級二的情況
      const level = cascadingLevels.value[levelIndex]
      if (level && level.options && level.options[optionIndex]) {
        targetOption = level.options[optionIndex]
      }
    }

    if (targetOption && targetOption.children && childIndex > 0) {
      const children = targetOption.children
      const child = children[childIndex]
      children.splice(childIndex, 1)
      children.splice(childIndex - 1, 0, child)
      // 更新 JSON
      updateJsonFromFieldData()
    }
  }

  // 下移指定選項的子選項
  function moveCascadingChildOptionDown (levelIndex, optionIndex, childIndex, level1OptionIndex = null) {
    let targetOption = null

    if (level1OptionIndex !== null && level1OptionIndex >= 0) {
      // 層級三及以後的情況
      const level1 = cascadingLevels.value[0]
      if (level1 && level1.options && level1.options[level1OptionIndex]) {
        const level1Option = level1.options[level1OptionIndex]
        if (level1Option.children && level1Option.children[optionIndex]) {
          targetOption = level1Option.children[optionIndex]
        }
      }
    } else {
      // 層級二的情況
      const level = cascadingLevels.value[levelIndex]
      if (level && level.options && level.options[optionIndex]) {
        targetOption = level.options[optionIndex]
      }
    }

    if (targetOption && targetOption.children) {
      const children = targetOption.children
      if (childIndex < children.length - 1) {
        const child = children[childIndex]
        children.splice(childIndex, 1)
        children.splice(childIndex + 1, 0, child)
        // 更新 JSON
        updateJsonFromFieldData()
      }
    }
  }

  // 在指定選項下添加子選項
  // levelIndex: 父選項所在的層級索引（對於層級三，這是層級二的索引，即 1）
  // optionIndex: 父選項在該層級中的索引（對於層級三，這是層級二的選項索引）
  // level1OptionIndex: 可選，如果提供，表示層級一的選項索引（用於層級三及以後）
  function addCascadingChildOption (levelIndex, optionIndex, level1OptionIndex = null) {
    let targetOption = null

    if (level1OptionIndex !== null && level1OptionIndex >= 0) {
      // 層級三及以後的情況：需要從層級一的選項中找到層級二的選項，然後在層級二的選項下添加子選項
      // level1OptionIndex 是層級一的選項索引
      // levelIndex 是層級二的索引（應該是 1）
      // optionIndex 是層級二的選項索引
      const level1 = cascadingLevels.value[0]
      if (level1 && level1.options && level1.options[level1OptionIndex]) {
        const level1Option = level1.options[level1OptionIndex]
        if (level1Option.children && level1Option.children[optionIndex]) {
          targetOption = level1Option.children[optionIndex]
        }
      }
    } else {
      // 層級二的情況：直接從層級一的選項中找到
      const level = cascadingLevels.value[levelIndex]
      if (level && level.options && level.options[optionIndex]) {
        targetOption = level.options[optionIndex]
      }
    }

    if (targetOption) {
      if (!targetOption.children) {
        targetOption.children = []
      }
      targetOption.children.push({
        value: '',
        label: '',
      })
      // 更新 JSON
      updateJsonFromFieldData()
    }
  }

  // 移除指定選項的子選項
  // levelIndex: 父選項所在的層級索引（對於層級三，這是層級二的索引，即 1）
  // optionIndex: 父選項在該層級中的索引（對於層級三，這是層級二的選項索引）
  // childIndex: 要移除的子選項索引
  // level1OptionIndex: 可選，如果提供，表示層級一的選項索引（用於層級三及以後）
  function removeCascadingChildOption (levelIndex, optionIndex, childIndex, level1OptionIndex = null) {
    let targetOption = null

    if (level1OptionIndex !== null && level1OptionIndex >= 0) {
      // 層級三及以後的情況：需要從層級一的選項中找到層級二的選項，然後移除其子選項
      const level1 = cascadingLevels.value[0]
      if (level1 && level1.options && level1.options[level1OptionIndex]) {
        const level1Option = level1.options[level1OptionIndex]
        if (level1Option.children && level1Option.children[optionIndex]) {
          targetOption = level1Option.children[optionIndex]
        }
      }
    } else {
      // 層級二的情況：直接從層級一的選項中找到
      const level = cascadingLevels.value[levelIndex]
      if (level && level.options && level.options[optionIndex]) {
        targetOption = level.options[optionIndex]
      }
    }

    if (targetOption && targetOption.children) {
      targetOption.children.splice(childIndex, 1)
      // 更新 JSON
      updateJsonFromFieldData()
    }
  }

  // 移動多層選單層級向上
  function moveCascadingLevelUp (levelIndex) {
    if (levelIndex === 0) return

    const level = cascadingLevels.value[levelIndex]
    cascadingLevels.value.splice(levelIndex, 1)
    cascadingLevels.value.splice(levelIndex - 1, 0, level)

    // 更新所有層級的 display_order
    for (const [index, l] of cascadingLevels.value.entries()) {
      l.display_order = index
    }

    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 移動多層選單層級向下
  function moveCascadingLevelDown (levelIndex) {
    if (levelIndex === cascadingLevels.value.length - 1) return

    const level = cascadingLevels.value[levelIndex]
    cascadingLevels.value.splice(levelIndex, 1)
    cascadingLevels.value.splice(levelIndex + 1, 0, level)

    // 更新所有層級的 display_order
    for (const [index, l] of cascadingLevels.value.entries()) {
      l.display_order = index
    }

    // 更新 JSON
    updateJsonFromFieldData()
  }

  // 從 fieldData 生成 JSON 配置
  function updateJsonFromFieldData () {
    if (isUpdatingJsonFromData.value) {
      return // 避免循環更新
    }

    try {
      isUpdatingJsonFromData.value = true

      // 建立一個完整的欄位配置物件，包含所有欄位設定
      const fullConfig = {
        // 基本欄位屬性
        field_key: fieldData.field_key || '',
        field_type: fieldData.field_type || 'text',
        field_label: fieldData.field_label || '',
        field_label_en: fieldData.field_label_en || '',
        display_order: fieldData.display_order === undefined ? 0 : Number(fieldData.display_order),
        field_group: fieldData.field_group || '',
        sub_group: fieldData.sub_group || '',
        is_required: fieldData.is_required || false,
        is_visible: fieldData.is_visible || false,
        is_readonly: fieldData.is_readonly || false,
        is_in_template: fieldData.is_in_template || false,
        placeholder: fieldData.placeholder || '',
        help_text: fieldData.help_text || '',
        default_value: fieldData.default_value || '',
        max_length: fieldData.max_length !== null && fieldData.max_length !== undefined ? Number(fieldData.max_length) : null,
        // field_config 中的配置
        field_config: { ...fieldData.field_config },
      }

      // 處理選項（如果需要的話）
      if (needsOptions.value && fieldOptions.value.length > 0) {
        fullConfig.field_config.options = fieldOptions.value
          .filter(opt => opt.value && opt.label)
          .map(opt => ({
            value: opt.value,
            label: opt.label,
            title: opt.label, // 兼容性
          }))
      }

      // 處理聚合資料模板
      if (needsAggregatedTemplate.value) {
        if (fieldData.field_config.template !== undefined) {
          fullConfig.field_config.template = fieldData.field_config.template
        }
        if (fieldData.field_config.counterValue !== undefined) {
          fullConfig.field_config.counterValue = Number(fieldData.field_config.counterValue) || 0
        }
      }

      // 處理多層選單配置
      if (needsCascadingLevels.value && cascadingLevels.value.length > 0) {
        // 層級配置（不包含 options），按照 display_order 排序
        const sortedLevels = [...cascadingLevels.value].toSorted((a, b) => {
          const orderA = a.display_order === undefined ? 0 : Number(a.display_order)
          const orderB = b.display_order === undefined ? 0 : Number(b.display_order)
          return orderA - orderB
        })

        fullConfig.field_config.levels = sortedLevels.map(level => ({
          label: level.field_label || level.label || '',
          placeholder: level.placeholder || '',
          field_key: level.field_key || '',
          field_label: level.field_label || '',
          is_required: level.is_required === undefined ? false : level.is_required,
          is_visible: level.is_visible === undefined ? true : level.is_visible,
          columnSize: level.columnSize !== undefined && level.columnSize !== null ? Number(level.columnSize) : 12,
          display_order: level.display_order !== undefined ? Number(level.display_order) : 0,
          placeholder_text: level.placeholder_text || '',
          default_value: level.default_value || '',
          help_text: level.help_text || '',
        }))

        // 將選項獨立為一個區塊（只包含第一層的選項，即 display_order 為 0 的層級）
        const firstLevel = sortedLevels.find(l => (l.display_order === undefined ? 0 : Number(l.display_order)) === 0) || sortedLevels[0]
        fullConfig.field_config.cascading_options = (firstLevel && firstLevel.options && firstLevel.options.length > 0)
          ? firstLevel.options.map(opt => ({
            value: opt.value || '',
            label: opt.label || '',
            title: opt.label || opt.value || '',
            children: opt.children || [],
          }))
          : []
      }

      // 將欄位寬度保存到 field_config.cols
      if (fieldData.columnSize !== undefined && fieldData.columnSize !== null) {
        fullConfig.field_config.cols = Number(fieldData.columnSize)
      }

      // 轉換為 JSON 字串
      fieldConfigJson.value = JSON.stringify(fullConfig, null, 2)
    } catch (error) {
      console.error('生成 JSON 配置失敗', error)
      fieldConfigJson.value = '{}'
    } finally {
      isUpdatingJsonFromData.value = false
    }
  }

  // 從 JSON 更新 fieldData（當用戶手動編輯 JSON 時）
  function updateFieldDataFromJson () {
    if (isUpdatingJsonFromData.value) {
      return // 避免循環更新
    }

    try {
      const config = JSON.parse(fieldConfigJson.value || '{}')
      jsonError.value = false

      // 更新基本欄位屬性
      if (config.field_key !== undefined) {
        fieldData.field_key = config.field_key
      }
      if (config.field_type !== undefined) {
        fieldData.field_type = config.field_type
        // 觸發欄位類型變更處理
        handleFieldTypeChange()
      }
      if (config.field_label !== undefined) {
        fieldData.field_label = config.field_label
      }
      if (config.field_label_en !== undefined) {
        fieldData.field_label_en = config.field_label_en
      }
      if (config.display_order !== undefined) {
        fieldData.display_order = Number(config.display_order) || 0
      }
      if (config.field_group !== undefined) {
        fieldData.field_group = config.field_group || ''
        handleFieldGroupChange(config.field_group)
      }
      if (config.sub_group !== undefined) {
        fieldData.sub_group = config.sub_group || ''
        handleFieldSubGroupChange(config.sub_group)
      }
      if (config.is_required !== undefined) {
        fieldData.is_required = config.is_required || false
      }
      if (config.is_visible !== undefined) {
        fieldData.is_visible = config.is_visible !== false
      }
      if (config.is_readonly !== undefined) {
        fieldData.is_readonly = config.is_readonly || false
      }
      if (config.is_in_template !== undefined) {
        fieldData.is_in_template = config.is_in_template || false
      }
      if (config.placeholder !== undefined) {
        fieldData.placeholder = config.placeholder || ''
      }
      if (config.help_text !== undefined) {
        fieldData.help_text = config.help_text || ''
      }
      if (config.default_value !== undefined) {
        fieldData.default_value = config.default_value || ''
      }
      if (config.max_length !== undefined && config.max_length !== null) {
        fieldData.max_length = Number(config.max_length) || null
      }

      // 處理 field_config
      if (config.field_config && typeof config.field_config === 'object') {
        // 合併到 fieldData.field_config
        fieldData.field_config = { ...fieldData.field_config, ...config.field_config }

        // 如果 JSON 中有 cols，更新 columnSize
        if (config.field_config.cols !== undefined) {
          fieldData.columnSize = Number(config.field_config.cols) || 12
        }

        // 如果有多層選單配置，更新 cascadingLevels
        if (needsCascadingLevels.value && config.field_config.levels) {
          cascadingLevels.value = Array.isArray(config.field_config.levels)
            ? JSON.parse(JSON.stringify(config.field_config.levels)).map((level, index) => {
              // 從獨立的 cascading_options 區塊讀取選項（僅第一層）
              let levelOptions = []
              if (index === 0 && config.field_config.cascading_options) {
                // 第一層使用 cascading_options
                levelOptions = Array.isArray(config.field_config.cascading_options)
                  ? config.field_config.cascading_options.map(opt => ({
                    value: opt.value || '',
                    label: opt.label || '',
                    children: opt.children || [],
                  }))
                  : []
              } else if (level.options) {
                // 兼容舊格式：如果層級中還有 options（向後兼容）
                levelOptions = Array.isArray(level.options)
                  ? level.options.map(opt => ({
                    value: opt.value || '',
                    label: opt.label || '',
                    children: opt.children || [],
                  }))
                  : []
              }

              return {
                label: level.field_label || level.label || `第 ${index + 1} 層`,
                placeholder: level.placeholder || '請選擇',
                field_key: level.field_key || '',
                field_label: level.field_label || '',
                is_required: level.is_required === undefined ? false : level.is_required,
                is_visible: level.is_visible === undefined ? true : level.is_visible,
                columnSize: level.columnSize !== undefined && level.columnSize !== null ? Number(level.columnSize) : 12,
                display_order: level.display_order || 0,
                placeholder_text: level.placeholder_text || '',
                default_value: level.default_value || '',
                help_text: level.help_text || '',
                options: levelOptions,
              }
            })
            : []
          cascadingLevelCount.value = cascadingLevels.value.length || 1
        }

        // 如果有選項配置，更新 fieldOptions
        if (needsOptions.value && config.field_config.options) {
          fieldOptions.value = Array.isArray(config.field_config.options)
            ? config.field_config.options.map(opt => {
              if (typeof opt === 'string') {
                return { value: opt, label: opt }
              }
              return { value: opt.value, label: opt.label || opt.title || opt.value }
            })
            : []
        }

        // 如果有聚合資料模板，更新 fieldData.field_config
        if (needsAggregatedTemplate.value) {
          if (config.field_config.template !== undefined) {
            fieldData.field_config.template = config.field_config.template
          }
          if (config.field_config.counterValue !== undefined) {
            fieldData.field_config.counterValue = Number(config.field_config.counterValue) || 0
          }
        }
      } else if (config.cols !== undefined) {
        // 兼容舊格式：如果 JSON 中直接有 cols（不在 field_config 中）
        fieldData.columnSize = Number(config.cols) || 12
        fieldData.field_config.cols = Number(config.cols) || 12
      }
    } catch (error) {
      console.error('解析 JSON 配置失敗', error)
      jsonError.value = true
      // 不更新，保持原來的值
    }
  }

  // 儲存欄位
  function saveField () {
    // 先從 JSON 更新 fieldData（如果用戶手動編輯了 JSON）
    updateFieldDataFromJson()

    // 處理選項
    if (needsOptions.value) {
      fieldData.field_config.options = fieldOptions.value
        .filter(opt => opt.value && opt.label)
        .map(opt => ({
          value: opt.value,
          label: opt.label,
          title: opt.label, // 兼容性
        }))
    }

    // 處理聚合資料模板
    if (needsAggregatedTemplate.value) {
      // 確保 template 存在
      if (!fieldData.field_config.template) {
        fieldData.field_config.template = ''
      }
      // 確保 counterValue 是數字
      if (fieldData.field_config.counterValue !== undefined) {
        fieldData.field_config.counterValue = Number(fieldData.field_config.counterValue) || 0
      }
    }

    // 處理多層選單配置
    if (needsCascadingLevels.value) {
      // 層級配置（不包含 options），按照 display_order 排序
      const sortedLevels = [...cascadingLevels.value].toSorted((a, b) => {
        const orderA = a.display_order === undefined ? 0 : Number(a.display_order)
        const orderB = b.display_order === undefined ? 0 : Number(b.display_order)
        return orderA - orderB
      })

      fieldData.field_config.levels = sortedLevels.map(level => ({
        label: level.field_label || level.label || '',
        placeholder: level.placeholder || '',
        // 層級專屬設定
        field_key: level.field_key || '',
        field_label: level.field_label || '',
        is_required: level.is_required === undefined ? false : level.is_required,
        is_visible: level.is_visible === undefined ? true : level.is_visible,
        columnSize: level.columnSize !== undefined && level.columnSize !== null ? Number(level.columnSize) : 12,
        display_order: level.display_order === undefined ? 0 : Number(level.display_order),
        placeholder_text: level.placeholder_text || '',
        default_value: level.default_value || '',
        help_text: level.help_text || '',
      }))

      // 將選項獨立為一個區塊（只包含第一層的選項，即 display_order 為 0 的層級）
      const firstLevel = sortedLevels.find(l => (l.display_order === undefined ? 0 : Number(l.display_order)) === 0) || sortedLevels[0]
      fieldData.field_config.cascading_options = (firstLevel && firstLevel.options && firstLevel.options.length > 0)
        ? firstLevel.options.map(opt => ({
          value: opt.value || '',
          label: opt.label || '',
          title: opt.label || opt.value || '',
          children: opt.children || [],
        }))
        : []
    }

    // 將欄位寬度保存到 field_config.cols
    if (fieldData.columnSize) {
      fieldData.field_config.cols = fieldData.columnSize
    }

    // 最後從 JSON 合併（確保用戶手動編輯的 JSON 也被包含）
    try {
      const config = JSON.parse(fieldConfigJson.value || '{}')

      // 更新基本欄位屬性（如果 JSON 中有）
      if (config.field_key !== undefined) {
        fieldData.field_key = config.field_key
      }
      if (config.field_type !== undefined) {
        fieldData.field_type = config.field_type
      }
      if (config.field_label !== undefined) {
        fieldData.field_label = config.field_label
      }
      if (config.field_label_en !== undefined) {
        fieldData.field_label_en = config.field_label_en
      }
      if (config.display_order !== undefined) {
        fieldData.display_order = Number(config.display_order) || 0
      }
      if (config.field_group !== undefined) {
        fieldData.field_group = config.field_group || ''
      }
      if (config.sub_group !== undefined) {
        fieldData.sub_group = config.sub_group || ''
      }
      if (config.is_required !== undefined) {
        fieldData.is_required = config.is_required || false
      }
      if (config.is_visible !== undefined) {
        fieldData.is_visible = config.is_visible !== false
      }
      if (config.is_readonly !== undefined) {
        fieldData.is_readonly = config.is_readonly || false
      }
      if (config.is_in_template !== undefined) {
        fieldData.is_in_template = config.is_in_template || false
      }
      if (config.placeholder !== undefined) {
        fieldData.placeholder = config.placeholder || ''
      }
      if (config.help_text !== undefined) {
        fieldData.help_text = config.help_text || ''
      }
      if (config.default_value !== undefined) {
        fieldData.default_value = config.default_value || ''
      }
      if (config.max_length !== undefined && config.max_length !== null) {
        fieldData.max_length = Number(config.max_length) || null
      }

      // 處理 field_config
      if (config.field_config && typeof config.field_config === 'object') {
        // 合併配置，但保留剛剛保存的 levels 配置（如果有的話）
        if (needsCascadingLevels.value && fieldData.field_config.levels) {
          // 如果有多層選單配置，先保存 levels，然後合併其他配置，最後恢復 levels
          const savedLevels = fieldData.field_config.levels
          fieldData.field_config = { ...fieldData.field_config, ...config.field_config }
          fieldData.field_config.levels = savedLevels // 恢復 levels 配置
        } else {
          fieldData.field_config = { ...fieldData.field_config, ...config.field_config }
        }
      } else if (config.cols !== undefined) {
        // 兼容舊格式：如果 JSON 中直接有 cols（不在 field_config 中）
        fieldData.columnSize = Number(config.cols) || 12
        fieldData.field_config.cols = Number(config.cols) || 12
      }

      // 確保 cols 不被 JSON 配置覆蓋
      if (fieldData.columnSize) {
        fieldData.field_config.cols = fieldData.columnSize
      }
    } catch (error) {
      console.error('解析 JSON 配置失敗', error)
    }

    const field = { ...fieldData }

    if (editingFieldIndex.value === null) {
      // 新增模式
      if (!field.display_order) {
        field.display_order = fields.value.length + 1
      }
      fields.value.push(field)
    } else {
      // 編輯模式
      fields.value[editingFieldIndex.value] = field
    }

    closeFieldDialog()
  }

  // 刪除欄位
  function deleteField (index) {
    fields.value.splice(index, 1)
    // 更新順序
    updateFieldOrders()
  }

  // 更新欄位順序
  function updateFieldOrders () {
    for (const [index, field] of fields.value.entries()) {
      field.display_order = index + 1
    }
  }

  // 上移欄位
  function moveFieldUp (index) {
    if (index === 0) return
    const field = fields.value[index]
    fields.value.splice(index, 1)
    fields.value.splice(index - 1, 0, field)
    updateFieldOrders()
  }

  // 下移欄位
  function moveFieldDown (index) {
    if (index === fields.value.length - 1) return
    const field = fields.value[index]
    fields.value.splice(index, 1)
    fields.value.splice(index + 1, 0, field)
    updateFieldOrders()
  }

  // 取得欄位在所有欄位中的索引
  function getFieldIndexInAllFields (field) {
    return fields.value.findIndex(f =>
      (f.id && f.id === field.id)
      || (!f.id && !field.id && f.field_key === field.field_key),
    )
  }

  // 取得群組中的欄位總數
  function getGroupFieldCount (group) {
    if (!group) return 0
    let count = 0
    if (group.subGroups) {
      for (const subGroupName of Object.keys(group.subGroups)) {
        count += (group.subGroups[subGroupName] || []).length
      }
    }
    if (group.ungrouped) {
      count += group.ungrouped.length
    }
    return count
  }

  // 在群組內上移欄位（僅用於未分組到子群組的欄位）
  function moveFieldUpInGroup (groupName, index) {
    if (index === 0) return

    const group = groupedFieldsForDesign.value[groupName]
    if (!group || !group.ungrouped || index >= group.ungrouped.length) return

    const field = group.ungrouped[index]

    // 從所有欄位中找到這個欄位
    const allFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === field.id)
      || (!f.id && !field.id && f.field_key === field.field_key),
    )

    if (allFieldIndex === -1) return

    // 找到前一個欄位
    const prevField = group.ungrouped[index - 1]
    const prevFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === prevField.id)
      || (!f.id && !prevField.id && f.field_key === prevField.field_key),
    )

    if (prevFieldIndex === -1) return

    // 交換位置
    if (allFieldIndex < prevFieldIndex) {
      // 從後往前移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(prevFieldIndex, 0, field)
    } else {
      // 從前往後移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(prevFieldIndex, 0, field)
    }

    updateFieldOrders()
  }

  // 在子群組內上移欄位
  function moveFieldUpInSubGroup (groupName, subGroupName, index) {
    const groupData = groupedFieldsForDesign.value[groupName]
    if (!groupData || !groupData.subGroups[subGroupName]) return

    const subGroup = groupData.subGroups[subGroupName]
    if (index <= 0 || index >= subGroup.length) return

    const field = subGroup[index]

    // 從所有欄位中找到這個欄位
    const allFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === field.id)
      || (!f.id && !field.id && f.field_key === field.field_key),
    )

    if (allFieldIndex === -1) return

    // 找到前一個欄位
    const prevField = subGroup[index - 1]
    const prevFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === prevField.id)
      || (!f.id && !prevField.id && f.field_key === prevField.field_key),
    )

    if (prevFieldIndex === -1) return

    // 交換位置
    if (allFieldIndex < prevFieldIndex) {
      // 從後往前移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(prevFieldIndex, 0, field)
    } else {
      // 從前往後移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(prevFieldIndex, 0, field)
    }

    updateFieldOrders()
  }

  // 在子群組內下移欄位
  function moveFieldDownInSubGroup (groupName, subGroupName, index) {
    const groupData = groupedFieldsForDesign.value[groupName]
    if (!groupData || !groupData.subGroups[subGroupName]) return

    const subGroup = groupData.subGroups[subGroupName]
    if (index < 0 || index >= subGroup.length - 1) return

    const field = subGroup[index]

    // 從所有欄位中找到這個欄位
    const allFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === field.id)
      || (!f.id && !field.id && f.field_key === field.field_key),
    )

    if (allFieldIndex === -1) return

    // 找到下一個欄位
    const nextField = subGroup[index + 1]
    const nextFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === nextField.id)
      || (!f.id && !nextField.id && f.field_key === nextField.field_key),
    )

    if (nextFieldIndex === -1) return

    // 交換位置
    if (allFieldIndex < nextFieldIndex) {
      // 從前往後移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(nextFieldIndex, 0, field)
    } else {
      // 從後往前移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(nextFieldIndex, 0, field)
    }

    updateFieldOrders()
  }

  // 在群組內下移欄位（僅用於未分組到子群組的欄位）
  function moveFieldDownInGroup (groupName, index) {
    const group = groupedFieldsForDesign.value[groupName]
    if (!group || !group.ungrouped || index >= group.ungrouped.length - 1) return

    const field = group.ungrouped[index]

    // 從所有欄位中找到這個欄位
    const allFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === field.id)
      || (!f.id && !field.id && f.field_key === field.field_key),
    )

    if (allFieldIndex === -1) return

    // 找到下一個欄位
    const nextField = group.ungrouped[index + 1]
    const nextFieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === nextField.id)
      || (!f.id && !nextField.id && f.field_key === nextField.field_key),
    )

    if (nextFieldIndex === -1) return

    // 交換位置
    if (allFieldIndex < nextFieldIndex) {
      // 從前往後移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(nextFieldIndex, 0, field)
    } else {
      // 從後往前移動
      fields.value.splice(allFieldIndex, 1)
      fields.value.splice(nextFieldIndex, 0, field)
    }

    updateFieldOrders()
  }

  // 拖曳開始
  function handleDragStart (event, field, groupName, index, subGroupName = null) {
    draggedField.value = field
    draggedFromGroup.value = groupName
    draggedFromSubGroup.value = subGroupName
    draggedFromIndex.value = index

    // 設定拖曳效果
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', JSON.stringify({
      fieldKey: field.field_key,
      groupName,
      subGroupName,
      index,
    }))

    // 設定拖曳時的視覺效果
    if (event.target.closest('.draggable-field')) {
      event.target.closest('.draggable-field').style.opacity = '0.5'
    }
  }

  // 拖曳結束
  function handleDragEnd (event) {
    if (event.target.closest('.draggable-field')) {
      event.target.closest('.draggable-field').style.opacity = '1'
    }
    draggedField.value = null
    draggedFromGroup.value = null
    draggedFromSubGroup.value = null
    draggedFromIndex.value = null
    dragOverGroup.value = null
    dragOverSubGroup.value = null
    dragOverIndex.value = null
  }

  // 拖曳進入群組
  function handleDragEnter (event, groupName, subGroupName = null) {
    if (!draggedField.value) return
    if (dragOverGroup.value !== groupName || dragOverSubGroup.value !== subGroupName) {
      dragOverGroup.value = groupName
      dragOverSubGroup.value = subGroupName
      dragOverIndex.value = -1 // 表示在群組/子群組開頭
    }
  }

  // 拖曳離開群組
  function handleDragLeave (event, groupName, subGroupName = null) {
    // 只有當真正離開群組時才清除（不是進入子元素）
    const relatedTarget = event.relatedTarget
    if ((!relatedTarget || !event.currentTarget.contains(relatedTarget)) && dragOverGroup.value === groupName && dragOverSubGroup.value === subGroupName) {
      dragOverGroup.value = null
      dragOverSubGroup.value = null
      dragOverIndex.value = null
    }
  }

  // 拖曳經過群組
  function handleDragOver (event, groupName, subGroupName = null) {
    if (!draggedField.value) return
    event.dataTransfer.dropEffect = 'move'
  }

  // 拖曳經過欄位項目
  function handleItemDragOver (event, groupName, index, subGroupName = null) {
    if (!draggedField.value) return

    // 更新拖曳目標位置
    dragOverGroup.value = groupName
    dragOverSubGroup.value = subGroupName
    dragOverIndex.value = index

    event.dataTransfer.dropEffect = 'move'
  }

  // 放置欄位
  function handleDrop (event, targetGroupName, targetSubGroupName = null) {
    event.preventDefault()
    event.stopPropagation()

    if (!draggedField.value) return

    // 從所有欄位中找到被拖曳的欄位
    const fieldIndex = fields.value.findIndex(f =>
      (f.id && f.id === draggedField.value.id)
      || (!f.id && !draggedField.value.id && f.field_key === draggedField.value.field_key),
    )

    if (fieldIndex === -1) return

    const field = { ...fields.value[fieldIndex] } // 複製欄位物件

    // 更新欄位的群組和子群組
    const newGroupName = targetGroupName === '未分組欄位' ? '' : targetGroupName
    field.field_group = newGroupName
    field.sub_group = targetSubGroupName || ''

    // 從原位置移除
    fields.value.splice(fieldIndex, 1)

    // 計算目標位置
    let targetIndex = dragOverIndex.value

    // 如果目標位置為 -1，表示放在群組/子群組開頭
    if (targetIndex === -1) {
      targetIndex = 0
    }

    // 如果沒有目標位置，放在群組最後
    if (targetIndex === null || targetIndex === undefined || targetIndex < 0) {
      // 計算目標群組的欄位數量
      const targetGroupFields = fields.value.filter(f => {
        const fGroup = f.field_group || ''
        return (newGroupName === '' && fGroup === '') || fGroup === newGroupName
      })
      targetIndex = targetGroupFields.length
    }

    // 找到插入位置
    let insertIndex = 0
    let foundTargetGroup = false
    let currentGroupIndex = 0

    for (let i = 0; i < fields.value.length; i++) {
      const f = fields.value[i]
      const fGroup = f.field_group || ''
      const isTargetGroup = (newGroupName === '' && fGroup === '') || fGroup === newGroupName

      if (isTargetGroup) {
        foundTargetGroup = true
        if (currentGroupIndex === targetIndex) {
          insertIndex = i
          break
        }
        currentGroupIndex++
        insertIndex = i + 1
      } else if (foundTargetGroup) {
        // 已經離開目標群組
        break
      } else {
        insertIndex = i + 1
      }
    }

    // 插入到新位置
    fields.value.splice(insertIndex, 0, field)

    // 更新順序
    updateFieldOrders()

    // 清除拖曳狀態
    draggedField.value = null
    draggedFromGroup.value = null
    draggedFromSubGroup.value = null
    draggedFromIndex.value = null
    dragOverGroup.value = null
    dragOverSubGroup.value = null
    dragOverIndex.value = null
  }

  // 取得欄位顯示標籤（用於列表顯示）
  function getFieldDisplayLabel (field) {
    // 如果是多層選單，組合所有層級的標籤
    if (field.field_type === 'cascading_select' && field.field_config?.levels) {
      const levelLabels = field.field_config.levels
        .map(level => level.label || level.field_label)
        .filter(Boolean) // 過濾掉空值

      if (levelLabels.length > 0) {
        return levelLabels.join(' / ')
      }
    }

    // 其他情況使用原來的邏輯
    return field.field_label || field.field_key
  }

  // 取得欄位總寬度（用於顯示）
  function getFieldTotalWidth (field) {
    // 如果是多層選單，計算所有層級的欄寬總和
    if (field.field_type === 'cascading_select' && field.field_config?.levels) {
      const totalWidth = field.field_config.levels.reduce((sum, level) => {
        const width = level.columnSize !== undefined && level.columnSize !== null
          ? Number(level.columnSize)
          : 12
        return sum + width
      }, 0)
      return totalWidth
    }

    // 其他情況使用原來的邏輯
    return field.field_config?.cols || 12
  }

  // 取得欄位鍵值顯示（用於列表顯示）
  function getFieldDisplayKey (field) {
    // 如果是多層選單，組合所有層級的鍵值
    if (field.field_type === 'cascading_select' && field.field_config?.levels) {
      const levelKeys = field.field_config.levels
        .map(level => level.field_key)
        .filter(Boolean) // 過濾掉空值

      if (levelKeys.length > 0) {
        return levelKeys.join(' / ')
      }
    }

    // 其他情況使用原來的邏輯
    return field.field_key
  }

  // 判斷是否應該顯示鍵值
  function shouldShowFieldKey (field) {
    // 所有欄位都顯示鍵值（包括多層選單）
    return true
  }

  // 取得欄位類型標籤
  function getFieldTypeLabel (type) {
    const option = fieldTypeOptions.find(opt => opt.value === type)
    return option ? option.title : type
  }

  // 取得欄位類型顏色
  function getFieldTypeColor (type) {
    const colors = {
      text: 'blue',
      textarea: 'blue',
      number: 'green',
      select: 'purple',
      multiselect: 'purple',
      cascading_select: 'indigo',
      checkbox: 'orange',
      radio: 'orange',
      date: 'teal',
      datetime: 'teal',
      file: 'red',
      json: 'grey',
    }
    return colors[type] || 'grey'
  }

  // 儲存表單
  async function saveForm () {
    const { valid } = await basicFormRef.value.validate()
    if (!valid) {
      await swal.warning('請填寫所有必填欄位')
      activeTab.value = 'basic'
      return
    }

    if (fields.value.length === 0) {
      await swal.warning('請至少新增一個欄位')
      activeTab.value = 'fields'
      return
    }

    saving.value = true
    saveProgress.value = 0

    try {
      let formId

      if (isEditMode.value) {
        console.log('開始更新表單，formId:', props.formId)

        // 更新表單（包含群組順序和子群組）
        saveProgress.value = 5
        const formConfig = { ...formData.form_config, group_order: groupOrder.value }
        // 保存子群組資料
        const subGroupsData = {}
        if (subGroups.value && subGroups.value.size > 0) {
          for (const [groupName, subGroupsList] of subGroups.value.entries()) {
            if (subGroupsList && subGroupsList.length > 0) {
              subGroupsData[groupName] = subGroupsList.map(sg => ({
                name: sg.name,
                order: sg.order || 0,
              }))
            }
          }
        }
        formConfig.sub_groups = subGroupsData
        console.log('保存子群組資料:', subGroupsData)

        saveProgress.value = 10
        const updatedForm = await formsService.updateForm(props.formId, {
          form_name: formData.form_name,
          form_name_en: formData.form_name_en,
          description: formData.description,
          is_active: formData.is_active,
          is_default: formData.is_default,
          form_config: formConfig,
        })
        formId = updatedForm.id
        console.log('表單更新成功，formId:', formId)

        // 更新欄位
        saveProgress.value = 20
        const existingFields = await formFieldsService.getFields(formId)
        console.log('現有欄位數量:', existingFields.length)
        console.log('要儲存的欄位數量:', fields.value.length)

        // 刪除不存在的欄位
        const deleteProgressStep = 10 / (existingFields.length || 1)
        for (const [idx, existingField] of existingFields.entries()) {
          const stillExists = fields.value.some(f =>
            (f.id && f.id === existingField.id) || f.field_key === existingField.field_key,
          )
          if (!stillExists) {
            console.log('刪除欄位:', existingField.field_key)
            await formFieldsService.deleteField(formId, existingField.id)
          }
          saveProgress.value = 20 + (idx + 1) * deleteProgressStep
        }

        // 更新或新增欄位
        const fieldProgressStep = 60 / fields.value.length
        for (let i = 0; i < fields.value.length; i++) {
          const field = fields.value[i]
          const fieldToSave = {
            field_key: field.field_key,
            field_label: field.field_label,
            field_label_en: field.field_label_en || '',
            field_type: field.field_type,
            max_length: field.max_length || null,
            is_required: field.is_required || false,
            field_group: field.field_group || '',
            sub_group: field.sub_group || '', // 子群組名稱
            display_order: field.display_order || (i + 1),
            field_config: field.field_config || {},
            default_value: field.default_value || '',
            placeholder: field.placeholder || '',
            help_text: field.help_text || '',
            validation_rules: field.validation_rules || {},
            is_visible: field.is_visible !== false,
            is_readonly: field.is_readonly || false,
            is_in_template: field.is_in_template || false,
          }

          // 確定欄位 ID：優先使用欄位的 id，如果沒有則從 existingFields 中查找
          let fieldId = field.id
          if (!fieldId) {
            const existingField = existingFields.find(ef => ef.field_key === field.field_key)
            if (existingField) {
              fieldId = existingField.id
              // 更新本地欄位的 id，以便後續操作
              field.id = fieldId
            }
          }

          if (fieldId) {
            // 更新現有欄位
            console.log(`更新欄位 ${i + 1}/${fields.value.length}:`, field.field_key, 'id:', fieldId)
            await formFieldsService.updateField(formId, fieldId, fieldToSave)
          } else {
            // 新增欄位（確認 field_key 不存在）
            console.log(`新增欄位 ${i + 1}/${fields.value.length}:`, field.field_key)
            const createdField = await formFieldsService.createField(formId, fieldToSave)
            // 更新本地欄位的 id，以便後續操作
            field.id = createdField.id
          }

          // 注意：cascading_select 的層級不再創建獨立的 form_fields 記錄
          // 層級的 field_key 只用於保存資料時識別，不會在 form_fields 中創建對應記錄

          saveProgress.value = 30 + (i + 1) * fieldProgressStep
        }
      } else {
        console.log('建立新表單')

        // 建立新表單（包含群組順序和子群組）
        saveProgress.value = 5
        const formConfig = { ...formData.form_config, group_order: groupOrder.value }
        // 保存子群組資料
        const subGroupsData = {}
        for (const [groupName, subGroupsList] of subGroups.value.entries()) {
          subGroupsData[groupName] = subGroupsList.map(sg => ({
            name: sg.name,
            order: sg.order || 0,
          }))
        }
        formConfig.sub_groups = subGroupsData

        saveProgress.value = 10
        const newForm = await formsService.createForm({
          form_code: formData.form_code,
          form_name: formData.form_name,
          form_name_en: formData.form_name_en || '',
          description: formData.description || '',
          is_active: formData.is_active !== false,
          is_default: formData.is_default || false,
          form_config: formConfig,
        })
        formId = newForm.id
        console.log('表單建立成功，formId:', formId)

        // 建立欄位
        const fieldProgressStep = 80 / fields.value.length
        for (let i = 0; i < fields.value.length; i++) {
          const field = fields.value[i]
          console.log(`建立欄位 ${i + 1}/${fields.value.length}:`, field.field_key)
          const createdField = await formFieldsService.createField(formId, {
            field_key: field.field_key,
            field_label: field.field_label,
            field_label_en: field.field_label_en || '',
            field_type: field.field_type,
            max_length: field.max_length || null,
            is_required: field.is_required || false,
            field_group: field.field_group || '',
            sub_group: field.sub_group || '', // 子群組名稱
            display_order: field.display_order || (i + 1),
            field_config: field.field_config || {},
            default_value: field.default_value || '',
            placeholder: field.placeholder || '',
            help_text: field.help_text || '',
            validation_rules: field.validation_rules || {},
            is_visible: field.is_visible !== false,
            is_readonly: field.is_readonly || false,
            is_in_template: field.is_in_template || false,
          })
          // 更新本地欄位的 id
          field.id = createdField.id

          // 注意：cascading_select 的層級不再創建獨立的 form_fields 記錄
          // 層級的 field_key 只用於保存資料時識別，不會在 form_fields 中創建對應記錄

          saveProgress.value = 20 + (i + 1) * fieldProgressStep
        }
      }

      console.log('表單儲存完成')
      saveProgress.value = 100

      // 等待一小段時間讓進度條顯示 100%
      await new Promise(resolve => setTimeout(resolve, 300))

      // 先關閉進度條
      saving.value = false
      saveProgress.value = 0

      // 顯示成功訊息
      await swal.success('表單已儲存')

      // 儲存成功後不關閉對話視窗，只發送保存事件讓父組件更新列表
      emit('saved', formId)
    } catch (error) {
      console.error('儲存表單失敗', error)
      console.error('錯誤詳情:', {
        message: error.message,
        stack: error.stack,
        response: error.response,
        data: error.data,
      })

      // 關閉進度條
      saving.value = false
      saveProgress.value = 0

      // 顯示錯誤訊息
      await swal.error(error.message || '儲存表單失敗，請查看控制台了解詳情')
    }
  }

  // 處理取消
  function handleCancel () {
    emit('cancel')
  }

  // 滾動到欄位設定分頁頂部
  function scrollToFieldsTop () {
    // 嘗試使用 ref 引用
    if (fieldsTabRef.value && fieldsTabRef.value.$el) {
      fieldsTabRef.value.$el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    } else {
      // 如果找不到，則滾動到視窗頂部
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  // 預覽用的欄位分組（按照群組順序排列）
  const previewGroupedFields = computed(() => {
    const groups = {}
    for (const field of fields.value) {
      const groupName = field.field_group || '_ungrouped'
      if (!groups[groupName]) {
        groups[groupName] = {
          subGroups: {},
          ungrouped: [],
        }
      }

      if (field.sub_group) {
        // 屬於子群組的欄位
        if (!groups[groupName].subGroups[field.sub_group]) {
          groups[groupName].subGroups[field.sub_group] = []
        }
        groups[groupName].subGroups[field.sub_group].push(field)
      } else {
        // 不屬於任何子群組的欄位
        groups[groupName].ungrouped.push(field)
      }
    }

    // 按 display_order 排序每個群組內的欄位
    for (const groupName of Object.keys(groups)) {
      // 排序子群組內的欄位
      for (const subGroupName of Object.keys(groups[groupName].subGroups)) {
        groups[groupName].subGroups[subGroupName].sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
      }
      // 排序未分組到子群組的欄位
      groups[groupName].ungrouped.sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }

    // 按照 groupOrder 排序群組
    const orderedGroups = {}

    // 先添加有順序的群組
    for (const groupName of groupOrder.value) {
      if (groups[groupName]) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    // 再添加沒有順序的群組（新群組或未在順序列表中的群組）
    for (const groupName of Object.keys(groups)) {
      if (groupName !== '_ungrouped' && !groupOrder.value.includes(groupName)) {
        orderedGroups[groupName] = groups[groupName]
      }
    }

    // 最後添加未分組欄位
    if (groups._ungrouped) {
      orderedGroups._ungrouped = groups._ungrouped
    }

    return orderedGroups
  })

  const previewUngroupedFields = computed(() => {
    const ungrouped = previewGroupedFields.value._ungrouped
    if (!ungrouped) return []
    // 合併未分組到子群組的欄位和子群組內的欄位
    const allFields = [...(ungrouped.ungrouped || [])]
    for (const subGroupName of Object.keys(ungrouped.subGroups || {})) {
      allFields.push(...(ungrouped.subGroups[subGroupName] || []))
    }
    return allFields
  })

  // 欄位組件映射
  const fieldComponents = {
    text: TextField,
    textarea: TextareaField,
    number: NumberField,
    select: SelectField,
    multiselect: MultiselectField,
    cascading_select: CascadingSelectField,
    checkbox: CheckboxField,
    radio: RadioField,
    date: DateField,
    datetime: DatetimeField,
    file: FileField,
    json: JsonField,
    aggregated: AggregatedField,
  }

  // 取得欄位組件
  function getFieldComponent (fieldType) {
    return fieldComponents[fieldType] || TextField
  }

  // 取得欄位選項
  function getFieldOptions (field) {
    const config = field.field_config || {}
    if (config.options && Array.isArray(config.options)) {
      return config.options.map(opt => {
        if (typeof opt === 'string') {
          return { title: opt, value: opt }
        }
        return { title: opt.label || opt.title, value: opt.value }
      })
    }
    return []
  }

  // 取得欄位寬度
  function getFieldCols (field) {
    const config = field.field_config || {}
    return config.cols || 12
  }

  function getFieldMd (field) {
    const config = field.field_config || {}
    return config.md || config.cols || 12
  }

  // 檢查群組是否展開
  function isGroupExpanded (groupName) {
    if (allGroupsExpanded.value) {
      return true
    }
    return expandedGroups.value.has(groupName)
  }

  // 切換群組展開/摺疊
  function toggleGroup (groupName) {
    // 如果當前是全部展開狀態，點擊單一群組時，先切換到個別控制模式
    if (allGroupsExpanded.value) {
      allGroupsExpanded.value = false
      // 將所有群組添加到展開列表，除了當前點擊的群組
      for (const name of Object.keys(groupedFieldsForDesign.value)) {
        if (name !== groupName) {
          expandedGroups.value.add(name)
        }
      }
    // 當前群組不添加到展開列表，所以會被摺疊
    } else {
      // 個別控制模式：切換當前群組的展開狀態
      if (expandedGroups.value.has(groupName)) {
        expandedGroups.value.delete(groupName)
      } else {
        expandedGroups.value.add(groupName)
      }
    }
  }

  // 切換所有群組展開/摺疊
  function toggleAllGroups () {
    allGroupsExpanded.value = !allGroupsExpanded.value
    if (allGroupsExpanded.value) {
      // 展開所有群組
      expandedGroups.value.clear()
      for (const groupName of Object.keys(groupedFieldsForDesign.value)) {
        expandedGroups.value.add(groupName)
      }
    } else {
      // 摺疊所有群組
      expandedGroups.value.clear()
    }
  }

  // 監聽群組變化，自動展開新群組
  watch(() => groupedFieldsForDesign.value, groups => {
    if (allGroupsExpanded.value) {
      for (const groupName of Object.keys(groups)) {
        expandedGroups.value.add(groupName)
      }
    }
  }, { immediate: true })

  // 監聽 fieldData 的變化，自動更新 JSON（但排除 fieldConfigJson 的變化）
  watch([
    () => fieldData.field_key,
    () => fieldData.field_type,
    () => fieldData.field_label,
    () => fieldData.field_label_en,
    () => fieldData.display_order,
    () => fieldData.field_group,
    () => fieldData.sub_group,
    () => fieldData.is_required,
    () => fieldData.is_visible,
    () => fieldData.is_readonly,
    () => fieldData.is_in_template,
    () => fieldData.placeholder,
    () => fieldData.help_text,
    () => fieldData.default_value,
    () => fieldData.max_length,
    () => fieldData.columnSize,
    () => fieldData.field_config,
    () => fieldOptions.value,
    () => cascadingLevels.value,
    () => cascadingLevelCount.value,
  ], () => {
    if (fieldDialog.value && !isUpdatingJsonFromData.value) {
      // 使用 nextTick 確保所有變更都已應用
      nextTick(() => {
        updateJsonFromFieldData()
      })
    }
  }, { deep: true })

  // 監聽 JSON 輸入的變化（用於驗證）
  watch(() => fieldConfigJson.value, newValue => {
    if (!newValue || newValue.trim() === '') {
      jsonError.value = false
      return
    }

    try {
      JSON.parse(newValue)
      jsonError.value = false
    } catch {
      jsonError.value = true
    }
  })

  // 切換懸浮視窗（手動切換時清除自動顯示標記）
  function toggleFloatingWindow () {
    isAutoShowingFloatingWindow.value = false
    floatingWindowVisible.value = !floatingWindowVisible.value
  }

  // 設置滾動監聽器
  function setupScrollObserver () {
    if (!fieldsHeaderRef.value) return

    // 使用 Intersection Observer 來檢測原始功能列是否可見
    scrollObserver = new IntersectionObserver(
      entries => {
        const entry = entries[0]
        // 如果原始功能列不可見（滾出視窗），且不是手動關閉的狀態，則自動顯示懸浮視窗
        if (!entry.isIntersecting && activeTab.value === 'fields') {
          if (!isAutoShowingFloatingWindow.value) {
            floatingWindowVisible.value = true
            isAutoShowingFloatingWindow.value = true
          }
        } else if (entry.isIntersecting && isAutoShowingFloatingWindow.value) {
          // 如果原始功能列重新可見，且是自動顯示的，則自動隱藏懸浮視窗
          floatingWindowVisible.value = false
          isAutoShowingFloatingWindow.value = false
        }
      },
      {
        root: null,
        rootMargin: '0px',
        threshold: 0.1, // 當 10% 的元素可見時觸發
      },
    )

    scrollObserver.observe(fieldsHeaderRef.value)
  }

  // 清理滾動監聽器
  function cleanupScrollObserver () {
    if (scrollObserver) {
      scrollObserver.disconnect()
      scrollObserver = null
    }
  }

  onMounted(() => {
    if (isEditMode.value) {
      loadForm()
    }
    // 初始化時展開所有群組
    allGroupsExpanded.value = true

    // 設置滾動監聽器
    nextTick(() => {
      setupScrollObserver()
    })
  })

  onUnmounted(() => {
    cleanupScrollObserver()
  })

  // 當切換到欄位設定分頁時，重新設置監聽器
  watch(() => activeTab.value, newTab => {
    if (newTab === 'fields') {
      nextTick(() => {
        cleanupScrollObserver()
        setupScrollObserver()
      })
    } else {
      cleanupScrollObserver()
      // 切換到其他分頁時，如果是自動顯示的，則隱藏懸浮視窗
      if (isAutoShowingFloatingWindow.value) {
        floatingWindowVisible.value = false
        isAutoShowingFloatingWindow.value = false
      }
    }
  })
</script>

<style scoped lang="scss">
@import '@/styles/material-system.scss';

.preview-form {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  padding: 16px;
}

// 預覽表單的樣式，與 MaterialApplicationForm.vue 保持一致
.preview-form .form-section {
  margin-bottom: 30px;
  padding: 25px;
  background: #f8f9fa;
  border-radius: 10px;

  h3 {
    color: #667eea;
    margin-bottom: 20px;
    font-size: 1.3em;
    border-bottom: 2px solid #667eea;
    padding-bottom: 10px;
  }
}

// 必填欄位的紅色星號樣式
.preview-form :deep(.v-label__asterisk) {
  color: #f44336 !important;
}

.preview-form :deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

.preview-form :deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

// 子群組容器樣式（用方框包圍）
.subgroup-container {
  margin: 12px 16px; // 左右邊距留白
  border: 2px solid #dee2e6;
  border-radius: 8px;
  background: #ffffff;
  overflow: hidden;

  .subgroup-header {
    background: #f8f9fa;
    padding: 12px 16px;
    border-bottom: 2px solid #dee2e6;
    display: flex;
    align-items: center;
    font-weight: 500;
    color: #495057;

    .subgroup-title {
      font-size: 0.95rem;
    }
  }

  .subgroup-content {
    padding: 16px 0; // 移除左右 padding，因為容器已經有 margin
  }
}

.preview-form :deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

.preview-form :deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

.preview-form :deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}

.border {
  border: 1px solid rgba(0, 0, 0, 0.12);
  border-radius: 4px;
}

.border-bottom {
  border-bottom: 1px solid rgba(0, 0, 0, 0.12);
}

.draggable-field {
  transition: all 0.2s ease;
  cursor: move;
}

.draggable-field:hover {
  background-color: rgba(0, 0, 0, 0.02);
}

.draggable-field.drag-over {
  border-top: 2px solid #1976d2;
  background-color: rgba(25, 118, 210, 0.05);
}

.drag-handle {
  cursor: grab;
}

.drag-handle:active {
  cursor: grabbing;
}

.cursor-move {
  cursor: move;
}

.field-list-未分組欄位 {
  min-height: 50px;
}

.group-card.drag-target {
  border: 2px dashed #1976d2;
  background-color: rgba(25, 118, 210, 0.05);
}

.draggable-field.dragging {
  opacity: 0.5;
  background-color: rgba(0, 0, 0, 0.05);
}

// 群組順序調整對話框的拖曳樣式
.v-list-item.drag-over {
  border-top: 2px solid #1976d2;
  background-color: rgba(25, 118, 210, 0.05);
}

.drop-indicator {
  margin: 4px 0;
}

.drop-indicator .v-divider {
  margin: 0;
}

// 必填欄位的紅色星號
:deep(.v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field-label--floating .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-field .v-field-label .v-label__asterisk) {
  color: #f44336 !important;
}

:deep(.v-input .v-label__asterisk) {
  color: #f44336 !important;
}

// 懸浮視窗：表單欄位功能按鈕
.fields-floating-window {
  position: fixed;
  bottom: 24px;
  right: 24px;
  z-index: 1000;
  min-width: 300px;
  max-width: 90vw;
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.2) !important;
  border-radius: 8px;
  animation: slideInUp 0.3s ease-out;
}

@keyframes slideInUp {
  from {
    transform: translateY(100%);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

// 響應式設計：小螢幕時調整位置和大小
@media (max-width: 960px) {
  .fields-floating-window {
    bottom: 16px;
    right: 16px;
    left: 16px;
    min-width: auto;
    max-width: none;
  }

  .fields-floating-window .v-card-text {
    padding: 12px !important;
  }

  .fields-floating-window .v-btn {
    flex: 1 1 auto;
    min-width: 0;
  }
}
</style>
