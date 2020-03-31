function decoding_erp(cfg)
%
% Performs MVPA on a single subject dataset. This function (and
% subfunctions prepare_my_vectors_erp and do_my_classification) extract
% data from prespecified time windows, sorts the data for classification or
% regression, assigns condition labels to each exemplar, and then performs
% MVPA by training and testing a classifier or regression model.
%
%
% Inputs:
%
%   cfg structure containing subject dataset information and decoding analysis
%   parameters. Information about each parameter is described in the
%   project wiki and in the example configuration script 
%   (EXAMPLE_run_decoding_analyses.m)
%
%		
% Optional keyword inputs:
%
%
% Usage:           decoding_erp(cfg)
%
%
% Copyright (c) 2013-2019: DDTBOX has been developed by Stefan Bode 
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



%% Section 1: Define Analysis Parameters

cfg.sbj_todo = cfg.sbj;

% Analysis mode label
if cfg.analysis_mode == 1 
    
    cfg.analysis_mode_label = 'SVM_LIBSVM';
    
elseif cfg.analysis_mode == 2 
    
    cfg.analysis_mode_label = 'SVM_LIBLIN';
    
elseif cfg.analysis_mode == 3
    
    cfg.analysis_mode_label = 'SVR_LIBSVM';
    
end % of if cfg.analysis_mode

% Adjust window and step widths using the sampling rate
cfg.window_width = floor(cfg.window_width_ms / ((1/cfg.sampling_rate) * 1000));
cfg.step_width = floor(cfg.step_width_ms / ((1/cfg.sampling_rate) * 1000));

% % Set dcg label for current analysis
% cfg.dcg_label = cfg.dcg_labels{cfg.dcg_todo};

% cross-validation defaults for single-trial decoding
cfg.n_all_analyses = cfg.cross_val_steps * cfg.n_rep_cross_val;
cfg.n_all_permutation = cfg.cross_val_steps * cfg.permut_rep;

if cfg.cross == 0 % If not performing cross-decoding
    
    fprintf('\nDCG %d will be analysed. \n',cfg.dcg_todo);     
    
elseif cfg.cross > 0
    
    fprintf('\nDCG %d and %d will be analysed for cross-condition classification. \n', cfg.dcg_todo(1), cfg.dcg_todo(2));
    
end % of if cfg.cross

