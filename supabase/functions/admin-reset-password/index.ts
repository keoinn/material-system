import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

type Body = {
  userId?: string
  newPassword?: string
}

const corsHeaders: HeadersInit = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

function json (data: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(data), {
    ...init,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...corsHeaders,
      ...(init.headers || {}),
    },
  })
}

Deno.serve(async req => {
  try {
    // CORS preflight
    if (req.method === 'OPTIONS') {
      return new Response('ok', { headers: corsHeaders })
    }

    if (req.method !== 'POST') {
      return json({ message: 'Method not allowed' }, { status: 405 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY')
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ message: 'Missing SUPABASE_URL / SERVICE_ROLE_KEY' }, { status: 500 })
    }

    const authHeader = req.headers.get('authorization') || ''
    const jwt = authHeader.replace(/^Bearer\s+/i, '').trim()
    if (!jwt) {
      return json({ message: 'Unauthorized' }, { status: 401 })
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    })

    const { data: authData, error: authError } = await adminClient.auth.getUser(jwt)
    if (authError || !authData?.user) {
      return json({ message: 'Unauthorized' }, { status: 401 })
    }

    const requesterId = authData.user.id

    // 授權檢查：必須是 admin 角色
    const { data: profile, error: profileError } = await adminClient
      .from('user_profiles')
      .select('role,is_active')
      .eq('id', requesterId)
      .maybeSingle()

    if (profileError) {
      return json({ message: profileError.message || 'Failed to load profile' }, { status: 500 })
    }

    if (!profile || profile.is_active === false || profile.role !== 'admin') {
      return json({ message: 'Forbidden' }, { status: 403 })
    }

    const body = (await req.json().catch(() => ({}))) as Body
    const userId = (body.userId || '').trim()
    const newPassword = body.newPassword || ''

    if (!userId) {
      return json({ message: 'userId is required' }, { status: 400 })
    }
    if (typeof newPassword !== 'string' || newPassword.length < 6) {
      return json({ message: 'newPassword must be at least 6 characters' }, { status: 400 })
    }

    const { error: updateError } = await adminClient.auth.admin.updateUserById(userId, {
      password: newPassword,
    })

    if (updateError) {
      return json({ message: updateError.message || 'Failed to update password' }, { status: 400 })
    }

    return json({ success: true })
  } catch (e) {
    return json({ message: e?.message || 'Unexpected error' }, { status: 500 })
  }
})

