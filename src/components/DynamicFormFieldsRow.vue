<template>
  <v-row>
    <template v-for="field in fields" :key="field.id">
      <template v-if="field.field_type === 'cascading_select' && field.field_config?.levels">
        <template
          v-for="(level, levelIndex) in field.field_config.levels"
          :key="`${field.id}-level-${levelIndex}`"
        >
          <v-col
            v-if="ctx.shouldShowField(field) && (level.is_visible !== false)"
            :cols="ctx.getLevelCols(level)"
            :md="ctx.getLevelMd(level)"
          >
            <CascadingSelectLevel
              :field="ctx.getFieldWithReadonly(field)"
              :level="level"
              :level-index="levelIndex"
              :loading="ctx.fieldLoading[field.field_key] || false"
              :selected-values="ctx.formValues[field.field_key] || []"
              @update:model-value="ctx.handleCascadingLevelUpdate(field.field_key, levelIndex, $event)"
            />
          </v-col>
        </template>
      </template>
      <v-col
        v-else-if="ctx.shouldShowField(field)"
        :cols="ctx.getFieldCols(field)"
        :md="ctx.getFieldMd(field)"
      >
        <component
          :is="ctx.getFieldComponent(field.field_type)"
          :field="ctx.getFieldWithReadonly(field)"
          :form-values="ctx.formValues"
          :loading="ctx.fieldLoading[field.field_key] || false"
          :model-value="ctx.formValues[field.field_key]"
          :options="ctx.getFieldOptions(field)"
          @update:model-value="ctx.handleFieldUpdate(field.field_key, $event)"
        />
      </v-col>
    </template>
  </v-row>
</template>

<script setup>
  import { inject } from 'vue'
  import CascadingSelectLevel from './form-fields/CascadingSelectLevel.vue'

  defineProps({
    fields: {
      type: Array,
      required: true,
    },
  })

  const ctx = inject('dynamicFormContext')
  if (!ctx) {
    throw new Error('DynamicFormFieldsRow must be used inside DynamicFormRenderer')
  }
</script>
