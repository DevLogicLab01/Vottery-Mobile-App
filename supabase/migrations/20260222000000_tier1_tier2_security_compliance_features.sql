-- =====================================================
-- TIER 1 & TIER 2 CRITICAL SECURITY FEATURES
-- IP Geolocation, Security Monitoring, ML Threat Detection,
-- Compliance Automation, Subscription Management
-- =====================================================

-- =====================================================
-- 0. CORE USER PROFILES TABLE (PREREQUISITE)
-- =====================================================

-- Create user_profiles table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'creator', 'admin', 'super_admin', 'moderator', 'security_admin', 'devops_admin')),
  bio TEXT,
  location TEXT,
  website TEXT,
  vp_balance INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  experience_points INTEGER DEFAULT 0,
  account_locked BOOLEAN DEFAULT false,
  email_verified BOOLEAN DEFAULT false,
  phone_verified BOOLEAN DEFAULT false,
  kyc_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_username ON public.user_profiles(username);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_locked ON public.user_profiles(account_locked);

-- Enable RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles" ON public.user_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'security_admin')
    )
  );

-- =====================================================
-- 1. IP GEOLOCATION & COUNTRY ACCESS CONTROL
-- =====================================================

-- Create Country Restrictions Table
CREATE TABLE IF NOT EXISTS public.country_restrictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code VARCHAR(2) UNIQUE NOT NULL,
  country_name VARCHAR(100) NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  fee_zone INTEGER DEFAULT 1 CHECK (fee_zone >= 1 AND fee_zone <= 8),
  compliance_level TEXT DEFAULT 'moderate' CHECK (compliance_level IN ('strict', 'moderate', 'relaxed')),
  blocked_reason TEXT,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for country_restrictions
CREATE INDEX IF NOT EXISTS idx_country_restrictions_enabled ON public.country_restrictions(is_enabled);
CREATE INDEX IF NOT EXISTS idx_country_restrictions_zone ON public.country_restrictions(fee_zone);
CREATE INDEX IF NOT EXISTS idx_country_restrictions_code ON public.country_restrictions(country_code);

-- Access Logs Table
CREATE TABLE IF NOT EXISTS public.access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  country_code VARCHAR(2),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  ip_address INET,
  access_granted BOOLEAN DEFAULT true,
  blocked_reason TEXT,
  user_agent TEXT,
  device_type TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for access_logs
CREATE INDEX IF NOT EXISTS idx_access_logs_user ON public.access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_country ON public.access_logs(country_code);
CREATE INDEX IF NOT EXISTS idx_access_logs_timestamp ON public.access_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_access_logs_granted ON public.access_logs(access_granted);

