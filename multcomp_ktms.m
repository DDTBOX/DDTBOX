function [Results] = multcomp_ktms(cond1_data, cond2_data, varargin)
%
% This function receives paired-samples data and outputs corrected p-values and
% hypothesis test results based on control of the generalised family-wise error rate
% (Korn, 2004, method A in their appendices). The permutation test in this script is based
% on the t-statistic from Student's paired-samples t-test, but can also be used
% with the more robust Yuen's paired-samples t test. If using Yuen's t this
% function calls another function yuend_ttest which should be provided with
% DDTBOX.
%
% Korn, E. L., Troendle, J. F., McShane, L. M., & Simon, R. (2004). Controlling
% the number of false discoveries: Application to high-dimensional genomic data.
% Journal of Statistical Planning and Inference, 124, 379-398. 
% doi 10.1016/S0378-3758(03)00211-8
%
% This function also implements a conservative p-value correction (for
% p-values after multiple comparisons correction) to avoid p-values of zero
% in permutation tests. The conservative method in Phipson & Smyth (2010) is used:
%
% Permutation p-values should never be zero: Calculating exact p-values
% when permutations are randomly drawn. Statistical Applications in
% Genetics and Molecular Biology, 9, 39. doi 10.2202/1544-6115.1585
%
% Please cite these articles when using this multiple comparisons
% correction method.
%
%
% Inputs:
%
%   cond1_data      data from condition 1, a subjects x time windows matrix
%
%   cond2_data      data from condition 2, a subjects x time windows matrix
%
%  'Key1'          Keyword string for argument 1
%
%   Value1         Value of argument 1
%
%   ...            ...
%
% Optional Keyword Inputs:
%
%   alpha           uncorrected alpha level for statistical significance, 
%                   default 0.05
%
%   iterations      number of permutation samples to draw, default 5000. 
%                   At least 1000 is recommended for the p = 0.05 alpha level, 
%                   and at least 5000 is recommended for the p = 0.01 alpha level.
%                   This is due to extreme events at the tails being very rare, 
%                   needing many random permutations to find enough of them.
%
%   ktms_u          the u parameter of the procedure, or the number of hypotheses
%                   to automatically reject. Allowing for more false discoveries
%                   improves the sensitivity of the method to find real effects. 
%                   Default is 1.
%
%   use_yuen        option to use Yuen's paired-samples t instead of
%                   Student's t. 1 = Yuen's t / 0 = Student's t
%
%   percent         percent to trim when using the trimmed mean. Value must
%                   be between 0 and 50. Default is 20.
%
%   tail            choices for one- or two-tailed testing. Default is two-tailed.
%                           'both' = two-tailed
%                           'right' = one-tailed test for positive differences
%                           'left' = one-tailed test for negative differences
%   
%
% Outputs:
%
%   Results structure containing:
%
%   corrected_h     vector of hypothesis tests in which statistical significance
%                   is defined by values above a threshold of the (alpha_level * 100)th
%                   percentile of the maximum statistic distribution.
%                   1 = statistically significant, 0 = not statistically significant
%
%   corrected_p     p-values corrected for multiple testing
%   
%   t_values        t values from hypothesis tests on observed data.
%  
%   critical_t      critical t value above which effects are declared
%                   statistically significant. 
%
%   ktms_u          the u statistic in the ktms procedure (also an input
%                   but recorded in the Results structure for reference).
%
%
% Example:  [Results] = multcomp_ktms(cond1_data, cond2_data, 'alpha', 0.05, 'iterations', 10000, 'ktms_u', 2, 'use_yuen', 1, 'percent', 20, 'tail', 'both')
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Daniel Feuerriegel
%
% DDTBOX is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


%% Handling Variadic Inputs

% Define defaults at the beginning
options = struct(...
    'alpha', 0.05,...
    'iterations', 5000,...
    'ktms_u', 1,...
    'use_yuen', 0,...
    'percent', 20,...
    'tail', 'both');

