function [ANALYSIS] = t_tests_classifier_accuracies(ANALYSIS)
%
% This function runs group-level one-sample or paired-samples t tests 
% on classifier accuracy/regression performance measures derived from 
% each subject. One-sample tests are performed against chance level, 
% and paired-samples tests compare the decoding accuracy using the 
% observed data with decoding accuracy using the permuted data from each 
% subject. The results are added to the ANALYSIS structure.
%
% This function calls the yuend_ttest function, also in DDTBOX. Depending
% on the multiple comparisons method chosen, this function will also call
% one of the multcomp functions included in the toolbox.
%
%
% Inputs:
%
%   ANALYSIS            Structure containing organised data and analysis
%                       parameters set in analyse_decoding_erp
%
%
% Outputs:
%
%   ANALYSIS            Structure containing the data input to the function
%                       plus the results of the statistical analyses.
%
%
% Example:        [ANALYSIS] = t_tests_classifier_accuracies(ANALYSIS)
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Stefan Bode
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



%% Perform Group-Level Tests

% Output that t tests were used to command line
fprintf('\n------------------------------------------------------------------------\nGroup decoding performance analyses using paired-samples t tests\n------------------------------------------------------------------------\n');

for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
        
    for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2) % step/analysis time window
            
        if ANALYSIS.permstats == 1 % If testing against theoretical chance
            
            % chance level = 100 / number conditions
            if ANALYSIS.use_robust == 0 % Student's t
                
                [H, P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:, na, step), ...
                    ANALYSIS.chancelevel, 'Alpha', ANALYSIS.pstats, ...
                    'Tail', ANALYSIS.groupstats_ttest_tail);
                
                T = otherstats.tstat;
                clear otherstats;
                
            elseif ANALYSIS.use_robust == 1 % Yuen's t
                
                % Generate a 'dummy' dataset of chance level values
                chance_level_data_temp = zeros(size(ANALYSIS.RES.all_subj_acc(:, na, step), 1), 1);
                chance_level_data_temp(:) = ANALYSIS.chancelevel;
                
                % Perform Yuen's t test
                [H,P, ~, T, ~, ~, ~, ~] = yuend_ttest(ANALYSIS.RES.all_subj_acc(:, na, step), ...
                    chance_level_data_temp, 'percent', ANALYSIS.trimming, ...
                    'alpha', ANALYSIS.pstats, 'tail', ANALYSIS.groupstats_ttest_tail);
            
            end % of if ANALYSIS.use_robust
            
        elseif ANALYSIS.permstats == 2 % If testing against permutation test results    
            
            if ANALYSIS.drawmode == 1 % If testing against average permuted-labels analysis accuracy scores from each subject.

                if ANALYSIS.use_robust == 0 % Student's t
                    
                    [H, P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:, na, step), ...
                        ANALYSIS.RES.all_subj_perm_acc(:,na,step), ...
                        'Alpha', ANALYSIS.pstats, 'Tail', ANALYSIS.groupstats_ttest_tail);
                    
                    T = otherstats.tstat;
                    clear otherstats;
                
                elseif ANALYSIS.use_robust == 1 % Yuen's t
                    
                    [H,P, ~, T, ~, ~, ~, ~] = yuend_ttest(ANALYSIS.RES.all_subj_acc(:, na, step), ...
                        ANALYSIS.RES.all_subj_perm_acc(:, na, step), 'percent', ANALYSIS.trimming, ...
                        'alpha', ANALYSIS.pstats, 'tail', ANALYSIS.groupstats_ttest_tail);
                    
                end % of if ANALYSIS.use_robust
                
            elseif ANALYSIS.drawmode == 2 % against one randomly drawn value (from all cross-val repetitions for each participant) for stricter test
                
                for sbj = 1:ANALYSIS.nsbj
                    
                    temp = randperm(size(ANALYSIS.RES.all_subj_perm_acc_reps_draw{sbj, na, step}(:,:), 2));
                    drawone = temp(1); clear temp;
                    ANALYSIS.RES.draw_subj_perm_acc(sbj, na, step) = ANALYSIS.RES.all_subj_perm_acc_reps_draw{sbj, na, step}(1, drawone);
                    clear drawone;
                    
                end % of for sbj
                
                if ANALYSIS.use_robust == 0 % Student's t
                    
                    [H,P, ~, otherstats] = ttest(ANALYSIS.RES.all_subj_acc(:,na,step), ...
                        ANALYSIS.RES.draw_subj_perm_acc(:,na,step), ...
                        'Alpha', ANALYSIS.pstats, 'Tail', ANALYSIS.groupstats_ttest_tail);
                    
                    T = otherstats.tstat;
                    clear otherstats;
                
                elseif ANALYSIS.use_robust == 1 % Yuen's t
                    
                    [H,P, ~, T, ~, ~, ~, ~] = yuend_ttest(ANALYSIS.RES.all_subj_acc(:,na,step), ...
                        ANALYSIS.RES.draw_subj_perm_acc(:,na,step), 'percent', ANALYSIS.trimming, ...
                        'alpha', ANALYSIS.pstats, 'tail', ANALYSIS.groupstats_ttest_tail);
                    
                end % of if ANALYSIS.use_robust
            end % if ANALYSIS.drawmode
        end % if ANALYSIS.permstats
       
        % Copy results into ANALYSIS structure
        ANALYSIS.RES.p_ttest(na,step) = P;
        clear P;
        ANALYSIS.RES.h_ttest_uncorrected(na, step) = H;
        clear H;
        ANALYSIS.RES.t_ttest(na,step) = T;
        clear T;
            
    end % of for step
