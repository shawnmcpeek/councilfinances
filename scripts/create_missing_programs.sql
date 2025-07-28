-- Create missing programs for CSV import
-- These programs are referenced in the financial data but don't exist in the programs table

INSERT INTO public.programs (id, organization_id, name, category, is_system_default, financial_type, is_enabled, is_assembly) VALUES
-- Council programs
('C015857_football_crazr', 'C015857', 'Football Crazr', 'COUNCIL', false, 'both', true, false),
('C015857_donations_received', 'C015857', 'Donations Received', 'COMMUNITY', false, 'both', true, false),
('C015857_parish_breakfast', 'C015857', 'Parish Breakfast', 'COMMUNITY', false, 'both', true, false),
('C015857_parish_movie_knight', 'C015857', 'Parish Movie Knight', 'FAMILY', false, 'both', true, false),
('C015857_chairperson_fund', 'C015857', 'Chairperson Fund', 'FAITH', false, 'both', true, false),
('C015857_st_martin_hot_chocolate', 'C015857', 'St Martin of Tours Hot Chocolate', 'FAITH', false, 'both', true, false),
('C015857_unbound', 'C015857', 'Unbound', 'LIFE', false, 'both', true, false),
('C015857_council_insurance', 'C015857', 'Council Insurance', 'COUNCIL', false, 'both', true, false),
('C015857_membership_expenses', 'C015857', 'Membership Expenses', 'COUNCIL', false, 'both', true, false),
('C015857_interest', 'C015857', 'Interest', 'COUNCIL', false, 'both', true, false),
('C015857_disaster_relief', 'C015857', 'Disaster Relief', 'COMMUNITY', false, 'both', true, false),
('C015857_seminarian_donations', 'C015857', 'Seminarian Donations', 'FAITH', false, 'both', true, false),
('C015857_movie_night', 'C015857', 'Movie Night', 'COMMUNITY', false, 'both', true, false),
('C015857_rsvp_fundraiser', 'C015857', 'RSVP Fundraiser', 'COMMUNITY', false, 'both', true, false),
('C015857_convention_expenses', 'C015857', 'Convention Expenses', 'COUNCIL', false, 'both', true, false),
('C015857_fish_fry', 'C015857', 'Fish Fry', 'COMMUNITY', false, 'both', true, false),
('C015857_conference_refund', 'C015857', 'Conference Refund', 'COUNCIL', false, 'both', true, false),
('C015857_per_capita_state', 'C015857', 'Per Capita - State', 'COUNCIL', false, 'both', true, false),
('C015857_postage', 'C015857', 'Postage', 'COUNCIL', false, 'both', true, false),
('C015857_membership_dues', 'C015857', 'Membership Dues', 'COUNCIL', false, 'both', true, false)
ON CONFLICT (id) DO NOTHING; 