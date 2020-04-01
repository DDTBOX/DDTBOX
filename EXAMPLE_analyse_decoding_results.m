% EXAMPLE_analyse_decoding_results.m
%
% This script is used for specifying settings for group-level analyses of
% decoding results using DDTBOX. All analysis parameters are specified in
% this script and passed to analyse_decoding_erp.m
%
% More information about analysis and plotting options, as well as 
% a tutorial on performing group analyses on MVPA results, can be 
% found in the DDTBOX wiki, available at: 
% https://github.com/DDTBOX/DDTBOX/wiki
%
%
% Copyright (c) 2013-2019: DDTBOX has been developed by Stefan Bode 
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




%% Housekeeping

% Clears the workspace and closes all figure windows
clear variables;
close all;




%% Select Subject Datasets and Discrimination Groups (dcgs)

% Set which subjects to include in group analyses.
% Example: sbjs_todo = [1:10] for subject numbers 1 to 10
sbjs_todo = [1:10];

% Enter the discrimination group for classification. 
% Example: dcg_todo = [1]
% Two discrimination groups can be entered as a vector when using cross-condition decoding.
% Example for cross-decoding: dcg_todo = [1, 2]
dcg_todo = [1];

% Was cross-condition decoding performed? 
% 0 = no / 1 = yes
cross = 0;




%% Filepaths and Locations of Subject Datasets

% Enter the name of the study (used for labeling saved decoding results files)
study_name = 'EXAMPLE';

% Base directory path
bdir = '/Desktop/My Study/';

% Output directory (where decoding results have been saved)
output_dir = '/Desktop/My Study/Decoding Results/';




%% EEG Dataset Information

nchannels = 64; % Number of channels
channel_names_file = 'channel_information.mat'; % Name of .mat file containing channel labels and channel locations
channellocs = [bdir, 'Channel Locations/']; % Path of directory containing channel information file (within the base directory)
sampling_rate = 1000; % Data sampling rate in Hz
pointzero = 100; % Corresponds to the time of the event/trigger code relative to the start of the epoch (in ms)




%% Condition and Discrimination Group (dcg) Information

% Label each condition
% Usage: cond_labels{condition number} = 'Name of condition';
% Example: cond_labels{1} = 'Correct Responses';
% Condition label {X} corresponds to data in column X of the single subject
% data arrays.
cond_labels{1} = 'condition_A';
cond_labels{2} = 'condition_B';
cond_labels{3} = 'condition_C';
cond_labels{4} = 'condition_D';
        
% Discrimination groups
% Enter the condition numbers of the conditions to discriminate between
% Usage: dcg{discrimination group number} = [condition 1, condition 2];
% Example: dcg{1} = [2, 3]; to compare conditions 2 and 3 for dcg 1
dcg{1} = [1, 3]; 
dcg{2} = [2, 4]; 
              
% Label each discrimination group
% Usage: dcg_labels{Discrimination group number} = 'Name of discrimination group'
% Example: dcg_labels{1} = 'Correct vs. Error Responses';
dcg_labels{1} = 'A vs. C';
dcg_labels{2} = 'B vs. D';


% This section automaticallly fills in various parameters related to dcgs and conditions 
ndcg = size(dcg, 2);
nclasses = size(dcg{1}, 2);      
ncond = size(cond_labels, 2);




%% Decoding Performance Analysis Parameters

% Specify the type of decoding analysis that was performed:
analysis_mode = 1; % ANALYSIS mode (1 = SVM classification with LIBSVM / 2 = SVM classification with LIBLINEAR / 3 = SVR with LIBSVM)
stmode = 1; % SPACETIME mode (1 = spatial / 2 = temporal / 3 = spatio-temporal)
avmode = 1; % AVERAGE mode (1 = no averaging; single-trial / 2 = run-averaged data) 
window_width_ms = 10; % Width of sliding analysis window in ms
step_width_ms = 10; % Step size with which sliding analysis window was moved through the trial

% Specify alpha level
pstats = 0.05; % critical p-value

% Select group-level statistical analysis method 
% 1 = Global null and population prevalence tests based on the minimum statistic
% 2 = Global null testing using paired-samples t tests
group_level_analysis_method = 1; 

% For spatial and spatiotemporal decoding results only:
% Last step (analysis time window) within the epoch to 
% include in group analyses. If left blank then this will
% be prompted at the command line while running group analyses.
% Example: laststep = [10] to perform tests on decoding results from analysis time windows 1 to 10.
laststep = []; 

% For temporal decoding results only:
allchan = 1; % Are all possible channels analysed? 1 = yes (default for spatial or spatio-temporal decoding) / 2 = no
relchan = []; % Specify channels to be analysed (for temporal decoding only)


%__________________________________________________________________________
% If using the minimum statistic method for group-level analyses:

