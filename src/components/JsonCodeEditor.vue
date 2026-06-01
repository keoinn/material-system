<template>
  <Codemirror
    :model-value="modelValue"
    :extensions="extensions"
    :indent-with-tab="true"
    :style="{ height: '100%' }"
    :tab-size="2"
    @update:model-value="$emit('update:modelValue', $event)"
  />
</template>

<script setup>
  import { json } from '@codemirror/lang-json'
  import { syntaxHighlighting, defaultHighlightStyle } from '@codemirror/language'
  import { linter, lintGutter } from '@codemirror/lint'
  import { EditorView } from '@codemirror/view'
  import { basicSetup } from 'codemirror'
  import { Codemirror } from 'vue-codemirror'

  defineProps({
    modelValue: {
      type: String,
      default: '',
    },
  })

  defineEmits(['update:modelValue'])

  const jsonSyntaxLinter = linter(view => {
    const text = view.state.doc.toString()
    if (!text.trim()) {
      return []
    }

    try {
      JSON.parse(text)
      return []
    } catch (error) {
      return [{
        from: 0,
        to: Math.max(text.length, 1),
        severity: 'error',
        message: error.message || 'JSON 格式錯誤',
      }]
    }
  })

  const extensions = [
    basicSetup,
    json(),
    lintGutter(),
    jsonSyntaxLinter,
    syntaxHighlighting(defaultHighlightStyle, { fallback: true }),
    EditorView.lineWrapping,
    EditorView.theme({
      '&': {
        height: '100%',
        backgroundColor: '#fafafa',
      },
      '.cm-scroller': {
        fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace',
        fontSize: '14px',
        lineHeight: '1.5',
      },
      '.cm-content': {
        minHeight: '100%',
        caretColor: '#667eea',
      },
      '.cm-gutters': {
        backgroundColor: '#f0f0f0',
        borderRight: '1px solid #e0e0e0',
      },
      '&.cm-focused': {
        outline: 'none',
      },
      '.cm-activeLine': {
        backgroundColor: 'rgba(102, 126, 234, 0.08)',
      },
    }),
  ]
</script>
