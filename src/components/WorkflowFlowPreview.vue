<template>
  <v-card
    class="workflow-flow-preview mb-4"
    variant="outlined"
  >
    <v-card-title
      class="workflow-flow-preview__header d-flex align-center py-3 px-4"
      @click="toggleExpanded"
    >
      <v-icon class="mr-2" size="small">mdi-graph-outline</v-icon>
      <span class="text-subtitle-2">流程概覽</span>
      <v-spacer />
      <span
        v-if="!loading && hasSteps"
        class="text-caption text-medium-emphasis mr-2"
      >
        {{ steps.length }} 個步驟
      </span>
      <v-btn
        v-if="!loading && hasSteps"
        class="mr-1"
        size="small"
        variant="text"
        @click.stop="viewerDialog = true"
      >
        <v-icon start size="small">mdi-fit-to-screen-outline</v-icon>
        視窗瀏覽
      </v-btn>
      <v-btn
        icon
        size="x-small"
        variant="text"
        @click.stop="toggleExpanded"
      >
        <v-icon>{{ expanded ? 'mdi-chevron-up' : 'mdi-chevron-down' }}</v-icon>
      </v-btn>
    </v-card-title>

    <v-expand-transition>
      <div v-show="expanded">
        <v-divider />
        <v-card-text class="workflow-flow-preview__body pa-4">
          <WorkflowFlowDiagram
            :loading="loading"
            :statuses="statuses"
            :steps="steps"
            :workflow="workflow"
          />
        </v-card-text>
      </div>
    </v-expand-transition>

    <v-dialog
      v-model="viewerDialog"
      max-width="960"
      scrollable
    >
      <v-card>
        <v-card-title class="d-flex align-center">
          <v-icon class="mr-2">mdi-graph-outline</v-icon>
          流程概覽
          <span
            v-if="workflow?.workflow_name"
            class="text-body-2 text-medium-emphasis ml-2"
          >
            — {{ workflow.workflow_name }}
          </span>
          <v-spacer />
          <v-btn
            icon
            size="small"
            variant="text"
            @click="viewerDialog = false"
          >
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-card-title>
        <v-divider />
        <v-card-text class="pa-6">
          <WorkflowFlowDiagram
            large
            :loading="loading"
            :statuses="statuses"
            :steps="steps"
            :workflow="workflow"
          />
        </v-card-text>
        <v-divider />
        <v-card-actions>
          <v-spacer />
          <v-btn @click="viewerDialog = false">關閉</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-card>
</template>

<script setup>
  import { computed, ref } from 'vue'
  import WorkflowFlowDiagram from '@/components/WorkflowFlowDiagram.vue'

  const STORAGE_KEY = 'material-system.workflow-flow-preview.expanded'

  const props = defineProps({
    steps: {
      type: Array,
      default: () => [],
    },
    workflow: {
      type: Object,
      default: null,
    },
    statuses: {
      type: Array,
      default: () => [],
    },
    loading: {
      type: Boolean,
      default: false,
    },
  })

  const expanded = ref(readExpandedPreference())
  const viewerDialog = ref(false)

  const hasSteps = computed(() => props.steps.length > 0)

  function readExpandedPreference () {
    try {
      const stored = localStorage.getItem(STORAGE_KEY)
      if (stored === 'false') {
        return false
      }
    } catch {
      // ignore
    }
    return true
  }

  function toggleExpanded () {
    expanded.value = !expanded.value
    try {
      localStorage.setItem(STORAGE_KEY, String(expanded.value))
    } catch {
      // ignore
    }
  }
</script>

<style scoped>
.workflow-flow-preview__header {
  cursor: pointer;
  user-select: none;
}
</style>