end % of for na



%% Corrections For Multiple Comparisons

ANALYSIS.RES.h_ttest = zeros(size(ANALYSIS.RES.mean_subj_acc, 1), size(ANALYSIS.RES.mean_subj_acc, 2)); % Preallocate

switch ANALYSIS.multcompstats

case 0 % No correction for multiple comparisons

    fprintf('\nCorrection for multiple comparisons has not been applied\n\n');

    ANALYSIS.RES.h_ttest = ANALYSIS.RES.h_ttest_uncorrected; 

case 1 % Bonferroni Correction

    fprintf('\nPerforming corrections for multiple comparisons (Bonferroni)\n\n');

    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding
        
        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
            
            [MCC_Results] = multcomp_bonferroni(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats); % Bonferroni correction

            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.bonferroni_adjusted_alpha(na) = MCC_Results.corrected_alpha;
            fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.bonferroni_adjusted_alpha(na));
            
        end % of for na
  
    elseif ANALYSIS.stmode == 2 % Temporal decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2) % step
            
            [MCC_Results] = multcomp_bonferroni(ANALYSIS.RES.p_ttest(:,step), 'alpha', ANALYSIS.pstats); % Bonferroni correction

            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.bonferroni_adjusted_alpha(step) = MCC_Results.corrected_alpha;
            fprintf('The adjusted critical alpha for step %i is %1.6f \n', step, ANALYSIS.RES.bonferroni_adjusted_alpha(step));
            
        end % of for step
        
    end % of if ANALYSIS.stmode

case 2 % Holm-Bonferroni Correction
    
    fprintf('\nPerforming corrections for multiple comparisons (Holm-Bonferroni)\n\n');

    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding

        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
            
            [MCC_Results] = multcomp_holm_bonferroni(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats); % Holm-Bonferroni correction  

            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.holm_adjusted_alpha(na) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for analysis %i is %1.6f   \n', na, ANALYSIS.RES.holm_adjusted_alpha(na));
            
        end % of for na
   
    elseif ANALYSIS.stmode == 2 % Temporal decoding

        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2) % step
            
            [MCC_Results] = multcomp_holm_bonferroni(ANALYSIS.RES.p_ttest(:, step), 'alpha', ANALYSIS.pstats); % Holm-Bonferroni correction  

            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.holm_adjusted_alpha(step) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for step %i is %1.6f   \n', step, ANALYSIS.RES.holm_adjusted_alpha(step));
            
        end % of for step
        
    end % of if ANALYSIS.stmode
    