P2 = 100000; % Number of second-level permutations to use

% Correct for multiple comparisons using the maximum statistic approach:
% 0 = no correction
% 1 = correction based on the maximum statistic (also applied to population prevalence estimates)
minstat_multcomp = 1; 


%__________________________________________________________________________
% If using paired-samples t tests for group-level analyses:

permstats = 2; % Testing against: 1 = theoretical chance level / 2 = permutation test results

% Testing against: 
% 1 = subject-averaged permuted labels decoding results (default)
% 2 = results of random permuted labels analysis repetitions drawn from each subject (stricter)
drawmode = 1; 

% Choose between two-tailed or one-tailed tests. 
% 'both' = two-tailed 
% 'right' or 'left' = one-tailed testing for above/below chance accuracy
groupstats_ttest_tail = 'right'; 

use_robust = 0; % Use Yuen's t, a robust version of the t test? 0 = no / 1 = yes
trimming = 20; % If using Yuen's t, select the trimming percentage for the trimmed mean

multcompstats = 0; % Correction for multiple comparisons: 
                    % 0 = no correction
                    % 1 = Bonferroni correction
                    % 2 = Holm-Bonferroni correction
                    % 3 = Strong FWER Control Permutation Test
                    % 4 = Cluster-Based Permutation Test
                    % 5 = KTMS Generalised FWER Control
                    % 6 = Benjamini-Hochberg FDR Control
                    % 7 = Benjamini-Krieger-Yekutieli FDR Control
                    % 8 = Benjamini-Yekutieli FDR Control
n_iterations = 5000; % Number of permutation or bootstrap iterations for resampling-based multiple comparisons correction procedures
ktms_u = 2; % u parameter for the KTMS GFWER control procedure
cluster_test_alpha = 0.05; % For cluster-based tests: Significance threshold for inclusion of individual time windows into clusters




%% Decoding Performance Plotting Options

disp.on = 1; % Display a results figure? 0 = no / 1 = yes
permdisp = 1; % Display results from permuted labels analyses in the figure as separate line? 0 = no / 1 = yes
disp.sign = 1; % Mark statistically significant steps in results figure? 0 = no / 1 = yes
plot_robust = 0; % Choose estimate of location to plot. 0 = arithmetic mean / 1 = trimmed mean / 2 = median
plot_robust_trimming = 20; % Percentage trimming if using the trimmed mean
disp.plotting_mode = 'classic'; % Plotting style (options include 'cooper' and 'classic')
disp.temporal_decoding_colormap = 'jet'; % Colormap for temporal decoding scalp maps (default 'jet')
disp.x_tick_spacing_steps = [5]; % Number of time steps between X axis time labels. If set to empty ([]) then plotting defaults are used.



%% Feature Weights Analysis Options

fw.do = 1; % Analyse feature weights? 0 = no / 1 = yes
fw.corrected = 1; % Use feature weights corrected using Haufe et al. (2014) method? 0 = no / 1 = yes
fw.steps_for_testing = []; % Time steps at which to perform statistical analyses on feature weights.
                           % Example: fw.steps_for_testing = [5:10]
                           % Input [] (empty vector) to manually input to 
                           % the command line during FW analyses.
fw.pstats = 0.05; % Alpha level for feature weights analyses
fw.use_robust = 0; % Use Yuen's t, a robust version of the t test? 0 = no / 1 = yes
fw.trimming = 20; % If using Yuen's t, select the trimming percentage for the trimmed mean
fw.ttest_tail = 'right'; % t test tail for feature weights analyses. Should be set to 'right' for all standard analyses of FWs

fw.multcompstats = 1; % Feature weights correction for multiple comparisons:
                        % 1 = Bonferroni correction
                        % 2 = Holm-Bonferroni correction
                        % 3 = Strong FWER Control Permutation Test
                        % 4 = Cluster-Based Permutation Test (Currently not available)
                        % 5 = KTMS Generalised FWER Control
                        % 6 = Benjamini-Hochberg FDR Control
                        % 7 = Benjamini-Krieger-Yekutieli FDR Control
                        % 8 = Benjamini-Yekutieli FDR Control
fw.n_iterations = 5000; % Number of permutation or bootstrap iterations for resampling-based multiple comparisons correction procedures
fw.ktms_u = 0; % u parameter of the KTMS GFWER control procedure




%% Display Settings For Feature Weights Results 

fw.disp_steps = []; % Consecutive time steps for which the feature weights matrix should be displayed
fw.colormap = 'jet'; % Colormap for plotting of feature weights heat maps

% _________________________________________________________________________

% Display? 0 = no / 1 = yes

fw.display_matrix = 1; % Feature weights matrix

