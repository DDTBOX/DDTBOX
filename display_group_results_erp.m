function display_group_results_erp(ANALYSIS, PLOT)
%
% This function plots results of group-level analyses of 
% classification/regression performance.  
%
% This function is called by analyse_decoding_erp, but can also be called
% by custom plotting scripts such as EXAMPLE_plot_group_results.
%
%
% Inputs:
%
%   ANALYSIS        structure containing analysis settings and data
% 
%   PLOT            structure containing decoding performance plotting
%                   settings. For a list of settings see the documentation
%                   or see the function dd_set_plotting_defaults
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
    PLOT.PermRes.LineColour, ...
    PLOT.Sign.LineColor);



%% (Spatial/Spatiotemporal Decoding) Plot the Results
% plots the results depending on s/t-mode (information time-courses for
% spatial/spatio-temporal decoding; heat maps for temporal decoding)

if ANALYSIS.stmode == 1 || ANALYSIS.stmode == 3 % Spatial and spatiotemporal decoding
    
    % Plot the information time-course for each analysis
    for ana = 1:size(ANALYSIS.RES.mean_subj_acc, 1)
        
        fighandle = figure('color', PLOT.background_colour, 'Position', PLOT.FigPos);
        
        % Calculate measure of central tendency for the group data      
        if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
            
            temp_data(1,:) = ANALYSIS.RES.mean_subj_acc(ana,:);
            temp_se(1,:) = ANALYSIS.RES.se_subj_acc(ana,:);
            fprintf('\nArithmetic mean used for plotting group average accuracy\nError bars represent standard errors\n\n');
        
        elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 
        
            temp_data(1,:) = ANALYSIS.RES.trimmean_subj_acc(ana,:);
            temp_se = ANALYSIS.RES.se_subj_acc(ana,:); % Still plotting non-robust SE
            fprintf('\n%i percent trimmed mean used for plotting group average accuracy\nError bars represent standard errors\n\n', ANALYSIS.plot_robust_trimming);

        elseif ANALYSIS.plot_robust == 2 % If plotting medians
            
            temp_data(1,:) = ANALYSIS.RES.median_subj_acc(ana,:);
            temp_se = ANALYSIS.RES.se_subj_acc(ana,:); % Still plotting non-robust SE
            fprintf('\nMedian used for plotting group average accuracy\nError bars represent standard errors\n\n');

        end % of if ANALYSIS.plot_robust
            
        % Calculate measure of central tendency for the permuted labels
        % decoding results
        if ANALYSIS.permstats == 1 % If testing against theoretical chance
            
            temp_perm_data(1, 1:size(ANALYSIS.RES.mean_subj_acc(ana,:), 2)) = ANALYSIS.chancelevel;
            temp_perm_se(1, 1:size(ANALYSIS.RES.mean_subj_acc(ana,:), 2)) = zeros;
            
        elseif ANALYSIS.permstats == 2
            
            if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
                
                temp_perm_data(1,:) = ANALYSIS.RES.mean_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:);
                
            elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

                temp_perm_data(1,:) = ANALYSIS.RES.trimmean_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:); % Still plotting non-robust SE
                
            elseif ANALYSIS.plot_robust == 2 % If plotting medians
                
                temp_perm_data(1,:) = ANALYSIS.RES.median_subj_perm_acc(ana,:);
                temp_perm_se(1,:) = ANALYSIS.RES.se_subj_perm_acc(ana,:); % Still plotting non-robust SE
                
            end % of if ANALYSIS.plot_robust
            
        end % of if ANALYSIS.permstats
        
        
        % Mark statistically significant time windows        
        if ANALYSIS.disp.sign == 1
            
            for step = 1:size(temp_data, 2)
                
                % Add background shading if statistically significant...
                if ANALYSIS.RES.h(ana, step) == 1
                    
                    % Note, in order to show the effect, we need to slightly broaden the
                    % patch by one sample (otherwise it is invisble - hence the -1 +1 here)
                    x_data = [step - 1, step - 1, step + 1, step + 1];
                    y_data = [PLOT.Y_min, PLOT.Y_max, PLOT.Y_max, PLOT.Y_min];

                    % Settings for significance marker patch object
                    sig_markers = patch('xdata', x_data, 'ydata', y_data);
                    sig_markers.FaceAlpha = .3;
                    sig_markers.FaceColor = plot_colour_map(3,:);
                    sig_markers.EdgeColor = 'none';
                    
                    hold on;
                    
                end % of if ANALYSIS.RES.h
            end % of for step
        end % of if ANALYSIS.disp.sign
        
        
        % Plot group-averaged decoding accuracy (or median, trimmed mean
        % etc.)
        plot(temp_data, PLOT.Res.Line, ...
            'Color', plot_colour_map(1, :), ...
            'LineWidth', PLOT.Res.LineWidth, ...
            'MarkerEdgeColor', PLOT.Res.MarkerEdgeColor,...
            'MarkerFaceColor', PLOT.Res.MarkerFaceColor, ...
            'MarkerSize', PLOT.Res.MarkerSize);
        
        hold on;      
           
        
        if strcmpi(ANALYSIS.disp.plotting_mode, 'cooper')
        
            % Plot shaded error regions
            % (Code for plotting shaded regions provided by Dr Patrick Cooper - Thanks Patrick!)

            % Generate shading for error regions
            [patch_x, patch_y] = dd_make_error_bar_object(1:size(temp_data, 2), temp_data, temp_se);

            SE_shading = patch('xdata', patch_x, 'ydata', patch_y);

            SE_shading.FaceAlpha = PLOT.Res.ShadingAlpha; % Transparency
            SE_shading.FaceColor = plot_colour_map(1,:); % First row of colour map
            SE_shading.EdgeColor = 'none';
            
        elseif strcmpi(ANALYSIS.disp.plotting_mode, 'classic')

            % Plot error bars
            errorbar(temp_data, temp_se, PLOT.Res.Error, ...
                'linestyle', PLOT.Res.ErrorLine, ...
                'linewidth', PLOT.Res.ErrorLineWidth);
        
        end % of if strcmpi ANALYSIS.disp.plotting_mode
            
        hold on;
        
        
        
        %% Plot Permutation / Chance Results

        if ANALYSIS.permdisp == 1 % If select to plot permutation decoding results
            
            plot(temp_perm_data, PLOT.PermRes.Line, ...
                'Color', plot_colour_map(2, :), ...
                'LineWidth', PLOT.PermRes.LineWidth, ...
                'MarkerEdgeColor', PLOT.PermRes.MarkerEdgeColor,...
                'MarkerFaceColor', PLOT.PermRes.MarkerFaceColor, ...
                'MarkerSize', PLOT.PermRes.MarkerSize);
            
            hold on;      

            
            if strcmpi(ANALYSIS.disp.plotting_mode, 'cooper')
            
                % Generate shading for error regions
                [perm_patch_x, perm_patch_y] = dd_make_error_bar_object(1:size(temp_perm_data, 2), temp_perm_data, temp_perm_se);

                perm_SE_shading = patch('xdata', perm_patch_x, 'ydata', perm_patch_y);

                perm_SE_shading.FaceAlpha = PLOT.Res.ShadingAlpha; % Transparency
                perm_SE_shading.FaceColor = plot_colour_map(2,:); % Second row of colour map
                perm_SE_shading.EdgeColor = 'none';
                
            elseif strcmpi(ANALYSIS.disp.plotting_mode, 'classic')
                
                % Plot error bars
                errorbar(temp_perm_data, temp_perm_se, PLOT.PermRes.Error, ...
                    'linestyle', PLOT.PermRes.ErrorLine, ...
                    'linewidth', PLOT.PermRes.ErrorLineWidth);
            
            end % of if strcmpi ANALYSIS.disp.plotting_mode
            
            hold on;
            
            
        end % of if ANALYSIS.permdisp
        
        
        
        %% Define Axis Labels, Point Zero, Title
              
        % Axis limits
        axis([1, ANALYSIS.laststep, PLOT.Y_min, PLOT.Y_max]);
        
        % Axis Labels
        xlabel([PLOT.xlabel.Text], 'FontSize', PLOT.xlabel.FontSize, 'FontWeight', PLOT.xlabel.FontWeight);
        ylabel([PLOT.ylabel.Text], 'FontSize', PLOT.ylabel.FontSize, 'FontWeight', PLOT.ylabel.FontWeight);
        
        % Title
        if size(ANALYSIS.DCG,1) == 1 % If did not perform cross-decoding
                
            title([PLOT.TitleString, ANALYSIS.DCG, ' N=',  num2str(ANALYSIS.nsbj)],...
                'FontSize', PLOT.TitleFontSize, 'FontWeight', PLOT.TitleFontWeight);
           
        elseif size(ANALYSIS.DCG,1) == 2 % If performed cross-decoding
                
            title([PLOT.TitleString, ANALYSIS.DCG{1}, 'to', ANALYSIS.DCG{2}, ' N=',  num2str(ANALYSIS.nsbj)],...
                'FontSize', PLOT.TitleFontSize, 'FontWeight', PLOT.TitleFontWeight);
           
        end % of if size

        % Mark point zero (data was time-locked to this event)
        line([PLOT.PointZero.Point, PLOT.PointZero.Point], [PLOT.Y_max, PLOT.Y_min], ...
            'Color', PLOT.PointZero.Color,...
            'LineWidth', PLOT.PointZero.LineWidth);
        
        
        
        %% Define X/Y Ticks and Axis Labels
        
        % X and Y ticks properties
        set(gca,'Ytick', PLOT.Ytick, ...
            'Xtick', PLOT.Xtick, ...
            'fontsize', PLOT.XY_tick_labels_fontsize, ...
            'fontname','Arial');
        
        % Convert X axis ticks to strings in a cell. This is to avoid the
        % weird X axis tick mislocalisation bug that sometimes occurs in
        % MATLAB
        clear XTickLabel_Cell;
        
        for x_tick_number = 1:length(PLOT.XtickLabel)

            XTickLabel_Cell{x_tick_number} = PLOT.XtickLabel(x_tick_number);

        end % of for x_tick_number
        
        set(gca, 'XTickLabel', XTickLabel_Cell);

        % clear temp-data
        clear temp_data;   
        clear temp_se; 
        
        % Remove top and right borders and associated X/Y ticks
        box off;
    
        
        
    end % of for ana (looping across channels)
    