-- Populate all 195 countries with default enabled status
INSERT INTO public.country_restrictions (country_code, country_name, is_enabled, fee_zone, compliance_level)
VALUES
  -- Zone 1: North America
  ('US', 'United States', true, 1, 'strict'),
  ('CA', 'Canada', true, 1, 'strict'),
  ('MX', 'Mexico', true, 1, 'moderate'),
  
  -- Zone 2: Europe
  ('GB', 'United Kingdom', true, 2, 'strict'),
  ('DE', 'Germany', true, 2, 'strict'),
  ('FR', 'France', true, 2, 'strict'),
  ('IT', 'Italy', true, 2, 'strict'),
  ('ES', 'Spain', true, 2, 'strict'),
  ('NL', 'Netherlands', true, 2, 'strict'),
  ('BE', 'Belgium', true, 2, 'strict'),
  ('AT', 'Austria', true, 2, 'strict'),
  ('CH', 'Switzerland', true, 2, 'strict'),
  ('SE', 'Sweden', true, 2, 'strict'),
  ('NO', 'Norway', true, 2, 'strict'),
  ('DK', 'Denmark', true, 2, 'strict'),
  ('FI', 'Finland', true, 2, 'strict'),
  ('PL', 'Poland', true, 2, 'moderate'),
  ('IE', 'Ireland', true, 2, 'strict'),
  ('PT', 'Portugal', true, 2, 'moderate'),
  ('GR', 'Greece', true, 2, 'moderate'),
  ('CZ', 'Czech Republic', true, 2, 'moderate'),
  ('RO', 'Romania', true, 2, 'moderate'),
  ('HU', 'Hungary', true, 2, 'moderate'),
  
  -- Zone 3: Asia-Pacific
  ('JP', 'Japan', true, 3, 'strict'),
  ('AU', 'Australia', true, 3, 'strict'),
  ('NZ', 'New Zealand', true, 3, 'strict'),
  ('SG', 'Singapore', true, 3, 'strict'),
  ('KR', 'South Korea', true, 3, 'strict'),
  ('HK', 'Hong Kong', true, 3, 'moderate'),
  ('TW', 'Taiwan', true, 3, 'moderate'),
  ('IN', 'India', true, 3, 'moderate'),
  ('MY', 'Malaysia', true, 3, 'moderate'),
  ('TH', 'Thailand', true, 3, 'moderate'),
  ('PH', 'Philippines', true, 3, 'moderate'),
  ('ID', 'Indonesia', true, 3, 'moderate'),
  ('VN', 'Vietnam', true, 3, 'moderate'),
  
  -- Zone 4: Middle East
  ('AE', 'United Arab Emirates', true, 4, 'moderate'),
  ('SA', 'Saudi Arabia', true, 4, 'moderate'),
  ('IL', 'Israel', true, 4, 'moderate'),
  ('QA', 'Qatar', true, 4, 'moderate'),
  ('KW', 'Kuwait', true, 4, 'moderate'),
  ('BH', 'Bahrain', true, 4, 'moderate'),
  ('OM', 'Oman', true, 4, 'moderate'),
  ('JO', 'Jordan', true, 4, 'moderate'),
  ('LB', 'Lebanon', true, 4, 'moderate'),
  
  -- Zone 5: Latin America
  ('BR', 'Brazil', true, 5, 'moderate'),
  ('AR', 'Argentina', true, 5, 'moderate'),
  ('CL', 'Chile', true, 5, 'moderate'),
  ('CO', 'Colombia', true, 5, 'moderate'),
  ('PE', 'Peru', true, 5, 'moderate'),
  ('VE', 'Venezuela', true, 5, 'moderate'),
  ('EC', 'Ecuador', true, 5, 'moderate'),
  ('UY', 'Uruguay', true, 5, 'moderate'),
  ('PY', 'Paraguay', true, 5, 'moderate'),
  ('BO', 'Bolivia', true, 5, 'moderate'),
  
  -- Zone 6: Africa
  ('ZA', 'South Africa', true, 6, 'moderate'),
  ('NG', 'Nigeria', true, 6, 'moderate'),
  ('KE', 'Kenya', true, 6, 'moderate'),
  ('EG', 'Egypt', true, 6, 'moderate'),
  ('MA', 'Morocco', true, 6, 'moderate'),
  ('GH', 'Ghana', true, 6, 'moderate'),
  ('TZ', 'Tanzania', true, 6, 'moderate'),
  ('UG', 'Uganda', true, 6, 'moderate'),
  ('ET', 'Ethiopia', true, 6, 'moderate'),
  ('DZ', 'Algeria', true, 6, 'moderate'),
  
  -- Zone 7: Eastern Europe & Central Asia
  ('RU', 'Russia', true, 7, 'moderate'),
  ('UA', 'Ukraine', true, 7, 'moderate'),
  ('TR', 'Turkey', true, 7, 'moderate'),
  ('KZ', 'Kazakhstan', true, 7, 'moderate'),
  ('UZ', 'Uzbekistan', true, 7, 'moderate'),
  ('BY', 'Belarus', true, 7, 'moderate'),
  ('AZ', 'Azerbaijan', true, 7, 'moderate'),
  ('GE', 'Georgia', true, 7, 'moderate'),
  ('AM', 'Armenia', true, 7, 'moderate'),
  
  -- Zone 8: Restricted Countries (Default DISABLED)
  ('KP', 'North Korea', false, 8, 'strict'),
  ('IR', 'Iran', false, 8, 'strict'),
  ('SY', 'Syria', false, 8, 'strict'),
  ('CU', 'Cuba', false, 8, 'strict'),
  
  -- Additional Countries (Enabled by default)
  ('CN', 'China', true, 7, 'moderate'),
  ('BD', 'Bangladesh', true, 3, 'moderate'),
  ('PK', 'Pakistan', true, 4, 'moderate'),
  ('MM', 'Myanmar', true, 3, 'moderate'),
  ('LK', 'Sri Lanka', true, 3, 'moderate'),
  ('NP', 'Nepal', true, 3, 'moderate'),
  ('AF', 'Afghanistan', true, 4, 'moderate'),
  ('IQ', 'Iraq', true, 4, 'moderate'),
  ('YE', 'Yemen', true, 4, 'moderate'),
  ('SD', 'Sudan', true, 6, 'moderate'),
  ('LY', 'Libya', true, 6, 'moderate'),
  ('TN', 'Tunisia', true, 6, 'moderate'),
  ('ZW', 'Zimbabwe', true, 6, 'moderate'),
  ('ZM', 'Zambia', true, 6, 'moderate'),
  ('MW', 'Malawi', true, 6, 'moderate'),
  ('MZ', 'Mozambique', true, 6, 'moderate'),
  ('AO', 'Angola', true, 6, 'moderate'),
  ('CM', 'Cameroon', true, 6, 'moderate'),
  ('CI', 'Ivory Coast', true, 6, 'moderate'),
  ('SN', 'Senegal', true, 6, 'moderate'),
  ('BF', 'Burkina Faso', true, 6, 'moderate'),
  ('ML', 'Mali', true, 6, 'moderate'),
  ('NE', 'Niger', true, 6, 'moderate'),
  ('TD', 'Chad', true, 6, 'moderate'),
  ('SO', 'Somalia', true, 6, 'moderate'),
  ('RW', 'Rwanda', true, 6, 'moderate'),
  ('BI', 'Burundi', true, 6, 'moderate'),
  ('BJ', 'Benin', true, 6, 'moderate'),
  ('TG', 'Togo', true, 6, 'moderate'),
  ('SL', 'Sierra Leone', true, 6, 'moderate'),
  ('LR', 'Liberia', true, 6, 'moderate'),
  ('GN', 'Guinea', true, 6, 'moderate'),
  ('GM', 'Gambia', true, 6, 'moderate'),
  ('GW', 'Guinea-Bissau', true, 6, 'moderate'),
  ('MR', 'Mauritania', true, 6, 'moderate'),
  ('BW', 'Botswana', true, 6, 'moderate'),
  ('NA', 'Namibia', true, 6, 'moderate'),
  ('LS', 'Lesotho', true, 6, 'moderate'),
  ('SZ', 'Eswatini', true, 6, 'moderate'),
  ('MG', 'Madagascar', true, 6, 'moderate'),
  ('MU', 'Mauritius', true, 6, 'moderate'),
  ('SC', 'Seychelles', true, 6, 'moderate'),
  ('KM', 'Comoros', true, 6, 'moderate'),
  ('DJ', 'Djibouti', true, 6, 'moderate'),
  ('ER', 'Eritrea', true, 6, 'moderate'),
  ('SS', 'South Sudan', true, 6, 'moderate'),
  ('CF', 'Central African Republic', true, 6, 'moderate'),
  ('CG', 'Republic of the Congo', true, 6, 'moderate'),
  ('CD', 'Democratic Republic of the Congo', true, 6, 'moderate'),
  ('GA', 'Gabon', true, 6, 'moderate'),
  ('GQ', 'Equatorial Guinea', true, 6, 'moderate'),
  ('ST', 'Sao Tome and Principe', true, 6, 'moderate'),
  ('CV', 'Cape Verde', true, 6, 'moderate'),
  ('KH', 'Cambodia', true, 3, 'moderate'),
  ('LA', 'Laos', true, 3, 'moderate'),
  ('MN', 'Mongolia', true, 3, 'moderate'),
  ('BT', 'Bhutan', true, 3, 'moderate'),
  ('MV', 'Maldives', true, 3, 'moderate'),
  ('BN', 'Brunei', true, 3, 'moderate'),
  ('TL', 'Timor-Leste', true, 3, 'moderate'),
  ('PG', 'Papua New Guinea', true, 3, 'moderate'),
  ('FJ', 'Fiji', true, 3, 'moderate'),
  ('SB', 'Solomon Islands', true, 3, 'moderate'),
  ('VU', 'Vanuatu', true, 3, 'moderate'),
  ('WS', 'Samoa', true, 3, 'moderate'),
  ('TO', 'Tonga', true, 3, 'moderate'),
  ('KI', 'Kiribati', true, 3, 'moderate'),
  ('TV', 'Tuvalu', true, 3, 'moderate'),
  ('NR', 'Nauru', true, 3, 'moderate'),
  ('PW', 'Palau', true, 3, 'moderate'),
  ('FM', 'Micronesia', true, 3, 'moderate'),
  ('MH', 'Marshall Islands', true, 3, 'moderate'),
  ('GT', 'Guatemala', true, 5, 'moderate'),
  ('HN', 'Honduras', true, 5, 'moderate'),
  ('SV', 'El Salvador', true, 5, 'moderate'),
  ('NI', 'Nicaragua', true, 5, 'moderate'),
  ('CR', 'Costa Rica', true, 5, 'moderate'),
  ('PA', 'Panama', true, 5, 'moderate'),
  ('BZ', 'Belize', true, 5, 'moderate'),
  ('JM', 'Jamaica', true, 5, 'moderate'),
  ('TT', 'Trinidad and Tobago', true, 5, 'moderate'),
  ('BB', 'Barbados', true, 5, 'moderate'),
  ('BS', 'Bahamas', true, 5, 'moderate'),
  ('GD', 'Grenada', true, 5, 'moderate'),
  ('LC', 'Saint Lucia', true, 5, 'moderate'),
  ('VC', 'Saint Vincent and the Grenadines', true, 5, 'moderate'),
  ('AG', 'Antigua and Barbuda', true, 5, 'moderate'),
  ('DM', 'Dominica', true, 5, 'moderate'),
  ('KN', 'Saint Kitts and Nevis', true, 5, 'moderate'),
  ('DO', 'Dominican Republic', true, 5, 'moderate'),
  ('HT', 'Haiti', true, 5, 'moderate'),
  ('SR', 'Suriname', true, 5, 'moderate'),
  ('GY', 'Guyana', true, 5, 'moderate'),
  ('BG', 'Bulgaria', true, 2, 'moderate'),
  ('HR', 'Croatia', true, 2, 'moderate'),
  ('SI', 'Slovenia', true, 2, 'moderate'),
  ('SK', 'Slovakia', true, 2, 'moderate'),
  ('EE', 'Estonia', true, 2, 'moderate'),
  ('LV', 'Latvia', true, 2, 'moderate'),
  ('LT', 'Lithuania', true, 2, 'moderate'),
  ('CY', 'Cyprus', true, 2, 'moderate'),
  ('MT', 'Malta', true, 2, 'moderate'),
  ('LU', 'Luxembourg', true, 2, 'strict'),
  ('IS', 'Iceland', true, 2, 'strict'),
  ('LI', 'Liechtenstein', true, 2, 'strict'),
  ('MC', 'Monaco', true, 2, 'strict'),
  ('SM', 'San Marino', true, 2, 'moderate'),
  ('VA', 'Vatican City', true, 2, 'moderate'),
  ('AD', 'Andorra', true, 2, 'moderate'),
  ('MD', 'Moldova', true, 7, 'moderate'),
  ('BA', 'Bosnia and Herzegovina', true, 2, 'moderate'),
  ('RS', 'Serbia', true, 2, 'moderate'),
  ('ME', 'Montenegro', true, 2, 'moderate'),
  ('MK', 'North Macedonia', true, 2, 'moderate'),
  ('AL', 'Albania', true, 2, 'moderate'),
  ('XK', 'Kosovo', true, 2, 'moderate'),
  ('TM', 'Turkmenistan', true, 7, 'moderate'),
  ('TJ', 'Tajikistan', true, 7, 'moderate'),
  ('KG', 'Kyrgyzstan', true, 7, 'moderate')
