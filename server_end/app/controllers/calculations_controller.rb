class CalculationsController < ApplicationController
	#Instead of completely turning off the built in security, 
	#kills off any session that might exist when something hits the server without the CSRF token.
	protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }
	#response_to :json
	def reputation_algorithms
=begin
		Input example:
		{
			"expert_grades": {"submission1": 90, "submission2":88, "submission3":93},  #optional
			"submission1": {"stu1":81, "stu3":89},
		    "submission2": {"stu5":87, "stu8":90},
			"submission3": {"stu2":84, "stu4":86}
		}
=end
		puts "Get post msg!" if !params.nil?		
		#prepare parameters
		submissions = Hash.new
		reviewers = Hash.new
		expert_grades = Hash.new
		has_expert_grades = false
		params.each do |key, value|
			if /expert_grades/.match(key)
				value.each do |k, v|
					submission_id = k.gsub(/submission/,'').to_i
					expert_grades[submission_id] = v
				end
				has_expert_grades = true
			end
			if /submission[0-9]+/.match(key)
				submission_id = key.gsub(/submission/,'').to_i
				s = Submission.new(id: submission_id, review_records: Array.new, temp_score: 0)
				value.each do |k, v|
					reviewer_id = k.gsub(/stu/,'').to_i
					rr = ReviewRecord.new(submission_id: submission_id, reviewer_id: reviewer_id, score: v)
					#check if this reviewer is already in hash.
					if reviewers[k].nil?
						r = Reviewer.new(id: reviewer_id, review_records: Array.new, reputation: nil, leniency: 0, weight: 1, variance: 0)
						r.review_records << rr
						reviewers[reviewer_id] = r
					else 
						r = reviewers[k]
						r.review_records << rr
					end
					s.review_records << rr
				end
				submissions[submission_id] = s
			end
		end

		final_reputation_hamer = Hamer.calculate_reputations(submissions, reviewers)
		final_reputation_hamer_extended = HamerExtended.calculate_reputations(submissions, reviewers, expert_grades) if has_expert_grades
	        final_reputation_lauw = Lauw.calculate_reputations(submissions, reviewers)
		final_reputation_lauw_supervised = LauwSupervised.calculate_reputations(submissions, reviewers, expert_grades) if has_expert_grades
		final_reputation = Hash.new
		final_reputation['Hamer'] = final_reputation_hamer
		final_reputation['HamerExtended'] = final_reputation_hamer_extended if has_expert_grades
		final_reputation['Lauw'] = final_reputation_lauw
		final_reputation['LauwSupervised'] = final_reputation_lauw_supervised if has_expert_grades
		render json: final_reputation.to_json
	end	
end