% Read the acceptable names
option_names = fieldnames(options);

% Count arguments
n_args = length(varargin);
if round(n_args/2) ~= n_args/2
    
   error([mfilename ' needs property name/property value pairs'])
   
end % of if round

for pair = reshape(varargin, 2, []) % pair is {propName;propValue}
    
   inp_name = lower(pair{1}); % make case insensitive

   % Overwrite default options
   if any(strcmp(inp_name, option_names))
       
      options.(inp_name) = pair{2};
      
   else
       
      error('%s is not a recognized parameter name', inp_name)
      
   end % of if any
end % of for pair

clear pair
clear inp_name

% Renaming variables for use below:
alpha_level = options.alpha;
n_iterations = options.iterations;
ktms_u = options.ktms_u;
use_yuen = options.use_yuen;
percent = options.percent;
tail = options.tail;
clear options;


%% Tests on Observed (Non-Permutation) Data

% Checking whether the number of steps of the first and second datasets are equal
if size(cond1_data, 2) ~= size(cond2_data, 2)
    
   error('Condition 1 and 2 datasets do not contain the same number of comparisons/tests!');
   
end % of if size

if size(cond1_data, 1) ~= size(cond2_data, 1)
    
   error('Condition 1 and 2 datasets do not contain the same number of subjects!');
   
end % of if size

% Generate difference scores between conditions
diff_scores = cond1_data - cond2_data;

n_subjects = size(diff_scores, 1); % Calculate number of subjects
n_total_comparisons = size(diff_scores, 2); % Calculating the number of comparisons

% Preallocate vector of uncorrected p-values
p_values = zeros(n_total_comparisons, 1);

% Perform t-tests at each step 
if use_yuen == 0 % If using Student's t
    
    [~, p_values, ~, extra_stats] = ttest(diff_scores, 0, 'Alpha', alpha_level, 'tail', tail);
    uncorrected_t = extra_stats.tstat; % Vector of t statistics from each test
    
elseif use_yuen == 1 % If using Yuen's t
    
    uncorrected_t = zeros(1, n_total_comparisons); % Preallocate
    
    for step = 1:n_total_comparisons
        
        [~, p_values(step), ~, uncorrected_t(step)] = yuend_ttest(cond1_data(:, step), cond2_data(:, step), 'alpha', alpha_level, 'percent', percent, 'tail', tail);
        
    end % of for step
end % of if use_yuen

% Seed the random number generator based on the clock time
rng('shuffle');

% Make a vector to denote statistically significant steps
corrected_h = zeros(1, n_total_comparisons);

sorted_p = sort(p_values); % Sort p-values from smallest to largest

% Automatically reject the u smallest hypotheses (u is set by user as ktms_u variable).
if ktms_u > 0
    
    ktms_auto_reject_threshold = sorted_p(ktms_u);
    
elseif ktms_u == 0 % if ktms_u is set to zero
    
    ktms_auto_reject_threshold = 0;
    
end % of if ktms_u

corrected_h(p_values <= ktms_auto_reject_threshold) = 1; % Mark tests with u smallest p-values as statistically significant.

% Run strong FWER control permutation test but use u + 1th most extreme
% test statistic.
ktms_t_max = zeros(1, n_iterations);
t_stat = zeros(n_total_comparisons, n_iterations);
temp_signs = zeros(n_subjects, n_total_comparisons);