ON CONFLICT (country_code) DO NOTHING;

-- =====================================================
-- 2. SECURITY MONITORING TABLES
-- =====================================================

-- Security Incidents Table (Enhanced)
CREATE TABLE IF NOT EXISTS public.security_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type TEXT NOT NULL, -- 'cors_violation', 'rate_limit_breach', 'webhook_replay', 'sql_injection'
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  source_ip TEXT,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  endpoint TEXT,
  request_method TEXT,
  request_payload JSONB,
  response_status INTEGER,
  action_taken TEXT, -- 'blocked', 'rate_limited', 'logged', 'alerted'
  detection_method TEXT, -- 'signature', 'anomaly', 'ml_model'
  threat_score DECIMAL(5,2) CHECK (threat_score >= 0 AND threat_score <= 100),
  metadata JSONB DEFAULT '{}'::jsonb,
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for security_incidents
CREATE INDEX IF NOT EXISTS idx_security_incidents_type ON public.security_incidents(incident_type);
CREATE INDEX IF NOT EXISTS idx_security_incidents_severity ON public.security_incidents(severity);
CREATE INDEX IF NOT EXISTS idx_security_incidents_user ON public.security_incidents(user_id);
CREATE INDEX IF NOT EXISTS idx_security_incidents_timestamp ON public.security_incidents(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_incidents_acknowledged ON public.security_incidents(acknowledged);

-- Rate Limit Violations Table
CREATE TABLE IF NOT EXISTS public.rate_limit_violations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  endpoint TEXT NOT NULL,
  request_count INTEGER NOT NULL,
  limit_threshold INTEGER NOT NULL,
  window_duration INTERVAL NOT NULL,
  source_ip TEXT,
  user_agent TEXT,
  action_taken TEXT, -- 'throttled', 'blocked', 'warned'
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for rate_limit_violations
CREATE INDEX IF NOT EXISTS idx_rate_limit_violations_user ON public.rate_limit_violations(user_id);
CREATE INDEX IF NOT EXISTS idx_rate_limit_violations_endpoint ON public.rate_limit_violations(endpoint);
CREATE INDEX IF NOT EXISTS idx_rate_limit_violations_timestamp ON public.rate_limit_violations(created_at DESC);

-- =====================================================
-- 3. ML THREAT DETECTION TABLES
-- =====================================================

-- ML Threat Detections Table
CREATE TABLE IF NOT EXISTS public.ml_threat_detections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  threat_type TEXT NOT NULL, -- 'behavioral_anomaly', 'account_takeover', 'bot_activity', 'fraud_pattern'
  threat_description TEXT,
  confidence_score DECIMAL(5, 4) CHECK (confidence_score >= 0 AND confidence_score <= 1),
  ai_provider TEXT, -- 'openai', 'anthropic', 'perplexity'
  ai_reasoning TEXT,
  recommended_action TEXT,
  status TEXT DEFAULT 'detected' CHECK (status IN ('detected', 'investigating', 'resolved', 'false_positive')),
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  resolution_notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for ml_threat_detections
CREATE INDEX IF NOT EXISTS idx_ml_threats_confidence ON public.ml_threat_detections(confidence_score DESC);
CREATE INDEX IF NOT EXISTS idx_ml_threats_user ON public.ml_threat_detections(user_id);
CREATE INDEX IF NOT EXISTS idx_ml_threats_status ON public.ml_threat_detections(status);
CREATE INDEX IF NOT EXISTS idx_ml_threats_detected_at ON public.ml_threat_detections(detected_at DESC);

-- User Activity Patterns Table (for ML analysis)
CREATE TABLE IF NOT EXISTS public.user_activity_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  activity_date DATE NOT NULL,
  login_times JSONB DEFAULT '[]'::jsonb, -- Array of login timestamps
  voting_frequency INTEGER DEFAULT 0,
  transaction_amounts JSONB DEFAULT '[]'::jsonb, -- Array of transaction amounts
  devices_used JSONB DEFAULT '[]'::jsonb, -- Array of device fingerprints
  ip_addresses JSONB DEFAULT '[]'::jsonb, -- Array of IP addresses
  locations JSONB DEFAULT '[]'::jsonb, -- Array of geolocation data
  anomaly_score DECIMAL(5, 4) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, activity_date)
);