% For SVR dcg_todo defines condition that the target variable comes from 
% (to be saved in cfg.regress_struct_name(rows = trials; columns = variable values)
if cfg.analysis_mode == 3 
    
    cfg.regr_todo = cfg.svr_cond_labels{cfg.dcg_todo};
    
end % of if cfg.analysis_mode
    
% Report information related to trial numbers and cross-validation settings
fprintf('\nCross-validation defaults for single-trial decoding:\n');
fprintf('\n%d steps with %d cycles resulting in %d analyses.\n', cfg.cross_val_steps, cfg.n_rep_cross_val, cfg.n_all_analyses);
fprintf('\nBalanced number of examples will be used for all analyses by default.\n');

if cfg.perm_test == 1 % if also doing permuted labels analyses
    
    fprintf('\nRandom-label analysis will be based on %d analyses.\n', cfg.n_all_permutation);
    
end % of if cfg.perm_test

%% LIBSVM and LIBLINEAR flags

% LIBSVM and LIBLINEAR require input flags (as strings) to specify the type of model that will be used for decoding.
% WARNING: Do not change these flags unless you really know what you are doing!!!

% For the full list of flags and their options see
% LIBSVM:    https://www.csie.ntu.edu.tw/~cjlin/libsvm/
% LIBLINEAR: https://www.csie.ntu.edu.tw/~cjlin/liblinear/
% The following flags are currently used as defaults in DDTBox

% -c cost : cost parameter

% The available backends are

% LIBSVM
% -s svm_type : set the type of support vector machine
% 	0 -- C-Support Vector Classification
% 	1 -- nu-Support Vector Classification
% 	2 -- one-class Support Vector Machine
% 	3 -- epsilon-Support Vector Regression
% 	4 -- nu-Support Vector Regression
% -t kernel_type : set type of kernel function
% 	0 -- linear: u'*v
% 	1 -- polynomial: (gamma*u'*v + coef0)^degree
% 	2 -- radial basis function: exp(-gamma*|u-v|^2)
% 	3 -- sigmoid: tanh(gamma*u'*v + coef0)

% LIBLINEAR
% -s svm_type:
%	 0 -- L2-regularized logistic regression (primal)
%	 1 -- L2-regularized L2-loss support vector classification (dual)
%	 2 -- L2-regularized L2-loss support vector classification (primal)
%	 3 -- L2-regularized L1-loss support vector classification (dual)
%	 4 -- support vector classification by Crammer and Singer
%	 5 -- L1-regularized L2-loss support vector classification
%	 6 -- L1-regularized logistic regression
%	 7 -- L2-regularized logistic regression (dual)
%	11 -- L2-regularized L2-loss support vector regression (primal)
%	12 -- L2-regularized L2-loss support vector regression (dual)
%	13 -- L2-regularized L1-loss support vector regression (dual)


% Defaults:
% Support Vector Classification with libsvm - '-s 0 -t 0 -c 1'
% Support Vector Regression with libsvm - '-s 3 -t 0 -c 0.1'
% Support Vector Regression (continuous) with libsvm - '-s 3 -t 0 -c 0.1'
% Support Vector Classification with liblinear - '-s 2 -c 1'

if cfg.analysis_mode == 1 % SVM classification with LIBSVM
    
    cfg.backend_flags.svm_type = 0;
    cfg.backend_flags.kernel_type = 0;
    cfg.backend_flags.cost = 1;
    cfg.backend_flags.extra_flags = []; % To input additional flag types
    
elseif cfg.analysis_mode == 2 % SVM with LIBLINEAR
    
    cfg.backend_flags.svm_type = 2;
    cfg.backend_flags.kernel_type = -1; % not valid for liblinear
    cfg.backend_flags.cost = 1;
    cfg.backend_flags.extra_flags = [];
    
elseif cfg.analysis_mode == 3 % SVR (regression)  with LIBSVM
    
    cfg.backend_flags.svm_type = 3;
    cfg.backend_flags.kernel_type = 0;
    cfg.backend_flags.cost = 0.1;
    cfg.backend_flags.extra_flags = []; 
    
end % of if cfg.analysis_mode

% Define 'quiet mode' flag to suppress output if selected by user
if cfg.quiet_mode == 1 % If using quiet mode
        
    cfg.backend_flags.quiet_mode_flag = ' -q ';

else

    cfg.backend_flags.quiet_mode_flag = ' ';

end % of if cfg.quiet_mode

% Merging all flags (except quiet mode flag) into a single string
cfg.backend_flags.all_flags = ['-s ', int2str(cfg.backend_flags.svm_type), ' -c ', num2str(cfg.backend_flags.cost)];

% LIBSVM specific options
if cfg.backend_flags.kernel_type ~= -1
    
	cfg.backend_flags.all_flags = [cfg.backend_flags.all_flags, ' -t ', int2str(cfg.backend_flags.kernel_type)];
    
end % of if cfg.backend_flags.kernel_type

% Add any extra flags defined by the user and quiet mode flag
cfg.backend_flags.all_flags = [cfg.backend_flags.quiet_mode_flag, cfg.backend_flags.all_flags, ' ', cfg.backend_flags.extra_flags];



%% Section 2: Read In Data
% basic data in: eeg_sorted_cond{run, cond}(timepoints, channels, trials)
% *** converted into work_data{run, cond}(timepoints, channels, trials)

fprintf('\nReading in data. Please wait... \n');
open_name = (cfg.data_open_name);
load(open_name);
fprintf('\nData loading complete.\n');

% read in regression labels if performing SVR
if cfg.analysis_mode == 3
    
    cfg.regress_open_name = cfg.regress_label_name;
    cfg.regress_data = load(cfg.regress_open_name);    
    fprintf('\nLoaded regressand labels.\n');

end % of if cfg.analysis_mode

work_data = eval(cfg.data_struct_name); % Copies eeg_sorted_cond data into work_data
cfg.nchannels=cfg.nchannels;

% If data is stored in a structure and not a cell, then convert into cell
% array format
if isstruct(work_data)
    
    fprintf('\nConverting EEG-structure into cell.\n');
    wd = struct2cell(work_data); 
    clear work_data;
    
    for i = 1:size(wd, 2)
        
        for j = 1:size(wd, 3)
            
            temp(:,:,:) = wd{1,i,j}(:,:,:);
            temp = double(temp);
            work_data{i,j} = temp;
            clear temp;
            
        end % of for j
    end % of for i
end % of if isstruct

clear wd;
clear eeg_sorted_cond;

% If channel and timepoint data dimensions are flipped (e.g, when taken directly from EEGlab):
if size(work_data{1,1}, 1) == cfg.nchannels && size(work_data{1,1}, 2) ~= cfg.nchannels  
    
    for row = 1:size(work_data, 1)
        
        for column = 1:size(work_data, 2)
            
            temp(:,:,:) = work_data{row,column}(:,:,:);
            temp = permute(temp, [2 1 3]);
            work_data{row,column} = temp;
            clear temp;  
            
        end % of for column        
    end % of for row
    
    fprintf('\nData was converted into the correct format: eeg_sorted_cond{run,cond}(timepoints,channels,trials).\n\n');   

elseif size(work_data{1,1}, 1) ~= cfg.nchannels && size(work_data{1,1}, 2) == cfg.nchannels  
    
    fprintf('\nData seems to be in the correct format: eeg_sorted_cond{run,cond}(timepoints,channels,trials).\n\n');
    
elseif size(work_data{1,1}, 1) == cfg.nchannels && size(work_data{1,1}, 2) == cfg.nchannels
    
    fprintf('\nNumber of channels = number of time points? Check whether data is in the correct format.\n\n');
    
elseif size(work_data{1,1}, 1) ~= cfg.nchannels && size(work_data{1,1}, 2) ~= cfg.nchannels 
    
    fprintf('\nData might not be in the required format: eeg_sorted_cond{run,cond}(timepoints,channels,trials). \n\n');
    
end % of if size work_data


%% Section 3: Reduce To Specified DCGs / Conditions

% Variables in the cfg structure defines all DCG with their respective conditions. In
% this section, work_data is reduced to the specified conditions
% *** work_data will be reduced to reduced_data{dcg, run, cond}(timepoints, channels, trials)

if cfg.analysis_mode ~= 3 % SVR does not require conditions
          
    for r = 1:size(work_data, 1) % for all runs

        % go through either one DCG (regular) or two DCGs (cross-condition decoding)
        for d = 1:size(cfg.dcg_todo, 2)
            
            for cond = 1:size(cfg.dcg{cfg.dcg_todo(d)}, 2) % for all conditions specified

                fprintf('Run %d: Extracting condition %d as specified in DCG %d.\n', r, (cfg.dcg{cfg.dcg_todo(d)}(cond)), cfg.dcg_todo(d));
                temp(:,:,:) = work_data{r, (cfg.dcg{cfg.dcg_todo(d)}(cond))}(:,:,:);
                reduced_data{d, r, cond} = temp; 
                clear temp;                    

            end % of for cond    
        end % of for d
    end % of for r 

elseif cfg.analysis_mode == 3 % If using SVR
    
    reduced_data{1,:,:} = work_data{:,:}; 
    
end % of if STUDY.analysis_mode

cfg.nconds = size(reduced_data, 3); % Calculates the number of conditions
clear work_data;


%% Section 4: Calculate The Minimum Number of Trials Per Condition
% Find the minimum number of trials for each condition in each
% discrimination group. The number of trials in each condition will be
% reduced to the minimum number of trials across all conditions, in order
% to have balanced data across conditions.
% If some trials need to be removed for a condition, then trials 
% will be allocated to that condition via random selection.
% *** clean_data will be converted to balanced_data{dcg, run, cond}(timepoints, channels, trials)

% Calculate min number of trials across conditions
for r = 1:size(reduced_data, 2)
    
    mintrs = []; % Vector of minimum numbers of trials
    
    for d = 1:size(reduced_data, 1)
        
        for cond = 1:size(reduced_data, 3)

            temp = reduced_data{d, r, cond};
            ntrials_cond = size(temp, 3);
            mintrs = [mintrs, ntrials_cond];
            clear temp;

        end % of for cond
    end % of for d 
    
    % Minimum per run (all DCGs)
    cfg.mintrs_min(r) = min(mintrs);
    
end % of for r

fprintf('\nMinimum number of trials per condition computed for participant %d \n', cfg.sbj_todo);

% select min trials in all conditions
for r = 1:size(reduced_data, 2)
    
    for d = 1:size(reduced_data, 1)
        
        for cond = 1:size(reduced_data, 3)

            % extract min number epochs for this DCG and run. If the
            % minimum number of epochs is less than the full data set, a
            % random subset of epochs is selected
            temp_data = reduced_data{d, r, cond};
            random_trials = sort(randperm(size(temp_data, 3), cfg.mintrs_min(r)));
            balanced_data{d, r, cond} = temp_data(:, :, random_trials);

            clear temp_data;
            clear random trials;
            

        end % of for cond          
    end % of for d
end % of for r

fprintf('\nSame number of trials used for all conditions within each run.\n');
clear reduced_data;


%% Section 5: Calculate Run-Averages / Pool Data Across Runs
% Data is either averaged across trials within runs: mean_balanced_data{run, cond}(timepoints, channels)
% or pooled across runs (if available): pooled_balanced_data{DCG, 1, cond}(timepoints, channels, trials)
% if only one run available, data will be unchanged: balanced_data will be
% replaced by mean_balanced_data

if cfg.avmode == 1 % single-trials 
    
    for d = 1:size(balanced_data, 1)
        
        for cond = 1:size(balanced_data, 3)
            
            for r = 1:size(balanced_data, 2)

                if r == 1
                    
                    all_data = balanced_data{d, r, cond};
                    
                elseif r > 1
                    
                    all_data = cat(3, all_data,balanced_data{d, r, cond});
                    
                end % of if r
            end % of for r
            
            pooled_balanced_data{d, 1, cond} = all_data;
            clear all_data;
            
        end % of for cond
    end % of for d
    
    fprintf('\nData from all runs (if more than one) have been pooled into one dataset.\n\n');    
    
elseif cfg.avmode == 2 % run averages
    
    for d = 1:size(balanced_data, 1)
        
        for r = 1:size(balanced_data, 2)
            
            for cond = 1:size(balanced_data, 3)

                mean_balanced_data{d, r, cond} = mean(balanced_data{d, r, cond}, 3);

            end % of for cond        
        end % of for r
    end % of for d
    
    fprintf('\nRun averages based across trials were computed for each condition.\n\n');
    
end % of if cfg.avmode

clear balanced_data;


%% Section 6: Sort Data For Classification
% output of this section:
%
% training_set{dcg, condition, cross-validation step, cycles of cross-validation}(datapoints, channels, trials/exemplars)
% test_set{dcg, condition, cross-validation step, cycles of cross-validation}(datapoints, channels, trials/exemplars)
%
% for run-averaged data the cross-validation steps = number of runs and
% one cycle of cross-validation only
% every cell contains one data-points x channels (x exemplars for one classification 
% step = trials / not necessary for run-average decoding) matrix

%% Single-Trial Data 
% all runs are pooled. Data is randomly drawn from all data
if cfg.avmode == 1
    
    % take X% of data as test data with X-fold cross-validation
    % repeat X-times with different test data sets
    for con = 1:size(pooled_balanced_data, 3) % For condition
        
        ntrs_set = floor(size(pooled_balanced_data{d,1,con}(:,:,:), 3) / cfg.cross_val_steps);
        
        for ncv = 1:cfg.n_rep_cross_val % For cross-validation step
            
            % draw x times without replacement
            random_set = randperm(ntrs_set * cfg.cross_val_steps);
            x = 1;
            
            for cv = 1:cfg.cross_val_steps
                
                % find the test-trials for current cross-validation step
                test_trials = random_set(x:(x + (ntrs_set - 1)));
                
                for d = 1:size(pooled_balanced_data, 1)
                    
                    % reduce data set to the trials * number of sets (after dividing in X% sets)
                    temp_training_set = pooled_balanced_data{d,1,con}(:,:,1:(ntrs_set * cfg.cross_val_steps));
                    
                    if cfg.analysis_mode == 3 % if SVR
                        % reduce data set to the trials * number of sets (after dividing in X% sets)
                        % use specifiied varaible condition only
                                                
                        if isfield(cfg.regress_data, 'SVR_labels') % Check whether SVR_labels was loaded from regression labels file
                            
                            temp_training_labels = cfg.regress_data.SVR_labels{cfg.regr_todo}(1:(ntrs_set * cfg.cross_val_steps));
                            
                        else % If using old SVR labels matrices DDTBOX will automatically convert to an array
                            
                            fprintf('\n WARNING: SVR labels are stored as a matrix. Coverting to cell array SVR_labels.\n Each cell number corresponds to a column in the SVR labels matrix.\n\n'); 
                            
                            % Convert matrix into array and remove NaN
                            % values for each cell (may arise when there are uneven
                            % exemplar numbers across label sets).
                            for svr_label_entry = 1:size(cfg.regress_data.SVR_matrix, 2)
                                
                                cfg.regress_data.SVR_labels{svr_label_entry} = cfg.regress_data.SVR_matrix(:, svr_label_entry);
                                cfg.regress_data.SVR_labels{svr_label_entry}(isnan(cfg.regress_data.SVR_labels{svr_label_entry}(:))) = []; % Remove NaN values   
                                
                            end % of for svr_label_entry
                            
                            temp_training_labels = cfg.regress_data.SVR_labels{cfg.regr_todo}(1:(ntrs_set * cfg.cross_val_steps));
                        end % of if isfield
                    end % if cfg.analysis_mode
                    
                    % extract test-trials and delete them from training-trials
                    for trl = 1:size(test_trials, 2)
                        
                        test_set{d,con,cv,ncv}(:,:,trl) = pooled_balanced_data{d,1,con}(:,:,test_trials(trl));
                        
                        if cfg.analysis_mode == 3 % if continuous SVR
                            
                            % take the value for the same trial as data chosen for the test data set
                            cfg.test_labels{d,con,cv,ncv}(trl,1) = temp_training_labels(test_trials(trl), 1);
                            cfg.test_trials{d,con,cv,ncv}(trl,1) = test_trials(trl);
                            
                        end % of if cfg.analysis_mode
                    end % of for trl
                    
                    % Cross-Condition SVM
                    % extract training set
                    if cfg.cross == 0 % If not performing cross-decoding
                        
                        delete_test_trials = fliplr(sort(test_trials));
                        
                    elseif cfg.cross == 1 % If performing cross-decoding
                        
                        % if doing cross-classification, ensure that trials
                        % from one training set don't end up in the
                        % opposite test set
                        delete_test_trials = [];
                        
                        for trl = 1:size(test_trials, 2)
                            
                            % find trials in training set which are the
                            % same as in opposite test set
                            for testTrl = 1:size(temp_training_set, 3)
                                
                                if isequal(pooled_balanced_data{(abs(d-2)+1),1,con}(:,:,test_trials(trl)), temp_training_set(:,:,testTrl))
                                    
                                    delete_test_trials = [delete_test_trials testTrl];
                                    
                                end % of if isequal
                            end % of for testTrl
                        end % of for trl
                        
                        if numel(delete_test_trials) < numel(test_trials)
                            
                            delete_test_trials = [delete_test_trials, test_trials(1:(numel(test_trials) - numel(delete_test_trials)))];
                            
                        end % of if numel
                    end % of if cfg.cross
                    
                    % Delete all used trials at once
                    temp_training_set(:,:,delete_test_trials) = [];
                    
                    training_set{d,con,cv,ncv} = temp_training_set;
                    
                    if cfg.analysis_mode == 3 % if continuous SVR
                        
                        % delete the same trials from regression labels as for data
                        temp_training_labels(delete_test_trials) = [];
                        cfg.training_labels{d,con,cv,ncv} = temp_training_labels;
                        
                    end % of if cfg.analysis_mode
                    
                    clear delete_test_trials;
                    clear temp_training_set;
                    clear temp_training_labels;
                    
                    fprintf('Data sorted for single-trial analysis: specified DCG %d condition %d cross-validation step %d of cycle %d. \n', d, con, cv, ncv);
                    
                end % of for d
                
                % go to next step and repeat
                x = x + ntrs_set;
                
                clear test_trials
                
            end % of for cv (cross-validation steps)
            
            clear random_set
            
        end % of for ncv (repetition of cross-validation)
        
        clear ntrs_set;
        
    end % of for con (all conditions in serial order)
    
    clear pooled_balanced_data
    
%% Run-Average Data
% test- and training-data correspond to run averages 

elseif cfg.avmode == 2 % run averages
    
    for d = 1:size(mean_balanced_data, 1)
        
        for con = 1:size(mean_balanced_data, 3)

            % take data from each run as test data once with number of runs =
            % cross-validation steps. Don't repeat because data is not randomly drawn from experiment        
            for r = 1:size(mean_balanced_data, 2)

                % run r = test data-set
                test_set{d,con,r,1} = mean_balanced_data{d,r,con};

                % all other runs = training data-set
                train_on = find(1:(size(mean_balanced_data, 2)) ~= r);
                sz_train = size(train_on, 2);

                for trainrun = 1:sz_train
                    
                    if trainrun == 1
                        
                        train_data = mean_balanced_data{d,train_on(trainrun),con};
                        
                    elseif trainrun > 1     
                        
                        train_data = cat(3, train_data, mean_balanced_data{d,train_on(trainrun), con});   
                        
                    end % of if trainrun
                end % of for trainrun

                training_set{d,con,r,1} = train_data;
                clear train_data;
                fprintf('Data sorted for run-average decoding: condition %d cross-validation step %d. \n', con, r);   

            end % of for r
        end % of for con
    end % of for d
    
    clear mean_balanced_data
    
end % of if cfg.avmode

%% Section 7: Build labels and do classification

fprintf('\nStarting with vector preparation... \n');
[RESULTS] = prepare_my_vectors_erp(training_set, test_set, cfg);

%% Section 8: Average Results Over Cross-Validation Steps

RESULTS.subj_acc = [];
RESULTS.subj_perm_acc = [];

% na = number analyses (stmode = 2 has one per channel)
for na = 1:size(RESULTS.prediction_accuracy, 2)
    
    pa(:,:,:) = RESULTS.prediction_accuracy{na}(:,:,:);
    
    if cfg.perm_test == 1
        
        perm_pa(:,:,:) = RESULTS.perm_prediction_accuracy{na}(:,:,:);
        
    end % of if cfg.perm_test
               
    % calculate average decoding accuracy
    RESULTS.subj_acc(na,:) = nanmean(nanmean(pa,3), 2);
    clear pa;
        
    % calculate average permutation test decoding accuracy
    if cfg.perm_test == 1
        
        RESULTS.subj_perm_acc(na,:) = nanmean(nanmean(perm_pa,3), 2);
        clear perm_pa;
        
    end % of if cfg.perm_test
        
end % of for na

fprintf('\nResults are computed and averaged for participant %d \n', cfg.sbj);

%% Section 9: Save The Decoding Results
% Saves decoding results to a .mat file in the output directory. Some analysis
% settings (e.g. window_width_ms) are included in the file name.

if cfg.cross == 0 % If not using cross-decoding
    
    savename = [(cfg.output_dir) cfg.study_name '_SBJ' num2str(cfg.sbj) ...
        '_win' num2str(cfg.window_width_ms) '_steps' num2str(cfg.step_width_ms)...
        '_av' num2str(cfg.avmode) '_st' num2str(cfg.stmode) '_' ...
        cfg.analysis_mode_label '_DCG' cfg.dcg_labels{cfg.dcg_todo} '.mat'];
    
elseif cfg.cross == 1 % Cross-decoding (train dcg 1, test dcg 2)
    
    savename = [(cfg.output_dir) cfg.study_name '_SBJ' num2str(cfg.sbj) ...
        '_win' num2str(cfg.window_width_ms) '_steps' num2str(cfg.step_width_ms)...
        '_av' num2str(cfg.avmode) '_st' num2str(cfg.stmode) '_' ...
        cfg.analysis_mode_label '_DCG' cfg.dcg_labels{cfg.dcg_todo(1)}...
        'toDCG' cfg.dcg_labels{cfg.dcg_todo(2)} '.mat'];
    
end % of if cfg.cross
    
save(savename, 'cfg', 'RESULTS'); % Save cfg and RESULTS structures into a .mat file

fprintf('\nResults are saved for participant %d in directory: %s \n', cfg.sbj, (cfg.output_dir));


%% Section 10: Display Individual Results
% Displays decoding results for the single subject dataset.

if cfg.display_on == 1
    
    % Load default plotting parameters for single subject plots
    PLOT = dd_set_plotting_defaults_indiv(cfg);
    PLOT.channel_names_file = cfg.channel_names_file;
    PLOT.channellocs = cfg.channellocs;
    
    % Call individual results display function
    display_indiv_results_erp(cfg, RESULTS, PLOT);

end % of if cfg.display_on
