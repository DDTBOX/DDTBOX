function dd_convert_eeg_data(EEG, events_by_cond, save_directory, save_filename, varargin)
%
% This function extracts EEG data epoched in EEGLAB or
% ERPLAB for use with DDTBOX, and saves the DDTBOX-compatible epoched data in the
% following array:
%
%   eeg_sorted_cond{run, condition}(timepoint, channel, epoch)
%
% This function also can create SVR condition labels corresponding to each
% epoch in the dataset, saved in the format:
%
%   SVR_labels{run, condition}(epoch, 1)
%
% If SVR labels will be created then data/labels will be pooled
% across runs to produce one cell entry for each column. This is
% because DDTBOX handles SVR data and labels that are collated within a
% single run.
%
% Epoching and artefact detection should be completed prior to running this
% function, either in EEGLAB or ERPLAB. This function will automatically
% exclude any epochs marked for rejection in EEGLAB or ERPLAB 
% (using information in EEG.reject.rejmanual).
%
% This function also creates a structure called dataset_info which contains
% some information about the epoched EEG data.
%
% WARNING: This function is in beta and has not been thoroughly
% tested across versions of EEGLAB/ERPLAB and on different EEG data types.
% Wherever possible, always check whether this script is properly
% extracting the correct epochs by manually extracting epoched data from 
% the EEG structure in EEGLab.
%
%
% Inputs:
%   
%   EEG     Structure containing EEG data and epoch information, created in
%           EEGLAB.
%
%   events_by_cond      Array containing event codes (if using EEGLAB) or bin
%                       indices (if using ERPLAB) for epochs in each
%                       condition/run used for MVPA. Organised as follows:
%                       events_by_cond{run, condition}([event_code_1, event_code_2)
%
%   save_directory       Filepath for saving the resulting DDTBOX-compatible
%                       .mat file containing epoched EEG data.
%
%   save_filename       Name of the .mat file containing DDTBOX-compatible
%                       epoched EEG data.
%
%
% Optional keyword inputs:
%
%   eeg_toolbox    Name of the toolbox used for epoching EEG data.
%                  This function accepts either 'EEGLAB' or 'ERPLAB'.
%                  Default is 'EEGLAB'
% 
%   data_type      Select whether to extract EEG data or independent component activations.
%                  This function accepts either 'EEG' or 'ICAACT'. 
%                  Default is 'EEG'
%
%   channels       Select channels/IC components to include in the
%                  DDTBOX-compatible epoched dataset. Enter as a vector of
%                  channel/component numbers, or 'All' to use all
%                  channels/components. Default is 'All'.
%
%   timepoints     Select the start and end timepoints (in ms relative to event onset) 
%                  for epochs in the DDTBOX-compatible dataset. Enter
%                  a vector of two numbers [epoch_start, epoch_end], or
%                  'All' to include the entire epoch as defined in EEGLAB/ERPLAB.
%                  Default is 'All'
%
%   svr_labels_vector    A vector of condition labels for each epoch, used for
%                        support vector regression (SVR) analyses. SVR labels
%                        will be stored in the same format as the epoched data:
%                        SVR_labels{run, condition}(epoch, 1)
%                        Each entry in the svr_labels vector must correspond to 
%                        the same epoch number in the EEG.epoch structure. If nothing
%                        is entered then this function will not create SVR labels.
%                        These labels will be saved in a separate .mat file with
%                        "_regress_sorted_data" appended to the name of the epoched 
%                        dataset file name.
% 
%
% Example:  dd_convert_eeg_data(EEG, events_by_cond, 'DDTBOX-Data/ID1/', 'ID1', 'eeg_toolbox', 'EEGLAB', 'data_type', 'ICAACT', 'channels', 1:10, 'timepoints', [-100, 500], 'svr_labels_vector', svr_labels_vector) 
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



%% Handling Variadic Inputs

% Define defaults at the beginning
options = struct(...
    'eeg_toolbox', 'EEGLAB',...
    'data_type', 'EEG',...
    'channels', 'All',...
    'timepoints', 'All', ...
    'svr_labels_vector', []);

% Read the acceptable names
option_names = fieldnames(options);

% Count arguments
n_args = length(varargin);
if round(n_args / 2) ~= n_args / 2
    
   error([mfilename ' needs property name/property value pairs'])
   
end % of if round

for pair = reshape(varargin, 2, []) % pair is {propName;propValue}
    
   inp_name = lower(pair{1}); % make case insensitive

   % Overwrite default options
   if any(strcmp(inp_name,option_names))
       
      options.(inp_name) = pair{2};
      
   else
       
      error('%s is not a recognized parameter name', inp_name)
      
   end % of if any
end % of for pair

clear pair
clear inp_name

% Renaming variables for use below:
eeg_toolbox = options.eeg_toolbox;
data_type = options.data_type;
channels = options.channels;
timepoints = options.timepoints;
svr_labels_vector = options.svr_labels_vector;
clear options;



%% Load and Trim the Epoched Data

% Check whether user has chosen to create SVR labels
if ~isempty(svr_labels_vector)
    
    create_svr_labels = 1;
    
else 
    
    create_svr_labels = 0; 
    
end % of ~isempty svr_labels_vector


% Check if svr labels is a vector
if create_svr_labels
    
    if ndims(svr_labels_vector) > 2;
        
        error([mfilename ': svr_labels_vector has too many dimensions. svr_labels_vector must be input as a vector'])
        
    end % of if ndims

    if size(svr_labels_vector, 1) > 1 && size(svr_labels_vector, 2) > 1
        
        error([mfilename ': svr_labels_vector was input as a matrix. svr_labels_vector must be input as a vector'])
        
    end % of if size
end % of if create_svr_labels


% Arranging the epoched data
if strcmp(data_type, 'EEG') == 1 % If using EEG data
    
    % First check if data has been epoched (contains multiple epochs)
    if size(EEG.data, 3) == 1
        
        error([mfilename ' only accepts epoched data. Please epoch your data before running this function']);
        
    end % of if size
    
    if ischar(channels) && strcmp(channels, 'All') == 1 % If selecting all channels
        
        epoched_data = EEG.data(:, :, :);
        
    else % If only selecting a subset of channels
        try
            
        epoched_data = EEG.data(channels, :, :);
        
        catch % If channels not specified properly
            
            error([mfilename ': Channels or IC components not specified correctly. Check that the selected channels/components are present in your dataset']);
            
        end % of try/catch
    end % of if ischar
    
    n_epochs_total = size(epoched_data, 3);
    
elseif strcmp(data_type, 'ICAACT') == 1 % If using independent component activations
    
    if ischar(channels) && strcmp(channels, 'All') == 1 % If selecting all channels
        
        epoched_data = EEG.icaact(:, :, :);
        
    else % If only selecting a subset of channels
        try
            
        epoched_data = EEG.icaact(channels, :, :);
        
        catch % If channels not specified properly
            
            error([mfilename ': Channels or IC components not specified correctly. Check that the selected channels/components are present in your dataset']);
            
        end % of try/catch
    end % of if ischar
    
    % Calculate total number of epochs in EEGLAB/ERPLAB dataset
    n_epochs_total = size(epoched_data, 3);
    
else % If data type not correctly specified
    
    error([mfilename ': Data type for DDTBOX not correctly specified. Please input either "EEG" or "ICAACT"']);
    
end % of if strcmp data_type

if strcmp(timepoints, 'All') % If all time points within the epoch were included
    
    epoch_start_index = 1;
    epoch_end_index = size(epoched_data, 2);
    
else % If user has selected custom time range
    
    % Trim to specified epoch start/end timepoints
    % Find epoch start and end samples (closest timepoints to selected epoch
    % start/end value)
    [~, epoch_start_index] = min(abs(EEG.times - timepoints(1)));
    [~, epoch_end_index] = min(abs(EEG.times - timepoints(2)));
    fprintf(['\n', mfilename, ': Adjusted epoch start/end times are %4.1f to %4.1f ms\n'], EEG.times(epoch_start_index), EEG.times(epoch_end_index));
    % Trim to selected epoch start/end lengths
    epoched_data = epoched_data(:, epoch_start_index:epoch_end_index, :);
    
end % of if ~strcmp

% Flip first and second dimensions of dataset to conform to DDTBOX format
epoched_data = permute(epoched_data, [2, 1, 3]);

% Check if the length of the SVR labels vector matches the number of epochs
if create_svr_labels && length(svr_labels_vector) ~= n_epochs_total
    
    error([mfilename, ': Length of svr_labels_vector vector does not match the number of epochs in the dataset']);
    
end % of if create_svr_labels

% Check if save filepath exists, create directory if doesn't exist
if ~exist(save_directory, 'dir')
    
    fprintf(['\n', mfilename, ': Specified save directory does not exist.\n Creating the directory ', save_directory, '...\n']);
    mkdir(save_directory);
    
end % of if ~exist



%% Check Number of Conditions/Runs and Number of Event Codes in Each Condition

n_conds = size(events_by_cond, 2);
n_runs = size(events_by_cond, 1);
n_eventcodes_by_cond = nan(n_runs, n_conds); % Preallocate

for run_no = 1:n_runs
    
    for cond_no = 1:n_conds
        
        n_eventcodes_by_cond(run_no, cond_no) = length(events_by_cond{run_no, cond_no});
        
    end % of for cond_no
end % of for run_no

% Create empty eeg_sorted_cond cell array
eeg_sorted_cond = cell(n_runs, n_conds);

% Create set of SVR labels
if create_svr_labels
    
    SVR_labels = cell(n_runs, n_conds);
    
end % of if create_svr_labels

% Notify user that we are extracting epoched data
fprintf(['\n', mfilename, ': Extracting epoched EEG data and saving in a DDTBOX-compatible format...\n']);



%% Extract Epochs for Each Condition

% Different methods of extracting epochs are used depending on whether data
% was epoched in EEGLAB or ERPLAB
if strcmp(eeg_toolbox, 'EEGLAB') == 1 % If using EEGLAB
    
    for epoch_no = 1:n_epochs_total
        
        bin_indices = (EEG.epoch(epoch_no).eventtype);
    
        % If more than one event code in epoch, then bin_indices will be a
        % cell array
        if iscell(bin_indices)
        
            % Checking whether event codes are strings and converting to double
            % precision floating point
            if ischar(bin_indices{1})

                for bin_index_temp = 1:length(bin_indices)

                    bin_indices{bin_index_temp} = str2num(bin_indices{bin_index_temp});

                end % of for bin_index_temp
                
            end % of if isstring

            % Convert cell array to vector
            bin_indices = cell2mat(bin_indices);
            
        else % If bin_indices is not a cell array
            
            % Checking whether event codes are strings and converting to double
            % precision floating point
            if ischar(bin_indices(1))

                for bin_index_temp = 1:length(bin_indices)

                    bin_indices(bin_index_temp) = str2num(bin_indices(bin_index_temp));

                end % of for bin_index_temp
                
            end % of if isstring
            
        end % of if iscell
        
        for bin_index = 1:length(bin_indices) % For each bin index in the epoch
        
            % Cycle through each condition/run combination and look for matching event codes
            for run_no = 1:n_runs
                
                for condition_no = 1:n_conds
                    
                    for event_code_no = 1:n_eventcodes_by_cond(run_no, condition_no)

                        % Check whether bin index matches a specified event
                        % code corresponding to a condition in DDTBOX analyses
                        if bin_indices(bin_index) == events_by_cond{run_no, condition_no}(event_code_no)

                             % Check if artefact rejection has been conducted, and
                             % if the epoch has been marked for rejection
                             % using artefact detection routines
                             if ~isempty(EEG.reject.rejmanual); % If artefact detection has been conducted
                                 
                                 if EEG.reject.rejmanual(1, epoch_no) == 0 % If not marked for rejection

                                     % Check whether this is the first
                                     % entry for this condition/run
                                     if isempty(eeg_sorted_cond{run_no, condition_no});
                                         
                                         eeg_sorted_cond{run_no, condition_no}(:,:,1) = epoched_data(:,:,epoch_no);
                                         
                                     else
                                         
                                         % Copy the epoch into the eeg_sorted_cond cell array
                                         eeg_sorted_cond{run_no, condition_no}(:,:,end + 1) = epoched_data(:,:,epoch_no);
                                         
                                     end % of if isempty
                                     
                                     if create_svr_labels % If creating SVR labels
                                         
                                         SVR_labels{run_no, condition_no}(end + 1, 1) = svr_labels_vector(epoch_no);
                                         
                                     end % of if create_svr_labels

                                 end % of if EEG.reject.rejmanual

                             else % If artefact detection has not been performed

                                 if isempty(eeg_sorted_cond{run_no, condition_no});
                                     
                                     eeg_sorted_cond{run_no, condition_no}(:,:,1) = epoched_data(:,:,epoch_no);
                                     
                                 else
                                     
                                     % Copy the epoch into the eeg_sorted_cond cell array
                                     eeg_sorted_cond{run_no, condition_no}(:,:,end + 1) = epoched_data(:,:,epoch_no);
                                     
                                 end % of if isempty
                                 
                                 if create_svr_labels % If creating SVR labels
                                     
                                     SVR_labels{run_no, condition_no}(end + 1, 1) = svr_labels_vector(epoch_no);
                                     
                                 end % of if create_svr_labels
                             end % of if ~isempty EEG.reject.rejmanual
                        end % of if bin_index 
                    end % of for event_code_no
                end % of for condition_no 
            end % of for run_no
        end % of for bin_index
    end % of for epoch_no
    
    
elseif strcmp(eeg_toolbox, 'ERPLAB') == 1 % If using ERPLab
    
    % Go through each epoch and check whether it belongs to a bin index
    % specified in events_by_cond
    for epoch_no = 1:n_epochs_total % Go through all epochs
        
        % Get vectors of bin indices for the epoch
        bin_indices = cell2mat(EEG.epoch(epoch_no).eventbini);
        
        for bin_index = 1:length(bin_indices) % For each bin index in the epoch
        
            % Cycle through each condition/run and look for matching event codes
            for run_no = 1:n_runs
                
                for condition_no = 1:n_conds
                    
                    for event_code_no = 1:n_eventcodes_by_cond(run_no, condition_no)

                        % Check whether bin index matches a specified event
                        % code corresponding to a condition in DDTBOX analyses
                        if bin_indices(bin_index) == events_by_cond{run_no, condition_no}(event_code_no)

                             % Check if artefact rejection has been conducted, and
                             % if the epoch has been marked for rejection
                             % using artefact detection routines
                             if ~isempty(EEG.reject.rejmanual); % If artefact detection has been conducted
                                 
                                 if EEG.reject.rejmanual(1, epoch_no) == 0 % If not marked for rejection

                                     if isempty(eeg_sorted_cond{run_no, condition_no});
                                         
                                         eeg_sorted_cond{run_no, condition_no}(:,:,1) = epoched_data(:,:,epoch_no);
                                         
                                     else
                                         
                                         % Copy the epoch into the eeg_sorted_cond cell array
                                         eeg_sorted_cond{run_no, condition_no}(:,:,end + 1) = epoched_data(:,:,epoch_no);
                                         
                                     end % of if isempty
                                     
                                 if create_svr_labels % If creating SVR labels
                                     
                                     SVR_labels{run_no, condition_no}(end + 1, 1) = svr_labels_vector(epoch_no);
                                     
                                 end % of if create_svr_labels
                                 
                                 end % of if EEG.reject.rejmanual

                              else % If artefact detection has not been performed

                                  if isempty(eeg_sorted_cond{run_no, condition_no});
                                      
                                     eeg_sorted_cond{run_no, condition_no}(:,:,1) = epoched_data(:,:,epoch_no);
                                     
                                  else
                                     
                                     % Copy the epoch into the eeg_sorted_cond cell array
                                     eeg_sorted_cond{run_no, condition_no}(:,:,end + 1) = epoched_data(:,:,epoch_no);
                                     
                                 end % of if isempty
                                     
                                 if create_svr_labels % If creating SVR labels
                                     
                                     SVR_labels{run_no, condition_no}(end + 1, 1) = svr_labels_vector(epoch_no);
                                     
                                 end % of if create_svr_labels
                             end % of if ~isempty EEG.reject.rejmanual
                        end % of if bin_index 
                    end % of for event_code_no
                end % of for condition_no 
            end % of for run_no
        end % of for bin_index
    end % of for epoch_no
    
else % EEG toolbox name incorrectly specified
    
    error([mfilename ': EEG toolbox name not correctly specified. Please input either "EEGLAB" or "ERPLAB"']);

end % of if strcmp eeg_toolbox



%% Pool Data Across Runs if SVR Data
% If SVR labels were defined, then pool data across runs for eeg data SVR labels arrays

if create_svr_labels == 1 && n_runs > 1 % If creating SVR labels and more than one block/run defined
    
    % Clear/preallocate
    temp_data = cell(1, n_conds);
    temp_labels = cell(1, n_conds);
    
    for cond_no = 1:n_conds
        
        for run_no = 1:n_runs
            
            n_epochs_in_run = size(eeg_sorted_cond{run_no, cond_no}, 3);
            
            if isempty(temp_data{1, cond_no}) % If no epochs have been added to the current condition cell
                
                temp_data{1, cond_no}(:, :, 1 : n_epochs_in_run) = eeg_sorted_cond{run_no, cond_no}(:,:,:);
                temp_labels{1, cond_no}(1 : n_epochs_in_run, 1)  = SVR_labels{run_no, cond_no};
            
            else
                
                temp_data{1, cond_no}(:,:,end + 1 : end + n_epochs_in_run) = eeg_sorted_cond{run_no, cond_no}(:,:,:);
                temp_labels{1, cond_no}(end + 1 : end + n_epochs_in_run, 1)  = SVR_labels{run_no, cond_no};
            
            end % of if isempty
        end % of for run_no   
    end % of for cond_no
    
    eeg_sorted_cond = temp_data;
    SVR_labels = temp_labels;
    fprintf(['\n', mfilename, ': EEG data and SVR labels were pooled across runs. \nNew number of runs = 1 \n']);
    n_runs = 1;
    
end % of if create_svr_labels && n_runs



%% Copy Dataset Information to dataset_information Structure

dataset_info.channel_indices = channels;
dataset_info.epoch_startend_ms = [EEG.times(epoch_start_index), EEG.times(epoch_end_index)];
dataset_info.sampling_rate_hz = EEG.srate;
dataset_info.times = EEG.times(epoch_start_index:epoch_end_index);
dataset_info.n_conds = n_conds;
dataset_info.n_runs_per_cond = n_runs;



%% Save DDTBOX-Compatible Epoched EEG Data File

try
    
    save([save_directory, '/', save_filename], 'eeg_sorted_cond', 'dataset_info', '-v7.3');
    
    if create_svr_labels % If SVR labels were created
        
        save([save_directory, '/', save_filename, '_regress_sorted_data'], 'SVR_labels', '-v7.3');
        
    end % of if ~isempty
    
catch % If user has added their own forward slash to end of directory path
    
    save([save_directory, save_filename], 'eeg_sorted_cond', 'dataset_info', '-v7.3');
    
    if create_svr_labels % If SVR labels were created
        
        save([save_directory, save_filename, '_regress_sorted_data'], 'SVR_labels', '-v7.3');
        
    end % of if ~isempty
end % of try/catch