% Maps and stats averaged over selected analysis time windows
fw.display_average_zmap = 1; % Z-standardised absolute FWs
fw.display_average_uncorr_threshmap = 1; % Map of statistically significant FWs (uncorrected for multiple comparisons)
fw.display_average_corr_threshmap = 1; % Map of statistically significant FWs (corrected for multiple comparisons)

% Maps and stats for each selected analysis time window, plotted separately
fw.display_all_zmaps = 1; % Z-standardised absolute FWs
fw.display_all_uncorr_thresh_maps = 1; % Map of statistically significant FWs (uncorrected for multiple comparisons)
fw.display_all_corr_thresh_maps = 1; % Map of statistically significant FWs (corrected for multiple comparisons)




%% Copy All Settings Into ANALYSIS Structure

% This structure is passed as a single input argument to analyse_decoding_erp
% No user input is required for this section

ANALYSIS.bdir = bdir;
ANALYSIS.output_dir = output_dir;
ANALYSIS.nchannels = nchannels;
ANALYSIS.channel_names_file = channel_names_file;
ANALYSIS.channellocs = channellocs;
ANALYSIS.sampling_rate = sampling_rate;
ANALYSIS.pointzero = pointzero;
ANALYSIS.cond_labels = cond_labels;
ANALYSIS.dcg = dcg;
ANALYSIS.dcg_labels = dcg_labels;
ANALYSIS.ndcg = ndcg;
ANALYSIS.nclasses = nclasses;
ANALYSIS.ncond = ncond;
ANALYSIS.study_name = study_name;
ANALYSIS.sbjs_todo = sbjs_todo;
ANALYSIS.dcg_todo = dcg_todo;
ANALYSIS.cross = cross;
ANALYSIS.allchan = allchan;
ANALYSIS.relchan = relchan;
ANALYSIS.analysis_mode = analysis_mode;
ANALYSIS.stmode = stmode;
ANALYSIS.avmode = avmode;
ANALYSIS.window_width_ms = window_width_ms;
ANALYSIS.step_width_ms = step_width_ms;
ANALYSIS.laststep = laststep;
ANALYSIS.pstats = pstats;
ANALYSIS.group_level_analysis_method = group_level_analysis_method;
ANALYSIS.P2 = P2;
ANALYSIS.minstat_multcomp = minstat_multcomp;
ANALYSIS.permstats = permstats;
ANALYSIS.drawmode = drawmode;
ANALYSIS.groupstats_ttest_tail = groupstats_ttest_tail;
ANALYSIS.use_robust = use_robust;
ANALYSIS.trimming = trimming;
ANALYSIS.multcompstats = multcompstats;
ANALYSIS.n_iterations = n_iterations;
ANALYSIS.ktms_u = ktms_u;
ANALYSIS.cluster_test_alpha = cluster_test_alpha;
ANALYSIS.disp.on = disp.on;
ANALYSIS.permdisp = permdisp;
ANALYSIS.disp.sign = disp.sign;
ANALYSIS.disp.plotting_mode = disp.plotting_mode;
ANALYSIS.disp.temporal_decoding_colormap = disp.temporal_decoding_colormap;
ANALYSIS.disp.x_tick_spacing_steps = disp.x_tick_spacing_steps;
ANALYSIS.plot_robust = plot_robust;
ANALYSIS.plot_robust_trimming = plot_robust_trimming;
ANALYSIS.fw.do = fw.do;
ANALYSIS.fw.corrected = fw.corrected;
ANALYSIS.fw.steps_for_testing = fw.steps_for_testing;
ANALYSIS.fw.pstats = fw.pstats;
ANALYSIS.fw.use_robust = fw.use_robust;
ANALYSIS.fw.trimming = fw.trimming;
ANALYSIS.fw.ttest_tail = fw.ttest_tail;
ANALYSIS.fw.multcompstats = fw.multcompstats;
ANALYSIS.fw.n_iterations = fw.n_iterations;
ANALYSIS.fw.ktms_u = fw.ktms_u;
ANALYSIS.fw.display_matrix = fw.display_matrix;
ANALYSIS.fw.disp_steps = fw.disp_steps;
ANALYSIS.fw.colormap = fw.colormap;
ANALYSIS.fw.display_average_zmap = fw.display_average_zmap;
ANALYSIS.fw.display_average_uncorr_threshmap = fw.display_average_uncorr_threshmap;
ANALYSIS.fw.display_average_corr_threshmap = fw.display_average_corr_threshmap;
ANALYSIS.fw.display_all_zmaps = fw.display_all_zmaps;
ANALYSIS.fw.display_all_uncorr_thresh_maps = fw.display_all_uncorr_thresh_maps;
ANALYSIS.fw.display_all_corr_thresh_maps = fw.display_all_corr_thresh_maps;



%% Analyse Decoding Results For Specified Subjects and dcgs

analyse_decoding_erp(ANALYSIS);