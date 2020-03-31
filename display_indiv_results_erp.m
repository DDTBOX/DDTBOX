function display_indiv_results_erp(cfg, RESULTS, PLOT)
%
% This function gets input from decoding_erp.m and displays decoding results 
% for a single subject. If permutation tests are run and display of 
% permutation results is on, then these results are displayed for comparison.
%
% This function is called by decoding_erp, but can also be called by 
% custom plotting scripts such as EXAMPLE_plot_individual_results
% 
%
% Inputs:
%
%   cfg         structure containing participant dataset information and 
%               multivariate classification/regression settings.
%
%   RESULTS     structure containing decoding results for an individual
%               subject datset.
%
%   PLOT        structure containing settings specific to plotting single
%               subject results.
%
%
% Usage:        display_indiv_results_erp(cfg, RESULTS, PLOT)
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



%% Set Plotting Colourmaps

% Set colour maps for plotting. Code provided by Dr Patrick Cooper (thanks
% Patrick!)
plot_colour_map = dd_make_colour_maps( ...
    PLOT.Res.LineColour, ...
    PLOT.PermRes.LineColour);



%% Display Results

% Determine the x-axis scaling
nsteps = size(RESULTS.subj_acc, 2);



%% For Spatial and Spatiotemporal Decoding

if cfg.stmode == 1 || cfg.stmode == 3 % Spatial and spatiotemporal decoding

    figure('color', PLOT.background_colour, 'Position', PLOT.FigPos);
    
    % Plot actual decoding results
    temp_data(1,:) = RESULTS.subj_acc(1,:);
    
    plot(temp_data, PLOT.Res.Line, ...
        'Color', plot_colour_map(1, :), ...
        'LineWidth', PLOT.Res.LineWidth, ...
        'MarkerEdgeColor',PLOT.Res.MarkerEdgeColor, ...
        'MarkerFaceColor', PLOT.Res.MarkerFaceColor, ...
        'MarkerSize', PLOT.Res.MarkerSize);
    
    hold on;

    % Plot permutation decoding results
    if cfg.perm_disp == 1

        temp_perm_data(1,:) = RESULTS.subj_perm_acc(1,:);
        
        plot(temp_perm_data, PLOT.PermRes.Line, ...
            'Color', plot_colour_map(2, :), ...
            'LineWidth', PLOT.PermRes.LineWidth, ...
            'MarkerEdgeColor', PLOT.PermRes.MarkerEdgeColor, ...
            'MarkerFaceColor', PLOT.PermRes.MarkerFaceColor, ...
            'MarkerSize', PLOT.PermRes.MarkerSize);

    end % of if cfg.perm_disp

    % X axis label
    xlabel('Time-steps [ms]', ...
        'FontSize', PLOT.xlabel.FontSize, ...
        'FontWeight', PLOT.xlabel.FontWeight);

    % Y axis label
    if cfg.analysis_mode ~= 3 % If performed classification analyses
        
        ylabel('Classification Accuracy [%]', ...
            'FontSize', PLOT.ylabel.FontSize, ...
            'FontWeight', PLOT.ylabel.FontWeight);
        
    elseif cfg.analysis_mode == 3 % If performing SVR
        
        ylabel('Fisher Z-transformed correlation coeff', ...
            'FontSize', PLOT.ylabel.FontSize, ...
            'FontWeight', PLOT.ylabel.FontWeight);
        
    end % of if cfg.analysis_mode

    
    % X axis tick labels
    XTickLabels(1 : ceil(nsteps / PLOT.x_tick_spacing)) = (((1 : PLOT.x_tick_spacing : nsteps) * cfg.step_width_ms) - cfg.step_width_ms) - cfg.pointzero; 
    
    % Determine point of event onset relative to start of epoch (in steps)
    plotting_point_zero = (cfg.pointzero / cfg.step_width_ms) + 1;
     
    % Mark event onset and set tick labels
    if cfg.analysis_mode ~= 3 % If performed classification
        
        line([plotting_point_zero, plotting_point_zero], [100 30], ...
            'Color', PLOT.PointZero.Color, ...
            'LineWidth', PLOT.PointZero.LineWidth);
        
        % Set locations of X and Y axis tickmarks
        set(gca, 'Ytick', [0 : PLOT.y_tick_spacing : 100], ...
            'Xtick', [1 : PLOT.x_tick_spacing : nsteps], ...
            'fontsize', PLOT.XY_tick_labels_fontsize, ...
            'fontname','Arial');
        
    elseif cfg.analysis_mode == 3 % If performed regression
        
        line([plotting_point_zero, plotting_point_zero], [1, -1], ...
            'Color', 'r', ...
            'LineWidth', 3);

        % Set locations of X and Y axis tickmarks
        set(gca,'Ytick', [-1 : PLOT.y_tick_spacing_regress : 1], ...
            'Xtick', [1 : PLOT.x_tick_spacing : nsteps], ...
            'fontsize', PLOT.XY_tick_labels_fontsize, ...
            'fontname','Arial');
        
    end % of if cfg.analysis_mode

    % Convert X axis ticks to strings in a cell. This is to avoid the
    % weird X axis tick mislocalisation bug that sometimes occurs in
    % MATLAB
    clear XTickLabel_Cell;
    
    for x_tick_number = 1:length(XTickLabels)
        
        XTickLabels_Cell{x_tick_number} = XTickLabels(x_tick_number);
        
    end % of for x_tick_number

    % Set X tick labels
    set(gca, 'XTickLabel', XTickLabels_Cell);

    % Title of plot
    if cfg.cross == 0 % If did not perform cross-decoding
        
        title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo}, ' - analysis ', num2str(1), ' of ', num2str(size(RESULTS.subj_acc, 1))], ...
            'FontSize', PLOT.TitleFontSize, ...
            'FontWeight', PLOT.TitleFontWeight);
        
    elseif cfg.cross == 1 % If performed cross-decoding
        
        title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo(1)}, ' train ', cfg.dcg_labels{cfg.dcg_todo(2)}, ' test ', '- analysis ', num2str(1), ' of ', num2str(size(RESULTS.subj_acc, 1))], ...
            'FontSize', PLOT.TitleFontSize, ...
            'FontWeight', PLOT.TitleFontWeight);
        
    end % of if cfg.cross
    
    % Legend
    if cfg.perm_disp == 1 % If plotting permutation results

        legend('Decoding Results', 'Permutation Decoding Results');

    elseif cfg.perm_disp == 0 % Not plotting permutation results

        legend('Decoding Results');

    end % of if cfg.perm.disp

    % Remove top and right borders and associated X/Y ticks
    box off;
    
    
    
    %% For Temporal Decoding
    