-- Create indexes for user_activity_patterns
CREATE INDEX IF NOT EXISTS idx_activity_patterns_user ON public.user_activity_patterns(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_patterns_date ON public.user_activity_patterns(activity_date DESC);
CREATE INDEX IF NOT EXISTS idx_activity_patterns_anomaly ON public.user_activity_patterns(anomaly_score DESC);

-- =====================================================
-- 4. COMPLIANCE AUTOMATION TABLES
-- =====================================================

-- GDPR Requests Table
CREATE TABLE IF NOT EXISTS public.gdpr_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  request_type TEXT NOT NULL CHECK (request_type IN ('access', 'erasure', 'portability', 'rectification')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  processed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  data_export_url TEXT,
  rejection_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for gdpr_requests
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_user ON public.gdpr_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_status ON public.gdpr_requests(status);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_type ON public.gdpr_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_requested_at ON public.gdpr_requests(requested_at DESC);

-- PCI Compliance Checklist Table
CREATE TABLE IF NOT EXISTS public.pci_compliance_checklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  control TEXT UNIQUE NOT NULL, -- 'encrypted_transactions', 'secure_storage', 'access_controls', 'audit_logs'
  compliant BOOLEAN DEFAULT false,
  last_audit_date TIMESTAMPTZ,
  audited_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  audit_notes TEXT,
  next_audit_due TIMESTAMPTZ,
  evidence_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default PCI-DSS controls
INSERT INTO public.pci_compliance_checklist (control, compliant, next_audit_due)
VALUES
  ('encrypted_transactions', true, NOW() + INTERVAL '90 days'),
  ('secure_storage', true, NOW() + INTERVAL '90 days'),
  ('access_controls', true, NOW() + INTERVAL '90 days'),
  ('audit_logs', true, NOW() + INTERVAL '90 days'),
  ('network_security', true, NOW() + INTERVAL '90 days'),
  ('vulnerability_management', true, NOW() + INTERVAL '90 days')
ON CONFLICT (control) DO NOTHING;

-- Compliance Reports Table
CREATE TABLE IF NOT EXISTS public.compliance_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL CHECK (report_type IN ('gdpr', 'pci_dss', 'sox', 'hipaa', 'quarterly', 'annual')),
  reporting_period_start DATE NOT NULL,
  reporting_period_end DATE NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  generated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  report_url TEXT,
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Create indexes for compliance_reports
CREATE INDEX IF NOT EXISTS idx_compliance_reports_type ON public.compliance_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_status ON public.compliance_reports(status);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_generated_at ON public.compliance_reports(generated_at DESC);

-- Compliance Calendar Table
CREATE TABLE IF NOT EXISTS public.compliance_calendar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('audit', 'report_due', 'certification', 'training')),
  due_date DATE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')),
  assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  notes TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for compliance_calendar
CREATE INDEX IF NOT EXISTS idx_compliance_calendar_due_date ON public.compliance_calendar(due_date);
CREATE INDEX IF NOT EXISTS idx_compliance_calendar_status ON public.compliance_calendar(status);
CREATE INDEX IF NOT EXISTS idx_compliance_calendar_assigned_to ON public.compliance_calendar(assigned_to);

-- =====================================================
-- 5. SUBSCRIPTION MANAGEMENT TABLES
-- =====================================================

-- Subscription Tiers Table
CREATE TABLE IF NOT EXISTS public.subscription_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name TEXT UNIQUE NOT NULL, -- 'Free', 'Premium', 'Pro', 'Enterprise'
  tier_level INTEGER UNIQUE NOT NULL,
  monthly_price DECIMAL(10, 2) NOT NULL,
  annual_price DECIMAL(10, 2),
  vp_multiplier DECIMAL(3, 2) DEFAULT 1.00,
  features JSONB DEFAULT '[]'::jsonb,
  max_elections INTEGER,
  max_votes_per_day INTEGER,
  priority_support BOOLEAN DEFAULT false,
  analytics_access BOOLEAN DEFAULT false,
  api_access BOOLEAN DEFAULT false,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default subscription tiers
INSERT INTO public.subscription_tiers (tier_name, tier_level, monthly_price, annual_price, vp_multiplier, features, max_elections, max_votes_per_day, priority_support, analytics_access, api_access)
VALUES
  ('Free', 1, 0.00, 0.00, 1.00, '["Basic voting", "5 elections/month", "Community support"]'::jsonb, 5, 50, false, false, false),
  ('Premium', 2, 9.99, 99.99, 1.50, '["Unlimited voting", "50 elections/month", "Email support", "1.5x VP multiplier"]'::jsonb, 50, 500, false, true, false),
  ('Pro', 3, 29.99, 299.99, 2.00, '["Unlimited voting", "Unlimited elections", "Priority support", "2x VP multiplier", "Advanced analytics"]'::jsonb, -1, -1, true, true, true),
  ('Enterprise', 4, 99.99, 999.99, 3.00, '["Everything in Pro", "3x VP multiplier", "Dedicated account manager", "Custom integrations", "SLA guarantee"]'::jsonb, -1, -1, true, true, true)
ON CONFLICT (tier_name) DO NOTHING;

-- User Subscriptions Table
CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tier_id UUID REFERENCES public.subscription_tiers(id) ON DELETE RESTRICT,
  stripe_subscription_id TEXT UNIQUE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'canceled', 'past_due', 'trialing', 'paused')),
  billing_cycle TEXT DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'annual')),
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at_period_end BOOLEAN DEFAULT false,
  canceled_at TIMESTAMPTZ,
  trial_start TIMESTAMPTZ,
  trial_end TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create indexes for user_subscriptions
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_tier ON public.user_subscriptions(tier_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_stripe ON public.user_subscriptions(stripe_subscription_id);

-- Subscription Analytics Table
CREATE TABLE IF NOT EXISTS public.subscription_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  tier_id UUID REFERENCES public.subscription_tiers(id) ON DELETE CASCADE,
  new_subscriptions INTEGER DEFAULT 0,
  canceled_subscriptions INTEGER DEFAULT 0,
  active_subscriptions INTEGER DEFAULT 0,
  mrr DECIMAL(12, 2) DEFAULT 0, -- Monthly Recurring Revenue
  churn_rate DECIMAL(5, 4) DEFAULT 0,
  ltv DECIMAL(12, 2) DEFAULT 0, -- Lifetime Value
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(date, tier_id)
);

