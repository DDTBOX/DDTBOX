function [Results] = multcomp_cluster_permtest(cond1_data, cond2_data, varargin)
%
% This function receives paired-samples data and outputs corrected p-values and
% null hypothesis test results based on a maximum cluster mass statistic permutation test,
% as described in Bullmore et al. (1999). The permutation test in this script is based
% on the t-statistic from Student's paired-samples t-test, but can also be used
% with the more robust Yuen's paired-samples t test. If using Yuen's t this
% function calls another function yuend_ttest which should be provided with
% DDTBOX.
%
% Bullmore, E. T., Suckling, J., Overmeyer, S., Rabe-Hesketh, S., 
% Taylor, E., & Brammer, M. J. (1999). Global, voxel, and cluster tests, 
% by theory and permutation, for a difference between two groups of 
% structural MR images of the brain. IEEE Transactions on Medical Imaging,
% 18, 32-42. doi 10.1109/42.750253
%
% This function implements a conservative correction for p-values when
% using permutation tests, as described by Phipson & Smyth (2010).
%
% Permutation p-values should never be zero: Calculating exact p-values
% when permutations are randomly drawn. Statistical Applications in
% Genetics and Molecular Biology, 9, 39. doi 10.2202/1544-6115.1585
%
% Please cite these articles when using this multiple comparisons
% correction.
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
% Optional Keyword Inputs
%
%   alpha           uncorrected alpha level for statistical significance, default 0.05
%
%   iterations      number of permutation samples to draw. At least 1000 is
%                   recommended for the p = 0.05 alpha level, and at least 5000 is
%                   recommended for the p = 0.01 alpha level. This is due to extreme events
%                   at the tails being very rare, needing many random permutations to find
%                   enough of them.
%
%   clusteringalpha the significance threshold used to define individual points 
%                   within a cluster. Setting this to larger values (e.g.
%                   0.05) will detect broadly distributed clusters, whereas setting it to
%                   0.01 for example will help detect smaller clusters that exhibit strong effects.
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
% Outputs:
%
%   Results structure containing:
%
%   uncorrected_h   vector of hypothesis tests not corrected for multiple
%                   comparisons.
%
%   corrected_h     vector of hypothesis tests in which statistical significance
%                   is defined by clsuter masses above a threshold of the 
%                   ((1 - alpha_level) * 100)th percentile of the maximum
%                    cluster mass statistic distribution.
%                   1 = statistically significant, 0 = not statistically significant
%
%   t_values        t values from each individual hypothesis test.
%
%   critical_cluster_mass       The threshold of cluster mass statistics
%                               above which clusters are declared
%                               statistically significant. Calculated as the
%                               ((1 - alpha_level) * 100)th of the
%                               maximum cluster mass permutation distribution.
%
%   cluster_p       p_value of each cluster. 
% 
%   cluster_sig     Marks whether each observed cluster is statistically
%                   significant. 1 = sig. / 0 = nonsig.
%
%   cluster_masses  Cluster masses (summed t-values within a cluster) for 
%                   each observed cluster of effects.
%
%   n_clusters      Number of observed clusters of effects
%
%   n_sig_clusters  Number of statistically significant clusters
%
%
% Example:          [Results] = multcomp_cluster_permtest(cond1_data, cond2_data, 'alpha', 0.05, 'iterations', 10000, 'clusteringalpha', 0.01, 'use_yuen', 1, 'percent', 20, 'tail', 'both')
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
%


%% Handling Variadic Inputs

