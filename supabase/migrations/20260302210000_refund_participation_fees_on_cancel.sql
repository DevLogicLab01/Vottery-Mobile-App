-- Refund participation fees when election is canceled/failed (blocked-account behavior).
-- Call this from app or Edge Function when election status becomes canceled or failed.

CREATE OR REPLACE FUNCTION public.refund_participation_fees_for_election(p_election_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated INTEGER;
  v_total NUMERIC := 0;
BEGIN
  WITH updated AS (
    UPDATE public.participation_fee_transactions
    SET status = 'refunded',
        updated_at = NOW()
    WHERE election_id = p_election_id
      AND status = 'completed'
    RETURNING amount
  )
  SELECT COUNT(*)::INTEGER, COALESCE(SUM(amount), 0) INTO v_updated, v_total
  FROM updated;

  RETURN jsonb_build_object(
    'election_id', p_election_id,
    'refunded_count', v_updated,
    'refunded_total', v_total,
    'message', format('Marked %s transaction(s) as refunded (total %s). Trigger Stripe refunds from your backend.', v_updated, v_total)
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.refund_participation_fees_for_election(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refund_participation_fees_for_election(UUID) TO service_role;

COMMENT ON FUNCTION public.refund_participation_fees_for_election(UUID) IS
  'Marks participation_fee_transactions as refunded for a canceled/failed election. Call Stripe refund API separately for each transaction.';
