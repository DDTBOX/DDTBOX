function dd_make_chanlocs_file(EEG, varargin)
%
% This function copies channel location information from a loaded EEGLab
% dataset and uses this data to create a channel locations file. The channel locations file
% is then saved at the specified location (folders are created if they do not already exist). 
% An EEGLab dataset must be loaded for this function to work.
%
%
% Inputs:
%
%   EEG            EEGLab data structure
%
%  'Key1'          Keyword string for argument 1
%
%   Value1         Value of argument 1
% 
%
% Optional Keyword Inputs:
%
%   save_filepath 	location in which to save the channel locations file, including file name. Default = pwd/ddchanlocstmp/chanlocs.mat 
%
%
% Usage:          make_chanlocs_file(EEG, 'save_filepath', 'Channel Locations/chanlocs_for_DDTBox.mat');
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
    'save_filepath', []);

% Read the acceptable names
option_names = fieldnames(options);

% Count arguments
n_args = length(varargin);
if round(n_args / 2) ~= n_args / 2
   error([mfilename, ' needs property name/property value pairs'])
end

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
save_filepath = options.save_filepath;
clear options;



%% Creating the Chanlocs File

if isempty(EEG.chaninfo)
    
    error('"chaninfo" field in EEG structure is empty. You must load EEG channel information in EEGLAB before running this function!');
    
end % of if isempty

if isempty(EEG.chanlocs)
    
    error('"chanlocs" field in EEG structure is empty. You must load EEG channel locations in EEGLAB before running this function!');
    
end % of if isempty


% Copy the relevant channel information from the EEGLab data structure
chaninfo = EEG.chaninfo;
chanlocs = EEG.chanlocs;

% Saves the file in the specified location
save([save_filepath 'chanlocs.mat'], 'chaninfo', 'chanlocs');
