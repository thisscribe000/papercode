-- Migration: Rebuild comments table for version-scoped feedback with threading support
-- Run this in Supabase SQL Editor

-- ============================================================
-- 1. Add new columns
-- ============================================================
ALTER TABLE comments ADD COLUMN content text;
ALTER TABLE comments ADD COLUMN updated_at timestamptz DEFAULT now();
ALTER TABLE comments ADD COLUMN parent_comment_id uuid REFERENCES comments(id);

-- ============================================================
-- 2. Migrate data: body -> content
-- ============================================================
UPDATE comments SET content = body;
ALTER TABLE comments ALTER COLUMN content SET NOT NULL;
ALTER TABLE comments DROP COLUMN body;

-- ============================================================
-- 3. Add indexes for common query patterns
-- ============================================================
CREATE INDEX idx_comments_asset_id ON comments(asset_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);
CREATE INDEX idx_comments_parent_comment_id ON comments(parent_comment_id);

-- ============================================================
-- 4. Drop old wide-open RLS policies
-- ============================================================
DROP POLICY IF EXISTS "Authenticated can read comments" ON comments;
DROP POLICY IF EXISTS "Authenticated can insert comments" ON comments;

-- ============================================================
-- 5. Add project-membership-based RLS policies
--
--    Access rule: a user can reach a comment only through
--    comment -> asset -> project -> project_members -> auth.uid()
-- ============================================================

-- SELECT: user must be a member of the project the asset belongs to
CREATE POLICY "Members can read project comments"
ON comments FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM assets
    JOIN project_members ON project_members.project_id = assets.project_id
    WHERE assets.id = comments.asset_id
    AND project_members.user_id = auth.uid()
  )
);

-- INSERT: user must be a member of the project the asset belongs to
CREATE POLICY "Members can create project comments"
ON comments FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM assets
    JOIN project_members ON project_members.project_id = assets.project_id
    WHERE assets.id = comments.asset_id
    AND project_members.user_id = auth.uid()
  )
);

-- UPDATE: user must be the comment author AND a project member
CREATE POLICY "Authors can update own comments"
ON comments FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM assets
    JOIN project_members ON project_members.project_id = assets.project_id
    WHERE assets.id = comments.asset_id
    AND project_members.user_id = auth.uid()
  )
)
WITH CHECK (
  user_id = auth.uid()
);

-- DELETE: comment author OR admin of the project
CREATE POLICY "Authors or admins can delete comments"
ON comments FOR DELETE
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM assets
    JOIN project_members ON project_members.project_id = assets.project_id
    WHERE assets.id = comments.asset_id
    AND project_members.user_id = auth.uid()
    AND project_members.is_admin = true
  )
);
