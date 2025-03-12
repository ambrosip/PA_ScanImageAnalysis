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


%% USER INPUT - SCOPE H5

% identify file directory
h5_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/20250303_00006.h5';

% label relevant events
% ALERT: ImagingWindow was used as trial_start in some files and as
% imaging_window in other files!
trial_start_dataset = '/ImagingWindow';
odor_dataset = '/OdorDelivery';


%% USER INPUT - SCOPE IMGS

% identify file directory 
imgs_file_dir = '/Users/priscilla/Documents/Local - Moss Lab/20250303_m0041/odor delivery 2 (105 to 204)';

% acquisition parameters
frame_rate_hz = 12.86;
frames_per_img = 200;


%% MAIN - OLFACTOMETER

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


%% CONCATENATING AND LABELING OLFACTOMETER ODOR TIMESTAMPS

% copy olfactometer timestamps into a different variable
odor1_start_ts_labeled = odor1_start_ts;
odor2_start_ts_labeled = odor2_start_ts;

% add odor identity to second column
odor1_start_ts_labeled(:,2) = 1;
odor2_start_ts_labeled(:,2) = 2;

% concatenate two odor lists
odor_start_ts_labeled = [odor1_start_ts_labeled; odor2_start_ts_labeled];

% sort odors lists based on timestamps
odor_start_ts_labeled = sortrows(odor_start_ts_labeled);


%% MIXING OLFACTOMETER AND SCOPE IMG DATA

% get all tif file names in dir
imgFileDirs = dir(fullfile(imgs_file_dir, '*.tif'));
imgFileNames = {imgFileDirs.name}';
numberOfImgs = length(imgFileNames);

% get acquisition # from img file name
% ASSUMPTION: all files name are in the format "YYMMDD_mNNNN_AAAAA_..."
% where N is mouse number and A is acquisition number
acq_list = [];
for file=1:numberOfImgs
    img_file_name = cell2mat(imgFileNames(file));
    acq_list = [acq_list; img_file_name(16:20)];
end

% add 3rd column with acquisition number for sorting img files later
% I need this semi-complicated method of assigning acquisition numbers to
% sequential odor deliveries because sometimes the scope acquires extra
% files, so the acquisition numbers are not neatly ordered "1,2,3..."
% but often have gaps, like "1,3,4..."
% ALERT: for this method to work, I need to manually remove single frame
% files from the directory. TO DO: automate removal of single frame files
% (you can do this based on the size of the file)
odor_start_ts_labeled(:,3) = str2num(acq_list);

% display as table with headers
array2table(odor_start_ts_labeled,'VariableNames',{'min','odor','acq'})

% get list of acq for each odor
acq_odor1 = odor_start_ts_labeled(odor_start_ts_labeled(:,2) == 1,3);
acq_odor2 = odor_start_ts_labeled(odor_start_ts_labeled(:,2) == 2,3);


% %% COPY IMG FILES BASED ON ODOR
% 
% % make directories for copying files
% destination_dir1 = fullfile(imgs_file_dir,'odor 1');
% destination_dir2 = fullfile(imgs_file_dir,'odor 2');
% mkdir(destination_dir1);
% mkdir(destination_dir2);
% 
% % copy img files into odor-segregated folders
% for file=1:numberOfImgs
%     img_file_name = cell2mat(imgFileNames(file));
%     acq_number = str2num(img_file_name(16:20));
%     source_file = fullfile(imgFileDirs(file).folder, imgFileDirs(file).name);
%     if ismember(acq_number,acq_odor1)
%         copyfile(source_file,destination_dir1);
%     elseif ismember(acq_number,acq_odor2)
%         copyfile(source_file,destination_dir2);
%     end
% end 


%% MAIN - SCOPE H5

% get today's date for naming output files
analysisDate =  datestr(datetime('today'),'yyyy-mm-dd');

% get relevant data
total_data_points = h5info(h5_file_dir, trial_start_dataset).Dataspace.Size;
samplerate = h5info(h5_file_dir).Attributes.Value;
trial_start_TTL = h5read(h5_file_dir, trial_start_dataset);
odor_TTL = h5read(h5_file_dir, odor_dataset);

% get relevant info fom file name
fileName_h5 = h5_file_dir(end-16:end);

% x axis in minutes
x_data_points_h5 = 1:total_data_points;
x_minutes_h5 = x_data_points_h5/samplerate/60;

% find onset of TTL pulses
[trial_pks,trial_locs]=findpeaks(diff(trial_start_TTL),'MinPeakHeight',2);
[odor_pks,odor_locs]=findpeaks(diff(odor_TTL),'MinPeakHeight',2);

% find offset of odor TTL pulse
[odor_end_pks,odor_end_locs]=findpeaks(-diff(odor_TTL),'MinPeakHeight',2);

% adjust timing of locs (to account for diff function used to find peaks)
trial_locs = trial_locs + 1;
odor_locs = odor_locs + 1;
odor_end_locs = odor_end_locs + 1;

% convert locs from data points to minutes
trial_locs = trial_locs/samplerate/60;
odor_locs = odor_locs/samplerate/60;
odor_end_locs = odor_end_locs/samplerate/60;


%% FIG 1 - OLFACTOMETER RASTER

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


%% FIG 2 - SCOPE H5 Time-series and peaks

fig2 = figure('name', strcat(fileName_h5, '_', analysisDate, ' - scope events'));
plot(x_minutes_h5,trial_start_TTL, 'Color','k')
hold on;
plot(trial_locs,trial_pks,'o','Color','k')
plot(x_minutes_h5,odor_TTL, 'Color','m')
plot(odor_locs,trial_pks,'o','Color','m')
plot(odor_end_locs,odor_end_pks,'*','Color','y')
hold off


%% FIG 3 - OLFACTOMETER vs SCOPE raster

fig3 = figure('name', strcat(fileName_h5, '_', analysisDate, ' - raster comparison'));
% olfactometer
    plot(trial_start_ts,1,'|','Color','k','LineWidth',1)
    hold on;
    plot(odor1_start_ts,2,'|','Color','b','LineWidth',1)
    plot(odor2_start_ts,3,'|','Color','r','LineWidth',1)
% scope
    xline(trial_locs,'Color','k')
    xline(odor_locs,'Color','m')
hold off;
axis([xMinInSec xMaxInSec yMinForRaster yMaxForRater])
yticks([]);
xticks([0,30]);
xlabel('Time (min)');
set(fig3, 'Position', [0 0 1000 100])    % x y width height


%% 

baseline_dur_in_s = mean((odor_locs - trial_locs)*60);
img_dur_in_s = frames_per_img / frame_rate_hz;
baseline_dur_in_frames = baseline_dur_in_s * frame_rate_hz;
odor_dur_in_s = mean((odor_end_locs - odor_locs)*60);
odor_dur_in_frames = odor_dur_in_s * frame_rate_hz;