-- Create indexes for subscription_analytics
CREATE INDEX IF NOT EXISTS idx_subscription_analytics_date ON public.subscription_analytics(date DESC);
CREATE INDEX IF NOT EXISTS idx_subscription_analytics_tier ON public.subscription_analytics(tier_id);

-- Billing History Table
CREATE TABLE IF NOT EXISTS public.billing_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
  stripe_invoice_id TEXT UNIQUE,
  amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  status TEXT NOT NULL CHECK (status IN ('paid', 'pending', 'failed', 'refunded')),
  invoice_url TEXT,
  billing_date TIMESTAMPTZ NOT NULL,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for billing_history
CREATE INDEX IF NOT EXISTS idx_billing_history_user ON public.billing_history(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_history_subscription ON public.billing_history(subscription_id);
CREATE INDEX IF NOT EXISTS idx_billing_history_status ON public.billing_history(status);
CREATE INDEX IF NOT EXISTS idx_billing_history_billing_date ON public.billing_history(billing_date DESC);

-- =====================================================
-- 6. GOOGLE ANALYTICS INTEGRATION TABLES
-- =====================================================

-- GA4 Events Table
CREATE TABLE IF NOT EXISTS public.ga4_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_name TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  session_id TEXT,
  event_category TEXT,
  event_parameters JSONB DEFAULT '{}'::jsonb,
  user_properties JSONB DEFAULT '{}'::jsonb,
  sent_to_ga BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for ga4_events
CREATE INDEX IF NOT EXISTS idx_ga4_events_name ON public.ga4_events(event_name);
CREATE INDEX IF NOT EXISTS idx_ga4_events_user ON public.ga4_events(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_events_session ON public.ga4_events(session_id);
CREATE INDEX IF NOT EXISTS idx_ga4_events_created_at ON public.ga4_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ga4_events_sent ON public.ga4_events(sent_to_ga);

-- GA4 Conversion Funnels Table
CREATE TABLE IF NOT EXISTS public.ga4_conversion_funnels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  funnel_name TEXT NOT NULL,
  funnel_type TEXT NOT NULL, -- 'creator_earnings', 'kyc_completion', 'settlement_success'
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  step_name TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  time_to_complete INTERVAL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for ga4_conversion_funnels
CREATE INDEX IF NOT EXISTS idx_ga4_funnels_user ON public.ga4_conversion_funnels(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_funnels_type ON public.ga4_conversion_funnels(funnel_type);
CREATE INDEX IF NOT EXISTS idx_ga4_funnels_completed ON public.ga4_conversion_funnels(completed);
CREATE INDEX IF NOT EXISTS idx_ga4_funnels_created_at ON public.ga4_conversion_funnels(created_at DESC);

-- GA4 Security Events Table
CREATE TABLE IF NOT EXISTS public.ga4_security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL, -- 'suspicious_auth', 'failed_payment', 'vote_manipulation', 'policy_violation'
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  event_details JSONB DEFAULT '{}'::jsonb,
  sent_to_ga BOOLEAN DEFAULT false,
  alert_triggered BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for ga4_security_events
CREATE INDEX IF NOT EXISTS idx_ga4_security_events_type ON public.ga4_security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_ga4_security_events_user ON public.ga4_security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_security_events_severity ON public.ga4_security_events(severity);
CREATE INDEX IF NOT EXISTS idx_ga4_security_events_created_at ON public.ga4_security_events(created_at DESC);

-- =====================================================
-- 7. PRODUCTION MONITORING TABLES
-- =====================================================

-- System Health Metrics Table
CREATE TABLE IF NOT EXISTS public.system_health_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  metric_value DECIMAL(12, 4) NOT NULL,
  metric_unit TEXT, -- 'ms', 'percent', 'count', 'bytes'
  service_name TEXT, -- 'supabase', 'stripe', 'openai', 'anthropic', 'perplexity'
  status TEXT DEFAULT 'healthy' CHECK (status IN ('healthy', 'degraded', 'down')),
  threshold_warning DECIMAL(12, 4),
  threshold_critical DECIMAL(12, 4),
  metadata JSONB DEFAULT '{}'::jsonb,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for system_health_metrics
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_name ON public.system_health_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_service ON public.system_health_metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_status ON public.system_health_metrics(status);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_recorded_at ON public.system_health_metrics(recorded_at DESC);

-- Performance Logs Table
CREATE TABLE IF NOT EXISTS public.performance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  response_time_ms INTEGER NOT NULL,
  status_code INTEGER NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance_logs
CREATE INDEX IF NOT EXISTS idx_performance_logs_endpoint ON public.performance_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_performance_logs_response_time ON public.performance_logs(response_time_ms);
CREATE INDEX IF NOT EXISTS idx_performance_logs_status_code ON public.performance_logs(status_code);
CREATE INDEX IF NOT EXISTS idx_performance_logs_created_at ON public.performance_logs(created_at DESC);

-- Error Logs Table
CREATE TABLE IF NOT EXISTS public.error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_type TEXT NOT NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  endpoint TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for error_logs
CREATE INDEX IF NOT EXISTS idx_error_logs_type ON public.error_logs(error_type);
CREATE INDEX IF NOT EXISTS idx_error_logs_severity ON public.error_logs(severity);
CREATE INDEX IF NOT EXISTS idx_error_logs_resolved ON public.error_logs(resolved);
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at ON public.error_logs(created_at DESC);

-- Automated Alerts Table
CREATE TABLE IF NOT EXISTS public.automated_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL, -- 'performance_degradation', 'error_spike', 'security_incident', 'compliance_due'
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  alert_message TEXT NOT NULL,
  triggered_by TEXT, -- 'threshold_breach', 'anomaly_detection', 'scheduled_check'
  notification_channels JSONB DEFAULT '[]'::jsonb, -- ['email', 'sms', 'slack']
  sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ,
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for automated_alerts
CREATE INDEX IF NOT EXISTS idx_automated_alerts_type ON public.automated_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_automated_alerts_severity ON public.automated_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_automated_alerts_sent ON public.automated_alerts(sent);
CREATE INDEX IF NOT EXISTS idx_automated_alerts_acknowledged ON public.automated_alerts(acknowledged);
CREATE INDEX IF NOT EXISTS idx_automated_alerts_created_at ON public.automated_alerts(created_at DESC);

-- =====================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.country_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rate_limit_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ml_threat_detections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gdpr_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pci_compliance_checklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_conversion_funnels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automated_alerts ENABLE ROW LEVEL SECURITY;

-- Country Restrictions Policies (Admin only for modifications, public read for enabled countries)
CREATE POLICY "Public can view enabled countries"
  ON public.country_restrictions FOR SELECT
  USING (is_enabled = true);

CREATE POLICY "Admins can manage country restrictions"
  ON public.country_restrictions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Access Logs Policies
CREATE POLICY "Users can view own access logs"
  ON public.access_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all access logs"
  ON public.access_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Security Incidents Policies
CREATE POLICY "Admins can manage security incidents"
  ON public.security_incidents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'security_admin')
    )
  );

