-- Create user_privacy_settings table
CREATE TABLE IF NOT EXISTS user_privacy_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Activity Privacy
  online_status_visibility TEXT DEFAULT 'Everyone' CHECK (online_status_visibility IN ('Everyone', 'Friends Only', 'Nobody')),
  last_seen_visibility TEXT DEFAULT 'Everyone' CHECK (last_seen_visibility IN ('Everyone', 'Friends Only', 'Nobody')),
  show_activity_status BOOLEAN DEFAULT true,
  send_read_receipts BOOLEAN DEFAULT true,
  show_typing_indicators BOOLEAN DEFAULT true,
  
  -- Profile Visibility
  profile_photo_visibility TEXT DEFAULT 'Public' CHECK (profile_photo_visibility IN ('Public', 'Friends', 'Private')),
  cover_photo_visibility TEXT DEFAULT 'Public' CHECK (cover_photo_visibility IN ('Public', 'Friends', 'Private')),
  bio_visibility TEXT DEFAULT 'Public' CHECK (bio_visibility IN ('Public', 'Friends', 'Private')),
  dob_visibility TEXT DEFAULT 'Friends' CHECK (dob_visibility IN ('Public', 'Friends', 'Private')),
  phone_visibility TEXT DEFAULT 'Private' CHECK (phone_visibility IN ('Public', 'Friends', 'Private')),
  email_visibility TEXT DEFAULT 'Private' CHECK (email_visibility IN ('Public', 'Friends', 'Private')),
  location_visibility TEXT DEFAULT 'Friends' CHECK (location_visibility IN ('Public', 'Friends', 'Private')),
  
  -- Contact Preferences
  who_can_message TEXT DEFAULT 'Everyone' CHECK (who_can_message IN ('Everyone', 'Friends', 'Nobody')),
  who_can_call TEXT DEFAULT 'Friends' CHECK (who_can_call IN ('Everyone', 'Friends', 'Nobody')),
  who_can_tag TEXT DEFAULT 'Friends' CHECK (who_can_tag IN ('Everyone', 'Friends', 'Nobody')),
  who_can_comment TEXT DEFAULT 'Everyone' CHECK (who_can_comment IN ('Everyone', 'Friends', 'Nobody')),
  who_can_share TEXT DEFAULT 'Everyone' CHECK (who_can_share IN ('Everyone', 'Friends', 'Nobody')),
  who_can_add_to_groups TEXT DEFAULT 'Friends' CHECK (who_can_add_to_groups IN ('Everyone', 'Friends', 'Nobody')),
  
  -- Data Sharing
  share_with_advertisers BOOLEAN DEFAULT false,
  share_with_analytics BOOLEAN DEFAULT true,
  share_location_data BOOLEAN DEFAULT false,
  share_device_info BOOLEAN DEFAULT true,
  share_contacts BOOLEAN DEFAULT false,
  share_usage_patterns BOOLEAN DEFAULT true,
  
  -- Location Privacy
  location_services_enabled BOOLEAN DEFAULT false,
  location_accuracy TEXT DEFAULT 'Approximate' CHECK (location_accuracy IN ('Precise', 'Approximate')),
  location_history_retention TEXT DEFAULT '1 month' CHECK (location_history_retention IN ('Never', '1 month', '3 months', '6 months')),
  allow_location_sharing BOOLEAN DEFAULT false,
  attach_location_to_posts BOOLEAN DEFAULT false,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Create error_tracking_logs table
CREATE TABLE IF NOT EXISTS error_tracking_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  severity TEXT DEFAULT 'error' CHECK (severity IN ('fatal', 'error', 'warning', 'info', 'debug')),
  screen_name TEXT,
  device_info TEXT,
  app_version TEXT,
  status TEXT DEFAULT 'new' CHECK (status IN ('new', 'investigating', 'resolved', 'ignored')),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON user_privacy_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_error_tracking_logs_user_id ON error_tracking_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_error_tracking_logs_severity ON error_tracking_logs(severity);
CREATE INDEX IF NOT EXISTS idx_error_tracking_logs_status ON error_tracking_logs(status);
CREATE INDEX IF NOT EXISTS idx_error_tracking_logs_created_at ON error_tracking_logs(created_at DESC);

-- Enable RLS
ALTER TABLE user_privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_tracking_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_privacy_settings
CREATE POLICY "Users can view own privacy settings"
  ON user_privacy_settings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own privacy settings"
  ON user_privacy_settings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own privacy settings"
  ON user_privacy_settings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for error_tracking_logs
CREATE POLICY "Anyone can insert error logs"
  ON error_tracking_logs FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Admins can view all error logs"
  ON error_tracking_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admins can update error logs"
  ON error_tracking_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'super_admin')
    )
  );
