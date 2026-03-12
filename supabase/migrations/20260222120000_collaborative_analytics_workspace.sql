-- Collaborative Analytics Workspace Migration
-- Creates tables for team collaboration, annotations, decision tracking, and insights

-- Workspaces table
CREATE TABLE IF NOT EXISTS public.workspaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  member_count INTEGER DEFAULT 1,
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  is_starred BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspace members table
CREATE TABLE IF NOT EXISTS public.workspace_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'editor', 'commenter', 'viewer')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(workspace_id, user_id)
);

-- Shared dashboards table
CREATE TABLE IF NOT EXISTS public.shared_dashboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES auth.users(id),
  member_access_count INTEGER DEFAULT 0,
  last_modified_at TIMESTAMPTZ DEFAULT NOW(),
  dashboard_config JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Chart annotations table
CREATE TABLE IF NOT EXISTS public.chart_annotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_id TEXT NOT NULL,
  dashboard_id UUID REFERENCES public.shared_dashboards(id) ON DELETE CASCADE,
  data_point_identifier JSONB NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  annotation_text TEXT NOT NULL,
  annotation_type TEXT NOT NULL CHECK (annotation_type IN ('insight', 'question', 'decision', 'action_item', 'warning')),
  color TEXT DEFAULT '#FF6B6B',
  mentioned_users UUID[] DEFAULT '{}',
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  attachments TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Annotation threads (replies)
CREATE TABLE IF NOT EXISTS public.annotation_threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  annotation_id UUID NOT NULL REFERENCES public.chart_annotations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  comment_text TEXT NOT NULL,
  mentioned_users UUID[] DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Annotation reactions
CREATE TABLE IF NOT EXISTS public.annotation_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  annotation_id UUID NOT NULL REFERENCES public.chart_annotations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(annotation_id, user_id, emoji)
);

-- Decision log table
CREATE TABLE IF NOT EXISTS public.decision_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  context TEXT,
  supporting_data JSONB DEFAULT '[]',
  expected_impact TEXT,
  stakeholders UUID[] DEFAULT '{}',
  implementation_owner UUID REFERENCES auth.users(id),
  target_date DATE,
  approval_required BOOLEAN DEFAULT FALSE,
  status TEXT NOT NULL CHECK (status IN ('proposed', 'under_review', 'approved', 'rejected', 'implemented')),
  proposer_id UUID NOT NULL REFERENCES auth.users(id),
  impact_badge TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Decision approvals table
CREATE TABLE IF NOT EXISTS public.decision_approvals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  decision_id UUID NOT NULL REFERENCES public.decision_log(id) ON DELETE CASCADE,
  approver_id UUID NOT NULL REFERENCES auth.users(id),
  status TEXT NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'changes_requested')),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(decision_id, approver_id)
);

-- Decision implementation checklist
CREATE TABLE IF NOT EXISTS public.decision_implementation_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  decision_id UUID NOT NULL REFERENCES public.decision_log(id) ON DELETE CASCADE,
  task_description TEXT NOT NULL,
  assignee_id UUID REFERENCES auth.users(id),
  due_date DATE,
  is_completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insights library table
CREATE TABLE IF NOT EXISTS public.insights_library (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('performance', 'security', 'revenue', 'user_behavior', 'engagement', 'technical')),
  author_id UUID NOT NULL REFERENCES auth.users(id),
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  analysis_period_start DATE,
  analysis_period_end DATE,
  related_metrics JSONB DEFAULT '[]',
  confidence_level TEXT NOT NULL CHECK (confidence_level IN ('low', 'medium', 'high')),
  key_findings TEXT[] DEFAULT '{}',
  recommendations TEXT[] DEFAULT '{}',
  upvotes INTEGER DEFAULT 0,
  downvotes INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT FALSE,
  public_link_token TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insight votes table
CREATE TABLE IF NOT EXISTS public.insight_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  insight_id UUID NOT NULL REFERENCES public.insights_library(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(insight_id, user_id)
);

