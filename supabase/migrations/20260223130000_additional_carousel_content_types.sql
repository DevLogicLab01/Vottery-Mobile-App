-- Migration: Additional Content Types for Premium 2D Carousels
-- Tables: creator_spotlights, creator_marketplace_services, prediction_champions

-- Creator Spotlights Table
CREATE TABLE IF NOT EXISTS creator_spotlights (
  spotlight_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  spotlight_reason TEXT NOT NULL,
  featured_content_id UUID,
  featured_content_type TEXT CHECK (featured_content_type IN ('election', 'jolt', 'post')),
  performance_stats JSONB DEFAULT '{}'::jsonb,
  spotlight_expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_creator_spotlights_creator ON creator_spotlights(creator_id);
CREATE INDEX idx_creator_spotlights_active ON creator_spotlights(is_active, spotlight_expires_at DESC);

-- Creator Marketplace Services Table
CREATE TABLE IF NOT EXISTS creator_marketplace_services (
  service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  service_type TEXT NOT NULL,
  description TEXT,
  price_range_min DECIMAL(10, 2),
  price_range_max DECIMAL(10, 2),
  portfolio_samples JSONB DEFAULT '[]'::jsonb,
  rating DECIMAL(3, 2) DEFAULT 0.00 CHECK (rating >= 0 AND rating <= 5),
  completed_projects INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_creator_services_creator ON creator_marketplace_services(creator_id);
CREATE INDEX idx_creator_services_rating ON creator_marketplace_services(rating DESC) WHERE is_active = true;
CREATE INDEX idx_creator_services_active ON creator_marketplace_services(is_active);

-- Prediction Champions Table
CREATE TABLE IF NOT EXISTS prediction_champions (
  champion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  accuracy_score DECIMAL(5, 2) NOT NULL CHECK (accuracy_score >= 0 AND accuracy_score <= 100),
  total_predictions INTEGER DEFAULT 0,
  winning_streak INTEGER DEFAULT 0,
  specialization TEXT,
  avg_brier_score DECIMAL(5, 3),
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_prediction_champions_user ON prediction_champions(user_id);
CREATE INDEX idx_prediction_champions_accuracy ON prediction_champions(accuracy_score DESC) WHERE is_active = true;
CREATE INDEX idx_prediction_champions_active ON prediction_champions(is_active);

-- RLS Policies for creator_spotlights
ALTER TABLE creator_spotlights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creator spotlights are viewable by everyone"
  ON creator_spotlights FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage creator spotlights"
  ON creator_spotlights FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- RLS Policies for creator_marketplace_services
ALTER TABLE creator_marketplace_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creator services are viewable by everyone"
  ON creator_marketplace_services FOR SELECT
  USING (is_active = true);

CREATE POLICY "Creators can manage their own services"
  ON creator_marketplace_services FOR ALL
  USING (creator_id = auth.uid());

-- RLS Policies for prediction_champions
ALTER TABLE prediction_champions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Prediction champions are viewable by everyone"
  ON prediction_champions FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can update prediction champions"
  ON prediction_champions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Functions for automatic timestamp updates
CREATE OR REPLACE FUNCTION update_creator_spotlight_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER creator_spotlights_updated_at
  BEFORE UPDATE ON creator_spotlights
  FOR EACH ROW
  EXECUTE FUNCTION update_creator_spotlight_timestamp();

CREATE OR REPLACE FUNCTION update_creator_service_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER creator_services_updated_at
  BEFORE UPDATE ON creator_marketplace_services
  FOR EACH ROW
  EXECUTE FUNCTION update_creator_service_timestamp();

CREATE OR REPLACE FUNCTION update_prediction_champion_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER prediction_champions_updated_at
  BEFORE UPDATE ON prediction_champions
  FOR EACH ROW
  EXECUTE FUNCTION update_prediction_champion_timestamp();
