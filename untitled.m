%{ 

%}

%% USER INPUT - OLFACTOMETER 

% identify file directory
olfactometer_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/Behavior/2025_03_03-14_38_17/2 odor passive delivery_scope-Bilateral-CH1/2 odor passive delivery_scope-2025_03_03-14_38_17-Events.csv';

% label relevant events
trial_start = "Output 1";
odor1_start = "Odor I 01 - eugenol,Output 4";
odor2_start = "Odor I 02 - methyl salicylate,Output 4";

% events raster plot viz
xMinInSec = 0;
xMaxInSec = inf;
yMinForRaster = 0;
yMaxForRater = 4;


%% MAIN

% get today's date for naming output files
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% load csv data and speficy text data as string instead of char
olfactometer_file = readtable(olfactometer_file_dir, TextType="string");

% get relevant info fom file name
fileName = olfactometer_file_dir(end-29:end-4);

% find rows with relevant events
trial_start_rows = matches(olfactometer_file.Events,trial_start);
odor1_start_rows = matches(olfactometer_file.Events,odor1_start);
odor2_start_rows = matches(olfactometer_file.Events,odor2_start);

% x axis in minutes
x_minutes = table2array(olfactometer_file(:,1))/60/1000;

% timestamps for relevant events
trial_start_ts = x_minutes(trial_start_rows);
odor1_start_ts = x_minutes(odor1_start_rows);
odor2_start_ts = x_minutes(odor2_start_rows);


%% FIG 1 - raster plot
fig1 = figure('name', strcat(fileName, '_', analysisDate, ' - raster'));
plot(trial_start_ts,1,'|','Color','k','LineWidth',1)
hold on;
plot(odor1_start_ts,2,'|','Color','b','LineWidth',1)
plot(odor2_start_ts,3,'|','Color','r','LineWidth',1)
hold off;
axis([xMinInSec xMaxInSec yMinForRaster yMaxForRater])
yticks([]);
xticks([0,30]);
xlabel('Time (min)');
set(fig1, 'Position', [0 0 500 100])    % x y width height
