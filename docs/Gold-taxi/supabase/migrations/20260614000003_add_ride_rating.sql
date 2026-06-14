-- Add rating column to rides table for driver statistics
-- Rating is 1-5 stars, nullable (old rides without rating remain NULL)
ALTER TABLE public.rides
  ADD COLUMN IF NOT EXISTS rating integer CHECK (rating >= 1 AND rating <= 5);

-- Index for efficient average rating queries per driver
CREATE INDEX IF NOT EXISTS rides_driver_id_rating_idx ON public.rides(driver_id) WHERE rating IS NOT NULL;