elseif cfg.stmode == 2 % Temporal decoding

    % Load channel information (locations and labels)
    channel_file = [PLOT.channellocs, PLOT.channel_names_file];
    load(channel_file);
    
    % Copy to PLOT structure
    PLOT.chaninfo = chaninfo;
    PLOT.chanlocs = chanlocs;

    % Plot decoding results
    temp_data(:, 1) = RESULTS.subj_acc(:, 1);
    
    figure;
    topoplot_decoding(temp_data, PLOT.chanlocs, ...
        'style', 'both', ...
        'electrodes', 'labelpoint', ...
        'maplimits', 'minmax', ...
        'chaninfo', PLOT.chaninfo, ...
        'colormap', PLOT.temporal_decoding_colormap);
    hold on;
    
    % Title of plot
    if cfg.cross == 0 % If did not perform cross-decoding
        
        title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo}], ...
            'FontSize', PLOT.TitleFontSize, ...
            'FontWeight', PLOT.TitleFontWeight);
            
    elseif cfg.cross == 1 % If performed cross-decoding
        
        title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo(1)}, ' train ', cfg.dcg_labels{cfg.dcg_todo(2)}, ' test'], ...
            'FontSize', PLOT.TitleFontSize, ...
            'FontWeight', PLOT.TitleFontWeight);
        
    end % of if cfg.cross
    
    % Plot permutation decoding results
    if cfg.perm_disp == 1 % If displaying permutation decoding results

        temp_perm_data(:, 1) = RESULTS.subj_perm_acc(:, 1);
        
        figure;
        topoplot_decoding(temp_perm_data, PLOT.chanlocs, ...
            'style', 'both', ...
            'electrodes', 'labelpoint', ...
            'maplimits', 'minmax', ...
            'chaninfo', PLOT.chaninfo, ...
            'colormap', PLOT.temporal_decoding_colormap);
        hold on;

        % Title of plot
        if cfg.cross == 0 % If did not perform cross-decoding
            
            title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo}, ' Permutation Decoding Results'], ...
                'FontSize', 14, ...
                'FontWeight', 'b');

        elseif cfg.cross == 1 % If performed cross-decoding
            
            title(['SBJ', num2str(cfg.sbj_todo), ' ', cfg.dcg_labels{cfg.dcg_todo(1)}, ' train ', cfg.dcg_labels{cfg.dcg_todo(2)}, ' test', ' Permutation Decoding Results'], ...
                'FontSize', 14, ...
                'FontWeight', 'b');
            
        end % of if cfg.cross
        
    end % of if cfg.perm_disp
  
end % of if cfg.stmode