case 3 % Strong FWER Control Permutation Test (Blaire-Karniski)
    
    fprintf('\nPerforming corrections for multiple comparisons (maximum statistic permutation test)\n\n');
    
    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding

        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis

            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
                perm_decoding_scores(:, 1, :) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
                    
                end % of if ANALYSIS.drawmode
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            [MCC_Results] = multcomp_blair_karniski_permtest(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'use_yuen', ANALYSIS.use_robust, 'percent', ANALYSIS.trimming, ...
                'tail', ANALYSIS.groupstats_ttest_tail);

            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.p_ttest(na,:) = MCC_Results.corrected_p;
            ANALYSIS.RES.critical_t(na) = MCC_Results.critical_t;
            fprintf('The adjusted critical t value for analysis %i is %3.3f \n', na, ANALYSIS.RES.critical_t(na));
            
        end % of for na
    
        clear real_decoding_scores
        clear perm_decoding_scores
        
    elseif ANALYSIS.stmode == 2 % Temporal decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)

            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), size(real_decoding_scores, 2), 1);
                perm_decoding_scores(:, :, 1) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, :, step);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, :, step);
                    
                end % of if ANALYSIS.drawmode
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            [MCC_Results] = multcomp_blair_karniski_permtest(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'use_yuen', ANALYSIS.use_robust, 'percent', ANALYSIS.trimming, ...
                'tail', ANALYSIS.groupstats_ttest_tail);

            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.p_ttest(:, step) = MCC_Results.corrected_p;
            ANALYSIS.RES.critical_t(step) = MCC_Results.critical_t;
            fprintf('The adjusted critical t value for step %i is %3.3f \n', step, ANALYSIS.RES.critical_t(step));
            
        end % of for step
    
        clear real_decoding_scores
        clear perm_decoding_scores
   
    end % of if ANALYSIS.stmode
   
case 4 % Cluster-Based Permutation Test
 
    fprintf('\nPerforming corrections for multiple comparisons (cluster-based permutation test)\n\n');
    
    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding

        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis

            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
                perm_decoding_scores(:, 1,:) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
                    
                end % of if ANALYSIS.drawmode    
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            % Cluster-based permutation test
            [MCC_Results] = multcomp_cluster_permtest(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'clusteringalpha', ANALYSIS.cluster_test_alpha, 'use_yuen', ANALYSIS.use_robust, ...
                'percent', ANALYSIS.trimming, 'tail', ANALYSIS.groupstats_ttest_tail);
            
            % Copy results into ANALYSIS structure
            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.critical_cluster_mass(na) = MCC_Results.critical_cluster_mass;
            ANALYSIS.RES.n_sig_clusters(na) = MCC_Results.n_sig_clusters;
            ANALYSIS.RES.cluster_masses{na} = MCC_Results.cluster_masses;
            ANALYSIS.RES.cluster_sig{na} = MCC_Results.cluster_sig;
            ANALYSIS.RES.cluster_p{na} = MCC_Results.cluster_p;
            
            % Report cluster-corrected results
            fprintf('The adjusted critical cluster mass for analysis %i is %3.3f \n', na, ANALYSIS.RES.critical_cluster_mass(na));
            fprintf('%i statistically significant cluster(s) were found for analysis %i \n', ANALYSIS.RES.n_sig_clusters, na);

        end % of for na loop
        
        clear real_decoding_scores
        clear perm_decoding_scores    

    elseif ANALYSIS.stmode == 2 % Temporal Decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)

            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), size(real_decoding_scores, 2), 1);
                perm_decoding_scores(:, :, 1) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, :, step);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, :, step);
                    
                end % of if ANALYSIS.drawmode    
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            [MCC_Results] = multcomp_cluster_permtest(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'clusteringalpha', ANALYSIS.cluster_test_alpha, 'use_yuen', ANALYSIS.use_robust, ...
                'percent', ANALYSIS.trimming, 'tail', ANALYSIS.groupstats_ttest_tail);
            
            % Copy results to ANALYSIS structure
            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.critical_cluster_mass(step) = MCC_Results.critical_cluster_mass;
            ANALYSIS.RES.n_sig_clusters(step) = MCC_Results.n_sig_clusters;
            ANALYSIS.RES.cluster_masses{step} = MCC_Results.cluster_masses;
            ANALYSIS.RES.cluster_sig{step} = MCC_Results.cluster_sig;
            ANALYSIS.RES.cluster_p{step} = MCC_Results.cluster_p;
            
            % Report cluster-corrected results
            fprintf('The adjusted critical cluster mass for step %i is %3.3f \n', step, ANALYSIS.RES.critical_cluster_mass(step));
            fprintf('%i statistically significant cluster(s) were found for step %i \n', ANALYSIS.RES.n_sig_clusters, step);

        end % of for step
        
        clear real_decoding_scores
        clear perm_decoding_scores    

    end % of if ANALYSIS.stmode
        
