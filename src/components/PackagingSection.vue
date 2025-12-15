<template>
  <div class="packaging-section">
    <h4>{{ title }}</h4>
    <v-row>
      <v-col cols="12">
        <v-chip-group
          v-model="selectedOptions"
          multiple
          selected-class="text-primary"
        >
          <v-chip
            v-for="option in options"
            :key="option"
            filter
            :value="option"
            variant="outlined"
          >
            {{ option }}
          </v-chip>
        </v-chip-group>
      </v-col>
      <v-col cols="12">
        <v-textarea
          v-model="localValue.description"
          auto-grow
          :placeholder="placeholder"
          rows="2"
          variant="outlined"
        />
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
  import { computed, watch } from 'vue'

  const props = defineProps({
    modelValue: {
      type: Object,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    options: {
      type: Array,
      required: true,
    },
    placeholder: {
      type: String,
      default: '',
    },
  })

  const emit = defineEmits(['update:modelValue'])

  const localValue = computed({
    get: () => props.modelValue,
    set: value => emit('update:modelValue', value),
  })

  const selectedOptions = computed({
    get: () => localValue.value.options || [],
    set: value => {
      localValue.value = {
        ...localValue.value,
        options: value,
      }
    },
  })
</script>

<style scoped lang="scss">
.packaging-section {
  background: #fff;
  border: 2px solid #dee2e6;
  border-radius: 10px;
  padding: 20px;
  margin-bottom: 20px;

  h4 {
    color: #495057;
    margin-bottom: 15px;
    font-size: 1.1em;
  }
}
</style>