-- ML Threat Detections Policies
CREATE POLICY "Admins can view threat detections"
  ON public.ml_threat_detections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'security_admin')
    )
  );

-- GDPR Requests Policies
CREATE POLICY "Users can view own GDPR requests"
  ON public.gdpr_requests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create GDPR requests"
  ON public.gdpr_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can manage GDPR requests"
  ON public.gdpr_requests FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'compliance_admin')
    )
  );

-- Subscription Tiers Policies
CREATE POLICY "Public can view subscription tiers"
  ON public.subscription_tiers FOR SELECT
  USING (active = true);

CREATE POLICY "Admins can manage subscription tiers"
  ON public.subscription_tiers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- User Subscriptions Policies
CREATE POLICY "Users can view own subscription"
  ON public.user_subscriptions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own subscription"
  ON public.user_subscriptions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all subscriptions"
  ON public.user_subscriptions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Billing History Policies
CREATE POLICY "Users can view own billing history"
  ON public.billing_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all billing history"
  ON public.billing_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'finance_admin')
    )
  );

-- GA4 Events Policies
CREATE POLICY "Users can create own GA4 events"
  ON public.ga4_events FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Admins can view all GA4 events"
  ON public.ga4_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'analytics_admin')
    )
  );

-- System Health Metrics Policies
CREATE POLICY "Admins can view system health metrics"
  ON public.system_health_metrics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'devops_admin')
    )
  );