case 5 % KTMS Generalised FWER Control Using Permutation Testing
    
    fprintf('\nPerforming corrections for multiple comparisons (KTMS generalised FWER control)\n\n');

    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding

        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1)
            
            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), 1, size(real_decoding_scores, 3));
                perm_decoding_scores(:, 1,:) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, na, :);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, na, :);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, na, :);
                    
                end % of if ANALYSIS.drawmode
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            [MCC_Results] = multcomp_ktms(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'ktms_u', ANALYSIS.ktms_u, 'use_yuen', ANALYSIS.use_robust, ...
                'percent', ANALYSIS.trimming, 'tail', ANALYSIS.groupstats_ttest_tail);

            % Copy results to ANALYSIS structure
            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.t_values(na, :) = MCC_Results.t_values;
            ANALYSIS.RES.critical_t(na) = MCC_Results.critical_t;
            ANALYSIS.RES.ktms_u(na) = MCC_Results.ktms_u;
            
            % Report results of multiple comparisons correction
            fprintf('The adjusted critical t for analysis %i is %3.3f with u parameter of %i \n', na, ANALYSIS.RES.critical_t(na), ANALYSIS.RES.ktms_u(na)); 
            
        end % of for na loop
        
        clear real_decoding_scores
        clear perm_decoding_scores

    elseif ANALYSIS.stmode == 2 % Temporal decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)

            if ANALYSIS.permstats == 1 % If testing against theoretical chance level
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                perm_decoding_scores = zeros(size(real_decoding_scores, 1), size(real_decoding_scores, 2), 1);
                perm_decoding_scores(:, :, 1) = ANALYSIS.chancelevel;
                
            elseif ANALYSIS.permstats == 2 % If testing against permutation decoding results
                
                real_decoding_scores = ANALYSIS.RES.all_subj_acc(:, :, step);
                
                if ANALYSIS.drawmode == 1 % If testing against average permuted distribution
                    
                    perm_decoding_scores = ANALYSIS.RES.all_subj_perm_acc(:, :, step);
                    
                elseif ANALYSIS.drawmode == 2 % If testing against one randomly drawn value
                    
                    perm_decoding_scores = ANALYSIS.RES.draw_subj_perm_acc(:, :, step);
                    
                end % of if ANALYSIS.drawmode
                
            end % of if ANALYSIS.permstats

            % Convert to two-dimensional matrix for multcomp correction algorithm
            tmp = squeeze(real_decoding_scores);
            real_decoding_scores = tmp;
            tmp = squeeze(perm_decoding_scores);
            perm_decoding_scores = tmp;

            [MCC_Results] = multcomp_ktms(real_decoding_scores, perm_decoding_scores, ...
                'alpha', ANALYSIS.pstats, 'iterations', ANALYSIS.n_iterations, ...
                'ktms_u', ANALYSIS.ktms_u, 'use_yuen', ANALYSIS.use_robust, ...
                'percent', ANALYSIS.trimming, 'tail', ANALYSIS.groupstats_ttest_tail);

            % Copy results to ANALYSIS structure
            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.t_values(:, step) = MCC_Results.t_values;
            ANALYSIS.RES.critical_t(step) = MCC_Results.critical_t;
            ANALYSIS.RES.ktms_u(step) = MCC_Results.ktms_u;
            
            % Report results of multiple comparisons correction
            fprintf('The adjusted critical t for step %i is %3.3f with u parameter of %i \n', na, ANALYSIS.RES.critical_t(step), ANALYSIS.RES.ktms_u(step)); 
            
        end % of for step
        clear real_decoding_scores
        clear perm_decoding_scores

    end % of if ANALYSIS.stmode
        