elseif ANALYSIS.stmode == 2 % If using temporal decoding
    
    
    
    %% (Temporal Decoding) Load channel information (locations and labels)
    channel_file = [ANALYSIS.channellocs, ANALYSIS.channel_names_file];
    load(channel_file);
    
    % Copy to FW_ANALYSIS structure
    FW_ANALYSIS.chaninfo = chaninfo;
    FW_ANALYSIS.chanlocs = chanlocs;
    
    clear temp_data;
    clear temp_perm_data;
    
    
    
    %% (Temporal Decoding) Plot Results
    
    % Estimate of location for actual decoding results (depends on plotting preferences)
    if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean
        
        temp_data = ANALYSIS.RES.mean_subj_acc(:,1);
        fprintf('\nArithmetic mean used for plotting group average accuracy\n\n');

    elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

        temp_data = ANALYSIS.RES.trimmean_subj_acc(:, 1);
        fprintf('\n%i percent trimmed mean used for plotting group average accuracy\n\n', ANALYSIS.plot_robust_trimming);

    elseif ANALYSIS.plot_robust == 2 % If plotting medians

        temp_data = ANALYSIS.RES.median_subj_acc(:, 1);
        fprintf('\nMedian used for plotting group average accuracy\nError bars represent standard errors\n\n');

    end % of if ANALYSIS.plot_robust
    
    % Estimate of location for permutation decoding results (depends on plotting preferences)
    if ANALYSIS.permstats == 1 % If testing against theoretical chance
        
        temp_perm_data(1:size(ANALYSIS.RES.mean_subj_acc, 1)) = ANALYSIS.chancelevel;
        
    elseif ANALYSIS.permstats == 2 % If testing against permutation results

        if ANALYSIS.plot_robust == 0 % If plotting the arithmetic mean

            temp_perm_data = ANALYSIS.RES.mean_subj_perm_acc(:, 1);

        elseif ANALYSIS.plot_robust == 1 % If plotting trimmed means 

            temp_perm_data = ANALYSIS.RES.trimmean_subj_perm_acc(:, 1);

        elseif ANALYSIS.plot_robust == 2 % If plotting medians
            
            temp_perm_data = ANALYSIS.RES.median_subj_perm_acc(:, 1);
            
        end % of if ANALYSIS.plot_robust
    end % of if ANALYSIS.permstats

    % Plot estimate of group decoding accuracy (mean/median/trimmed mean)
    figure;
    
    topoplot_decoding(temp_data, FW_ANALYSIS.chanlocs, ...
        'style', 'both', ...
        'electrodes', 'labelpoint', ...
        'maplimits', 'minmax', ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
        
    % Plot estimate of group decoding accuracy relative to chance or permutation
    % decoding accuracy (actual - chance | actual - permutation)
    figure;
    
    % Plot data on scalp map
    topoplot_decoding(temp_data - temp_perm_data, FW_ANALYSIS.chanlocs, ...
        'style', 'both', ...
        'electrodes', 'ptslabels', ...
        'maplimits', 'minmax', ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' Decoding Results Minus Chance, N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
        
            
    % Plot statistically significant channels (corrected for multiple
    % comparisons)
    sig_locations = ANALYSIS.RES.h; % Mask based on statistical significance
    
    figure;
    
    topoplot_decoding(sig_locations, FW_ANALYSIS.chanlocs, ...
        'style', 'fill', ...
        'electrodes', 'ptslabels', ...
        'numcontour', 1, ...
        'conv', 'off', ...
        'maplimits', [0 2], ...
        'ccolor', [0 0 0], ...
        'ecolor', [1 1 1], ...
        'chaninfo', FW_ANALYSIS.chaninfo, ...
        'colormap', ANALYSIS.disp.temporal_decoding_colormap);
    hold on;
    
    % Title
    title([PLOT.TitleString, ANALYSIS.DCG, ' Masked by stat. sig., N=',  num2str(ANALYSIS.nsbj)], ...
                'FontSize', PLOT.TitleFontSize, ...
                'FontWeight', PLOT.TitleFontWeight);
            
end % of if ANALYSIS.stmode