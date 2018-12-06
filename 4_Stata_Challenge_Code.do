cls // clear window

/********************************************************************************
STATA CHALLENGE 26/09/18 – EG DIB Surveyor Teams

DATE:	19 Sep 2018

INPUT: 	2_surveyor_list.dta

OUTPUT:	3_example team assignment_[date].xls
		
DESCRIPTION: 	This .do file randomly groups surveyors into teams and pairs
				under certain conditions such as experience, bikes, home state.

AUTHOR:	Lucas Kitzmueller - lucas.kitzmueller@idinsight.org
		(based on a .do file written by Qayam Jetha - qayam.jetha@idinsight.org)
				
********************************************************************************/

* Adding this comment

	
	
	*---------------------------*
	* II. Prepare data for loop *
	*---------------------------*
	
		* (1) Calculate how many Surveyors from Rajasthan should be in each team
		* 	  if they are alloted to groups evenly.
		count if state == "Raj"
		local rajasthan_total `r(N)'
		local rajasthan_per_group = `rajasthan_total' / 4
		 

		 
	*-----------*
	* III. Loop *
	*-----------*
	
	/* Note:	In this loop, we randomize the order of surveyors, put them 
				into pairs and teams, check if our conditions are fulfilled, 
				and if not, tell Stata to start the loop again from the beginning. 
				We continue doing this until all of our conditions are met. */
	
	local i 0 // we will use this to count the number of loops; not strictly necessary
	
	local x FALSE 

	while "`x'" == "FALSE" { 
		
		* Tells Stata to repeat executing the commands in {} until the 
		* expression we specified ("`x'" == "FALSE") isn't true anymore.
		
		local ++i // increment change in loop count; not strictly necessary
		
		
		
		* (1) Drop variables from previous run of the loop
		
			local vars_from_loop rand team pair bikes_team experience_pair raj_team
			foreach var in `vars_from_loop' {
				capture drop `var'
			}
			
			/* 	Note: 	The capture command allows the do file to continue running even 
						if you're trying to drop a variable that doesn't exist. You 
						could also drop these variables in the if-commands below. */
		
		
		
		* (2) Randomizing
			
			* This section puts the surveyors in a random order.
		
			gen rand = runiform()
			sort rand, stable
		
		
		
		* (3) Putting surveyors into teams and pairs
		
			gen byte team = sum((mod(_n, 8) == 1)) // Create teams of 8 surveyors each
			gen byte pair = sum((mod(_n, 2) == 1)) // Create pairs of 2 surveyors each

			
			
		* (4) Check if each group has more than 4 bikes
		
			bys team: egen bikes_team = sum(bike) 
			label variable bikes_team "Number of bikes in team"

			quietly count if bikes_team < 4 // Count the number of teams with less than 4 bikes
		
			if r(N) != 0 { 	// If there's at least one team ...
				continue	// ... we tell Stata to go back to the beginning of the loop
			}
			
			 /* Note: 	If the count is not 0 (if there are groups with less than 4 bikes) 
						then we drop assignment and re-run the loop. The continue command does that 
						for us: It breaks the execution of the current loop iteration, skips the 
						remaining commands within the loop, and resumes at the top of the loop.
				
						You could also drop the variables "pair team bikes_team" here instead
						of doing it in (1). */	
			
			
			
		* (5) Check if experienced surveyors are paired with inexperienced surveyors
			
			*	Note: 	This means, we don't want there to be a pair of experienced surveyors
			*			if there's also a pair of inexperienced surveyors)
		
			bys pair: egen experience_pair = sum(experience) 
			label variable experience_pair "Number of experienced surveyors in pair"

			quietly sum experience_pair
			if r(max) == 2 { // if there's a pair with two experienced surveyors ...
				
				quietly count if experience_pair == 0 	// ... there shouldn't be one with 
														//     two inexperienced surveyors
				
				if r(N) != 0 {					// if there is ...
					continue					// ... start again from the beginning
				}
				
			}
			/* Note:	There are multiple other correct ways to check if 
						experience is evenly distributed. */
		
		
		
		* (6) Check that surveyors from Rajasthan are alloted to teams as evenly as possible
		
			/* Note:	If the number of surveyors from Rajasthan is a multiple of 4,
						we want each survey team to have exactly 
							(number of surveyors from Raj / 4) 
						surveyors from Rajasthan. 
					
						If the number is not a multiple of 4, but for example 22 as in our case,
						we only want teams with either 5 or 6 surveyors from Rajasthan, as
						(22 / 4) = 5.5 */
			
			bys team: egen raj_team = total(state == "Raj") 
			label variable raj_team "Number of surveyors from Rajasthan in team"

			quietly count if raj_team <= (`rajasthan_per_group' - 1) | raj_team >= (`rajasthan_per_group' + 1)

			if r(N) !=0 { 
				continue
			} 	
			
			
			
			
		* (7) End loop
		
			local x TRUE // If the file gets to this line, that means all conditions are met, and x is now TRUE.
			display "Loop ran `i' times."
		
	}
		
		
		
	*---------------------*
	* IV. Save and Export *
	*---------------------*
		
		keep   team pair name state bike experience  
		order  team pair name state bike experience  

		export excel using "`export'", firstrow(variables) replace

* END