case 6 % Benjamini-Hochberg FDR Control

    fprintf('\nPerforming corrections for multiple comparisons (Benjamini-Hochberg FDR control)\n\n');
    
    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding
    
        % Here a family of tests is defined as all steps within a given analysis
        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
            
            [MCC_Results] = multcomp_fdr_bh(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);
            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.bh_crit_alpha(na) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for analysis %i is %1.6f \n\n', na, MCC_Results.critical_alpha(na));
            
        end % of for na

    elseif ANALYSIS.stmode == 2 % Temporal decoding
    
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)
            
            [MCC_Results] = multcomp_fdr_bh(ANALYSIS.RES.p_ttest(:, step), 'alpha', ANALYSIS.pstats);
            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.bh_crit_alpha(step) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for step %i is %1.6f \n\n', step, MCC_Results.critical_alpha(step));
            
        end % of for step
    
    end % of if ANALYSIS.stmode
    
case 7 % Benjamini-Krieger-Yekutieli FDR Control
    
    fprintf('\nPerforming corrections for multiple comparisons (Benjamini-Krieger-Yekutieli FDR control)\n\n');

    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding
    
        % Here a family of tests is defined as all steps within a given analysis
        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
            
            [MCC_Results] = multcomp_fdr_bky(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);

            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.bky_crit_alpha(na) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.bky_crit_alpha(na));
            
        end % of for na

    elseif ANALYSIS.stmode == 2 % Temporal Decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)
            
            [MCC_Results] = multcomp_fdr_bky(ANALYSIS.RES.p_ttest(:, step), 'alpha', ANALYSIS.pstats);

            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.bky_crit_alpha(step) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for step %i is %1.6f \n', step, ANALYSIS.RES.bky_crit_alpha(step));
            
        end % of for step
        
    end % of if ANALYSIS.stmode
    
case 8 % Benjamini-Yekutieli FDR Control
    
    fprintf('\nPerforming corrections for multiple comparisons (Benjamini-Yekutieli FDR control)\n\n');

    if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial or spatiotemporal decoding
    
        % Here a family of tests is defined as all steps within a given analysis
        for na = 1:size(ANALYSIS.RES.mean_subj_acc, 1) % analysis
            
            [MCC_Results] = multcomp_fdr_by(ANALYSIS.RES.p_ttest(na,:), 'alpha', ANALYSIS.pstats);

            ANALYSIS.RES.h_ttest(na, :) = MCC_Results.corrected_h;
            ANALYSIS.RES.by_crit_alpha(na) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for analysis %i is %1.6f \n', na, ANALYSIS.RES.by_crit_alpha(na));
            
        end % of for na

    elseif ANALYSIS.stmode == 2 % Temporal decoding
        
        for step = 1:size(ANALYSIS.RES.mean_subj_acc, 2)
            
            [MCC_Results] = multcomp_fdr_by(ANALYSIS.RES.p_ttest(:, step), 'alpha', ANALYSIS.pstats);

            ANALYSIS.RES.h_ttest(:, step) = MCC_Results.corrected_h;
            ANALYSIS.RES.by_crit_alpha(step) = MCC_Results.critical_alpha;
            fprintf('The adjusted critical alpha for step %i is %1.6f \n', step, ANALYSIS.RES.by_crit_alpha(step));
            
        end % of for step
        
    end % of if ANALYSIS.stmode
    
otherwise % If some other option is chosen then do not correct for multiple comparisons, but notify user
        
    fprintf('\nUnavailable multiple comparisons option chosen. Will use uncorrected p-values\n\n');
    ANALYSIS.RES.h_ttest = ANALYSIS.RES.h_ttest_uncorrected; 
    
end % of ANALYSIS.multcompstats switch

% Marking h values (statistical significance) for plotting
ANALYSIS.RES.h = ANALYSIS.RES.h_ttest;