-- Performance Logs Policies
CREATE POLICY "Admins can view performance logs"
  ON public.performance_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'devops_admin')
    )
  );

-- Error Logs Policies
CREATE POLICY "Admins can manage error logs"
  ON public.error_logs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'devops_admin')
    )
  );

-- Automated Alerts Policies
CREATE POLICY "Admins can manage automated alerts"
  ON public.automated_alerts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'devops_admin', 'security_admin')
    )
  );

-- =====================================================
-- 9. FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_country_restrictions_updated_at
  BEFORE UPDATE ON public.country_restrictions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_security_incidents_updated_at
  BEFORE UPDATE ON public.security_incidents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_activity_patterns_updated_at
  BEFORE UPDATE ON public.user_activity_patterns
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pci_compliance_checklist_updated_at
  BEFORE UPDATE ON public.pci_compliance_checklist
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compliance_calendar_updated_at
  BEFORE UPDATE ON public.compliance_calendar
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_tiers_updated_at
  BEFORE UPDATE ON public.subscription_tiers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON public.user_subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to check country access
CREATE OR REPLACE FUNCTION check_country_access(country_code_param VARCHAR(2))
RETURNS BOOLEAN AS $$
DECLARE
  is_allowed BOOLEAN;
BEGIN
  SELECT is_enabled INTO is_allowed
  FROM public.country_restrictions
  WHERE country_code = country_code_param;
  
  RETURN COALESCE(is_allowed, true); -- Default to true if country not found
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log access attempt
CREATE OR REPLACE FUNCTION log_access_attempt(
  user_id_param UUID,
  country_code_param VARCHAR(2),
  latitude_param DECIMAL(10, 8),
  longitude_param DECIMAL(11, 8),
  ip_address_param INET,
  access_granted_param BOOLEAN,
  blocked_reason_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  log_id UUID;
BEGIN
  INSERT INTO public.access_logs (
    user_id,
    country_code,
    latitude,
    longitude,
    ip_address,
    access_granted,
    blocked_reason
  ) VALUES (
    user_id_param,
    country_code_param,
    latitude_param,
    longitude_param,
    ip_address_param,
    access_granted_param,
    blocked_reason_param
  )
  RETURNING id INTO log_id;
  
  RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate subscription MRR
CREATE OR REPLACE FUNCTION calculate_subscription_mrr()
RETURNS VOID AS $$
DECLARE
  current_date DATE := CURRENT_DATE;
BEGIN
  INSERT INTO public.subscription_analytics (date, tier_id, active_subscriptions, mrr)
  SELECT
    current_date,
    st.id,
    COUNT(us.id),
    SUM(
      CASE
        WHEN us.billing_cycle = 'monthly' THEN st.monthly_price
        WHEN us.billing_cycle = 'annual' THEN st.annual_price / 12
        ELSE 0
      END
    )
  FROM public.subscription_tiers st
  LEFT JOIN public.user_subscriptions us ON us.tier_id = st.id AND us.status = 'active'
  GROUP BY st.id
  ON CONFLICT (date, tier_id) DO UPDATE
  SET
    active_subscriptions = EXCLUDED.active_subscriptions,
    mrr = EXCLUDED.mrr;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. INITIAL DATA & CONFIGURATION
-- =====================================================

-- Insert sample compliance calendar events
INSERT INTO public.compliance_calendar (event_name, event_type, due_date, status)
VALUES
  ('Q1 2026 GDPR Compliance Audit', 'audit', '2026-03-31', 'pending'),
  ('Q1 2026 Tax Report', 'report_due', '2026-04-15', 'pending'),
  ('PCI-DSS Recertification', 'certification', '2026-06-30', 'pending'),
  ('Annual Security Training', 'training', '2026-12-31', 'pending')
ON CONFLICT DO NOTHING;

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