for iteration = 1:n_iterations

    % Draw a random sample for each test
        % Randomly switch the sign of difference scores (equivalent to
        % switching labels of conditions). The assignment of labels across
        % tests are consistent within each participant.
        temp = zeros(n_subjects, n_total_comparisons); % Preallocate
        temp_signs = (rand(n_subjects, 1) > .5) * 2 - 1; % Switches signs of labels

    for step = 1:n_total_comparisons
        
        temp(:, step) = temp_signs .* diff_scores(1:n_subjects, step);
        
    end % of for step
    
    % Perform paired-samples t tests
    if use_yuen == 0 % If using Student's t 
        
        [~, ~, ~, temp_stats] = ttest(temp, 0, 'Alpha', alpha_level, 'tail', tail);
        t_stat(:, iteration) = temp_stats.tstat;
        
    elseif use_yuen == 1 % If using Yuen's t
        
        temp_t = zeros(1, n_total_comparisons); % Preallocate
        temp_comparison_dataset = zeros(size(temp, 1), 1);
        
        for step = 1:n_total_comparisons
            
            [~, ~, ~, temp_t(step)] = yuend_ttest(temp(1:n_subjects, step), temp_comparison_dataset, 'alpha', alpha_level, 'percent', percent, 'tail', tail);
            
        end % of for step
        
        t_stat(:, iteration) = temp_t;
        
    end % of if use_yuen
    
    % Get the maximum t-value (postive or negative) within the family of tests and store in a
    % vector. This is to create a null hypothesis distribution.
    if strcmp(tail, 'both') == 1 % If using two-tailed testing
        
        % Get the maximum t-value within the family of tests and store in a
        % vector. This is to create a null hypothesis distribution.
        t_sorted = sort(abs(t_stat(:, iteration)), 'descend');

    elseif strcmp(tail, 'right') == 1; % One-tailed testing for positive differences
        
        t_sorted = sort(t_stat(:, iteration), 'descend');
        
    elseif strcmp(tail, 'left') == 1; % One-tailed testing for negative differences
        
        t_sorted = sort(t_stat(:, iteration) .* -1, 'descend');
        
    end % of if strcmp tail
    
   ktms_t_max(iteration) = t_sorted(ktms_u + 1); % Get the u + 1th largest t-value in ktms procedure

    
end % of for iteration

% Calculating the 95th percentile of t_max values (used as decision
% critieria for statistical significance)
ktms_null_cutoff = prctile(ktms_t_max, ((1 - alpha_level) * 100));

% Calculating a p-value for each step
for step = 1:n_total_comparisons
    
    % Implementing a conservative p-value correction based on Phipson &
    % Smyth (2010)
    % Calculate the number of permutation samples with maximum statistics
    % larger than the observed test statistic for a given cluster
    
    if strcmp(tail, 'both') == 1 % If using two-tailed testing
        
        b = sum(ktms_t_max(:) >= abs(uncorrected_t(step)));
        p_t = (b + 1) / (n_iterations + 1); % Calculate conservative version of p-value as in Phipson & Smyth, 2010
        p_t = p_t .* 2; % Doubling of p-value for two-tailed testing (essentially Bonferroni correction for two tests)
        corrected_p(step) = p_t;
        
    elseif strcmp(tail, 'right') == 1 % One-tailed testing for positive differences
        
        b = sum(ktms_t_max(:) >= uncorrected_t(step));
        p_t = (b + 1) / (n_iterations + 1); % Calculate conservative version of p-value as in Phipson & Smyth, 2010
        corrected_p(step) = p_t;
        
    elseif strcmp(tail, 'left') == 1 % One-tailed testing for negative differences
        
        b = sum(ktms_t_max(:) >= uncorrected_t(step) .* -1);
        p_t = (b + 1) / (n_iterations + 1); % Calculate conservative version of p-value as in Phipson & Smyth, 2010
        corrected_p(step) = p_t;
        
    end % of if strcmp tail

end % of for step loop

% Adjusting p-values that are larger than 1 (can occur due to doubling of
% p-values with two-tailed testing)
corrected_p(corrected_p > 1) = 1;

% Mark statistically significant steps
corrected_h(corrected_p < alpha_level) = 1;


%% Copy Output Into Results Structure

Results.corrected_h = corrected_h;
Results.corrected_p = corrected_p;
Results.t_values = uncorrected_t;
Results.critical_t = ktms_null_cutoff;
Results.ktms_u = ktms_u;