-- Workspace activity feed
CREATE TABLE IF NOT EXISTS public.workspace_activity (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  activity_type TEXT NOT NULL,
  activity_description TEXT NOT NULL,
  related_entity_id UUID,
  related_entity_type TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Workspace exports table
CREATE TABLE IF NOT EXISTS public.workspace_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id UUID NOT NULL REFERENCES public.workspaces(id) ON DELETE CASCADE,
  exported_by UUID NOT NULL REFERENCES auth.users(id),
  export_type TEXT NOT NULL CHECK (export_type IN ('pdf', 'csv', 'json')),
  file_url TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_workspaces_owner ON public.workspaces(owner_id);
CREATE INDEX IF NOT EXISTS idx_workspace_members_workspace ON public.workspace_members(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_members_user ON public.workspace_members(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_dashboards_workspace ON public.shared_dashboards(workspace_id);
CREATE INDEX IF NOT EXISTS idx_chart_annotations_dashboard ON public.chart_annotations(dashboard_id);
CREATE INDEX IF NOT EXISTS idx_chart_annotations_chart ON public.chart_annotations(chart_id);
CREATE INDEX IF NOT EXISTS idx_annotation_threads_annotation ON public.annotation_threads(annotation_id);
CREATE INDEX IF NOT EXISTS idx_annotation_reactions_annotation ON public.annotation_reactions(annotation_id);
CREATE INDEX IF NOT EXISTS idx_decision_log_workspace ON public.decision_log(workspace_id);
CREATE INDEX IF NOT EXISTS idx_decision_log_status ON public.decision_log(status);
CREATE INDEX IF NOT EXISTS idx_decision_approvals_decision ON public.decision_approvals(decision_id);
CREATE INDEX IF NOT EXISTS idx_insights_library_workspace ON public.insights_library(workspace_id);
CREATE INDEX IF NOT EXISTS idx_insights_library_category ON public.insights_library(category);
CREATE INDEX IF NOT EXISTS idx_workspace_activity_workspace ON public.workspace_activity(workspace_id);
CREATE INDEX IF NOT EXISTS idx_workspace_activity_created ON public.workspace_activity(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.workspaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_dashboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chart_annotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.annotation_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.annotation_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decision_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decision_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decision_implementation_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insights_library ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.insight_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workspace_exports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for workspaces
CREATE POLICY "Users can view workspaces they are members of"
  ON public.workspaces FOR SELECT
  USING (
    owner_id = auth.uid() OR
    id IN (SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create workspaces"
  ON public.workspaces FOR INSERT
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Owners can update their workspaces"
  ON public.workspaces FOR UPDATE
  USING (owner_id = auth.uid());

CREATE POLICY "Owners can delete their workspaces"
  ON public.workspaces FOR DELETE
  USING (owner_id = auth.uid());

-- RLS Policies for workspace members
CREATE POLICY "Users can view workspace members"
  ON public.workspace_members FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Owners can manage workspace members"
  ON public.workspace_members FOR ALL
  USING (
    workspace_id IN (SELECT id FROM public.workspaces WHERE owner_id = auth.uid())
  );

-- RLS Policies for shared dashboards
CREATE POLICY "Workspace members can view dashboards"
  ON public.shared_dashboards FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Editors can create dashboards"
  ON public.shared_dashboards FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members 
      WHERE user_id = auth.uid() AND role IN ('owner', 'editor')
    )
  );

-- RLS Policies for annotations
CREATE POLICY "Workspace members can view annotations"
  ON public.chart_annotations FOR SELECT
  USING (
    dashboard_id IN (
      SELECT id FROM public.shared_dashboards WHERE workspace_id IN (
        SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        UNION
        SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
      )
    )
  );

CREATE POLICY "Workspace members can create annotations"
  ON public.chart_annotations FOR INSERT
  WITH CHECK (
    dashboard_id IN (
      SELECT id FROM public.shared_dashboards WHERE workspace_id IN (
        SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
        UNION
        SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
      )
    )
  );

-- RLS Policies for decision log
CREATE POLICY "Workspace members can view decisions"
  ON public.decision_log FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Workspace members can create decisions"
  ON public.decision_log FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for insights
CREATE POLICY "Workspace members can view insights"
  ON public.insights_library FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    ) OR is_public = TRUE
  );

CREATE POLICY "Workspace members can create insights"
  ON public.insights_library FOR INSERT
  WITH CHECK (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for workspace activity
CREATE POLICY "Workspace members can view activity"
  ON public.workspace_activity FOR SELECT
  USING (
    workspace_id IN (
      SELECT id FROM public.workspaces WHERE owner_id = auth.uid()
      UNION
      SELECT workspace_id FROM public.workspace_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create activity"
  ON public.workspace_activity FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Function to update workspace last_activity_at
CREATE OR REPLACE FUNCTION update_workspace_activity()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.workspaces
  SET last_activity_at = NOW()
  WHERE id = NEW.workspace_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for workspace activity updates
CREATE TRIGGER update_workspace_activity_trigger
AFTER INSERT ON public.workspace_activity
FOR EACH ROW
EXECUTE FUNCTION update_workspace_activity();