% Define defaults at the beginning
options = struct(...
    'alpha', 0.05,...
    'iterations', 5000,...
    'clusteringalpha', 0.05,...
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

% Renaming variables for use in the function:
alpha_level = options.alpha;
n_iterations = options.iterations;
clustering_alpha = options.clusteringalpha;
use_yuen = options.use_yuen;
percent = options.percent;
tail = options.tail;
clear options;


%% Tests on Observed (Non-Permutation) Data

% Checking whether the number of steps of the first and second datasets are equal
if size(cond1_data, 2) ~= size(cond2_data, 2)
    
   error('Condition 1 and 2 datasets do not contain the same number of comparisons!');
   
end % of if size

if size(cond1_data, 1) ~= size(cond2_data, 1)
    
   error('Condition 1 and 2 datasets do not contain the same number of subjects!');
   
end % of if size

% Generate difference scores between conditions
diff_scores = cond1_data - cond2_data;

n_subjects = size(diff_scores, 1); % Calculate number of subjects
n_total_comparisons = size(diff_scores, 2); % Calculating the number of comparisons

% Preallocate vector of uncorrected h values (1 = sig / 0 = nonsig)
uncorrected_h = zeros(n_total_comparisons, 1);

% Perform t-tests at each step 
if use_yuen == 0 % If using Student's t
    
    [uncorrected_h, ~, ~, extra_stats] = ttest(diff_scores, 0, 'Alpha', clustering_alpha, 'tail', tail);
    uncorrected_t = extra_stats.tstat; % Vector of t statistics from each test

elseif use_yuen == 1 % If using Yuen's t
    
    uncorrected_t = zeros(1, n_total_comparisons); % Preallocate
    
    for step = 1:n_total_comparisons
        
        [uncorrected_h(step), ~, ~, uncorrected_t(step)] = yuend_ttest(cond1_data(:, step), cond2_data(:, step), 'alpha', alpha_level, 'percent', percent, 'tail', tail);
        
    end % of for step
end % of if use_yuen

% Seed the random number generator based on the clock time
rng('shuffle');

% Generate the maximum cluster mass distribution from the randomly-permuted data
t_stat = zeros(n_total_comparisons, n_iterations); % Preallocate
max_cluster_mass = zeros(1, n_iterations); % Preallocate
cluster_perm_test_h = zeros(n_total_comparisons, n_iterations); % Preallocate
t_sign = zeros(n_total_comparisons, n_iterations); % Preallocate

for iteration = 1:n_iterations
    
    % Draw a random permutation sample for each test
    temp = zeros(n_subjects, n_total_comparisons); % Preallocate
    
    % Randomly switch signs of difference scores to create a random
    % partition (permutation sample). Switched signs are consistent across
    % tests within each participant.
    temp_signs = (rand(n_subjects, 1) > .5) * 2 - 1; % Switches signs of labels

    for step = 1:n_total_comparisons 
        
        % Randomly switch the sign of difference scores (equivalent to
        % switching labels of conditions)
        temp(:,step) = temp_signs .* diff_scores(1:n_subjects, step);
        
    end % of for step
    
    % Run t tests
    if use_yuen == 0 % If using Student's t
        
        % Run t tests
        [cluster_perm_test_h(:, iteration), ~, ~, temp_stats] = ttest(temp, 0, 'Alpha', clustering_alpha, 'tail', tail);
        t_stat(:, iteration) = temp_stats.tstat; % Get t statistics

    elseif use_yuen == 1 % If using Yuen's t
        
        temp_comparison_dataset = zeros(size(temp, 1), 1); % Create dummy comparison dataset of zeroes
        
        for step = 1:n_total_comparisons
            
            [cluster_perm_test_h(step, iteration), ~, ~, t_stat(step, iteration)] = yuend_ttest(temp(:, step), temp_comparison_dataset, 'alpha', alpha_level, 'percent', percent, 'tail', tail);
            
        end % of for step
    end % of if use_yuen
        
        % Marking the sign of each t statistic to avoid clustering pos
        % and neg direction significant results
        for step = 1:n_total_comparisons
            
            if t_stat(step, iteration) < 0;
                
                t_sign(step, iteration) = -1; 
                
            else
                
                t_sign(step, iteration) = 1; 
                
            end % of if t_stat
        end % of for step
        
    % Identify clusters and generate a maximum cluster statistic
    cluster_mass_vector = [0]; % Resets vector of cluster masses
    cluster_counter = 0;

    for step = 1:n_total_comparisons    
        
        if cluster_perm_test_h(step, iteration) == 1
            
            if step == 1 % If the first test in the set
                
                cluster_counter = cluster_counter + 1;
                cluster_mass_vector(cluster_counter) = abs(t_stat(step, iteration));
                
            else
                
                % Add to the cluster if there are consecutive
                % statistically significant tests with the same sign.
                % Otherwise, make a new cluster.
                if cluster_perm_test_h(step - 1, iteration) == 1 && t_sign(step - 1, iteration) == t_sign(step, iteration)
                    
                    cluster_mass_vector(cluster_counter) = cluster_mass_vector(cluster_counter) + abs(t_stat(step, iteration));
                    
                else
                    
                    cluster_counter = cluster_counter + 1;
                    cluster_mass_vector(cluster_counter) = abs(t_stat(step, iteration));
                    
                end % of if cluster_perm_test_h
            end % of if step
        end % of if cluster_perm_test_h
    end % of for step

    % Find the maximum cluster mass
    max_cluster_mass(iteration) = max(cluster_mass_vector);
    
end % of for iteration

% Calculating the 95th percentile of maximum cluster mass values (used as decision
% critieria for statistical significance)
cluster_mass_null_cutoff = prctile(max_cluster_mass, ((1 - alpha_level) * 100));

% Calculate cluster masses in the actual (non-permutation) tests
cluster_mass_vector = [0]; % Resets vector of cluster masses
cluster_counter = 0;
cluster_locations = zeros(1, n_total_comparisons);
cluster_corrected_sig_steps = zeros(1, n_total_comparisons);
clear t_sign;

for step = 1:n_total_comparisons   
    
    if uncorrected_h(step) == 1
        
        if step == 1 % If the first test in the set
            
            cluster_counter = cluster_counter + 1;
            cluster_mass_vector(cluster_counter) = abs(uncorrected_t(step));
            cluster_locations(step) = cluster_counter;
            % Tagging as positive or negative sign effect
            
            if uncorrected_t < 0
                
                t_sign(step) = -1;
                
            else
                
                t_sign(step) = 1;
                
            end % of if uncorrected_t
            
        elseif step > 1
            
            % Tagging as positive or negative sign effect
            if uncorrected_t < 0
                
                t_sign(step) = -1;
                
            else
                
                t_sign(step) = 1;
                
            end % of if uncorrected_t

            % Add to the same cluster only if the previous test was sig.
            % and of the same sign (direction).
            if uncorrected_h(step - 1) == 1 && t_sign(step - 1) == t_sign(step)
                
                cluster_mass_vector(cluster_counter) = cluster_mass_vector(cluster_counter) + abs(uncorrected_t(step));
                cluster_locations(step) = cluster_counter;
                
            else
                
                cluster_counter = cluster_counter + 1;
                cluster_mass_vector(cluster_counter) = abs(uncorrected_t(step));
                cluster_locations(step) = cluster_counter;
                
            end % of if uncorrected_h
        end % of if step
    end % of if uncorrected_h(step)  
end % of for step


%% Calculate P-Values For Each Cluster

% Calculating a p-value for each cluster
% p-values are corrected according to Phipson and Smyth (2010) methods
cluster_p = ones(length(cluster_mass_vector), 1); % Preallocate p-values

for cluster_no = 1:length(cluster_mass_vector)
    
    % Calculate the number of permutation samples with cluster masses
    % larger than the observed cluster mass for a given cluster
    b = sum(abs(max_cluster_mass) >= abs(cluster_mass_vector(cluster_no)));
    p_t = (b + 1) / (n_iterations + 1); % Calculate conservative version of p-value as in Phipson & Smyth, 2010
    
    if strcmp(tail, 'both') == 1 % If using two-tailed testing
        
        p_t = p_t .* 2; % Doubling of p-value for two-tailed testing (essentially Bonferroni correction for two tests)
        
    end % of if strcmp tail

    cluster_p(cluster_no) = p_t; % P-value for each cluster
    
end % of for cluster_no

% Check whether the p-value of each cluster is smaller than the critical
% alpha level
cluster_sig = zeros(length(cluster_mass_vector), 1); % Preallocate vector that marks sig. clusters

for cluster_no = 1:length(cluster_mass_vector);
    
    if cluster_p(cluster_no) < alpha_level % if cluster is statistically significant
        
        % Mark tests within cluster as significant
        cluster_corrected_sig_steps(cluster_locations == cluster_no) = 1;    
        cluster_sig(cluster_no) = 1;
        
    end % of if cluster_p
end % of for cluster_no

% Update analysis structure with cluster-corrected significant time
% windows
corrected_h = cluster_corrected_sig_steps;


%% Copy Output into Results Structure

Results.uncorrected_h = uncorrected_h;
Results.corrected_h = corrected_h;
Results.t_values = uncorrected_t;
Results.critical_cluster_mass = cluster_mass_null_cutoff;
Results.cluster_p = cluster_p;
Results.cluster_sig = cluster_sig;
Results.cluster_masses = cluster_mass_vector;
Results.n_clusters = length(cluster_mass_vector);
Results.n_sig_clusters = sum(cluster_sig);